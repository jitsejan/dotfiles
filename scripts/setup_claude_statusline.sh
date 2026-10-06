#!/usr/bin/env bash
# Point Claude Code at the repo's Monokai statusline.
#
# ~/.claude/settings.json is deliberately NOT tracked in this repo — it holds MCP
# server tokens. So rather than symlinking the whole file, this merges just the
# statusLine key into it and leaves everything else untouched.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Configuring Claude Code statusline..."

SETTINGS="$HOME/.claude/settings.json"
STATUSLINE="$REPO_ROOT/.claude/statusline.sh"

if ! command -v python3 &>/dev/null; then
  warn "python3 not found — skipping statusline wiring"
  exit 0
fi

chmod +x "$STATUSLINE"

mkdir -p "$(dirname "$SETTINGS")"
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

# Merge in place. Rewrites only the statusLine key, so tokens and plugin state in
# the same file survive — and re-running is a no-op once it already points here.
STATUSLINE_PATH="$STATUSLINE" python3 - "$SETTINGS" <<'PY'
import json, os, sys

path = sys.argv[1]
command = os.environ["STATUSLINE_PATH"]

try:
    with open(path) as f:
        settings = json.load(f)
except (json.JSONDecodeError, OSError) as exc:
    print(f"  ! {path} is not readable JSON ({exc}) — leaving it alone")
    sys.exit(0)

desired = {"type": "command", "command": command, "padding": 0}

if settings.get("statusLine") == desired:
    print("  = statusLine already configured")
    sys.exit(0)

settings["statusLine"] = desired

# Write via a temp file in the same directory, then replace, so an interrupted
# run can never leave a truncated settings.json behind.
tmp = f"{path}.dotfiles-tmp"
with open(tmp, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
os.replace(tmp, path)
print("  → statusLine set")
PY

ok "Claude Code statusline configured"
