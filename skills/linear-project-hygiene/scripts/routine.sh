#!/usr/bin/env bash
# Scheduler entry point. Runs one headless pass of the skill and hands any report to the notifier.
#
#   routine.sh daily     repair drift, report what it changed
#   routine.sh weekly    draft one pulse per active project; never posts
#
# LPH_LINEAR_MCP  name of the Linear MCP server (default: linear)
# LPH_NOTIFY      command called as: $LPH_NOTIFY <title> <one line> <report path>; unset = print the path
# LPH_STATE_DIR   where reports and the log go (default: $HOME/.local/share/linear-project-hygiene)
set -uo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

mode=${1:?usage: routine.sh daily|weekly}
case "$mode" in daily|weekly) ;; *) echo "unknown mode '$mode' (daily or weekly)" >&2; exit 64 ;; esac

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
state_dir="${LPH_STATE_DIR:-$HOME/.local/share/linear-project-hygiene}"
mcp="mcp__${LPH_LINEAR_MCP:-linear}__"
mkdir -p "$state_dir/reports"
exec >>"$state_dir/routine.log" 2>&1
echo "=== $(date '+%F %T') $mode ==="

reads="${mcp}list_projects,${mcp}get_project,${mcp}list_milestones,${mcp}list_issues,${mcp}get_issue,${mcp}get_status_updates,${mcp}get_user"
tools="$reads"
[ "$mode" = daily ] && tools="$reads,${mcp}save_issue,${mcp}save_project,${mcp}save_milestone"
[ "$mode" = weekly ] && tools="$reads,${mcp}list_comments,Bash(gh pr view:*)"

report="$state_dir/reports/$(date +%F)-$mode.md"
prompt="Read $skill_dir/SKILL.md and run its $mode pass now, live against Linear. Today is $(date +%F). Output only the artifact the skill defines."
# The daily pass moves overdue dates, so the weekly pass gets the original dates from its reports.
[ "$mode" = weekly ] && prompt+=" Dates the daily pass moved, first date on the left: $(grep -h 'targetDate:' "$state_dir"/reports/*-daily.md 2>/dev/null | sort -u | tr '\n' ' ')"

result=$(cd "$skill_dir" && nice -n 15 env -u CLAUDECODE timeout 900 claude -p "$prompt" \
  --model "$([ "$mode" = daily ] && echo sonnet || echo opus)" \
  --allowedTools "$tools" --max-budget-usd "$([ "$mode" = daily ] && echo 2 || echo 5)" --output-format json </dev/null 2>/dev/null \
  | jq -r '(if type=="array" then (map(select(.type=="result"))|last) else . end) | .result // "(\(.subtype), $\(.total_cost_usd))"')

# A hook block or a crash comes back as plain text; only the skill's own first line counts as a run.
case "$(printf '%s' "$result" | head -1)" in
  NOTHING) echo "nothing to report"; [ "$mode" = daily ] && : >"$state_dir/flags-seen.tsv"; exit 0 ;;
  HEADLINE:*) ;;
  *) printf 'no artifact from claude:\n%s\n' "$result"
     failed="$state_dir/failed-$(date +%F)-$mode"
     if [ -n "${LPH_NOTIFY:-}" ] && [ ! -f "$failed" ]; then
       touch "$failed"; "$LPH_NOTIFY" "Linear $mode check failed" "retrying hourly; see the log" "$state_dir/routine.log"
     fi
     exit 1 ;;
esac
printf '%s\n' "$result" > "$report"
headline=$(sed -n 's/^HEADLINE: //p' "$report" | head -1)
if [ "$mode" = daily ]; then
  read -r new unchanged since < <(python3 "$skill_dir/scripts/new-flags.py" "$report" "$state_dir/flags-seen.tsv")
  repairs=$(printf '%s' "$headline" | sed -n 's/^\([0-9]*\) repair.*/\1/p')
  if [ "${repairs:-0}" = 0 ] && [ "${new:-0}" = 0 ]; then echo "no repairs, no new flags ($unchanged unchanged since $since)"; exit 0; fi
  flags="$new new flags need you"; [ "$new" = 1 ] && flags="1 new flag needs you"
  headline="${repairs:-0} repairs done; $flags"
  [ "${unchanged:-0}" != 0 ] && headline+=" ($unchanged unchanged since $since, not repeated)"
fi
title="Linear $mode check"; [ "$mode" = weekly ] && title="Linear pulse drafts"
if [ -n "${LPH_NOTIFY:-}" ]; then "$LPH_NOTIFY" "$title" "${headline:-report ready}" "$report"; else echo "report: $report"; fi
