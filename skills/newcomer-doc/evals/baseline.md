# newcomer-doc baseline (no skill)

Each case ran once with no skill loaded, on the same request, and one strict judge scored it against `rubric.md`.

| Case | Scores (dims 1-7) | Total | Verdict | Main gaps |
|---|---|---|---|---|
| 1 | 0 2 0 2 2 1 0 | 7/14 | FAIL | no running example; the 30% bulk-import defect of option C lost its figure; open decision not a question |
| 2 | 1 2 2 2 2 1 2 | 12/14 | PASS | generic example instead of the reader clicking; decision not a question |
| 3 | 1 1 1 2 2 2 2 | 11/14 | PASS | borderline: thin example, one term unexplained |
| 4 | 0 2 1 2 2 1 2 | 10/14 | FAIL | no single request followed from intake to payout |
| 5 | 0 1 1 2 2 0 0 | 6/14 | FAIL | no invoice followed; no decision framed as a question; figures dropped |

The baseline passes 2 of 5 cases, both short requests. It fails the three that need a running example, a weighed defect and decisions framed as questions.

The baseline runs on a host whose global instructions already ask for short sentences and plain words, so it starts above a bare model. Dimensions 4 and 5 (prose and proportion) score 2 everywhere for that reason.

The baseline ran with the host's prose hooks on, and those hooks rewrote some drafts before they were saved. The with-skill round 0 ran the same way. Rounds 1 to 3 ran with hooks off, which makes the with-skill scores slightly conservative against this baseline.

## With the skill, for comparison

Each case ran 3 times per round. A second judge scored run a of each case. Rounds 1 to 3 ran with hooks off.

| Case | Round 0 | Round 3 (final skill) |
|---|---|---|
| 1 | 12 / 12 / 12 | 12 / 14 / 12 |
| 2 | 13 / 12 / 12 | 12 / 12 / 11 |
| 3 | 10 / 11 (a dimension at 0) / 10, all FAIL | 10 FAIL / 13 / 12 |
| 4 (held out) | 13 / 13 / 12 | 13 / 12 / 13 |
| 5 (held out) | 12 / 11 / 11 | 13 / 11 / 11 |

The final skill passes 14 of 15 runs. One run of case 3 still gave the rejected alternative its own section, and both judges failed it.
