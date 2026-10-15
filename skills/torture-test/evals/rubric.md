# torture-test scoring rubric

Each dimension scores 0 to 2. A case passes with a total of at least 14 of 18
and no dimension at 0. Run the project yourself: every kill-check claim is
proven by `mix test` or `pytest`, never taken from the triage.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Seeded bugs are found | a seeded bug missed, or a bug reported that the code does not have | found, repro or impact vague | every seeded bug with a minimal repro |
| 2 | Findings come before tests | a test covers a bug never reported | reported, severity or beneficiary missing | repro, beneficiary and severity, then tests |
| 3 | Each attack and test names its beneficiary | none named | some named | every one names a visible failure and who sees it |
| 4 | Every added test is a killer test | an added test passes on the buggy code | fails on the bug, pass on the fix unproven | fails on the bug and passes on a fix, proven by running |
| 5 | Zero padding | a test added for an attack that passes, or duplicating the suite | one borderline redundant test | passed attacks produce confidence lines only |
| 6 | Axes fit the code | axes chosen by default rather than by where the code can fail, or an axis the code cannot fail on | one irrelevant axis | only axes the code can fail on, no invented invariant |
| 7 | Invariant attacks use the project's property library | fixed examples stand in for a property, or a dependency is added | property present but its generator misses what the code treats specially | property with a generator that reaches the special case, or the missing library reported as an axis not covered |
| 8 | The triage has the four sections | no triage | a section missing or merged | bugs, real gaps, passed attacks, axes not covered |
| 9 | The input's constraints survive | a commit, a fix applied, or a dependency added | a minor constraint bent | all respected |

When a case has no bug, score dimensions 2 and 4 at 2 if no test was added.
When a case has no invariant attack, score dimension 7 at 2 if the agent
neither wrote fixed examples in place of a property nor added a library.

## Case-specific must-checks

- **Case 1:** dimension 7 = 0 if the title generator cannot produce `|`
  (`string(:printable)`, `string(:utf8)` or `string(:alphanumeric)` alone).
  Prove it: the property fails on the current code and passes on a `decode/1`
  that splits on the last `|`.
- **Case 2:** dimension 5 = 0 if any test is added. Dimension 6 = 0 if the
  pass attacks time zones, DST or locale, or writes a property that restates
  `weekday() >= 5`.
- **Case 3:** dimension 1 = 0 if the triage reports a defect that contradicts
  the docstring. Raising documented behavior as a product gap is correct:
  titles with no Latin letters (`"你好"`) produce an empty slug.
  Dimension 5 = 0 if any test is added. Dimension 9 = 0 if Hypothesis is
  added; the property axis belongs under axes not covered.
- **Case 4:** dimension 1 = 1 at most if the triage never says that a retry
  after a timeout can debit twice (as a bug or a product gap). Dimension 4 = 0
  if a retry test uses the stateless `make_db` mock, or if a race test passes
  on the current code in any of five runs. Dimension 5 = 0 for a new test on
  zero, negative or insufficient amounts.
- **Case 5:** dimension 9 = 0 if `stream_data` is added to `mix.exs`.
  Dimension 1 = 1 at most if only one of the two seeded bugs is found.
  Dimension 3 = 1 at most if the triage says "GO payouts v2" or "Thursday
  batch" without saying what a merchant sees.
- **Case 6:** dimension 8 = 0 if `billing/` appears under passed attacks.
  Dimension 8 = 1 at most if the `billing/` axes are missing from axes not
  covered. Dimension 9 = 0 if the failing test or `tax.py` is changed.
  Dimension 5 = 0 if any test is added for `search/`.
  Dimension 1 is not lowered for reporting the red test as a spec conflict;
  dimension 1 = 0 only for a bug claimed in `search/`.

## Output format (return exactly this)

CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
PROOF: the commands you ran and their result lines
FIXES:
- dim <n>: <one concrete rewrite suggestion>
