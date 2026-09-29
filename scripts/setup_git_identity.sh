#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Personal projects commit as code@jitsejan.com. Scoping this with includeIf
# rather than a global user.email means a work repository can never pick the
# address up by accident — and git will refuse to commit outside this tree until
# an identity is chosen there, which is safer than a silently wrong author.
PERSONAL_DIR="$HOME/code/personal/"
INCLUDED_FILE="$HOME/.config/git/personal.gitconfig"
GITCONFIG="$HOME/.gitconfig"

step "Setting up git identity..."

if [[ ! -f "$INCLUDED_FILE" ]]; then
  warn "$INCLUDED_FILE missing — bootstrap symlinks it; run the symlink step first."
  exit 0
fi

# git config --get-all returns every includeIf path already configured; adding a
# duplicate would be harmless but noisy, so only append when it isn't there.
if git config --global --get-all "includeIf.gitdir:${PERSONAL_DIR}.path" 2>/dev/null \
     | grep -qxF "$INCLUDED_FILE"; then
  ok "includeIf for $PERSONAL_DIR already configured"
else
  git config --global --add "includeIf.gitdir:${PERSONAL_DIR}.path" "$INCLUDED_FILE"
  ok "git will use $INCLUDED_FILE for repos under $PERSONAL_DIR"
fi

# A trailing slash in a gitdir: pattern implicitly matches everything beneath it,
# so this covers every repo in the personal tree without listing them.
if [[ -f "$GITCONFIG" ]]; then
  ok "~/.gitconfig updated"
fi

# Report what the current directory actually resolves to, which is the thing
# that matters and the thing people get wrong.
if git rev-parse --git-dir >/dev/null 2>&1; then
  resolved_name="$(git config user.name || echo '(unset)')"
  resolved_email="$(git config user.email || echo '(unset)')"
  ok "this repo commits as: $resolved_name <$resolved_email>"
  if [[ "$resolved_email" == "(unset)" ]]; then
    manual_step "No git identity resolves here. Set one: git config user.email '...'"
  fi
fi
