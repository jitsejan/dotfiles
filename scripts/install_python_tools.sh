#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Installing Python tools..."
activate_brew || true

# uv is installed via the Brewfile. pipx keeps ruff and pyright in their own
# virtualenvs; both land under ~/.local/bin, so no admin is involved.
# ruff covers linting + formatting + import sorting (replaces black & isort).
if command -v pipx &>/dev/null; then
  pipx install ruff || warn "pipx install ruff failed"
  pipx install pyright || warn "pipx install pyright failed"
  ok "ruff and pyright installed via pipx"
else
  warn "pipx not found. Install it with: brew install pipx"
fi
