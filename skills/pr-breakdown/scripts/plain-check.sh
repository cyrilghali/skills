#!/usr/bin/env bash
# Lists the code names a breakdown leans on: code spans, function names, snake_case
# identifiers, file paths, dotted module names and commit hashes. Links are ignored.
#
#   plain-check.sh <breakdown.md>    prints line:token for each hit, and a length line when a PR
#                                    with two decisions or fewer runs past 20 lines; exits 1 when any
set -euo pipefail

[ $# -eq 1 ] && [ -f "$1" ] || { echo "usage: plain-check.sh <breakdown.md>" >&2; exit 2; }

patterns=(
  '`[^`]+`'
  '\b[a-z_][a-z0-9_?!]*/[0-9]\b'
  '\b[a-z][a-z0-9]*(_[a-z0-9]+)+\b'
  '\b[A-Za-z0-9_/.-]+\.(exs?|tsx?|jsx?|py|rb|go|sql|json|ya?ml|toml|sh)\b'
  '\b[A-Z][A-Za-z]+(\.[A-Z][A-Za-z]+)+\b'
  '\b[0-9a-f]{7,40}\b'
)

# Link targets and URLs are references, not explanation.
text=$(sed -E 's/\]\([^)]*\)/]/g; s#https?://[^ )>]+##g' "$1")

hits=$(for p in "${patterns[@]}"; do grep -noE "$p" <<< "$text" || true; done \
  | awk -F: '$2 !~ /^[0-9a-f]+$/ || ($2 ~ /[0-9]/ && $2 ~ /[a-f]/)' \
  | sort -t: -k1,1n -u)

# A table cell holds one sentence; past 35 words it is carrying a paragraph.
hits+=$'\n'$(awk -F'|' '/^\|/ { for (i = 2; i < NF; i++) if (split($i, w, " ") > 35) { print NR ":long cell, " split($i, w, " ") " words"; break } }' "$1")

# Two decisions or fewer get the example and the decisions table, nothing more.
decisions=$(awk '/^### /{on = /^### Which decisions/} on && /^\|/ && !/^\|[- |]+\|$/' "$1" | tail -n +2 | wc -l | tr -d ' ')
lines=$(grep -c . "$1" || true)
if [ "$decisions" -le 2 ] && [ "$lines" -gt 20 ]; then
  hits+=$'\n'"length: $lines lines for $decisions decisions; keep only the example and the decisions table"
fi

hits=$(sed '/^$/d' <<< "$hits")
[ -z "$hits" ] && exit 0
echo "$hits"
exit 1
