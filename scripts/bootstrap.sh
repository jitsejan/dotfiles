#!/usr/bin/env bash
# Re-exec under bash when started as `sh scripts/...`. macOS's /bin/sh is bash in
# POSIX mode, which rejects bash-only syntax such as `< <(...)` before any of it
# runs. Plain POSIX syntax only up to here; the sentinel stops a re-exec loop.
if [ -z "${BASH_VERSION:-}" ] || case ":${SHELLOPTS:-}:" in *:posix:*) true ;; *) false ;; esac; then
  if [ -z "${DOTFILES_REEXEC:-}" ]; then
    DOTFILES_REEXEC=1 exec bash "$0" "$@"
  fi
  echo "error: run this with bash, e.g. ./scripts/bootstrap.sh" >&2
  exit 1
fi
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Run from the repo root regardless of where the user invoked the script, so the
# symlinks below always point at tracked files rather than at $PWD.
cd "$REPO_ROOT"

# --dry-run changes nothing: it reports what a real run would still install or
# link, which is exactly what verify.sh checks.
if [[ "${1:-}" == "--dry-run" ]]; then
  echo "🔍 Dry run — nothing is changed. A real run would fix everything flagged below."
  exec "$SCRIPT_DIR/verify.sh"
fi

# Start each run with a clean manual-steps list.
: > "$MANUAL_STEPS_FILE"
trap 'rm -f "$MANUAL_STEPS_FILE"' EXIT

echo "🚀 Bootstrapping your dev environment..."
if no_admin; then
  echo "🔒 No admin rights detected — running in no-admin mode."
  echo "   Apps install to $(app_install_dir), CLI shims to $(user_bin_dir),"
  echo "   Docker comes from colima, and fish is launched from zsh instead of chsh."
else
  echo "🔑 Admin rights detected — running the full setup."
fi
echo

# Safely (re)create a symlink at $2 pointing to $1, replacing any existing
# file/dir/symlink so we never nest a link inside an existing directory.

# Warn early if the Swift/Command Line Tools toolchain is broken — otherwise
# Homebrew casks that move .app bundles fail cryptically mid-run.
check_swift_toolchain() {
  if ! printf 'print("ok")\n' | swift - >/dev/null 2>&1; then
    warn "Swift / Command Line Tools look broken — casks that move .app bundles may fail."
    if no_admin; then
      manual_step "Ask IT to reinstall the Command Line Tools (needs admin): sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --install"
    else
      echo "    Fix: sudo rm -rf /Library/Developer/CommandLineTools && sudo xcode-select --install"
    fi
  fi
}

OS="$(uname -s)"
if [[ "$OS" == "Darwin" ]]; then
  check_swift_toolchain
  ./scripts/install_brew.sh
elif [[ "$OS" == "Linux" ]]; then
  ./scripts/install_apt.sh || echo "Skip (not implemented)"
else
  echo "❌ Unsupported OS: $OS"
  exit 1
fi

activate_brew || true

# Symlinks come before the shell switch so fish starts with its config already
# in place, and so setup_shell.sh can find the tracked zsh handoff snippet.
step "Symlinking configs..."
while IFS=$'\t' read -r src dest; do
  mkdir -p "$(dirname "$dest")"
  link_config "$src" "$dest"
done < <(tracked_links "$REPO_ROOT")
find_app "Visual Studio Code.app" >/dev/null || [[ -d "$HOME/Library/Application Support/Code/User" ]] \
  || skip "VS Code config (VS Code not installed)"

./scripts/setup_shell.sh || true
./scripts/setup_git_identity.sh || true
./scripts/install_python_tools.sh || true
./scripts/install_apps.sh || true
./scripts/install_vscode_extensions.sh || true
./scripts/setup_obsidian.sh || true
./scripts/setup_docker.sh || true
./scripts/setup_fork.sh || true
./scripts/setup_terraform.sh || true
./scripts/setup_git_filter_repo.sh || true
./scripts/setup_iterm2.sh || true
./scripts/setup_claude_statusline.sh || true
./scripts/setup_dock.sh || true

# Anything substituted for lack of admin is named rather than silently dropped.
if no_admin; then
  step "Substitutions made because there is no admin password:"
  echo "  • Docker Desktop → colima"
  echo "  • node (brew)    → fnm + upstream's prebuilt binaries"
  echo "  • opencode       → its npm package"
fi

echo
echo "✅ Dotfiles setup complete!"

if [[ -s "$MANUAL_STEPS_FILE" ]]; then
  echo
  echo "📋 Manual steps still needed:"
  cat "$MANUAL_STEPS_FILE"
fi
