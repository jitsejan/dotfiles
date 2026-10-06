#!/usr/bin/env bash
# Claude Code statusline — Monokai-themed, to match .config/iterm2 and VS Code.
#
# Claude Code pipes a JSON blob describing the session on stdin and renders our
# stdout as the status line. Keep this fast: it runs on every render, so no
# network calls and no unbounded git work.
set -uo pipefail

input="$(cat)"

# jq is in the Brewfile, but the statusline must degrade rather than print an
# error into the UI if it somehow isn't on PATH yet (e.g. mid-bootstrap).
if ! command -v jq &>/dev/null; then
  echo "claude"
  exit 0
fi

field() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

model="$(field '.model.display_name')"
cwd="$(field '.workspace.current_dir')"
[[ -n "$cwd" ]] || cwd="$(field '.cwd')"

# Monokai palette, matching the ANSI colours in the iTerm2 profile.
PINK=$'\033[38;5;197m'   # #f3005f
GREEN=$'\033[38;5;112m'  # #97e023
ORANGE=$'\033[38;5;208m' # #fa8419
PURPLE=$'\033[38;5;141m' # #9c64fe
CYAN=$'\033[38;5;80m'    # #57d1ea
GREY=$'\033[38;5;101m'   # #615e4b
RESET=$'\033[0m'

# Powerline branch glyph, from the JetBrains Mono Nerd Font in the Brewfile.
BRANCH_GLYPH=$''

parts=()

# Directory, shown as ~-relative so long absolute paths don't dominate the line.
if [[ -n "$cwd" ]]; then
  parts+=("${CYAN}${cwd/#"$HOME"/~}${RESET}")
fi

# Git branch, plus a dirty marker. --short keeps this to one cheap call.
if branch="$(git -C "${cwd:-.}" symbolic-ref --quiet --short HEAD 2>/dev/null)"; then
  dirty=""
  if [[ -n "$(git -C "${cwd:-.}" status --porcelain 2>/dev/null | head -1)" ]]; then
    dirty="${ORANGE}*${RESET}"
  fi
  parts+=("${GREEN}${BRANCH_GLYPH} ${branch}${RESET}${dirty}")
fi

# Model name.
if [[ -n "$model" ]]; then
  parts+=("${PURPLE}${model}${RESET}")
fi

# Context usage, when Claude Code reports it.
used="$(field '.context.used_tokens')"
if [[ -n "$used" && "$used" =~ ^[0-9]+$ ]]; then
  if (( used >= 1000 )); then
    parts+=("${PINK}$(( used / 1000 ))k${RESET}")
  else
    parts+=("${PINK}${used}${RESET}")
  fi
fi

# Join with a dim separator.
sep="${GREY} · ${RESET}"
out=""
for i in "${!parts[@]}"; do
  (( i > 0 )) && out+="$sep"
  out+="${parts[$i]}"
done

# %s, not %b: the colour codes above are already real escape characters, and %b
# would additionally eat backslashes that appear in paths or branch names.
printf '%s\n' "$out"
