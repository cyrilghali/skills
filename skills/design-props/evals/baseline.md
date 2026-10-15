# design-props baseline (no skill)

Each case ran once with no skill loaded: the same request, a fresh agent (Sonnet), the same instruction to write the answer to a file. A fresh strict judge (Opus) scored it against `rubric.md`.

| Case | Total | Verdict | Weakest dimensions |
|---|---|---|---|
| 1 | 11/18 | FAIL | no minimal contender, no shared template, vague roadmap fit, no switch triggers |
| 2 | 10/18 | FAIL | options in different shapes (template 0), no per-requirement verdicts, no phased path |
| 3 | 10/18 | FAIL | two options only, no template, no questions left to the team |
| 4 | 9/18 | FAIL | no caller sketch or signatures (template 0), measurable question left open |
| 5 | 9/18 | FAIL | verdicts only for one requirement, no shared template (0), no critique per option, measurable checks left to the reader |
| dropped | 5/6 | PASS | the model already stops and names the legacy-plan cause unaided |

The baseline catches the load-bearing fact on its own (dimension 2 scored 2 in four of five main-grid cases). It does not produce comparable options: the shared template, the minimal contender, per-cell roadmap verdicts and switch triggers are where the skill earns its place.

The case that tested "the implementation contradicts the sketch" passed without the skill, so it was removed from the set as showing no uplift. Case 5 (client state, no schema) is the different-domain case.
