#!/usr/bin/env bash
# Seed the untracked employer layer that ~/.claude/CLAUDE.md imports.
#
# The personal defaults are tracked (.config/claude/CLAUDE.md) and symlinked by
# bootstrap. They end with `@~/.claude/local.md`, which is where anything
# employer-specific goes: client name, trackers, house style, who decides what.
# That file is deliberately NOT tracked, because this repo is public.
#
# Without it the import dangles and the employer layer is silently empty, so on
# a new machine this asks for the organisation and its homepage, then seeds both
# the employer file and a stub house-style skill pointed at that site. Neither
# is ever overwritten once it exists.
#
# Non-interactive: set DOTFILES_ORG and DOTFILES_ORG_URL, or neither, in which
# case the files are seeded with their placeholders intact and recorded as a
# manual step. It never blocks an unattended bootstrap waiting on a prompt.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

step "Configuring Claude Code instructions..."

TEMPLATES="$REPO_ROOT/.config/claude/templates"
LOCAL="$HOME/.claude/local.md"
SKILLS="$HOME/.claude/skills"

mkdir -p "$HOME/.claude"

ORG="${DOTFILES_ORG:-}"
ORG_URL="${DOTFILES_ORG_URL:-}"

# Only prompt when there is a human on the other end and there is something to
# ask for. bootstrap.sh runs this unattended often enough that a blocking read
# would be a hang, not a question.
if [[ -z "$ORG" && ! -f "$LOCAL" && -t 0 ]]; then
  echo "  Employer layer: who is this machine's work for? Enter to skip."
  read -r -p "    Organisation (e.g. Acme Corp): " ORG || ORG=""
  if [[ -n "$ORG" ]]; then
    read -r -p "    Homepage (e.g. https://acme.com): " ORG_URL || ORG_URL=""
  fi
fi

# A slug for the skill directory: lowercase, spaces and punctuation to hyphens.
# Written for bash 3.2, which is what macOS ships, so no ${var,,}.
# Left empty when there is no organisation, so the template keeps its {{ORG_SLUG}}
# placeholder rather than filling in a misleading "org-style".
ORG_SLUG=""
if [[ -n "$ORG" ]]; then
  ORG_SLUG="$(printf '%s' "$ORG" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-//' -e 's/-$//')"
  [[ -n "$ORG_SLUG" ]] || ORG_SLUG="org"
fi

# Substitute into a template, leaving any token we have no answer for in place
# so it reads as an unfilled blank rather than an empty string.
fill() {
  local src="$1" dest="$2"
  ORG="$ORG" ORG_URL="$ORG_URL" ORG_SLUG="$ORG_SLUG" DATE="$(date +'%-d %b %Y')" \
    python3 - "$src" "$dest" <<'PY'
import os, sys

src, dest = sys.argv[1], sys.argv[2]
with open(src) as f:
    text = f.read()
for key in ("ORG", "ORG_URL", "ORG_SLUG", "DATE"):
    value = os.environ.get(key, "")
    if value:
        text = text.replace("{{%s}}" % key, value)
with open(dest, "w") as f:
    f.write(text)
PY
}

if ! command -v python3 &>/dev/null; then
  warn "python3 not found — skipping employer layer"
  exit 0
fi

if [[ -f "$LOCAL" ]]; then
  skip "employer defaults already at ~/.claude/local.md"
elif [[ ! -f "$TEMPLATES/local.md" ]]; then
  warn "template missing at $TEMPLATES/local.md — skipping"
  exit 0
else
  fill "$TEMPLATES/local.md" "$LOCAL"
  ok "seeded ~/.claude/local.md${ORG:+ for $ORG}"
  if [[ -n "$ORG" ]]; then
    manual_step "Finish ~/.claude/local.md: repos, trackers, data and people. Untracked on purpose — this repo is public."
  else
    manual_step "Fill in ~/.claude/local.md (organisation, homepage, tracker, data, people), or re-run with DOTFILES_ORG and DOTFILES_ORG_URL set."
  fi
fi

# The house style is derived from the organisation's own site, so it is only
# worth stubbing once we know what that site is.
STYLE_DIR="$SKILLS/$ORG_SLUG-style"
if [[ -n "$ORG" && -f "$TEMPLATES/brand-style.SKILL.md" ]]; then
  if [[ -f "$STYLE_DIR/SKILL.md" ]]; then
    skip "$ORG_SLUG-style skill already present"
  else
    mkdir -p "$STYLE_DIR"
    fill "$TEMPLATES/brand-style.SKILL.md" "$STYLE_DIR/SKILL.md"
    ok "stubbed $ORG_SLUG-style skill"
    # Built up beforehand: an apostrophe inside ${var:-default} inside double
    # quotes opens a quote bash never closes, and takes the whole block with it.
    site="$ORG_URL"
    [[ -n "$site" ]] || site="the organisation site"
    manual_step "Write the $ORG_SLUG-style skill from $site: Character first, then Type and Tokens. The stub explains the order."
  fi
fi

# The tracked CLAUDE.md is linked by bootstrap's tracked_links. If one is still
# sitting there as a regular file, link_config backs it up rather than deleting
# it, but whatever was inside drops out of Claude's context until it is moved.
TRACKED="$REPO_ROOT/.config/claude/CLAUDE.md"
LIVE="$HOME/.claude/CLAUDE.md"
if [[ -e "$LIVE" && ! -L "$LIVE" ]] && ! diff -q "$TRACKED" "$LIVE" >/dev/null 2>&1; then
  manual_step "~/.claude/CLAUDE.md is a regular file, not the tracked symlink. Bootstrap will back it up and replace it — move anything employer-specific into ~/.claude/local.md first."
fi

ok "Claude Code instructions configured"
