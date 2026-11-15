#!/usr/bin/env bash
# Paces outward actions so they don't land seconds apart.
#   pace-gate.sh check   (PreToolUse)  refuses a merge or tracker status change that comes too soon
#   pace-gate.sh record  (PostToolUse) stamps the time after one succeeds
# Merges: 10 min apart, and the target repo's default branch must have finished,
# green CI. Redmine status changes: 60 s apart.
#
# Linked to ~/.claude/hooks/pace-gate.sh by bootstrap; setup_claude_settings.sh
# wires it into ~/.claude/settings.json. The repo is read from `gh pr merge -R`
# or from the session's working directory, so nothing here names a project.
set -u

MERGE_GAP="${PACE_MERGE_GAP:-600}"
STATUS_GAP="${PACE_STATUS_GAP:-60}"
STATE="$HOME/.claude/state/pace"
mkdir -p "$STATE"

mode="${1:-check}"
input="$(cat)"
tool="$(jq -r '.tool_name // ""' <<<"$input")"
command="$(jq -r '.tool_input.command // ""' <<<"$input")"

kind=""
case "$tool" in
  Bash)
    grep -qE '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$)' <<<"$command" && kind="merge"
    ;;
  mcp__redmine__update_issue)
    [ "$(jq -r '.tool_input.status_id // empty' <<<"$input")" != "" ] && kind="redmine-status"
    ;;
esac
[ -z "$kind" ] && exit 0

now="$(date +%s)"

if [ "$mode" = "record" ]; then
  echo "$now" >"$STATE/$kind"
  exit 0
fi

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

gap=$([ "$kind" = "merge" ] && echo "$MERGE_GAP" || echo "$STATUS_GAP")
last="$(cat "$STATE/$kind" 2>/dev/null || echo 0)"
wait=$((last + gap - now))
if [ "$wait" -gt 0 ]; then
  deny "Pace gate: last $kind was $((now - last))s ago; wait ${wait}s more (minimum ${gap}s between them)."
fi

if [ "$kind" = "merge" ]; then
  # Which repo: an explicit -R/--repo wins, else the repo of the session's cwd.
  repo="$(grep -oE '(-R|--repo)[[:space:]=]+[^[:space:]]+' <<<"$command" | head -1 | sed -E 's/^(-R|--repo)[[:space:]=]+//')"
  cwd="$(jq -r '.cwd // empty' <<<"$input")"
  info="$(cd "${cwd:-.}" 2>/dev/null && gh repo view ${repo:+"$repo"} --json nameWithOwner,defaultBranchRef 2>/dev/null)" ||
    deny "Pace gate: could not work out which repo this merge targets, so CI can't be checked. Pass -R owner/repo, or merge by hand."
  repo="$(jq -r .nameWithOwner <<<"$info")"
  branch="$(jq -r .defaultBranchRef.name <<<"$info")"
  sha="$(gh api "repos/$repo/commits/$branch" --jq .sha 2>/dev/null)" ||
    deny "Pace gate: could not read $repo $branch head from GitHub, so CI can't be checked. Retry, or merge by hand."
  runs="$(gh run list -R "$repo" --commit "$sha" --json workflowName,status,conclusion 2>/dev/null)" ||
    deny "Pace gate: could not read CI runs for $repo $branch ($sha)."
  pending="$(jq -r '[.[] | select(.status != "completed") | .workflowName] | join(", ")' <<<"$runs")"
  [ -n "$pending" ] && deny "Pace gate: CI still running on $repo $branch (${sha:0:7}): $pending. Merge once it is green."
  failed="$(jq -r '[.[] | select(.conclusion as $c | ["success","skipped","neutral"] | index($c) | not) | "\(.workflowName)=\(.conclusion)"] | join(", ")' <<<"$runs")"
  [ -n "$failed" ] && deny "Pace gate: $repo $branch (${sha:0:7}) is not green: $failed. Fix it before merging more."
fi
exit 0
