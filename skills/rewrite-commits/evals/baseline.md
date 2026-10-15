# rewrite-commits baseline (no skill)

One run per case, Sonnet, fresh headless session, no skill folder; judged by a fresh Opus session against `rubric.md`.

| Case | Total | Verdict | What went wrong |
|---|---|---|---|
| 1 | 13/18 | FAIL | `git add -p` for the split file (needs an editor an agent cannot drive); an unrequested `git rebase origin/main` before the rewrite; backup taken after that rebase |
| 2 | 17/18 | PASS | none: said there was nothing to collapse and ran nothing |
| 3 | 4/18 | FAIL | squashed and force-pushed a non-draft PR with a changes-requested review, detaching the reviewer's inline comments |
| 4 | 13/18 | FAIL | soft reset to the trunk tip instead of the fork point; branches pushed one at a time; tree check printed a warning but did not gate the push |
| 5 | 17/18 | PASS | none of consequence: read the base from the PR, kept the teammate's commits out, flagged the stale hash |

Gaps the skill has to close: stop on a reviewed PR, split a file without interactive staging, reset to the fork point rather than the base tip, keep the rewrite to the commits (no rebase onto a newer base), and push a stack atomically only after its final tree is proven unchanged.

Cases 2 and 5 pass without the skill. They stay as regression guards: case 2 checks the skill does not inflate a one-commit branch, case 5 is the different-domain case and checks the skill keeps the base the model already reads correctly.

## With the skill

Three runs per case, same models and judge, generated from a copy of the folder without `evals/`.

| Case | Baseline | Run 1 | Run 2 | Run 3 | Second judge on run 1 |
|---|---|---|---|---|---|
| 1 | 13 FAIL | 17 PASS | 17 PASS | 17 PASS | 17 PASS |
| 2 | 17 PASS | 18 PASS | 17 PASS | 18 PASS | 18 PASS |
| 3 | 4 FAIL | 17 PASS | 18 PASS | 18 PASS | 17 PASS |
| 4 | 13 FAIL | 15 PASS | 15 PASS | 15 PASS | 16 PASS |
| 5 | 17 PASS | 18 PASS | 17 PASS | 17 PASS | 17 PASS |

Case 4 loses points on guesses the input leaves open (which paths the bottom branch owns), not on the stack procedure.
