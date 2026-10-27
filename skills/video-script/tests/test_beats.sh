#!/usr/bin/env bash
# Exercises scripts/beats.py on small beat tables. Prints "beats check ok" when every case behaves.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
run() { python3 -I "$here/scripts/beats.py" "$tmp" >"$tmp/out" 2>&1; echo $?; }
fail() { echo "FAIL: $*"; cat "$tmp/out"; exit 1; }
table() { printf '| id | narration | words on screen | picture |\n|---|---|---|---|\n%s\n' "$1" >"$tmp/script.md"; }

table '| pull | The moon pulls the sea toward it. So the water bulges. | Moon; water | sea bulges |'
echo '[{"id":"pull","text":"The moon pulls the sea toward it. So the water bulges."}]' >"$tmp/beats.json"
[ "$(run)" = 0 ] || fail "a sound beat must pass"

table '| pull | The moon pulls the sea. The water bulges. So the tide comes in. | Moon | sea bulges |'
rm "$tmp/beats.json"
[ "$(run)" = 1 ] && grep -q "3 sentences" "$tmp/out" || fail "three sentences must fail"

table '| pull | The moon pulls the sea toward it. | Why tides? | sea bulges |'
[ "$(run)" = 1 ] && grep -q "not said: tide" "$tmp/out" || fail "a label word the narration does not say must fail"

table '| pull | The ships are anchoring. | Anchored ships | ships stop |'
[ "$(run)" = 0 ] || fail "a label word with a short ending of a said word must pass"

table '| pull | The moon pulls the sea. | | sea bulges |'
[ "$(run)" = 1 ] && grep -q "no words on screen" "$tmp/out" || fail "an empty screen column must fail"

table '| pull | The moon pulls the sea. | Moon | sea bulges |'
echo '[{"id":"pull","text":"The moon pulls seas."}]' >"$tmp/beats.json"
[ "$(run)" = 1 ] && grep -q "differs" "$tmp/out" || fail "beats.json drifting from the table must fail"
echo "beats check ok"
