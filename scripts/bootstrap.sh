#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Run from the repo root regardless of where the user invoked the script, so the
# symlinks below always point at tracked files rather than at $PWD.
cd "$REPO_ROOT"

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
link_config() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    ok "$dest already linked"
    return
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "  ↻ replacing existing $dest"
    rm -rf "$dest"
  fi
  ln -s "$src" "$dest"
  echo "  → linked $dest"
}

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
mkdir -p ~/.config
link_config "$REPO_ROOT/.config/ghostty" ~/.config/ghostty
link_config "$REPO_ROOT/.config/starship.toml" ~/.config/starship.toml
link_config "$REPO_ROOT/.config/fish" ~/.config/fish
link_config "$REPO_ROOT/.config/zsh" ~/.config/zsh

mkdir -p ~/.config/git
link_config "$REPO_ROOT/.config/git/personal.gitconfig" ~/.config/git/personal.gitconfig

VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
if [[ -d "$VSCODE_USER_DIR" ]]; then
  link_config "$REPO_ROOT/.config/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
  link_config "$REPO_ROOT/.config/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
else
  skip "VS Code config (VS Code not launched yet — re-run bootstrap after first launch)"
fi

./scripts/setup_shell.sh || true
./scripts/setup_git_identity.sh || true
./scripts/install_python_tools.sh || true
./scripts/install_apps.sh || true
./scripts/setup_obsidian.sh || true
./scripts/setup_docker.sh || true
./scripts/setup_beyondcompare.sh || true
./scripts/setup_fork.sh || true
./scripts/setup_terraform.sh || true
./scripts/setup_git_filter_repo.sh || true
./scripts/setup_dock.sh || true

# Anything skipped for lack of admin is listed rather than silently dropped.
if no_admin; then
  step "Software that needs an admin password (skipped):"
  echo "  • Docker Desktop        → colima was set up instead"
  echo "  • zoom, windows-app, intune-company-portal → ask IT, or use the web versions"
  echo "  • mactex                → for LaTeX without admin, use: brew install pandoc + tinytex"
fi

echo
echo "✅ Dotfiles setup complete!"

if [[ -s "$MANUAL_STEPS_FILE" ]]; then
  echo
  echo "📋 Manual steps still needed:"
  cat "$MANUAL_STEPS_FILE"
fi
