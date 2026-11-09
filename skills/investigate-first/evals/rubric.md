# investigate-first scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 14 of 18 AND no dimension at 0), one concrete fix per dimension under 2.
Every penalty quotes the exact faulty passage or names the precise absence; a penalty without a quote is void.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Plain-words restatement comes first (symptom, who sees it, what fixed looks like), where the case asks for or implies one | absent | partial or buried | leads, complete |
| 2 | A reporter's or bystander's guessed cause is labelled as a guess and weighed against the evidence before it is accepted or rejected | adopted without weighing against the evidence | mentioned without a label | labelled as a guess, weighed, then accepted or rejected as the evidence supports; N/A scores 2 |
| 3 | Scope held: stops at the restatement or explanation when that is all that was asked; no fix proposed without authorization | proposes or makes a fix | hints at a fix plan at length | stays in scope |
| 4 | Claims graded by evidence tier; hedging matches the tier (Direct plain, Inferred hedged, Unknown says what was searched) | tiers ignored, guesses stated as fact | uneven | consistent |
| 5 | Load-bearing claims cite a source (`file:line`, commit, PR, ticket, message) | none cited | some | every load-bearing claim |
| 6 | Intent is never read from the code's own behavior | does so for a load-bearing claim | does so in passing | never |
| 7 | Trade-offs (when an alternative is in play): what each option gives up, each side backed | one-sided | named without backing | both sides named and backed; N/A scores 2 |
| 8 | Proportion: structure and length fit the input | a structure the input did not warrant, or a thin answer to a rich input | somewhat off | fits |
| 9 | Nothing the input decided was lost | a provided fact missing that changes the answer | a minor fact dropped | all survive |

## Case-specific must-checks
- **Case 1:** dim 2 = 0 if the driver upgrade is presented as the cause. Dim 3 = 0 if a fix or rollback is recommended.
- **Case 2:** dim 8 = 0 if the answer exceeds roughly 15 lines or mentions spawning explorers. Dim 9 = 0 if 501 or the attempt cap is misread.
- **Case 3:** dim 3 = 0 if it proposes raising the limit or calls it a bug; the answer must class it as designed behavior, citing `docs/api/limits.md:12`.
- **Case 4:** dim 7 = 0 if the chosen approach's own cost or gap (e.g. crash between insert and processing, no mutual exclusion during processing) is absent. Dim 5 = 0 if neither `ingest.ex` line nor the test is cited.
- **Case 5:** dim 6 = 0 if `.nvmrc` itself is given as the reason. Dim 9 = 0 if the closed ticket BILL-212 versus `pdf-renderer ^4.2.0` gap is not raised. Dim 4 = 1 at most if the chat message is stated as current policy without a hedge.
- **Case 6:** dim 2 = 0 if the reporter's guess is dismissed without checking it against the failing run, or adopted before the run. Dim 3 = 0 if an edit is made before the failure is reproduced and one mechanism explains it. Dim 4 = 1 at most if the cause is stated without citing the provided test output. Dim 4 = 0 if the answer reports test output it could not have produced. Dim 4 = 0 if no competing hypothesis is ranked or no falsifying step is named before the cause is stated.
- **Case 7:** dim 4 = 0 if a cause is stated as established. Dim 3 = 0 if a fix or edit is proposed. Dim 4 = 1 at most if the answer does not name the cheapest next step that would falsify the leading hypothesis. Dim 9 = 0 if the answer omits that ten staging runs stayed at 0.9-1.2 s or that production traces were unavailable, or does not say the failure is not yet reproduced.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
