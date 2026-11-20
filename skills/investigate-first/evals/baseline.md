# investigate-first baseline

Run 20/11/2026. "Old" is the skill before the red-command gate. "New" is the text with it. Judges were blind to the arm. For cases 8-10 they reran each report's repro command on a pristine fixture copy. These runs test this edit against the previous text; the no-skill arm is at the end.

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

(The no-skill arm now exists; see the last section.)

- The repro-command gate: no effect on cases 8-10, where every arm ran code first. It showed one on real-use case 13 (see the last sections).
- Tagged debug logs and the cleanup grep: 0 of 9 runs in either arm added a log.
- The lines added after these runs, listed in `coverage.md`.
- The short-code line's word target: runs under the earlier "about 100 words" wording came in at 137-147 words against 332 for the old text, all with a short list. Case 11 was written in the same session as that line, so it is held out in time only; a case written by an agent that has not read the skill is still missing.
- The description's "where should this live" and "performance regressions" triggers: no case covers them yet.

Two fresh-agent leak audits read the skill diff against every case and fixture. The second, on the text after the round-2 hypotheses change, found no line restating a case.

## Text after the roast fixes, one run each

Held-out case 10: 19. Case 4: 19. Case 5: 18. Case 7: 20. All PASS. These runs cover the moved evidence-tiers pointer and the new done states.

## Text after roast round 3, one run each

Case 8: 18. Case 9: 19. Held-out case 10: 18 (no prediction stated that run). All PASS, and judges reran each repro on a pristine copy: same output, no diff, no leftover debug lines.

Case 2 failed on length with the round-3 text (17, dim 8: 0) and with the old text (18, dim 8: 0, about 28 lines), so the inflation predates this edit. After one line telling a question about a few lines of code to get a few lines back, case 2 passed with 19 at 266 words, still with a bullet list. Case 3 on that text: 17, PASS, losing points on evidence grading and length. Round 3 also changed the evidence-grading line, which every question uses, so that line may explain part of case 3's drop (old 20, then 19, 18, 17, one run each).

## Final text after roast round 4, one run each unless noted

The short-code line now asks for about 100 words in plain sentences. The case 2 rule now counts words and caps a list at dim 8 = 1, since a line count let a 266-word answer with a bullet list pass.

| Case | Score | Words |
|---|---|---|
| 2, two runs | 18, 19 | 137, 139 (old text: 332) |
| 11, held out, written after the line | 19 | 147 |
| 10, held out | 18 | |
| 3 | 18 | |

All PASS. The short answers still used a numbered or bullet list, so dim 8 stayed at 1. Judge replies: `final-round4.md` and `final-round4-c3.md` in the eval scratch folder; earlier rounds' replies are in the session log.

## Committed text (round 5), one run each

The round-5 text raised the short-code target from about 100 to about 150 words to match the rubric, and dropped the rubric rule that capped a list at dim 8 = 1. That moves the bar toward what the runs produced; the gain it still shows is 131-145 words against 332 for the old text.

Case 2: 20 (145 words). Case 11: 20 (131 words). Case 8: 19, repro rerun on a pristine copy, no diff, no debug lines, no extra files, so the reworded cleanup line kept the harness rule intact. Judge replies: `final-committed.md` in the eval scratch folder. A fresh leak audit of the final short-code line found no leak.

## No skill loaded, one run per case

Same requests, fresh agents told not to load any skill, judged blind with the same rubric. Skill column: the latest run of the current text (cases 1, 4-7, 9 ran on earlier wordings of it; see above).

| Case | No skill | Skill |
|---|---|---|
| 1 | 19 | 19 |
| 2 | 17, FAIL (311 words) | 20 |
| 3 | 17 | 18 |
| 4 | 19 | 19 |
| 5 | 18 | 18 |
| 6 | 16 | 17 |
| 7 | 16 | 20 |
| 8 | 18 | 19 |
| 9 | 17 | 19 |
| 10 | 18 | 18 |
| 11 | 18, FAIL (192 words) | 20 |

Without the skill, 9 of 11 pass. Its two failures are short code questions answered at length. Where the skill gains points: it proposes no fix nobody asked for (no-skill lost dim 3 on cases 3-6 and 8-10), and it states predictions and the smallest failing input (no-skill got dim 10: 1 on all three runnable cases). Both arms ran the code first on cases 8-10, so the repro gate still shows no effect on these cases. Judge replies: `K-runnable.md`, `K-paper-a.md`, `K-paper-b.md`.

## Case 3 isolation

Two runs on the current text scored 19 and 19. Two runs with "incidental ones included" removed from the evidence-grading line scored 19 and 20. The earlier 17 and 18 were run-to-run spread, not that phrase, so it stays. Judge replies: `H-case3.md`.

## Cases from real use (12-14), one run per arm

Three past sessions where an agent named a cause before running anything, rebuilt as small runnable projects with the domain renamed. Judges saw the two reports per case under neutral names, reran each repro on a clean copy, diffed the run folder and grepped for leftover debug lines.

| Case | No skill | Skill |
|---|---|---|
| 12, redirect loop | 17 | 19 |
| 13, empty first scan | 13, FAIL | 18 |
| 14, deadline missed some days | 13, FAIL | 19 |

This is the first place the repro gate shows an effect. Without the skill, case 13 named the cause from reading the code and only reran the replay; with it, the run changed the delay and showed the scan succeed. Without the skill, case 14 cited no source and proposed fixes. The agent that wrote these cases had read the skill, so their traps may lean toward what it checks. Judge replies: `X12.md`, `X13.md`, `X14.md`.
