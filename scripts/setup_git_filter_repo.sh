#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Checking git-filter-repo..."
activate_brew || true

if command -v git-filter-repo &>/dev/null; then
  ok "git-filter-repo found: $(git filter-repo --version 2>/dev/null)"
else
  warn "git-filter-repo not found. Install it with: brew install git-filter-repo"
fi
