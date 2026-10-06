#!/usr/bin/env bash
# Install the tracked iTerm2 Monokai profile.
#
# iTerm2 holds its preferences in memory and writes com.googlecode.iterm2.plist
# out on quit, so anything written directly into that plist while iTerm2 runs is
# silently clobbered. DynamicProfiles sidestep that entirely: iTerm2 *reads* the
# JSON files in its DynamicProfiles directory and never writes to them, picking
# changes up within seconds and without a restart. So the profile is tracked in
# this repo and symlinked into place, like every other config here.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Setting up iTerm2..."

if ! find_app "iTerm.app" >/dev/null && ! find_app "iTerm 2.app" >/dev/null; then
  skip "iTerm2 not installed"
  exit 0
fi

# The profile names JetBrainsMonoNFM-Regular. If the font is missing the prompt
# renders powerline separators and Nerd Font icons as ? boxes, so warn loudly
# rather than installing a profile that looks broken.
if ! ls ~/Library/Fonts/JetBrainsMonoNerdFont* >/dev/null 2>&1; then
  warn "JetBrains Mono Nerd Font not installed — run 'brew bundle' first, or the profile will show ? boxes."
fi

PROFILE_SRC="$REPO_ROOT/.config/iterm2/DynamicProfiles/monokai.json"
PROFILE_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
PROFILE_DEST="$PROFILE_DIR/monokai.json"

if [[ ! -f "$PROFILE_SRC" ]]; then
  warn "tracked profile missing at $PROFILE_SRC"
  exit 0
fi

# Validate before linking: iTerm2 ignores a malformed DynamicProfile silently,
# which is a miserable thing to debug from the UI.
if command -v python3 &>/dev/null; then
  if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$PROFILE_SRC" 2>/dev/null; then
    warn "$PROFILE_SRC is not valid JSON — not linking it"
    exit 0
  fi
fi

mkdir -p "$PROFILE_DIR"

if [[ -L "$PROFILE_DEST" && "$(readlink "$PROFILE_DEST")" == "$PROFILE_SRC" ]]; then
  ok "iTerm2 Monokai profile already linked"
else
  [[ -e "$PROFILE_DEST" || -L "$PROFILE_DEST" ]] && rm -f "$PROFILE_DEST"
  ln -s "$PROFILE_SRC" "$PROFILE_DEST"
  echo "  → linked $PROFILE_DEST"
fi

# A DynamicProfile cannot make itself the default profile — that pointer lives in
# the main plist, which iTerm2 would overwrite on quit. Setting it by hand is a
# one-off, so record it as a manual step rather than fighting the plist.
if ! defaults read com.googlecode.iterm2 "Default Bookmark Guid" 2>/dev/null | grep -q "jj-monokai-fish"; then
  manual_step "Make Monokai the default iTerm2 profile: Settings → Profiles → select 'Monokai' → Other Actions… → Set as Default."
fi

ok "iTerm2 Monokai profile installed"
