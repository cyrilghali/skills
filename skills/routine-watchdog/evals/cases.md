# routine-watchdog eval cases

Each case gives a generation agent `scripts/routine_watchdog.py --problems`'s
already-printed output (step 1 already ran) and asks it to apply `SKILL.md`
step 2: report what's flagged. A judge scores it against `rubric.md`. The
`Trap` field names the failure mode the case is designed to catch.

## Case 1 — two real failures, evidence included

**Input:**
```
com.example.mail-unsub: last exit 1 (7 runs) -- tail: sqlite3.DatabaseError: authorization denied
com.example.payfit: last exit 1 (284 runs) -- tail: sqlite3.OperationalError: unable to open database file
```

**Trap:** merging both into one finding, or dropping either label or its own tail;
a shared cause may be offered only as a labelled hypothesis, with each tail still quoted.

## Case 2 — all healthy

**Input:**
```
all 30 routines healthy
```

**Trap:** inventing a caveat or a "minor concern" when the script found nothing
wrong; the correct reading is one flat sentence, no padding.

## Case 3 — a "not loaded" line for a job that self-retires

**Input, plus the reader is told:** "fr.example.migrate-once is documented
elsewhere as a job that unloads itself once its one-time migration finishes."
```
fr.example.migrate-once: not loaded in launchd
```

**Trap:** reporting this as a failure on the same footing as a nonzero exit
code. `not loaded` isn't one of the four numbered checks; the correct reading
names it as a separate signal and states the self-retiring context makes it
ambiguous rather than calling it broken.

## Case 4 — a stale-log flag next to a real failure

**Input:**
```
com.example.cal-notify: log /tmp/cal-notify.log is 3d old on a ~1m schedule
com.example.mail-unsub: last exit 1 (7 runs) -- tail: sqlite3.DatabaseError: authorization denied
```

**Trap:** collapsing a "stale log" finding (check 3) and a "nonzero exit" finding
(check 1) into one severity. Also don't drop the schedule context ("~1m
schedule") when restating cal-notify's line — a job whose newest log file is
3 days old against a 1-minute schedule is thousands of missed cycles' worth of
staleness, real evidence the check already computed, not a number to soften.

## Case 5 — a missing-tool flag

**Input:**
```
com.example.weekly-weeding: python3, digest-add not on PATH=/usr/bin:/bin:/usr/sbin:/sbin
```

**Trap:** describing this as "the script crashed" or "a bug in weekly-weeding"
instead of naming the actual cause — the plist's own `PATH` doesn't reach
those binaries, the same root cause the skill's own build report found in two
real plists (a fixable one-line plist edit, not a code fix).

## Case 6 — a "not loaded" line for a job that should be running

**Input, plus the reader is told:** "com.example.nightly-sync has a plist with a daily calendar schedule, and its notes say it is a permanent recurring job with no end date."
```
com.example.nightly-sync: not loaded in launchd
```

**Trap:** softening every status outside the four checks into "ambiguous". Here the
job's own context shows it should be loaded, so the correct reading calls it a
real problem and cites that evidence.
