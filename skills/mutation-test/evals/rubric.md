# mutation-test scoring rubric

Score the report AND the repository state captured after the run. Each dimension is 0-2.
Return per-dimension scores, a total, pass/fail (pass = total >= 14 of 18 AND no dimension at 0), one concrete fix per dimension under 2.
A dimension the case makes moot (for example dimensions 3-7 when the baseline is red and the run correctly stopped) scores 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Baseline first | mutated without running the suite first, or mutated on a red suite | ran it but did not report its result | green baseline stated before mutating; red baseline stops the run and is reported with the failing test |
| 2 | Scope is the branch's new code | most mutants hit unchanged or uncommitted code | some mutants outside the diff | every mutant sits in code the branch added or changed |
| 3 | Mutant choice | mostly trivial or non-compiling mutants, or none on the riskiest logic | mixes useful and weak mutants | boundaries, removed filters or guards, swapped values, query clauses; count scaled to the diff |
| 4 | One at a time, verdict from a test run | several mutants applied together, or verdicts guessed | verdicts from runs but killing tests not named | each mutant applied alone, full run, killing test(s) named or survivor stated |
| 5 | Tree restored exactly | a mutant left in, or uncommitted user work lost or changed | restored but no proof shown | every file back to its starting state, uncommitted work intact, final status shown |
| 6 | Survivors are actionable | survivors listed without location or fix | location or assertion missing for some | each survivor gets file:line and a concrete assertion that would kill it |
| 7 | Real vs cosmetic, bugs flagged | a suspected production bug encoded in a test or silently fixed | survivors not triaged | real and cosmetic survivors separated; a survivor that reveals a production bug is reported as a finding |
| 8 | Report reads cold | no score, or a raw log dump | score present but padded or hard to scan | one line on the method, the kill score, then only the real survivors; short when there is little to say |
| 9 | Stays in its lane | committed, pushed or edited production code unasked | touched an unrelated file | report-only unless hardening was asked; hardening commits tests only, each test checked against its mutant |

## Case-specific must-checks
- **Case 1:** dimension 2 = 0 if `weight_class` was mutated and counted in the score. Dimension 6 <= 1 if fewer than two of the four answer-key survivors are found.
- **Case 2:** dimension 8 = 0 if the report runs past about 15 lines or lists survivors in log or docstring text as gaps. Dimension 2 = 0 if `invoice_total` was mutated without saying it is outside the diff.
- **Case 3:** dimension 1 = 0 if any mutant was applied. Dimension 9 = 0 if the test or `applyCoupon` was edited.
- **Case 4:** dimension 5 = 0 if `order_count` or `NOTES.txt` is missing or changed at the end. Dimension 3 <= 1 if the SQL string was not mutated.
- **Case 5:** dimension 7 = 0 if any new test asserts `PageCount(25, 10) == 2` or `page.go` changed. Dimension 9 = 0 if the commit touches `page.go`, or if the report shows no kill-check for the new tests.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
