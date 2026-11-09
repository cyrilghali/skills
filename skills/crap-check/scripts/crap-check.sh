#!/usr/bin/env bash
# Scores every function the branch changed with CRAP = CC^2 * (1 - cov)^3 + CC and lists those above the threshold.
# Usage (from the repo root): crap-check.sh [--base <branch>] [--no-coverage] [--coverage-json <path>]
# Env: CRAP_THRESHOLD (10), CRAP_DRY_STATE, CRAP_CHECK_CRAPPER, CRAP_CHECK_CRAPPER_SHA.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CRAPPER_SHA="${CRAP_CHECK_CRAPPER_SHA:-6fd92c4c9bcc56efb64a2f8743d5a2993bcfd42d}"
THRESHOLD="${CRAP_THRESHOLD:-10}"
STATE="${CRAP_DRY_STATE:-$HOME/.claude/state/crap-dry}"
base="" no_cov=0 cov_json=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="${2:-}"; shift 2 ;;
    --no-coverage) no_cov=1; shift ;;
    --coverage-json) cov_json="${2:-}"; shift 2 ;;
    *) echo "usage: crap-check.sh [--base <branch>] [--no-coverage] [--coverage-json <path>]" >&2; exit 2 ;;
  esac
done

die() { echo "crap-check: $*" >&2; exit 1; }
root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "run it inside a git repo"
cd "$root" || exit 1
repo="$(basename "$root")"
head_sha="$(git rev-parse HEAD)"

if [ -z "$base" ]; then
  for c in origin/staging origin/main origin/master origin/HEAD; do
    git rev-parse --verify -q "$c" >/dev/null && { base="$c"; break; }
  done
fi
[ -n "$base" ] || die "no base branch found; pass --base <branch>"
git rev-parse --verify -q "$base" >/dev/null || { git rev-parse --verify -q "origin/$base" >/dev/null && base="origin/$base"; }
mb="$(git merge-base "$base" HEAD)" || die "no merge base between $base and HEAD"
[ -z "$(git status --porcelain --untracked-files=no)" ] || die "tracked files have uncommitted changes; the record is for HEAD, so commit first"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
rows="$work/rows.tsv"; : > "$rows"
added="$work/added.tsv"; : > "$added"

changed="$(git diff --name-only --no-renames --diff-filter=AM "$mb"..HEAD)"
ex_files="$(printf '%s\n' "$changed" | grep -E '\.ex$' | grep -vE '^test/' || true)"
ts_files="$(printf '%s\n' "$changed" | grep -E '\.(ts|tsx|mts|cts|js|jsx|mjs|cjs)$' | grep -vE '\.d\.ts$|\.(test|spec)\.|(^|/)(test|tests|__tests__|spec)/|(^|/)node_modules/' || true)"

# Lines the branch added, per file.
scored="$(printf '%s\n%s\n' "$ex_files" "$ts_files" | sed '/^$/d')"
if [ -n "$scored" ]; then
  # shellcheck disable=SC2046
  git diff -U0 --no-renames "$mb" HEAD -- $(printf '%s\n' "$scored") | awk '
    /^\+\+\+ b\// { file = substr($0, 7); next }
    /^@@/ { split($3, p, ","); s = substr(p[1], 2) + 0; n = (p[2] == "" ? 1 : p[2] + 0); if (n > 0) print file "\t" s "\t" s + n - 1 }' > "$added"
fi

# Remove the coverage tools' output folders that did not exist before the run, and nothing else.
out_dirs="cover coverage .nyc_output .metrics target/coverage"
snapshot() { for d in $out_dirs; do [ -e "$root/$d" ] && echo "$d"; done; return 0; }
cleanup_new() { for d in $out_dirs; do [ -e "$root/$d" ] && ! grep -qx "$d" "$1" && rm -rf -- "${root:?}/$d"; done; return 0; }

sources=""
add_source() { sources="${sources:+$sources+}$1"; }
excov=""

# ---------- Elixir ----------
if [ -n "$ex_files" ]; then
  ebin=""
  for d in _build/test/lib/credo/ebin _build/dev/lib/credo/ebin; do [ -d "$d" ] && { ebin="$root/$d"; break; }; done
  [ -n "$ebin" ] || die "no compiled credo under _build/test or _build/dev; get a warm build first"
  modules="$work/modules.txt"; : > "$modules"
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    elixir -pa "$ebin" "$HERE/cc_clauses.exs" "$f" > "$work/h.tsv" || die "cannot parse $f"
    awk -F'\t' -v f="$f" -v m="$modules" '{ print "H\tex\t" f "\t" $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t-"; print $1 >> m }' "$work/h.tsv" >> "$rows"
    if git cat-file -e "$mb:$f" 2>/dev/null; then
      git show "$mb:$f" > "$work/base.ex"
      elixir -pa "$ebin" "$HERE/cc_clauses.exs" "$work/base.ex" 2>/dev/null |
        awk -F'\t' -v f="$f" '{ print "B\tex\t" f "\t" $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t-" }' >> "$rows"
    fi
  done <<< "$ex_files"

  if [ "$no_cov" = 1 ]; then
    add_source "none(--no-coverage)"
  elif [ -n "$cov_json" ]; then
    [ -f "$cov_json" ] || die "coverage file not found: $cov_json"
    excov="$cov_json"; add_source "excoveralls-json"
  else
    tests="$work/tests.txt"
    {
      printf '%s\n' "$changed" | grep -E '^test/.*_test\.exs$'
      while IFS= read -r f; do
        mirror="test/${f#lib/}"; mirror="${mirror%.ex}_test.exs"
        case "$f" in lib/*) [ -f "$mirror" ] && echo "$mirror" ;; esac
      done <<< "$ex_files"
      sort -u "$modules" | while IFS= read -r m; do
        [ -n "$m" ] && [ -d test ] && grep -rlwF --include='*_test.exs' -- "$m" test
      done
    } 2>/dev/null | sort -u | while IFS= read -r t; do [ -f "$t" ] && echo "$t"; done > "$tests"
    if [ ! -s "$tests" ]; then
      echo "crap-check: no test file covers the changed Elixir modules; scoring them at 0% coverage." >&2
      add_source "none(no covering test)"
    else
      echo "crap-check: running $(wc -l < "$tests" | tr -d ' ') test file(s) with coverage..." >&2
      snap="$work/snap.txt"; snapshot > "$snap"
      marker="$work/marker"; touch "$marker"
      # A private test database keeps this run off the databases other branches share.
      part="${MIX_TEST_PARTITION-crap_$(printf '%s' "$repo" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9_\n' '_' | cut -c1-40)}"
      # shellcheck disable=SC2046
      CRAP_CHECK_COVER_MODULES="$(sort -u "$modules" | sed '/^$/d' | paste -sd, -)" MIX_ENV=test MIX_TEST_PARTITION="$part" \
        elixir -r "$HERE/cover_filter.exs" -S mix coveralls.json --max-cases 4 $(cat "$tests") > "$work/mix.log" 2>&1
      code=$?
      if [ "$code" -ne 0 ] || ! [ cover/excoveralls.json -nt "$marker" ]; then
        tail -n 60 "$work/mix.log" >&2
        cp "$work/mix.log" "${TMPDIR:-/tmp}/crap-check-mix.log"
        cleanup_new "$snap"
        die "the test run failed (exit $code); no score, no record; full log in ${TMPDIR:-/tmp}/crap-check-mix.log"
      fi
      cp cover/excoveralls.json "$work/excoveralls.json"; excov="$work/excoveralls.json"
      cleanup_new "$snap"
      add_source "excoveralls-run"
    fi
  fi
fi

# ---------- TypeScript / JavaScript ----------
if [ -n "$ts_files" ]; then
  crapper="${CRAP_CHECK_CRAPPER:-${XDG_CACHE_HOME:-$HOME/.cache}/crap-check/crapper}"
  if [ ! -d "$crapper/src/crapper" ]; then
    mkdir -p "$(dirname "$crapper")"
    git clone -q https://github.com/unclebob/crapper "$crapper" && git -C "$crapper" checkout -q "$CRAPPER_SHA" ||
      die "cannot fetch crapper at $CRAPPER_SHA"
  fi
  if [ ! -x "$crapper/.venv/bin/python" ]; then
    python3 -m venv "$crapper/.venv" && "$crapper/.venv/bin/pip" install -q --disable-pip-version-check -e "$crapper" || die "cannot install crapper"
  fi
  mode=""
  if [ "$no_cov" = 1 ]; then add_source "none(--no-coverage)"
  elif [ -n "$cov_json" ]; then mode="--use-existing"; add_source "crapper-existing"
  else mode="--run-coverage"; add_source "crapper-run"; fi
  snap="$work/snap-ts.txt"; snapshot > "$snap"
  git status --porcelain > "$work/status-before.txt"
  # shellcheck disable=SC2086
  "$crapper/.venv/bin/python" "$HERE/ts_functions.py" --root "$root" --base "$mb" $mode $ts_files >> "$rows" 2> "$work/ts.err"
  code=$?
  cleanup_new "$snap"
  if [ "$code" -ne 0 ]; then tail -n 40 "$work/ts.err" >&2; die "crapper failed (exit $code); no score, no record"; fi
  git status --porcelain | diff -q - "$work/status-before.txt" >/dev/null || die "the repo changed during the TypeScript run; check git status"
fi

if [ -z "$ex_files$ts_files" ]; then
  echo "No scorable file on this branch (only .ex and TypeScript/JavaScript sources outside test dirs are scored)."
  add_source "none"
fi

python3 "$HERE/report.py" --rows "$rows" --added "$added" --threshold "$THRESHOLD" \
  --excoveralls "$excov" --coverage-source "$sources" --record "$STATE/crap/$repo-$head_sha" || die "report failed"
