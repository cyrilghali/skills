# investigate-first baseline

Run 20/11/2026 on cases 8-10, the runnable cases. "Old" is the skill before the red-command gate; "new" is the skill with it. Each arm ran each case three times. Judges were blind to the arm and reran each report's repro command on a pristine fixture copy. A second judge scored one run per case and gave the same verdict each time. No no-skill arm was run: these cases test this edit against the previous text.

| Case | Old totals (/20) | New totals (/20) | Old runs with dim 10 at 2 | New runs with dim 10 at 2 |
|---|---|---|---|---|
| 8 | 18, 18, 18 | 20, 18, 20 | 0 of 3 | 2 of 3 |
| 9 | 19, 20, 18 | 18, 18, 20 | 1 of 3 | 2 of 3 |
| 10 (held out) | 19, 18, 18 | 19, 19, 19 | 0 of 3 | 2 of 3 |

Every run passed in both arms. The previous text already ran the code and rejected the bystander guesses. The edit adds shrinking to the smallest failing input, hypotheses with stated predictions, and a cleanup check.

Regression run of the new text on cases 1, 3, 6 and 7, once each: 19, 19, 17 and 18, all PASS. On case 6, the run that had nothing to execute said so and presented no output it had not produced.

After the leak audit, the flaky-failure line was reworded to the upstream skill's list. Two more case 9 runs on that wording measured the failure rate, pinned a setting that fails every run and named the smallest input. They were not judged.
