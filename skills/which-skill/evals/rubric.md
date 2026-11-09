# which-skill scoring rubric

Each dimension is 0-2. Pass = total >= 11 of 14 AND no dimension at 0.
The judge may run `scripts/list-skills.sh` from the skill folder to check names and counts.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Right branch (reminder / match / inventory) | wrong branch | right branch, extra work from another | exactly one branch |
| 2 | Right skill, or honest "none fits" | wrong skill or forced match | defensible but not the best | best available |
| 3 | Every name exists in the scan or shortlist | an invented or misspelled name | — | all real |
| 4 | Answer shape: one-line what + call line for Claude and Codex; manual flag when manual | shape absent | partly | complete (inventory: names grouped, manual marked) |
| 5 | Scope: one answer, or the full inventory only when asked | dumps unrelated material | slight excess | tight |
| 6 | Grounded: the pick matches what the skill's own description says | contradicts it | vague | matches |
| 7 | Nothing the user needed is missing | the key fact missing | a minor omission | complete |

## Case-specific must-checks
- **Case 1:** dim 2 = 0 unless the answer is intent-pr.
- **Case 2:** dim 5 = 0 if the output adds skills or sections absent from SHORTLIST.md.
- **Case 3:** dim 2 = 0 if a skill is presented as able to book tickets; dim 7 = 0 without a "none fits" statement.
- **Case 4:** dim 7 = 0 if more than 3 scan names are missing from the output; dim 4 = 0 if the groups are not the scan's category column or a skill appears under two categories.
- **Case 5:** dim 2 = 0 unless check-pr-comments is the answer (babysit may be named as the second line).

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_
TOTAL: _/14
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
