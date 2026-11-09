# skill-telemetry scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 14 of 18 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | One JSON line per run, appended to `runs.jsonl` in the right folder | no line, or wrong folder | line present but malformed or in a second file | one valid JSON line in `$SKILL_TELEMETRY_DIR/runs.jsonl` (or the default under `HOME`) |
| 2 | Every base field present: ts (ISO 8601 UTC), skill, repo, branch, pr, session | two or more missing | one missing or wrong type | all six present, null where unknown |
| 3 | Values typed: numbers as numbers, `a/b` as `a` and `a_of` | all strings | one typing rule missed | both rules hold |
| 4 | Text with quotes and spaces survives byte for byte | lost or truncated | escaped wrongly | identical on read-back |
| 5 | Report prints one block per skill with runs, last run, per-metric median, last value and half-to-half change | missing block or crash | a stat missing or wrong | all stats, plain text, within 80 columns |
| 6 | Compliance line compares sessions that invoked the skill with runs recorded | absent | one count only | both counts on one line |
| 7 | Trend read in the metric's own direction (fewer survivors is better; more killed is better) | direction inverted | direction right, no judgment | direction right and a one-line judgment on keeping the skill |
| 8 | Recording happens once, only at the end, never on a dry run, and never asks about the folder | asks or records at start | one of the three conditions missing | all three stated or honored |
| 9 | Nothing the input decided was lost | a fact missing | a minor fact dropped | all survive |

## Case-specific must-checks
- **Case 1:** dimension 4 = 0 if the stored note differs from `it's a "b" test`; dimension 3 = 0 if `killed` is stored as a string or `killed_of` is absent.
- **Case 2:** dimension 5 = 0 if the output shows a median, a trend or a last-run date for zero runs, or if the script exits non-zero.
- **Case 3:** dimension 8 = 0 if the sentence is placed anywhere but the skill's last step, or if a dry run is not excluded; dimension 9 = 0 if a metric name is not in `METRICS.md`.
- **Case 4:** dimension 7 = 0 if the answer treats fewer `real_survivors` as worse, or counts torture-test rows as mutation-test runs; dimension 6 = 0 if the compliance line is missing or compares the wrong counts.
- **Case 5:** dimension 8 = 0 if the agent asks where to store the line; dimension 1 = 0 if the line lands anywhere but `$HOME/.local/share/skill-telemetry/runs.jsonl`.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
