#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Ghostty's font and palette live in its own tracked config, but iTerm2 keeps
# both in its preferences plist, so they have to be configured separately.
# Without the font, starship's powerline separators and icons render as "?"
# boxes; without the palette, iTerm2 stays on its default light scheme while
# Ghostty is dark.
FONT="JetBrainsMonoNFM-Regular"   # Nerd Font *Mono* variant — correct for terminals
SIZE=13
GHOSTTY_CONFIG="$REPO_ROOT/.config/ghostty/config"
ITERMCOLORS="$REPO_ROOT/.config/iterm2/monokai.itermcolors"

# iTerm2's tab-bar theme, stored in TabStyleWithAutomaticOption. The numbers are
# an internal enum with no documented mapping, and the order of strings in the
# app's nib does not reflect it — so this stays empty until the value has been
# read back from an iTerm2 actually set via the GUI. Writing a guessed number
# would silently apply the wrong theme. Export TAB_STYLE=<n> to manage it.
TAB_STYLE="${TAB_STYLE:-}"

step "Setting up iTerm2..."

if ! find_app "iTerm.app" >/dev/null && ! find_app "iTerm 2.app" >/dev/null; then
  skip "iTerm2 not installed"
  exit 0
fi

if ! ls ~/Library/Fonts/JetBrainsMonoNerdFont* >/dev/null 2>&1; then
  warn "JetBrains Mono Nerd Font not installed — install it via the Brewfile first."
  exit 0
fi

# Keep the colour preset in step with the Ghostty palette. Generating rather
# than maintaining a second copy by hand means the two terminals cannot drift.
if [[ -f "$GHOSTTY_CONFIG" ]]; then
  if python3 "$SCRIPT_DIR/generate_itermcolors.py" "$GHOSTTY_CONFIG" "$ITERMCOLORS" >/dev/null; then
    ok "regenerated $(basename "$ITERMCOLORS") from the Ghostty palette"
  else
    warn "could not regenerate the iTerm2 colour preset"
  fi
fi

# iTerm2 holds its preferences in memory and writes them out on quit, so
# anything written here while it is running gets clobbered. Only touch the plist
# when it is closed; otherwise record the GUI equivalents as manual steps.
#
# Detect via ps, not pgrep. pgrep proved unreliable for this process — both
# `-x iTerm2` and `-f` on the executable path failed to match a demonstrably
# running iTerm2, whose comm is the full bundle path. A missed detection is not
# harmless here: the script would write prefs that iTerm2 silently overwrites.
if ps -A -o comm= | grep -q "/MacOS/iTerm2$"; then
  warn "iTerm2 is running — it would overwrite these settings on quit."
  manual_step "Set iTerm2 up in the GUI (it is running): Settings > Profiles > Text > Font > 'JetBrainsMono Nerd Font Mono' size $SIZE; Settings > Profiles > Colors > Color Presets > Import... > $ITERMCOLORS then select 'monokai'; Settings > Appearance > Theme > Minimal. Or quit iTerm2 and re-run scripts/setup_iterm2.sh."
  exit 0
fi

python3 - "$FONT" "$SIZE" "$ITERMCOLORS" "$TAB_STYLE" <<'PYEOF'
import os
import plistlib
import subprocess
import sys
import tempfile

font, size, colours_path, tab_style = sys.argv[1:5]

raw = subprocess.run(["defaults", "export", "com.googlecode.iterm2", "-"],
                     capture_output=True).stdout
prefs = plistlib.loads(raw) if raw else {}
profiles = prefs.get("New Bookmarks") or []

colours = {}
if os.path.exists(colours_path):
    with open(colours_path, "rb") as fh:
        colours = plistlib.load(fh)

for profile in profiles:
    profile["Normal Font"] = f"{font} {size}"
    profile["Non Ascii Font"] = f"{font} {size}"
    profile["Use Non-ASCII Font"] = False
    # An .itermcolors file is keyed by exactly the names iTerm2 stores colours
    # under in a profile, so the preset merges in without translation.
    profile.update(colours)

prefs["New Bookmarks"] = profiles

# Tab style is global, not per-profile.
if tab_style:
    prefs["TabStyleWithAutomaticOption"] = int(tab_style)

with tempfile.NamedTemporaryFile(suffix=".plist", delete=False) as fh:
    fh.write(plistlib.dumps(prefs))
    tmp = fh.name
subprocess.run(["defaults", "import", "com.googlecode.iterm2", tmp], check=True)
os.unlink(tmp)

extra = ", tab style" if tab_style else ""
print(f"  updated {len(profiles)} profile(s): font, {len(colours)} colours{extra}")
PYEOF

ok "iTerm2 font and colours applied (restart iTerm2 to see them)"
if [[ -z "$TAB_STYLE" ]]; then
  manual_step "Set the iTerm2 tab bar theme once by hand: Settings > Appearance > Theme > Minimal. Then record the value it writes (defaults read com.googlecode.iterm2 TabStyleWithAutomaticOption) as TAB_STYLE in scripts/setup_iterm2.sh so it is managed from then on."
fi
