# investigate-first baseline

Run 20/11/2026. "Old" is the skill before the red-command gate. "New" is the text with it. Judges were blind to the arm. For cases 8-10 they reran each report's repro command on a pristine fixture copy. No no-skill arm was run: these runs test this edit against the previous text.

## Cases 8-10, three runs per arm (first new draft)

| Case | Old totals (/20) | New totals (/20) |
|---|---|---|
| 8 | 18, 18, 18 | 20, 18, 20 |
| 9 | 19, 20, 18 | 18, 18, 20 |
| 10 (held out) | 19, 18, 18 | 19, 19, 19 |

Every run passed in both arms. Both arms ran the code and showed real output, and both rejected the bystander guesses. These cases show no effect from the gate itself.

Counted from the 18 reports:

| Behavior | Old | New |
|---|---|---|
| Names the smallest failing input | 3 of 9 (case 8 only) | 9 of 9 |
| States a prediction per hypothesis | 0 of 9 | 4 of 9 |
| Adds tagged debug logs (so the cleanup rule ran) | 0 of 9 | 0 of 9 |

The four runs with a prediction per hypothesis: new case 8 runs 1 and 3, new case 9 run 3, new case 10 run 2. Old case 10 run 1 had a second judge, who gave 18; the table shows the first judge's 19.

The judges did not agree on dimension 10 when predictions were missing: some gave 2 and others gave 1. Read the counts above, not the dimension 10 scores.

## Older cases, one run each

| Case | Old | First new draft | Final text |
|---|---|---|---|
| 3 | 20 (judge reply kept in the session log, no file) | 19 (dim 8: 1) | 18 (dim 8: 1) |
| 6 | 16, FAIL (dim 4: 0) | 17 | not rerun |
| 7 | 19 | 18 (dim 8: 1) | 19 |
| 1 | not run | 19 | not rerun |

The first draft asked for "three to five hypotheses". That padded the case 3 and case 7 answers. The final text asks for at least two while the cause is open, listing only what the evidence leaves open. Case 7 recovered. Case 3 still loses one proportion point on a single run, so watch it in the next round.

## Final text on cases 8-10, one run each

Case 8: 19. Case 9: 20. Case 10: 18 (it did not name the smallest input that run).

Two more case 9 runs on an earlier wording of the flaky-failure line were not judged. Both measured the failure rate, pinned a setting that fails every run and named the smallest input.

## Not yet proven

- The repro-command gate: both arms ran code first on cases 8-10, so these cases show no effect from it. A case where the old text theorizes from code is still missing.
- Tagged debug logs and the cleanup grep: 0 of 9 runs in either arm added a log.
- The lines added after these runs, listed in `coverage.md`.
- The description's "where should this live" and "performance regressions" triggers: no case covers them yet.

Two fresh-agent leak audits read the skill diff against every case and fixture. The second, on the text after the round-2 hypotheses change, found no line restating a case.

## Text after the roast fixes, one run each

Held-out case 10: 19. Case 4: 19. Case 5: 18. Case 7: 20. All PASS. These runs cover the moved evidence-tiers pointer and the new done states.

## Text after roast round 3, one run each

Case 8: 18. Case 9: 19. Held-out case 10: 18 (no prediction stated that run). All PASS, and judges reran each repro on a pristine copy: same output, no diff, no leftover debug lines.

Case 2 failed on length with the round-3 text (17, dim 8: 0) and with the old text (18, dim 8: 0, about 28 lines), so the inflation predates this edit. After one line telling a question about a few lines of code to get a few lines back, case 2 passed with 19 in about 9 lines. Case 3 on that text: 17, PASS, losing points on evidence grading and length; it does not use the changed line.
