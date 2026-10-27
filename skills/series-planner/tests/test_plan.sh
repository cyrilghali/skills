#!/usr/bin/env bash
# Exercises scripts/plan.py on small plans. Prints "plan check ok" when every case behaves.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
run() { python3 -I "$here/scripts/plan.py" "$tmp/p" >"$tmp/out" 2>&1; echo $?; }
fail() { echo "FAIL: $*"; cat "$tmp/out"; exit 1; }
mkdir "$tmp/p"
plan() { cat >"$tmp/p/plan.json"; }

good='{"goal":"New keepers can inspect a hive alone","evidence":"a new keeper inspects a hive alone in week two",
 "audiences":[{"id":"keeper","who":"a new beekeeper","knows":"nothing about the colony"},
              {"id":"breeder","who":"a queen breeder","knows":"the overview"}],
 "tiers":[{"id":"overview","audiences":["keeper","breeder"],"standalone":true},
          {"id":"deep","audiences":["breeder"]}],
 "units":[{"id":"u1","tier":"overview","idea":"a calm hive is opened from the side"},
          {"id":"u2","tier":"deep","idea":"a queen cell is capped on day eight","prerequisites":["u1"]}],
 "facts":[{"id":"f1","text":"Smoke calms the guard bees","source":"guide p.3","unit":"u1"},
          {"id":"f2","text":"A queen cell is capped eight days after the egg","source":"guide p.9","unit":"u2"}%s]}'

printf "$good" "" | plan
[ "$(run)" = 0 ] && [ -f "$tmp/p/briefs/u2.md" ] || fail "a sound plan must pass and write briefs"
grep -q "f1" "$tmp/p/briefs/u2.md" && grep -q "already has" "$tmp/p/briefs/u2.md" || fail "u2's brief must list u1's facts as already known"

printf "$good" ',{"id":"f3","text":"Drones have no sting","source":"guide p.12"}' | plan
[ "$(run)" = 1 ] && grep -q "f3: in no unit" "$tmp/out" || fail "an unplaced fact must fail"

printf "$good" ',{"id":"f3","text":"Drones have no sting","source":"guide p.12","dropped":"off-goal: too technical for new keepers"}' | plan
[ "$(run)" = 1 ] && grep -q "dropped for depth" "$tmp/out" || fail "a fact dropped for depth must fail"

printf "$good" ',{"id":"f3","text":"Hives are checked weekly","source":"old leaflet","dropped":"outdated: checks are every nine days since the new guide"}' | plan
[ "$(run)" = 0 ] || fail "a fact dropped as outdated must pass"

printf "$good" ',{"id":"f3","text":"smoke calms the guard  bees","source":"guide p.3","unit":"u2"}' | plan
[ "$(run)" = 1 ] && grep -q "same text as f1" "$tmp/out" || fail "one fact taught in two units must fail"

printf "$good" '' | sed 's/"prerequisites":\["u1"\]/"prerequisites":[]/; s/"tier":"overview","idea"/"tier":"overview","prerequisites":["u2"],"idea"/' | plan
[ "$(run)" = 1 ] && grep -q "stands alone" "$tmp/out" || fail "a standalone unit with a prerequisite must fail"
printf "$good" '' | sed 's/"tier":"overview","idea"/"tier":"overveiw","idea"/' | plan
[ "$(run)" = 1 ] && grep -q "tier 'overveiw' does not exist" "$tmp/out" && ! grep -q Traceback "$tmp/out" || fail "a misspelled tier on a prerequisite must be listed, not crash"

printf "$good" '' | sed 's/"id":"u2"/"id":"u1"/; s/"unit":"u2"/"unit":"u1"/; s/"prerequisites":\["u1"\]/"prerequisites":[]/' | plan
[ "$(run)" = 1 ] && grep -q "unit u1: id used twice" "$tmp/out" || fail "two units with one id must fail"

printf "$good" ',{"id":"f3","text":"Smoke keeps the guard bees calm","source":"guide p.4","dropped":"duplicate: f1 says this in more detail"}' | plan
[ "$(run)" = 0 ] || fail "a duplicate drop that mentions detail must pass"

echo '{bad' >"$tmp/p/plan.json"
[ "$(run)" = 1 ] && grep -q "not valid JSON" "$tmp/out" && ! grep -q Traceback "$tmp/out" || fail "invalid JSON must fail with one line"

echo '{"goal":"g","evidence":"e","units":[{"tier":"overview"}]}' >"$tmp/p/plan.json"
[ "$(run)" = 1 ] && grep -q "has no id" "$tmp/out" && ! grep -q Traceback "$tmp/out" || fail "a unit with no id must fail with one line"

printf "$good" '' | python3 -c 'import json,sys; p=json.load(sys.stdin); p.pop("audiences"); [t.pop("audiences") for t in p["tiers"]]; print(json.dumps(p))' | plan
[ "$(run)" = 1 ] && grep -q "no audiences" "$tmp/out" || fail "a plan with no audiences must fail"

echo "plan check ok"
