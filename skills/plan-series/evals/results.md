# plan-series eval results

Pass is 14 of 18 with no dimension at 0 (`rubric.md`). Each case ran three times on fresh subagents that saw only the request and the fixture files: runs 1 and 2 on Sonnet, run 3 on Opus. A blind Opus judge scored the three runs of a case together, shuffled as A, B and C; a second Sonnet judge scored A alone. Cases 5 and 6 are held out: no skill change was made from their results. Run on 27/10/2026.

## Scores

| Case | Baseline (no skill) | Round 2 | Round 3 (final) | Judges agree |
|---|---|---|---|---|
| 1, onboarding funnel | 12 FAIL | 16, 16, 17 | 17, 18, 17 | yes |
| 2, one-page closing checklist | 11 FAIL | 15 FAIL, 15 FAIL, 18 | 18, 18, 18 | yes |
| 3, two audiences | 11 FAIL | 16, 16, 17 | 14, 16, 16 | yes |
| 4, ward induction | 11 FAIL | 15, 14, 16 | 15, 15, 16 | yes |
| 5, docs pages (held out) | 12 FAIL | 16, 15, 16 | 14, 15, 18 | yes |
| 6, a course (held out) | 12 FAIL | 17, 17, 17 | 17, 16, 17 | yes |

The baseline fails all six cases: it re-teaches facts in deeper units and adds recap or intro units with no facts of their own. The final skill passes 18 of 18 runs, held-out cases included.

## What changed between rounds

1. **Round 1 → 2:** a unit splits only where its viewer would stop between the parts (another audience, another moment of use, a skill to practise first). In round 1, every run of case 2 failed on size.
2. **Round 2 → 3:** length never splits a unit by itself; a unit past the length cap gets chapters inside it. In round 2, two of three runs of case 2 cut a one-evening checklist into several videos because their fact count ran past the cap. In round 3 all three kept one unit, with chapters.

Between rounds 2 and 3, a leak audit also found example text that matched case 1 (`FORMAT.md`, a word in `scripts/plan.py`) and case 2's domain (`tests/test_plan.sh`). All three were replaced with unrelated examples before round 3 ran. The same review found that a timetabled lesson cannot take chapters, so a lesson past its slot splits at the nearest break.

## Weak spots left

- Dimension 5, one idea per unit stated as an outcome, scored 1 in at least two runs of five cases. Units often state a topic plus an outcome, or two outcomes.
- Dimension 2, a first tier that stands alone, scored 1 in all runs of cases 3 and 4.
- Case 5 (held out): two runs missed the same fact. The checker only sees facts that reached the inventory, so step 2's read of the source is the only guard.

## Triggers

Open queries 12 of 12; held-out queries 6 of 8 (`triggers-result.md`). "Content series" and "tutorial series" did not fire. The description is 654 characters, about 164 tokens loaded in every session.
