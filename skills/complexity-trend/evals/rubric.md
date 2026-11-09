# complexity-trend scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 10 of 12 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Answer first | no one-line answer up top | answer present but buried or missing a part | first line gives the 30-day density direction and the merged pull request count, or says why either is missing |
| 2 | Density before counts | raw counts drive the verdict | density mentioned but not weighed against line growth | verdict rests on density, with growth named when lines outgrew complexity |
| 3 | Honest about thin data | a trend is read into too little history | caveat present but the verdict still overreaches | missing baselines and short windows are stated plainly and no verdict outruns them |
| 4 | Config finding | proposes editing `.credo.exs`, a threshold or a `credo:disable` | notes the two numbers without saying what the gap means | when `complexity_all` moves while the own-config delta stays near zero, says the project's config cannot see the trend, as a finding; when both move together, does not claim this |
| 5 | Numbers faithful | a number invented or misquoted | a minor rounding or date slip | every number and date traces to the input |
| 6 | Brevity | a wall of restated metrics | some restated lines | answer line plus a few lines that add judgment |

## Case-specific must-checks
- **Case 1:** dimension 1 = 0 if the merged pull request count (604) is absent from the answer line.
- **Case 2:** dimension 2 = 0 if the reading says complexity got worse without naming the density drop.
- **Case 3:** dimension 3 = 0 if the reading calls the level good or bad or implies a direction.
- **Case 4:** dimension 4 = 0 on any proposed config change; dimension 3 = 1 at most if the reading presents the 20-day window as a 30-day trend.
- **Case 5:** dimension 5 = 0 if last week's row is presented as today's measurement; dimension 3 = 0 if the failure is not reported.
- **Case 6:** dimension 4 = 0 if the reading claims the project's config cannot see the trend.
- **Case 7:** dimension 6 = 0 if the reading invents a direction or adds judgment lines the numbers do not support; dimension 3 = 1 at most if it flags a trend.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_
TOTAL: _/12
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
