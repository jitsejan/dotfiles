#!/usr/bin/env bash
# Report how this Mac differs from what the repo describes, without changing
# anything. `./scripts/bootstrap.sh --dry-run` runs this too: everything it flags
# is something a real bootstrap run would install or fix.
#
# Checks: Brewfile entries not installed, tracked configs not symlinked (or with
# something else in the way), the iTerm2 profile, and the fish shell setup.
# Outdated packages are listed for information but don't count as drift.
#
# Exits 0 when nothing needs doing, 1 when something does.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

DRIFT=0
bad() { echo "  ✗ $*"; DRIFT=$((DRIFT + 1)); }

# --- Homebrew packages -------------------------------------------------------

step "Brewfile packages..."
if ! activate_brew || ! brew --prefix >/dev/null 2>&1; then
  bad "Homebrew is not installed or not working — bootstrap installs it"
else
  # --no-upgrade: only report what is missing; outdated is listed separately.
  if missing="$(brew bundle check --no-upgrade --verbose --file="$REPO_ROOT/Brewfile" 2>&1)"; then
    ok "every Brewfile entry is installed"
  else
    while IFS= read -r line; do
      [[ "$line" == *"needs to be installed"* ]] && bad "${line#→ }"
    done <<< "$missing"
    # Anything brew reported that wasn't a per-entry line (e.g. a Brewfile error).
    grep -q "needs to be installed" <<< "$missing" || bad "brew bundle check failed: $missing"
  fi

  outdated="$(brew outdated --quiet 2>/dev/null || true)"
  if [[ -n "$outdated" ]]; then
    echo "  ℹ outdated (not drift; 'brew upgrade' updates them): $(echo "$outdated" | tr '\n' ' ')"
  fi
fi

# --- Config symlinks ---------------------------------------------------------

check_link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" && -e "$dest" ]]; then
    ok "$dest"
  elif [[ -L "$dest" ]]; then
    bad "$dest points to $(readlink "$dest"), not the repo"
  elif [[ -e "$dest" ]]; then
    bad "$dest is a real file or folder — bootstrap would move it to a .backup and link it"
  else
    bad "$dest is not linked"
  fi
}

step "Config symlinks..."
while IFS=$'\t' read -r src dest; do
  check_link "$src" "$dest"
done < <(tracked_links "$REPO_ROOT")

if find_app "iTerm.app" >/dev/null || find_app "iTerm 2.app" >/dev/null; then
  check_link "$REPO_ROOT/.config/iterm2/DynamicProfiles/monokai.json" \
    "$HOME/Library/Application Support/iTerm2/DynamicProfiles/monokai.json"
fi

# --- Shell ---------------------------------------------------------------------

step "Fish shell..."
fish_bin="$(command -v fish 2>/dev/null)" || fish_bin=""
if [[ -z "$fish_bin" ]] && prefix="$(brew_prefix 2>/dev/null)" && [[ -x "$prefix/bin/fish" ]]; then
  fish_bin="$prefix/bin/fish"
fi
if [[ -z "$fish_bin" ]]; then
  bad "fish is not installed"
elif no_admin; then
  if grep -qF "# >>> dotfiles: fish handoff >>>" "$HOME/.zshrc" 2>/dev/null; then
    ok "your .zshrc hands off to fish"
  else
    bad "your .zshrc does not hand off to fish"
  fi
else
  login_shell="$(dscl . -read ~/ UserShell 2>/dev/null | awk '{print $2}')"
  if [[ "$login_shell" == */fish ]]; then
    ok "fish is the login shell"
  else
    bad "login shell is ${login_shell:-unknown}, not fish"
  fi
fi

# --- Summary -------------------------------------------------------------------

echo
if (( DRIFT == 0 )); then
  echo "✅ This Mac matches the repo."
  exit 0
fi
echo "⚠️  $DRIFT thing(s) differ from the repo. Run ./scripts/bootstrap.sh to fix them."
exit 1
