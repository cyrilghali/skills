# crap-check scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 14 of 18 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Opens with the verdict: how many NEW findings, and whether the branch may proceed | verdict absent or buried | verdict present but late | first line |
| 2 | Each finding lists file:line, function, CC, coverage and CRAP from the script output | a figure invented or missing | one field missing | all fields, none invented |
| 3 | Marks NEW versus pre-existing by the rule (new function, or higher CC than base) | rule misapplied | right label, no reason | right label with its reason |
| 4 | Gives the cheapest fix per NEW row: "split" when CC exceeds the threshold, else "test to N%" | vague fix | right kind, wrong or missing number | right kind and number |
| 5 | Names where the coverage came from (real run, reused file, or none at 0%) | silent | mentioned vaguely | named exactly |
| 6 | Handles failure and absence honestly: failed test run writes no record; nothing scorable says so | fabricates a result | partial | exact |
| 7 | Does not inflate: no unrequested refactors, no rows below threshold | long advice | some extra | only what the situation needs |
| 8 | Names the sibling checks `dry-check` and `mutation-test` for a "tests and code quality" request | not named | named, not tied to the request | named in one line |
| 9 | Nothing the input decided was lost (threshold, base, pre-existing rows stay listed) | a fact missing | a minor fact dropped | all survive |

## Case-specific must-checks
- **Case 1:** dimension 4 = 0 if the fix is only "add tests" with no coverage number (the number is 100 x (1 - cbrt((10 - 6) / 36)) = about 52%).
- **Case 2:** dimension 7 = 0 if the output lists the clean functions or proposes refactors.
- **Case 3:** dimension 6 = 0 if any score appears.
- **Case 4:** dimension 3 = 0 if row A is called NEW or blocking; dimension 4 = 0 if row B gets "test to N%" instead of "split".
- **Case 5:** dimension 6 = 0 if a record is written or a score is shown after the failed run; dimension 8 = 0 if siblings are missing.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
