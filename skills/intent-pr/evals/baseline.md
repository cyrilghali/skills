# intent-pr baseline

Each case ran once in a fresh headless session with no skill, no user instructions and no hooks loaded, on the same request the with-skill runs got. A fresh judge scored it against `rubric.md`.

| Case | Baseline scores (1-9) | Baseline total | With skill, three runs | Second judge on run 2 |
|---|---|---|---|---|
| 1 | 1 2 1 1 0 1 2 0 0 | 8 FAIL | 16, 17, 17 PASS | 17 PASS |
| 2 | 1 2 1 0 1 1 2 0 0 | 8 FAIL | 17, 17, 17 PASS | 17 PASS |
| 3 | 2 2 2 2 1 1 2 0 1 | 13 FAIL | 17, 16, 16 PASS | 16 PASS |
| 4 (held out) | 1 2 1 1 0 0 1 0 0 | 6 FAIL | 15, 17, 16 PASS | 17 PASS |
| 5 (held out) | 1 2 1 0 0 1 1 0 1 | 7 FAIL | 18, 17, 18 PASS | 17 PASS |

The baseline writes a sound why but a long body: Summary, Changes and Test plan sections with the checks pasted in, code names throughout, and a reply that does not certify in the first person. Case 3's baseline did recommend a split, then spent a table and a merge plan on it.

Two refinement rounds ran after the first scoring. Round 1 kept extra sections to cases where the author has the material and moved proof numbers out of the body. Round 2 kept code names out of the Why. A fresh audit after each round found no line restating a case.
