#!/usr/bin/env bash
# Lists near-duplicate code pairs that involve lines the current branch added, and records the count
# for the head commit. Run from inside the repo. Usage: dry-check.sh [--base <branch>]
# Env: DRY_THRESHOLD (0.8), DRY_MIN_LINES (6), DRY_CHECK_DRYER (a dryer clone), DRY_CHECK_SRC (dryer
# source dirs, colon-separated), DRY_CHECK_MIX_ENV (test), CRAP_DRY_STATE (record folder).
set -uo pipefail

DRYER_URL=https://github.com/unclebob/dryer.git
DRYER_SHA=66ff6d21a42c04afcad89c78a80066176d1294b0
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
skill=$(dirname "$here")
threshold=${DRY_THRESHOLD:-0.8}
min_lines=${DRY_MIN_LINES:-6}
die() { echo "dry-check: $*" >&2; exit 2; }

base_arg=""
while [ $# -gt 0 ]; do
  case $1 in
    --base) base_arg=${2:-}; [ -n "$base_arg" ] || die "--base needs a branch"; shift 2 ;;
    -h|--help) sed -n 2,5p "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

repo=$(git rev-parse --show-toplevel 2>/dev/null) || die "not inside a git repo"
cd "$repo" || exit 2
repo_name=$(basename "$repo")

base=""
if [ -n "$base_arg" ]; then candidates=("$base_arg" "origin/$base_arg"); else candidates=(origin/staging origin/main origin/master "$(git symbolic-ref -q --short refs/remotes/origin/HEAD)"); fi
for c in "${candidates[@]}"; do
  [ -n "$c" ] && git rev-parse --verify -q "$c^{commit}" >/dev/null && { base=$c; break; }
done
[ -n "$base" ] || die "base ${base_arg:-branch} does not resolve; fetch it or pass --base <branch>"
head=$(git rev-parse HEAD)
mb=$(git merge-base "$base" HEAD) || die "no merge base between $base and HEAD"
[ -z "$(git status --porcelain --untracked-files=no)" ] || die "tracked files have uncommitted changes; line numbers must match HEAD, so commit first"

changed=$(git diff --name-only --diff-filter=AM "$mb" HEAD)
not_test() { grep -Ev '(^|/)(test|tests|spec|specs|__tests__)/|_test\.|\.test\.|\.spec\.|(^|/)test_[^/]*\.py$'; }
ex_files=$(printf '%s\n' "$changed" | grep -E '\.ex$' | not_test)
dr_files=$(printf '%s\n' "$changed" | grep -E '\.(clj|cljc|cljs|cljd|bb|java|go|ts|tsx|mts|cts|rs|py)$' | grep -v '\.d\.ts$' | not_test)

work=$(mktemp -d) || exit 2
trap 'rm -rf "$work"' EXIT
rows="$work/rows"; : > "$rows"

if [ -n "$ex_files" ]; then
  [ -f mix.exs ] || die "Elixir files changed but there is no mix.exs at the repo root"
  dirs=$(git ls-files '*.ex' | awk -F/ '
    $1=="test" || $1=="deps" || $1=="_build" || $1=="config" || NF==1 { next }
    $1=="apps" { if (NF > 3 && $3 != "test") seen[$1 "/" $2 "/" $3]++; next }
    { seen[$1]++ }
    END { for (d in seen) printf "%s/:", d }')
  echo "dry-check: elixir, credo DuplicatedCode over ${dirs:-lib/} (exact AST match, mass 40)" >&2
  # Credo exits non-zero when it finds issues; join.py exits 3 when the output is not Credo's JSON.
  MIX_ENV=${DRY_CHECK_MIX_ENV:-test} DRY_CHECK_DIRS=${dirs:-lib/} \
    mix credo --config-file "$skill/credo/dry.exs" --format json --all > "$work/credo.json" 2> "$work/credo.err"
  # The same check on the base tree, so a duplicate the branch only edits is not counted as new.
  mkdir -p "$work/base"
  # shellcheck disable=SC2046
  git archive "$mb" -- $(printf '%s' "${dirs:-lib/}" | tr ':' ' ') | tar -x -C "$work/base" 2>/dev/null
  base_dirs=$(printf '%s' "${dirs:-lib/}" | tr ':' '\n' | sed "/^$/d; s|^|$work/base/|" | paste -sd: -)
  MIX_ENV=${DRY_CHECK_MIX_ENV:-test} DRY_CHECK_DIRS=$base_dirs \
    mix credo --config-file "$skill/credo/dry.exs" --format json --all > "$work/credo-base.json" 2>> "$work/credo.err"
  python3 -I "$here/join.py" credo --base "$mb" --input "$work/credo.json" --min-lines "$min_lines" \
    --base-input "$work/credo-base.json" --base-root "$work/base" >> "$rows"
  rc=$?
  if [ $rc -eq 3 ]; then tail -15 "$work/credo.err" >&2; die "Credo printed no report; fix the mix error above, then rerun"; fi
  [ $rc -eq 0 ] || die "could not read Credo's report (join.py exit $rc)"
fi

if [ -n "$dr_files" ]; then
  dryer=${DRY_CHECK_DRYER:-${XDG_CACHE_HOME:-$HOME/.cache}/dry-check/dryer}
  if [ ! -x "$dryer/dryer" ]; then
    mkdir -p "$(dirname "$dryer")"
    git clone -q "$DRYER_URL" "$dryer" && git -C "$dryer" checkout -q "$DRYER_SHA" || die "could not fetch dryer from $DRYER_URL"
  fi
  src=""
  for d in ${DRY_CHECK_SRC:+$(printf '%s' "$DRY_CHECK_SRC" | tr ':' ' ')}; do src="$src $d"; done
  if [ -z "$src" ]; then
    for d in src lib app apps packages server services source; do [ -d "$d" ] && src="$src $repo/$d"; done
  fi
  src=${src:-$repo}
  echo "dry-check: dryer over$src (threshold $threshold, min lines $min_lines)" >&2
  # --root points at scratch space: dryer writes .metrics/ under it, never in the repo.
  # shellcheck disable=SC2086
  "$dryer/dryer" --root "$work" --edn --threshold "$threshold" --min-lines "$min_lines" $src > "$work/dry.edn" 2> "$work/dry.err" \
    || { tail -10 "$work/dry.err" >&2; die "dryer failed"; }
  grep -q 'No source files' "$work/dry.edn" && : > "$work/dry.edn" && echo '{:candidates []}' > "$work/dry.edn"
  mkdir -p "$work/b/root"
  bsrc=""
  for d in $src; do
    rel=${d#"$repo"}; rel=${rel#/}
    git archive "$mb" -- "${rel:-.}" 2>/dev/null | tar -x -C "$work/b/root" 2>/dev/null
    bsrc="$bsrc $work/b/root/$rel"
  done
  # shellcheck disable=SC2086
  "$dryer/dryer" --root "$work/b/root" --edn --threshold "$threshold" --min-lines "$min_lines" $bsrc > "$work/dry-base.edn" 2>> "$work/dry.err" \
    || { tail -10 "$work/dry.err" >&2; die "dryer failed on the base tree"; }
  grep -q '{:candidates' "$work/dry-base.edn" || echo '{:candidates []}' > "$work/dry-base.edn"
  python3 -I "$here/join.py" dryer --base "$mb" --input "$work/dry.edn" --root "$work" \
    --base-input "$work/dry-base.edn" --base-root "$work/b/root" >> "$rows" \
    || die "could not read dryer's report"
fi

sort -t'|' -k3,3nr -k4,4 -k5,5 -u "$rows" > "$work/sorted"
n=$(wc -l < "$work/sorted" | tr -d ' ')

echo "| new? | score | left file:start-end | right file:start-end | fix |"
echo "|---|---|---|---|---|"
cat "$work/sorted"
echo "new=$n threshold=$threshold min_lines=$min_lines"

state=${CRAP_DRY_STATE:-$HOME/.claude/state/crap-dry}/dry
mkdir -p "$state" || die "cannot create $state"
{ echo "new=$n"; cat "$work/sorted"; } > "$state/.tmp.$$" && mv "$state/.tmp.$$" "$state/$repo_name-$head"
echo "dry-check: recorded $state/$repo_name-$head" >&2
exit 0
