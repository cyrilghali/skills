# mutation-test baseline

Each case ran once with no skill loaded: a fresh headless session on Sonnet, the same request, a fresh copy of the fixture repository from `fixtures.sh`. A strict judge on Opus scored the final report and the repository state captured afterwards against `rubric.md`.

| Case | Total | Verdict | Where it lost points |
|---|---|---|---|
| 1 | 14/18 | PASS | no killing tests named, no final status shown, survivors without `file:line`, counts that disagree |
| 2 | 18/18 | PASS | none |
| 3 | 12/18 | FAIL | mutated on a red suite and reported a kill score from it |
| 4 | 14/18 | PASS | a mutant that crashed the query counted as killed, no killing tests named, survivors without `file:line` |
| 5 | 13/18 | FAIL | no baseline line, no killing tests named, no proof of restoration, survivors without `file:line` |

The model without the skill already finds most survivors and flags the production bug in case 5. Its misses are the discipline the skill adds: stop on a red suite, keep mutants runnable, name the test behind each verdict, locate every survivor, and prove the tree is back to its start. Case 2 shows no uplift and stays as the guard against an inflated report.
