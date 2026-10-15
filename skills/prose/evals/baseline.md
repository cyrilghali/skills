# prose baseline (no skill)

Each case ran once in a fresh subagent with no skill loaded, given only the reader and the text, and was scored by a separate strict judge against `rubric.md`.

| Case | Scores (dimensions 1 to 9) | Total | Verdict | What failed |
| -- | -- | -- | -- | -- |
| 1 | 1 2 0 1 1 2 1 1 2 | 11/18 | FAIL | Rerun on the clarified input. The first run (12/18) kept the label heading, the row count, the date, the colleague's name and four label-colon paragraphs |
| 2 | 2 2 2 2 0 2 2 2 2 | 16/18 | FAIL | The "not X, just Y" reframe and an em dash survived |
| 3 | 2 2 2 2 0 2 2 0 2 | 14/18 | FAIL | Test count kept in prose; closing offer kept instead of a directed ask |
| 4 | 0 2 2 1 0 2 2 2 2 | 13/18 | FAIL | Punchline heading kept; transitions as bullets, not a table; two dangling "this" sentences |
| 5 | 2 2 2 1 2 2 1 2 2 | 16/18 | PASS | "Grace period" left undefined; "credit" and "tier" quietly redefined as a refund and a payment choice |

The baseline passes one case of five. Without the skill, the model keeps the proof trail, statement headings and label-colon fragments, and leaves reframes and closing offers in place.

The subagents ran in a session whose global instructions already ask for plain, short prose, so this baseline is likely higher than a clean install would score.
