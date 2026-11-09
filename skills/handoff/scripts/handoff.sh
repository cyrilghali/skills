#!/usr/bin/env bash
# Launch a fresh Claude session on a handoff brief from whatever surface this session runs in.
#
# Usage: handoff.sh <brief.md> --cwd <dir> [--surface herdr|tmux|desktop|print] [--title "<title>"] [--model <alias>] [--effort <level>] [--prompt "<text>"] [--on <machine>] [--dry-run]
#
# Surface, first match wins: herdr (HC_TERMINAL_ID set and hc on PATH), tmux (TMUX set),
# desktop (macOS with open), print (anything else: prints the command to paste in a new terminal).
# herdr, tmux and print need --title, --model and --effort. desktop ignores them.
# --on <machine> (herdr only) runs the session on another Herdr machine; --cwd is a path there.
# --dry-run prints the launch without opening anything. Output is one JSON line.
set -euo pipefail

usage() { sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
fail() { echo "handoff: $*" >&2; exit 1; }

brief="${1:-}"; case "$brief" in ""|-h|--help) usage ;; esac
shift
cwd=""; title=""; prompt=""; model=""; effort=""; surface=""; on=""; dry=""
while [ $# -gt 0 ]; do
  case "$1" in
    --cwd) cwd="${2:-}"; shift 2 ;;
    --title) title="${2:-}"; shift 2 ;;
    --model) model="${2:-}"; shift 2 ;;
    --effort) effort="${2:-}"; shift 2 ;;
    --prompt) prompt="${2:-}"; shift 2 ;;
    --surface) surface="${2:-}"; shift 2 ;;
    --on) on="${2:-}"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    -h|--help) usage ;;
    *) echo "unknown option: $1" >&2; usage ;;
  esac
done

if [ -z "$surface" ]; then
  if [ -n "${HC_TERMINAL_ID:-}" ] && command -v hc >/dev/null; then surface=herdr
  elif [ -n "${TMUX:-}" ]; then surface=tmux
  elif [ "$(uname)" = Darwin ] && command -v open >/dev/null; then surface=desktop
  else surface=print; fi
fi
case "$surface" in herdr|tmux|desktop|print) ;; *) fail "--surface must be herdr, tmux, desktop or print" ;; esac
[ -z "$on" ] || [ "$surface" = herdr ] || fail "--on works on the herdr surface only"

[ -f "$brief" ] || fail "brief not found: $brief"
[ -n "$cwd" ] || fail "--cwd is required"
if [ -n "$on" ]; then
  # The path lives on the other machine, so only its shape can be checked here; the home-folder check runs after the brief copy.
  case "$cwd" in /*) ;; *) fail "--cwd must be an absolute path on $on" ;; esac
else
  [ -d "$cwd" ] || fail "--cwd must be an existing directory"
  [ "$(cd "$cwd" && pwd -P)" != "$(cd "$HOME" && pwd -P)" ] || fail "--cwd must not be the home directory: use the repo the task touches, or a dedicated folder for work outside any repo"
fi

for h in "## Task" "## Context" "## Deliverable" "## Verification" "## Ask the user for"; do
  grep -q "^$h" "$brief" || fail "brief is missing the heading '$h' (see BRIEF.md)"
done
grep -qi "do not touch\|out of scope" "$brief" || fail "brief has no 'do not touch' or 'out of scope' line"

if [ "$surface" != desktop ]; then
  [ -n "$title" ] || fail "--title is required"
  [ -n "$model" ] || fail "--model is required (pick it from the task: see SKILL.md step 3)"
  case "$effort" in low|medium|high|xhigh|max) ;; *) fail "--effort must be low, medium, high, xhigh or max" ;; esac
fi
[ -n "$dry" ] || [ "$surface" = print ] || case "$surface" in
  herdr) command -v hc >/dev/null || fail "hc not on PATH" ;;
  tmux) command -v tmux >/dev/null || fail "tmux not on PATH" ;;
  desktop) command -v open >/dev/null || fail "open not on PATH (the Desktop launch needs macOS)" ;;
esac
command -v python3 >/dev/null || fail "python3 not on PATH (needed to print JSON)"

brief_abs="$(cd "$(dirname "$brief")" && pwd)/$(basename "$brief")"
[ -n "$prompt" ] || prompt="/goal The brief at $brief_abs is executed end to end: its Deliverable holds, proven in this conversation by the checks in its Verification section; the report is written to the path its Deliverable names and linked in your final reply, addressed to the reviewer it names; and the brief is renamed to ${brief_abs%.md}.done.md. Or the user drops the task and you rename the brief to ${brief_abs%.md}.superseded.md yourself. Or every step left needs the user (a login, a secret, a decision): you wrote the report with those open items first, linked it in your reply, and renamed the brief to ${brief_abs%.md}.blocked.md, and you send no further \"still blocked\" replies. Or stop after 20 turns."

json() { python3 -c 'import json,sys; print(json.dumps(dict(zip(sys.argv[1::2], sys.argv[2::2]))))' "$@"; }

if [ "$surface" = desktop ]; then
  [ -z "$model$effort" ] || echo "handoff: --model/--effort ignored: Desktop uses its own defaults" >&2
  cwd_abs="$(cd "$cwd" && pwd -P)"
  url="$(python3 -c 'import sys,urllib.parse as u; print("claude://code/new?folder=%s&q=%s" % (u.quote(sys.argv[1], safe=""), u.quote(sys.argv[2], safe="")))' "$cwd_abs" "$prompt")"
  python3 -c 'import json,sys; print(json.dumps({"surface":"desktop","folder":sys.argv[1],"brief":sys.argv[2],"url":sys.argv[3],"opened":not sys.argv[4]}))' "$cwd_abs" "$brief_abs" "$url" "$dry"
  [ -n "$dry" ] || open "$url"
  exit 0
fi

claude_argv=(claude --model "$model" --effort "$effort" "$prompt")
claude_line="$(printf '%q ' "${claude_argv[@]}")"
cwd_abs="$cwd"; [ -n "$on" ] || cwd_abs="$(cd "$cwd" && pwd -P)"

case "$surface" in
print)
  printf '{"surface":"print","dry_run":%s}\n' "$([ -n "$dry" ] && echo true || echo false)"
  echo "Paste in a new terminal:"
  printf 'cd %q && %s\n' "$cwd_abs" "$claude_line"
  ;;
tmux)
  cmd=(tmux new-window -d -c "$cwd_abs" -n "$title" "$claude_line")
  if [ -n "$dry" ]; then printf '{"surface":"tmux","dry_run":true}\n'; printf '%q ' "${cmd[@]}"; echo; exit 0; fi
  "${cmd[@]}"
  json surface tmux title "$title" brief "$brief_abs"
  ;;
herdr)
  # Open the tab in the caller's own space so it lands beside this session.
  space=""; label=()
  if [ -z "$on" ] && [ -n "${HC_TERMINAL_ID:-}" ] && command -v herdr-app >/dev/null; then
    space="$(herdr-app ls 2>/dev/null | python3 -c 'import json,sys
t=sys.argv[1]
try:
    for s in json.load(sys.stdin)["spaces"]:
        if any(x["terminal"]==t for tab in s["tabs"] for x in tab["terminals"]): print(s["id"]); break
except Exception: pass' "$HC_TERMINAL_ID")" || space=""
  fi
  [ -z "$space" ] || label=(--label "herdr.space=$space")
  name="$(printf '%s' "$title" | tr 'A-Z ' 'a-z-' | tr -cd 'a-z0-9_-' | cut -c1-24)-$(date +%H%M%S)"
  onflag=(); [ -z "$on" ] || onflag=(--on "$on")
  if [ -n "$on" ]; then
    # Copy the brief to the same path under the other machine's home; the session there needs its absolute path.
    case "$brief_abs" in "$HOME"/*) rel="${brief_abs#"$HOME"/}" ;; *) fail "brief must sit under $HOME to be copied to $on" ;; esac
    if [ -n "$dry" ]; then remote_abs="<home on $on>/$rel"
    else
      remote_abs="$(hc file write --on "$on" --json "$rel" < "$brief_abs" | python3 -c 'import json,sys; print(json.load(sys.stdin)["path"])')" || fail "could not copy the brief to $on"
    fi
    [ -n "$dry" ] || [ "${cwd%/}" != "${remote_abs%/"$rel"}" ] || fail "--cwd must not be the home directory of $on: use the repo the task touches, or a dedicated folder for work outside any repo"
    prompt="${prompt//"${brief_abs%.md}"/${remote_abs%.md}}"
    prompt="${prompt//"$brief_abs"/$remote_abs}"
    claude_argv=(claude --model "$model" --effort "$effort" "$prompt")
  fi
  cmd=(hc run --bg --json --no-parent --no-notify --name "$name" ${onflag[@]+"${onflag[@]}"} --cwd "$cwd_abs" ${label[@]+"${label[@]}"} -- "${claude_argv[@]}")
  if [ -n "$dry" ]; then
    printf '{"surface":"herdr","dry_run":true,"on":"%s","space":"%s"}\n' "$on" "$space"
    [ -z "$on" ] || printf 'hc file write --on %q --json %q < %q\n' "$on" "$rel" "$brief_abs"
    printf '%q ' "${cmd[@]}"; echo
    exit 0
  fi
  out="$("${cmd[@]}" 2>&1)" || fail "hc run failed: $out"
  addr="$(printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("terminal") or d.get("address") or "")' 2>/dev/null || true)"
  [ -n "$addr" ] || fail "hc run printed no terminal address: $out"
  # The app creates the tab a moment after the terminal starts; give it the title once it exists.
  if [ -z "$on" ] && command -v herdr-app >/dev/null; then
    for _ in $(seq 1 20); do
      tab="$(herdr-app ls 2>/dev/null | python3 -c 'import json,sys
t=sys.argv[1]
try:
    for s in json.load(sys.stdin)["spaces"]:
        for tab in s["tabs"]:
            if any(x["terminal"]==t for x in tab["terminals"]): print(tab["id"]); raise SystemExit
except Exception: pass' "$addr")"
      [ -z "$tab" ] || { herdr-app do tab.rename --id "$tab" --name "$title" >/dev/null && break; }
      sleep 0.5
    done
  fi
  json surface herdr terminal "$addr" title "$title" name "$name" space "$space" on "$on" brief "$brief_abs"
  ;;
esac
