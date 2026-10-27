# plan-series baseline (no skill)

Each case ran once on Sonnet as a fresh general-purpose agent with no skill loaded. The agent got the case's Input reworded as a plain request, plus the fixture copied alone into a scratch folder. One fresh Opus judge scored each output against `rubric.md` with the case's fact key.

Outputs (plan.md plus briefs) are kept outside the skill, in the build evidence folder under `series-planner-baseline/job<N>/`.

| Case | Held out | Total | Verdict | Lowest dimensions | Coverage (placed / missing / double-placed, of true facts; false caught) |
|---|---|---|---|---|---|
| 1 Onboarding funnel | no | 12/18 | FAIL | 4 re-teach = 0 (deep dive re-teaches the match rule); 5, 6, 7, 9 = 1 | 27 / 0 / 11 of 27; 2 of 2 |
| 2 Bakery checklist | no | 11/18 | FAIL | 9 size = 0 (six videos plus a recap for one page); 2-6 = 1 | 15 / 0 / 0 of 15; 1 of 1 |
| 3 Recycling, two audiences | no | 11/18 | FAIL | 4 re-teach = 0; 1, 3, 5, 6, 9 = 1 | 24 / 1 / 4 of 25; 2 of 2 |
| 4 Ward induction | no | 11/18 | FAIL | 4 re-teach = 0, 9 size = 0 (four recap case videos); 2, 5, 6 = 1 | 30 / 0 / 25 of 30; 2 of 2 |
| 5 Library docs | yes | 12/18 | FAIL | 4 re-teach = 0; 2, 3, 6, 9 = 1 | 22 / 0 / 4 of 22; 2 of 2 |
| 6 Groundwater course | yes | 12/18 | FAIL | 9 size = 0 (recap lesson); 2, 4, 5, 6 = 1 | 21 / 0 / 0 of 21; 2 of 2 |

Every case fails with no skill. The same gaps recur: facts taught again in later units, padding units (recaps, worked-case repeats), briefs with no per-fact source, tier or prerequisites, and units with several ideas. The baseline already does well on two things. It drops no fact for depth, and it catches every false or outdated fact. Dimensions 1 and 8 have little headroom.

Rubric change after this run: two judges scored a fact placed in two units under dimension 1 as well as dimension 4. Dimension 1 now counts only missing or wrongly dropped facts. The table shows totals under the new line: cases 1, 4 and 5 each gained 1 point on dimension 1 (the judges gave 11, 10 and 11). The verdicts did not change. The judges' raw scores and fixes are in `judge.md` in each job folder.

Checked: none of the six generation runs called a skill or opened the skill folder; each only read its fixture and wrote its plan.
