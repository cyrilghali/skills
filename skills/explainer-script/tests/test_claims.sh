#!/usr/bin/env bash
# Exercises scripts/claims.py on small fixtures. Prints "claims check ok" when every case behaves.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
run() { python3 -I "$here/scripts/claims.py" "$@" >"$tmp/out" 2>&1; echo $?; }
fail() { echo "FAIL: $*"; cat "$tmp/out"; exit 1; }

mkdir "$tmp/p"
cat >"$tmp/p/beats.json" <<'J'
[{"id":"a","text":"A visitor asks for a page, so the cache answers first."},
 {"id":"b","text":"After 600 seconds, the cache drops the page from `pages_hot`."}]
J
[ "$(run "$tmp/p")" = 1 ] && grep -q "beat b" "$tmp/out" || fail "missing claims.json must fail and name beat b"

echo '[{"beat":"b","claim":"drops a page after 600 seconds","source":"cache.md:9","verdict":"false"}]' >"$tmp/p/claims.json"
[ "$(run "$tmp/p" --stamp)" = 1 ] && grep -q "unchanged" "$tmp/out" || fail "false verdict on an unchanged beat must fail"

sed -i.bak 's/600 seconds/300 seconds/' "$tmp/p/beats.json"
[ "$(run "$tmp/p")" = 0 ] || fail "a fixed beat must pass"

echo '[{"beat":"b","claim":"x","source":"","verdict":"true"}]' >"$tmp/p/claims.json"
[ "$(run "$tmp/p")" = 1 ] && grep -q "missing source" "$tmp/out" || fail "blank source must fail"

echo '[{"beat":"b","claim":"x","source":"cache.md:9","verdict":"true","note":"secret reasoning"}]' >"$tmp/p/claims.json"
python3 -I "$here/scripts/claims.py" "$tmp/p" --blind >"$tmp/out"
grep -q '"source"' "$tmp/out" && ! grep -q 'verdict\|secret' "$tmp/out" || fail "--blind must keep the source and drop verdict and note"

[ "$(run "$tmp/p" --final)" = 1 ] && grep -q "second-read.json" "$tmp/out" || fail "--final needs second-read.json"
echo '[{"beat":"b","claim":"x","verdict":"partly"}]' >"$tmp/p/second-read.json"
[ "$(run "$tmp/p" --final)" = 1 ] && grep -q "resolved" "$tmp/out" || fail "a disagreeing second read needs resolved"
echo '[{"beat":"b","claim":"x","verdict":"true"},{"beat":"a","claim":"the cache answers first","verdict":"true"}]' >"$tmp/p/second-read.json"
[ "$(run "$tmp/p" --final)" = 1 ] && grep -q "added a claim" "$tmp/out" || fail "a claim the reader added must be in claims.json"
echo '[{"beat":"b","claim":"x","verdict":"true"}]' >"$tmp/p/second-read.json"
[ "$(run "$tmp/p" --final)" = 0 ] || fail "--final with an agreeing second read must pass"
mkdir "$tmp/q"
echo '[{"id":"a","text":"It is the only bridge you can cross on foot."}]' >"$tmp/q/beats.json"
echo '[]' >"$tmp/q/claims.json"
[ "$(run "$tmp/q")" = 1 ] && grep -q "absolute 'only'" "$tmp/out" || fail "an absolute word with no entry must fail"
echo "claims check ok"
