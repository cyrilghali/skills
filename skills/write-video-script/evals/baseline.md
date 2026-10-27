# write-video-script baseline

Each case ran once on a fresh Sonnet subagent with no skill loaded. It had the case's Input as a plain request and a scratch folder holding only the fixture files, renamed to neutral names (`caseN/`, `brief.md`, `source.md`). A fresh Opus judge then scored each folder and the agent's final reply against `rubric.md`. Pass is 18 of 22 with no dimension at 0. Run on 27/10/2026, before SKILL.md existed.

The generators still inherit the machine owner's global instructions and memory. Some of those lines are about explainer videos and plain prose, and no run method strips them. No output showed signs of a loaded skill (no animation plan, claims file or second-read file).

## No skill

| Case | Total | Verdict | Lowest dimensions | Output |
|---|---|---|---|---|
| 1, a brief fact its source contradicts | 16/22 | FAIL | 5 at 0 (a six-sentence beat, a beat with two points); 4, 6, 8, 11 at 1 | `outputs/case1` |
| 2, a deep dive on known basics | 17/22 | FAIL | 4, 5, 7, 9, 11 at 1 (re-teaches clonal growth in two sentences; 216 words against about 300) | `outputs/case2` |
| 3, jargon source, lay audience | 18/22 | PASS | 2, 5, 6, 11 at 1 ("doubled in a few hours" unsourced; "crumb" undefined) | `outputs/case3` |
| 4, a 30-second ask | 19/22 | PASS | 4, 8, 11 at 1 (a recap beat; labels the narration does not say) | `outputs/case4` |
| 5, no brief (held out) | 14/22 | FAIL | 8 at 0 (no on-screen words); 1, 4, 5, 6, 10, 11 at 1 | `outputs/case5` |
| 6, a shorter remake (held out) | 14/22 | FAIL | 6 at 0 ("the stacks", "Dewey Decimal", "withdraw" undefined); 1, 4, 5, 8, 10, 11 at 1 (one hold rule lost its conditions; "000 to 999" in digits) | `outputs/case6` |

Two of six pass. Since that is under the four-of-six bar set before the run, the cases were kept as they are.

`outputs/caseN` means `video-script-baseline/outputs/caseN` in the build's evidence folder, outside this repo. The judges' verdicts sit beside it as `judge-caseN.txt`.

## What the baseline already gets right

- **Source conflicts:** it reports them unprompted. Case 1 said twelve and told the user the brief's twenty was wrong. Case 5 kept the figurehead as a legend.
- **Short asks:** it does not pad them. Case 4 ran 65 words.
- **Brief facts:** it keeps every one, and adds almost nothing unsourced.

## Where it fails

These gaps recur across cases:

- **The hand-over:** in all six cases, `beats.json` is an object with extra fields, not a list of `id` and `text`.
- **Beats:** they hold three to six sentences or several points (cases 1, 2, 3, 5 and 6).
- **One concrete example:** a generic "job", "germ" or "book" stands in for one specific example followed through the story (cases 1, 2, 4, 5 and 6).
- **On-screen words:** they are missing, hold symbols, or use words the narration never says (cases 1, 4, 5 and 6).
- **Terms:** words this audience does not know go undefined ("discarded", "crumb", "harbour pilot", "the stacks").
- **Numbers:** they are left as digits in the narration (cases 5 and 6).

The traps in cases 1, 4 and 5 showed no uplift room on their own target dimension (3 for cases 1 and 5, 9 for case 4). Those cases still fail or nearly pass on the shared gaps above. If the with-skill runs score them at full marks, replace them with harder ones.

## Rubric change after this run

The case 3 judge scored the labels inside picture descriptions as on-screen words. The rubric now defines on-screen words so a second judge reads that line the same way. No score was changed.
