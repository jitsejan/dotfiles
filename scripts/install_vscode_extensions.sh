#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

step "Installing VS Code extensions..."
activate_brew || true

if ! no_admin; then
  skip "VS Code extensions come from the Brewfile on an admin machine"
  exit 0
fi

if ! command -v code >/dev/null 2>&1; then
  warn "the 'code' CLI is not available — install the visual-studio-code cask first."
  exit 0
fi

# The Brewfile remains the source of truth. Its `vscode` entries sit behind
# `unless no_admin` so `brew bundle` doesn't attempt them and fail, so read the
# list by deliberately evaluating the *admin* branch.
# Built with a read loop rather than `mapfile`, which is bash 4+ — macOS ships
# bash 3.2, so mapfile would fail on exactly the fresh machine this is for.
EXTENSIONS=()
while IFS= read -r line; do
  [[ -n "$line" ]] && EXTENSIONS+=("$line")
done < <(
  HOMEBREW_DOTFILES_NO_ADMIN=0 brew bundle list --vscode --file="$REPO_ROOT/Brewfile" 2>/dev/null \
    | grep -v '^Skipping'
)

if [[ "${#EXTENSIONS[@]}" -eq 0 ]]; then
  warn "no vscode entries found in the Brewfile"
  exit 0
fi

# Installed extension ids are reported lowercase; compare case-insensitively.
installed="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"

failed=0
for ext in "${EXTENSIONS[@]}"; do
  [[ -z "$ext" ]] && continue
  if grep -qxF "$(echo "$ext" | tr '[:upper:]' '[:lower:]')" <<<"$installed"; then
    ok "$ext already installed"
  elif code --install-extension "$ext" --force >/dev/null 2>&1; then
    ok "installed $ext"
  else
    warn "failed to install $ext"
    failed=$((failed + 1))
  fi
done

if [[ "$failed" -gt 0 ]]; then
  manual_step "$failed VS Code extension(s) failed to install. Retry: ./scripts/install_vscode_extensions.sh"
fi
