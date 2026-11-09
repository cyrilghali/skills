#!/usr/bin/env bash
# Executable checks for the surface choice in scripts/handoff.sh. Never opens a terminal tab or Desktop.
# The scratch folder sits under $HOME because --on copies a brief by its path under the home folder.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"; sh="$here/scripts/handoff.sh"
tmp="$(mktemp -d "$HOME/.handoff-eval.XXXXXX")"; repo="$tmp/my repo"; mkdir "$repo"; brief="$tmp/b.md"
mkdir "$tmp/bin"; printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/hc"; chmod +x "$tmp/bin/hc"
printf '# H\n\n## Task\nx\n\n## Context\nx\n\n## Deliverable\nDo not touch anything.\n\n## Verification\nx\n\n## Ask the user for\nx\n' > "$brief"
n=0; bad=0
check() { n=$((n+1)); if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; bad=$((bad+1)); fi; }
req=(--title t --model sonnet --effort low --dry-run)
run() { env -u HC_TERMINAL_ID -u TMUX "$@" 2>/dev/null; }
base=(bash "$sh" "$brief" --cwd "$repo")
fakepath="$tmp/bin:$PATH"

h="$(run env PATH="$fakepath" HC_TERMINAL_ID=t9 "${base[@]}" "${req[@]}")"
check "HC_TERMINAL_ID and hc -> herdr" '[[ "$h" == *"\"surface\": \"herdr\""* || "$h" == *"\"surface\":\"herdr\""* ]]'
check "herdr runs unparented in the cwd" '[[ "$h" == *"--no-parent"* && "$h" == *"--cwd"*"my\\ repo"* && "$h" == *"--model\\ sonnet"* ]] || [[ "$h" == *"hc run --bg"* && "$h" == *"--no-parent"* && "$h" == *"sonnet"* ]]'
check "HC_TERMINAL_ID without hc -> not herdr" '[[ "$(run env PATH=/usr/bin:/bin HC_TERMINAL_ID=t9 "${base[@]}" "${req[@]}")" != *herdr* ]]'
t="$(run env TMUX=/tmp/x,1,0 "${base[@]}" "${req[@]}")"
check "TMUX -> tmux new-window" '[[ "$t" == *"tmux new-window -d -c"* && "$t" == *"-n t"* ]]'
check "herdr wins over tmux" '[[ "$(run env PATH="$fakepath" HC_TERMINAL_ID=t9 TMUX=/x "${base[@]}" "${req[@]}")" == *herdr* ]]'
d="$(run "${base[@]}" --dry-run)"
if [ "$(uname)" = Darwin ]; then
  check "macOS, no multiplexer -> desktop" '[[ "$d" == *"\"surface\": \"desktop\""* ]]'
  check "desktop url has encoded folder" '[[ "$d" == *"claude://code/new?folder="*"my%20repo&q=%2Fgoal%20"* ]]'
  check "model and effort optional on desktop" '[[ "$d" == *"\"opened\": false"* ]]'
fi
p="$(run "${base[@]}" --surface print "${req[@]}")"
check "--surface print prints a claude command" '[[ "$p" == *"claude --model sonnet --effort low"* && "$p" == *"my\\ repo"* ]]'
check "--surface desktop wins inside tmux" '[[ "$(run env TMUX=/x "${base[@]}" --surface desktop --dry-run)" == *claude://code/new* ]]'
check "--surface tmux wins without TMUX" '[[ "$(run "${base[@]}" --surface tmux "${req[@]}")" == *"tmux new-window"* ]]'
check "--surface herdr wins without HC_TERMINAL_ID" '[[ "$(run env PATH="$fakepath" "${base[@]}" --surface herdr "${req[@]}")" == *"hc run"* ]]'
check "--on adds the machine and copies the brief" '[[ "$(run env PATH="$fakepath" "${base[@]%"$repo"}" --cwd /srv/r --surface herdr --on nas "${req[@]}")" == *"hc file write --on nas"* ]]'
check "--on refused outside herdr" '! run "${base[@]}" --surface tmux --on nas "${req[@]}" >/dev/null'
check "--on refuses a relative path" '! run env PATH="$fakepath" "${base[@]%"$repo"}" --cwd dev/r --surface herdr --on nas "${req[@]}" >/dev/null'
check "--split is gone" '! run "${base[@]}" --surface print --split right "${req[@]}" >/dev/null'
check "unknown surface refused" '! run "${base[@]}" --surface otty "${req[@]}" >/dev/null'
check "print needs --model" '! run "${base[@]}" --surface print --title t --effort low --dry-run >/dev/null'
check "print needs --effort in range" '! run "${base[@]}" --surface print --title t --model sonnet --effort loud --dry-run >/dev/null'
check "home directory refused" '! run bash "$sh" "$brief" --cwd "$HOME" --surface print "${req[@]}" >/dev/null'
check "bad brief refused" '! run bash "$sh" "$tmp/none.md" --cwd "$repo" --surface print "${req[@]}" >/dev/null'
printf '# H\n\n## Task\nx\n' > "$tmp/short.md"
check "brief missing headings refused" '! run bash "$sh" "$tmp/short.md" --cwd "$repo" --surface print "${req[@]}" >/dev/null'
echo "checks: $n, failed: $bad"; rm -rf "$tmp"; [ "$bad" -eq 0 ]
