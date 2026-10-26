# explainer-video baseline

Each case run once by a fresh agent with no skill loaded, judged against `rubric.md` by a fresh strict judge.

| Case | Total | Verdict | Lowest dimensions |
|---|---|---|---|
| 1, binary search | 13/20 | FAIL | 10 (dark slide look) 0; 2, 4, 5, 7, 8 at 1 (cuts between titled slides, 138 s, 1280x720) |
| 7, five-minute library episode | 12/20 | FAIL | 2 (no chapters) 0, 10 (ruled-notebook cards cut one to the next) 0; 4, 5, 6, 8 at 1 |

Cases 2 to 6 have no baseline run yet.

## With the skill

Same cases, one run each by a fresh agent following the skill, judged by a fresh strict judge on the final MP4.

| Case | Total | Verdict | Lowest dimensions |
|---|---|---|---|
| 1, binary search | 16/20 (+3) | PASS | 2, 5, 6, 10 at 1 (payoff halving finishes before the voice names it; the million band still reads as a bar) |
| 7, five-minute library episode | 16/20 (+4) | PASS | 2, 3, 5, 6 at 1 (only chapter 1 opens on a hook; four sentences name things never drawn) |

Both runs got the drawn look, the Kokoro fallback with measured word times, and a clean layout check on the final.

## Fact-check cases (8 and 9), planning stage only

Run through steps 2 to 4 only (no render), one run each at low effort, judged against the case-specific must-checks in `rubric.md` by running `scripts/claims.py --final` and reading the files. Not a full 20-point scoring; the render dimensions were not exercised.

| Case | No skill | With skill |
|---|---|---|
| 8, wrong attempt limit | beats say 12 (correct) but no `claims.json`: dimension 1 = 0 by the must-check; the one unchecked assumption (attempt numbering) was only mentioned in chat | `claims.py --final` passes (13 claims, 7 beats); a fresh reviewer cut 3 unsourced lines and one more it found; must-check holds |
| 9, remake | no `remake.md`; 6 caption facts left out and listed only in `plan.md`: must-check fails | `remake.md` lists all 14 old claims, 8 kept, 6 dropped on purpose with a reason; `claims.py --final` passes (16 claims, 9 beats); must-check holds |

Limits: the no-skill agent got the correct 12 from `retry.md` without help, so the number trap alone did not bite; what the skill adds is the written, re-checked trail. The with-skill agent set one `text_at_check` by hand after forgetting `--stamp`, and did not re-run the second read after its last edits. No full render was run for these cases.

## Non-code case (10), planning stage only

Run through steps 2 to 4 only (no render), one run each on Sonnet, judged against the case 10 must-check in `rubric.md`.

| Case | No skill | With skill |
|---|---|---|
| 10, a myth in the request | Narration corrects the myth, but there is no `claims.json`; the agent did not open the agency pages it leaned on and took a quote from search summaries; no second read: must-check fails | `claims.py --final` passes (14 claims, 8 beats, every source a URL from NASA, ESA or a science publisher); a blind second read changed one job title in the narration; the premise was flagged to the user: must-check holds |

Limit: neither run repeated the myth, so here too what the skill adds is the opened sources and the second read, not the verdict itself.
