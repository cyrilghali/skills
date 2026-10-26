# explainer-script baseline

Each run is a fresh Sonnet agent with the case's fixtures in an empty folder, judged by a fresh strict judge against `rubric.md` on the files alone (not the agent's report). One run per case.

## No skill

| Case | Total | Verdict | Lowest dimensions |
|---|---|---|---|
| 1, a tiny request | 11/18 | FAIL | 6 (no claims.json) 0, 7 (no second read) 0; 1, 2, 4 at 1 (grid, then pizza, then stickers) |
| 2, written from inside a project | 10/18 | FAIL | 3 ("jitter" spoken before it is explained) 0, 6 and 7 at 0 |
| 3, a fact-check trap | — | FAIL | from the earlier combined skill's planning-stage run: beats said 12, but no claims.json, so the must-check fails |
| 4, a remake | — | FAIL | from the earlier combined skill's planning-stage run: no remake.md; 6 caption facts left out and listed only in notes |
| 5, a myth in the request | — | FAIL | from the earlier combined skill's planning-stage run: myth corrected, but no claims.json, sources not opened, no second read |

Cases 3 to 5 carry over the no-skill runs made when this content lived in the video skill; their fixtures were rebuilt for this skill and the runs were not repeated.

## With the skill, round 1

| Case | Total | Verdict | Lowest dimensions |
|---|---|---|---|
| 1, a tiny request | 18/18 | PASS | none (a second judge also gave 18/18) |
| 2, written from inside a project | 15/18 | PASS | 1, 2, 3 at 1 (switches to a hundred jobs for the jitter; a four-sentence beat; "discarded" explained one beat late) |
| 3, a fact-check trap | 17/18 | PASS | 2 at 1 (a six-sentence hook); says twelve, names the old twenty to the user (a second judge also gave 17/18) |
| 4, a remake | 15/18 | FAIL | 6 at 0: remake.md marks "by the front door" as kept while only the picture note carries it |
| 5, a myth in the request | 17/18 | PASS | 2 at 1 (a four-sentence beat); myth corrected and named, NASA and ESA sources opened, blind second read recorded |

## With the skill, round 2

Two changes: step 2 now ends on "one or two sentences" per beat, and a remake row counts as kept or moved only when the new narration itself states the claim. A fresh leak audit then flagged one line in step 2 that echoed case 1 ("a 20-second ask"); it was rewritten in general terms and case 1 was re-run on that text.

| Case | Total | Verdict | Lowest dimensions |
|---|---|---|---|
| 1, a tiny request | 18/18 | PASS | none |
| 2, written from inside a project | 16/18 | PASS | 2 at 1 (three-sentence beats), 3 at 1 (`max_attempts` read aloud) |
| 3, a fact-check trap | 17/18 | PASS | 2 at 1 (three- and four-sentence beats) |
| 4, a remake | 16/18 | FAIL | 6 at 0: remake.md marks the fiction-shelving row as kept while the beat dropped "alphabetically" |
| 5, a myth in the request | 17/18 | PASS | 2 at 1 (three-sentence beats) |

Every with-skill run in both rounds wrote claims.json and second-read.json, and `claims.py --final` passed on all of them. Every case beats its baseline.

Still open: the sentence-count line did not move dimension 2, and the remake audit still lets a reworded claim count as kept (case 4). Each case ran once per round, not three times, and the second judge overlapped on cases 1 and 3 of round 1 only.
