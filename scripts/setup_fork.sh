#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Checking Fork Git client..."

if FORK_APP="$(find_app "Fork.app")"; then
  ok "Fork found at $FORK_APP"
else
  warn "Fork.app not found. Install it with: brew install --cask fork"
fi

# Check the identity that actually applies here, not the global one. Identity is
# scoped per-directory with includeIf (see setup_git_identity.sh), so a repo can
# be correctly configured while `git config --global user.email` is deliberately
# empty — checking --global would report a problem that does not exist.
if git config user.name >/dev/null 2>&1 && git config user.email >/dev/null 2>&1; then
  ok "Git identity here: $(git config user.name) <$(git config user.email)>"
else
  warn "No git identity resolves in this directory."
  manual_step "Set a git identity for this tree: git config user.name '...' && git config user.email '...'"
fi
