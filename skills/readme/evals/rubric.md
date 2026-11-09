# readme scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 14 of 18 and no dimension at 0), and one concrete fix per dimension under 2.
Rerun at least one example command from the README against the fixture before scoring dimension 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | First screen | opens on install, badges or a feature list | question or output present but below the fold | the question, what it does, and the start of real output |
| 2 | Output is real | an output block disagrees with a rerun | matches, but trimmed with no note | every block matches a rerun; trims are marked |
| 3 | Output is read | output shown with no word on what it means | a vague sentence | two or three sentences using the output's own numbers |
| 4 | Every fact kept | a safety or behaviour fact from the old README is missing | a minor fact dropped | all survive, or the drop is named with a reason |
| 5 | Size fits the project | sections the project cannot fill (empty agent section, flags table for one flag) | one extra section | every section earns its place |
| 6 | Headings | label headings throughout | mixed | questions a reader asks |
| 7 | Reference placement | long reference inline above the example | reference below the example but unfolded when long | long reference folded in `<details>`, short reference inline |
| 8 | Public and self-explaining | private names or data remain in a public README, or two or more terms undefined | one term undefined | no private data in a public README; every term defined at first use |
| 9 | Links and claims | a dead link, a broken anchor, or a number that matches no output | a claim is loosely worded | every link resolves and every number traces to output |

## Case-specific must-checks
- **Case 2:** dimension 5 = 0 if the README has badges, a `<details>` block, or more than two headings below the title.
- **Case 3:** dimension 5 = 0 and dimension 4 = 0 if the example output or the "characters dropped" caveat changed; full marks when the README is returned unchanged or with at most one line changed and a reason; dimension 5 = 0 if the `## License` heading was rewritten as a question.
- **Case 4:** dimension 4 = 0 if any of the four safety facts is missing; dimension 2 = 0 if the dry-run output was not produced in a scratch git repository.
- **Case 5:** dimension 8 = 0 if the employer's org or repo name, or a team slug from the old README, appears.
- **Case 6:** dimension 2 = 0 if the `wrap` result shown was not produced by importing and calling it.
- **Case 7:** dimension 8 = 0 if the host, folder, team or channel names the team needs to run the tool were removed; dimension 2 = 0 if the output was not produced in a scratch folder.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
