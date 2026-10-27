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
 {"id":"b","text":"After six hundred seconds, the cache drops the page from PagesHot."}]
J
[ "$(run "$tmp/p")" = 1 ] && grep -q "beat b" "$tmp/out" || fail "missing claims.json must fail and name beat b"

echo '[{"beat":"b","claim":"drops a page after six hundred seconds","source":"cache.md:9","verdict":"false"}]' >"$tmp/p/claims.json"
[ "$(run "$tmp/p" --stamp)" = 1 ] && grep -q "unchanged" "$tmp/out" || fail "false verdict on an unchanged beat must fail"

sed -i.bak 's/six hundred seconds/three hundred seconds/' "$tmp/p/beats.json"
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

mkdir "$tmp/s"
echo '{"beats":[{"id":"a","text":"Hello."}]}' >"$tmp/s/beats.json"
[ "$(run "$tmp/s")" = 1 ] && grep -q "JSON list" "$tmp/out" || fail "beats.json that is not a list must fail cleanly"
echo '[{"id":"a","text":"Hello.","facts":[]}]' >"$tmp/s/beats.json"
[ "$(run "$tmp/s")" = 1 ] && grep -q "only id and text" "$tmp/out" || fail "a beat with extra fields must fail"
echo '[{"id":"a","text":"Hello."},{"id":"a","text":"Again."}]' >"$tmp/s/beats.json"
[ "$(run "$tmp/s")" = 1 ] && grep -q "duplicate id" "$tmp/out" || fail "a duplicate beat id must fail"
echo '[{"id":"a","text":"The area is x^2 square metres."}]' >"$tmp/s/beats.json"
echo '[{"beat":"a","claim":"the area is x squared","source":"s.md","verdict":"true"}]' >"$tmp/s/claims.json"
[ "$(run "$tmp/s")" = 1 ] && grep -q "'^'" "$tmp/out" && grep -q "'2'" "$tmp/out" || fail "a digit or symbol in the narration must fail"

mkdir "$tmp/f"
echo '[{"id":"a","text":"The moon pulls the sea, so the tide rises."}]' >"$tmp/f/beats.json"
cat >"$tmp/f/brief.md" <<'B'
# Brief: u07 — Why the tide rises

## Facts this unit must say

| id | fact | source |
|---|---|---|
| f01 | The moon pulls the sea. | notes.md |
| f02 | The tide rises. | notes.md |

## Facts the viewer already has (cue them when the story needs them; never teach them again)

| id | fact | taught in |
|---|---|---|
| f00 | The moon circles the earth. | u06 |
B
echo '[{"beat":"a","fact":"f01","claim":"the moon pulls the sea","source":"notes.md","verdict":"true"}]' >"$tmp/f/claims.json"
[ "$(run "$tmp/f" --brief "$tmp/f/brief.md")" = 1 ] && grep -q "brief fact f02" "$tmp/out" && ! grep -q "f00\|f01" "$tmp/out" || fail "--brief must name the missing must-say fact f02 only"
echo '[{"beat":"a","fact":"f01","claim":"the moon pulls the sea","source":"notes.md","verdict":"true"},{"beat":"a","fact":"f02","claim":"the tide rises","source":"notes.md","verdict":"true"}]' >"$tmp/f/claims.json"
[ "$(run "$tmp/f" --brief "$tmp/f/brief.md")" = 0 ] || fail "--brief with every must-say fact named must pass"
echo "claims check ok"
