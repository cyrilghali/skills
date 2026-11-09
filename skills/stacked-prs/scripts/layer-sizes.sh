#!/usr/bin/env bash
# Changed lines per stack layer, each measured against the layer below it.
# Exits 1 when a layer passes 500 lines.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

usage() { echo "usage: layer-sizes.sh <base> <layer-1> [<layer-2> ...] [-- <pathspec excludes, e.g. ':!mix.lock'>]" >&2; exit 2; }

refs=()
while [ $# -gt 0 ] && [ "$1" != "--" ]; do refs+=("$1"); shift; done
[ $# -gt 0 ] && shift
[ ${#refs[@]} -ge 2 ] || usage

for r in "${refs[@]}"; do
  git rev-parse --verify --quiet "$r^{commit}" >/dev/null || { echo "error: '$r' is not a commit in $(pwd)" >&2; exit 2; }
done

n=$(( ${#refs[@]} - 1 )); over=0
printf '%-6s %-40s %7s %7s %7s  %s\n' layer branch added deleted total check
for i in $(seq 1 "$n"); do
  read -r add del < <(git diff --numstat "${refs[i-1]}" "${refs[i]}" -- . "$@" \
    | awk '$1 != "-" { a += $1; d += $2 } END { print a+0, d+0 }')
  total=$(( add + del ))
  if   [ "$total" -gt 500 ]; then check="OVER 500"; over=1
  elif [ "$total" -gt 400 ]; then check="above target (400)"
  else check="ok"; fi
  printf '%-6s %-40s %7d %7d %7d  %s\n' "$i/$n" "${refs[i]}" "$add" "$del" "$total" "$check"
done

[ "$over" -eq 0 ] || { echo "error: at least one layer passes 500 lines; split it or name the exception" >&2; exit 1; }
