#!/usr/bin/env bash
# Checks a trace's shape and citations: one sentence and one path:line per numbered step,
# every citation resolves, and at most two lines follow the list. Prints each cited line.
# Usage: check-trace.sh <trace-file | -> <repo-root> [more repo roots]
set -u
usage="usage: check-trace.sh <trace-file | -> <repo-root> [more repo roots]"
src="${1:?$usage}"; shift
[ $# -ge 1 ] || { echo "$usage"; exit 2; }
text=$(cat "$( [ "$src" = "-" ] && echo /dev/stdin || echo "$src")")
steps=$(printf '%s\n' "$text" | grep -E '^[[:space:]]*[0-9]+\.')
[ -n "$steps" ] || { echo "FAIL: no numbered steps found"; exit 1; }

errors=0
fail() { echo "FAIL $*"; errors=$((errors + 1)); }
cite_re='[A-Za-z0-9_./-]+\.[A-Za-z0-9]+:[0-9]+'

while IFS= read -r step; do
  label=$(printf '%s' "$step" | sed -E 's/^[[:space:]]*([0-9]+)\..*/step \1/')
  cites=$(printf '%s\n' "$step" | grep -oE "$cite_re")
  prose=$(printf '%s' "$step" | sed -E 's/^[[:space:]]*[0-9]+\.[[:space:]]*//; s/\(`[^`]*`\)//g; s/`[^`]*`//g')
  [ "$(printf '%s' "$prose" | grep -oE '[.!?][[:space:]]+[A-Z]' | wc -l | tr -d ' ')" -eq 0 ] ||
    fail "$label: more than one sentence; keep one, move the rest to its own step"
  words=$(printf '%s' "$prose" | wc -w | tr -d ' ')
  [ "$words" -le 35 ] || fail "$label: $words words; one plain sentence stays under 35"
  count=$(printf '%s' "$cites" | grep -c .)
  if [ "$count" -eq 0 ]; then fail "$label: no file:line"; continue; fi
  [ "$count" -eq 1 ] || fail "$label: $count citations; one hop per step means one citation"
  for cite in $cites; do
    path=${cite%:*}
    line=${cite##*:}
    found=""
    if [[ "$path" == /* ]]; then
      [ -f "$path" ] && found="$path"
    else
      for root in "$@"; do
        [ -f "$root/$path" ] && { found="$root/$path"; break; }
      done
    fi
    if [ -z "$found" ]; then
      fail "$cite: file not found under $*"
    elif [ "$line" -gt "$(wc -l < "$found" | tr -d ' ')" ]; then
      fail "$cite: past the end of the file"
    else
      echo "OK   $cite: $(sed -n "${line}p" "$found" | sed 's/^[[:space:]]*//' | cut -c1-110)"
    fi
  done
done <<< "$steps"

after=$(printf '%s\n' "$text" | awk '/^[[:space:]]*[0-9]+\./ {n=0; next} NF && /[^`]/ && !/^```/ {n++} END {print n+0}')
[ "$after" -le 2 ] || fail "$after lines after the last step; keep at most two"

[ "$errors" -eq 0 ] && echo "All checks pass. Read each OK line: it must show what its step says."
exit $((errors > 0))
