# make-video baseline

Since the narration moved out of this skill, every case starts from a finished `beats.json` in `fixtures/`. The scores below were taken before that change, when each case started from the topic alone and the skill also wrote the narration; dimensions 1, 3, 7 and 9 have changed since. Re-run the cases against the current rubric before trusting these numbers as a baseline. Cases 8 to 10 (narration and claim checks) were removed with that content.

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

## With the skill, from a finished narration (current rubric)

One run per case by a fresh agent following the skill, from the `fixtures/` narration, judged by a fresh strict judge on the final MP4.

| Case | Total | Verdict | Lowest dimension |
|---|---|---|---|
| 1, binary search | 19/20 | PASS | 3 at 1: the "left" counter label types on about 10 s before the voice says "left" |
| 2, a quarter for a ten-year-old | 19/20 | PASS | 6 at 1: the pizza rim stays whole when the slice slides out, so it cuts across the lifted slice |

Each run spent 85 to 94% of its wall time inside `render.sh` (14 of 17 minutes and 17 of 22 minutes), rendering the whole video three or four times.
