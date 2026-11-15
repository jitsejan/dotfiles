#!/usr/bin/env bash
# Merge the tracked Claude Code defaults into ~/.claude/settings.json.
#
# The file itself is not tracked (it holds MCP server tokens), so this adds
# only what every machine should have and leaves every other key alone:
#   - attribution off: no Co-Authored-By trailer, no "Generated with" PR line,
#     no session URL
#   - the pace-gate hook (linked to ~/.claude/hooks/ by bootstrap) on PR merges
#     and Redmine status changes
# A hook already present with the same command is not added twice, so re-running
# is a no-op. Employer hooks are added by hand or by the employer's own setup.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Merging Claude Code settings defaults..."

SETTINGS="$HOME/.claude/settings.json"
HOOK="$HOME/.claude/hooks/pace-gate.sh"

if ! command -v python3 &>/dev/null; then
  warn "python3 not found — skipping Claude settings"
  exit 0
fi
[[ -e "$HOOK" ]] || warn "$HOOK not linked yet; the hook entries are added anyway and start working once it is"
command -v jq &>/dev/null || warn "jq not found; the pace gate needs it (it is in the Brewfile)"

mkdir -p "$(dirname "$SETTINGS")"
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

python3 - "$SETTINGS" <<'PY'
import json, os, sys

path = sys.argv[1]
try:
    with open(path) as f:
        settings = json.load(f)
except (json.JSONDecodeError, OSError) as exc:
    print(f"  ! {path} is not readable JSON ({exc}) — leaving it alone")
    sys.exit(0)

changes = []

if settings.get("attribution") != {"commit": "", "pr": ""}:
    settings["attribution"] = {"commit": "", "pr": ""}
    changes.append("attribution off")
if settings.get("sessionUrl") is not False:
    settings["sessionUrl"] = False
    changes.append("sessionUrl off")

gate = "~/.claude/hooks/pace-gate.sh"
wanted = {
    "PreToolUse": [
        {"matcher": "Bash", "hooks": [{"type": "command", "command": f"{gate} check", "if": "Bash(gh pr merge*)", "timeout": 30, "statusMessage": "Checking merge pace and CI"}]},
        {"matcher": "mcp__redmine__update_issue", "hooks": [{"type": "command", "command": f"{gate} check", "timeout": 10}]},
    ],
    "PostToolUse": [
        {"matcher": "Bash", "hooks": [{"type": "command", "command": f"{gate} record", "if": "Bash(gh pr merge*)", "timeout": 10}]},
        {"matcher": "mcp__redmine__update_issue", "hooks": [{"type": "command", "command": f"{gate} record", "timeout": 10}]},
    ],
}

hooks = settings.setdefault("hooks", {})
for event, entries in wanted.items():
    current = hooks.setdefault(event, [])
    for entry in entries:
        cmd = entry["hooks"][0]["command"]
        present = any(
            g.get("matcher") == entry["matcher"]
            and any(h.get("command") == cmd for h in g.get("hooks", []))
            for g in current
        )
        if not present:
            current.append(entry)
            changes.append(f"{event} {entry['matcher']}: {cmd.split()[-1]}")

if not changes:
    print("  = Claude settings defaults already in place")
    sys.exit(0)

# Temp file then replace, so an interrupted run never truncates settings.json.
tmp = f"{path}.dotfiles-tmp"
with open(tmp, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
os.replace(tmp, path)
for c in changes:
    print(f"  → {c}")
PY

ok "Claude Code settings defaults merged"
