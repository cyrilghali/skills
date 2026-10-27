# video-script eval results

Pass is 18 of 22 with no dimension at 0 (`rubric.md`). Each case ran three times on fresh subagents that saw only the request and the fixture files: runs 1 and 2 on Sonnet, run 3 on Opus. A blind Opus judge scored the three runs of a case together, shuffled as A, B and C; a second Sonnet judge scored A alone. Cases 5 and 6 are held out: no skill change was made from their results. Run on 27/10/2026.

## Scores

| Case | Baseline (no skill) | Round 0 (first draft) | Round 2 (final) | Judges agree |
|---|---|---|---|---|
| 1, a brief fact its source contradicts | 16 FAIL | 21, 19, 18 | 21, 22, 21 | yes |
| 2, a deep dive on known basics | 17 FAIL | 18 FAIL, 18 FAIL, 21 | 19, 20, 20 | yes |
| 3, jargon source, lay audience | 18 | 21, 20, 20 | 21, 21, 20 | yes |
| 4, a 30-second ask | 19 | 22, 21, 21 | 22, 22, 21 | yes |
| 5, no brief (held out) | 14 FAIL | 18, 20, 18 | 20, 19, 21 | yes |
| 6, a shorter remake (held out) | 14 FAIL | 19 FAIL, 22, 19 | 20, 19, 20 | yes |

The baseline passes 2 of 6 cases. The final skill passes 18 of 18 runs, held-out cases included.

## What changed between rounds

One change: `scripts/beats.py`, run in step 4. In round 0 the recurring misses were beats of three sentences (dimension 5) and on-screen words the narration never says (dimension 8). The script now lists both, plus drift between `beats.json` and the table.

## Weak spots left

- Case 6 (held out): dimension 6, a term left undefined, scored 1 in all three runs. Not tuned, since the case is held out.
- Case 2: dimension 7 (a known fact said in more than a clause) scored 1 in two runs. It no longer fails the case.

## Triggers

20 of 20 queries routed as expected (`triggers-result.md`). The description is 525 characters, about 131 tokens loaded in every session.

## Leak audit

After round 0, a fresh reviewer read the skill against the cases. It flagged the old `tests/test_beats.sh`, whose fixture used the subjects of cases 2 and 3; the test was rewritten in an unrelated domain. An earlier audit also removed a remake sentence that restated case 6's source. A final audit after round 2 found two more in `tests/test_claims.sh` (case 1's `2^attempt` and case 3's bread facts); both were moved to unrelated examples. Those tests sat in the skill folder during round 2, so a generator could have read them; whether one did was not checked. Case 1 and case 3 scores may be slightly flattered. The skill text itself (SKILL.md, STYLE.md, REFERENCE.md, BRIEF.md) restates no case.
