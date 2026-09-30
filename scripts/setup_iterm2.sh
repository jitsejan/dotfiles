#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Ghostty's font lives in its own tracked config, but iTerm2 keeps font settings
# in its preferences plist, so a Nerd Font has to be set there separately. Without
# it the starship prompt renders powerline separators and icons as ? boxes.
FONT="JetBrainsMonoNFM-Regular"   # Nerd Font *Mono* variant — correct for terminals
SIZE=13

step "Setting up iTerm2..."

if ! find_app "iTerm.app" >/dev/null && ! find_app "iTerm 2.app" >/dev/null; then
  skip "iTerm2 not installed"
  exit 0
fi

if ! ls ~/Library/Fonts/JetBrainsMonoNerdFont* >/dev/null 2>&1; then
  warn "JetBrains Mono Nerd Font not installed — install it via the Brewfile first."
  exit 0
fi

# iTerm2 holds its preferences in memory and writes them out on quit, so anything
# written here while it is running gets clobbered. Only touch the plist when it
# is closed; otherwise tell the user where the setting lives.
# Detect via ps, not pgrep. pgrep proved unreliable for this process here — both
# `-x iTerm2` and `-f` on the executable path failed to match a demonstrably
# running iTerm2 (its comm is the full bundle path, "…/iTerm 2.app/Contents/
# MacOS/iTerm2"). A missed detection is not harmless: the script would write
# prefs that iTerm2 silently overwrites when it quits.
if ps -A -o comm= | grep -q "/MacOS/iTerm2$"; then
  warn "iTerm2 is running — it would overwrite this on quit."
  manual_step "Set the iTerm2 font by hand: Settings → Profiles → Text → Font → 'JetBrainsMono Nerd Font Mono' (size $SIZE). Or quit iTerm2 and re-run scripts/setup_iterm2.sh."
  exit 0
fi

current="$(defaults read com.googlecode.iterm2 "New Bookmarks" 2>/dev/null | grep -c "$FONT" || true)"
if [[ "$current" -gt 0 ]]; then
  ok "iTerm2 already uses $FONT"
  exit 0
fi

# Rewrite the font in every profile. Done via plistlib rather than `defaults`
# because the profiles live in an array of dictionaries that `defaults write`
# cannot edit in place.
python3 - "$FONT" "$SIZE" <<'PY'
import plistlib, subprocess, sys, tempfile, os
font, size = sys.argv[1], sys.argv[2]
raw = subprocess.run(["defaults", "export", "com.googlecode.iterm2", "-"],
                     capture_output=True).stdout
prefs = plistlib.loads(raw) if raw else {}
profiles = prefs.get("New Bookmarks") or []
for p in profiles:
    p["Normal Font"] = f"{font} {size}"
    p["Non Ascii Font"] = f"{font} {size}"
    p["Use Non-ASCII Font"] = False
prefs["New Bookmarks"] = profiles
with tempfile.NamedTemporaryFile(suffix=".plist", delete=False) as fh:
    fh.write(plistlib.dumps(prefs)); tmp = fh.name
subprocess.run(["defaults", "import", "com.googlecode.iterm2", tmp], check=True)
os.unlink(tmp)
print(f"  updated {len(profiles)} iTerm2 profile(s)")
PY

ok "iTerm2 font set to $FONT $SIZE (restart iTerm2 to see it)"
