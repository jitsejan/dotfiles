#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Setting up Fish as the interactive shell..."

activate_brew || true

if ! command -v fish >/dev/null 2>&1; then
  warn "fish not found — skipping shell setup (install it via the Brewfile first)."
  exit 0
fi

FISH_PATH="$(command -v fish)"
ok "fish found at $FISH_PATH"

# --- Admin path: make fish the real login shell ----------------------------

setup_login_shell_as_admin() {
  local current
  current="$(dscl . -read ~/ UserShell 2>/dev/null | awk '{print $2}')"

  if [[ "$current" == "$FISH_PATH" ]]; then
    ok "fish is already your login shell"
    return 0
  fi

  if ! grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null; then
    step "Adding $FISH_PATH to /etc/shells (needs sudo)..."
    sudo sh -c "echo '$FISH_PATH' >> /etc/shells"
  fi
  chsh -s "$FISH_PATH"
  ok "login shell changed to fish"
}

# --- No-admin path: hand off from zsh --------------------------------------

# /etc/shells is root-owned and chsh validates against it, so the login shell
# stays zsh. Instead, zsh execs fish for interactive sessions. The logic lives in
# a tracked repo file; ~/.zshrc only gets a one-line source hook.
setup_login_shell_no_admin() {
  local zshrc="$HOME/.zshrc"
  local marker="# >>> dotfiles: fish handoff >>>"
  local launcher="$HOME/.config/zsh/launch-fish.zsh"

  if [[ ! -f "$launcher" ]]; then
    warn "$launcher missing — bootstrap symlinks it; run the symlink step first."
    return 0
  fi

  if grep -qF "$marker" "$zshrc" 2>/dev/null; then
    ok "~/.zshrc already hands off to fish"
    return 0
  fi

  step "Appending the fish handoff to ~/.zshrc..."
  # Appended last so the exports above it are inherited by the fish process.
  cat >> "$zshrc" <<'BLOCK'

# >>> dotfiles: fish handoff >>>
# No admin rights to chsh, so zsh launches fish for interactive shells instead.
# Logic lives in the dotfiles repo; unset DOTFILES_NO_FISH=1 to bypass for a session.
[ -f "$HOME/.config/zsh/launch-fish.zsh" ] && source "$HOME/.config/zsh/launch-fish.zsh"
# <<< dotfiles: fish handoff <<<
BLOCK
  ok "~/.zshrc now launches fish for interactive shells"
  manual_step "Open a new terminal tab to land in fish (or run 'exec fish' now)."
}

if no_admin; then
  echo "  (no admin: chsh cannot be used, /etc/shells is not writable)"
  setup_login_shell_no_admin
else
  setup_login_shell_as_admin
fi
