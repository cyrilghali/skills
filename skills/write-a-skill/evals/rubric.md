# write-a-skill scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail, one concrete fix per dimension under 2. The total is over the scored dimensions (2 points each, 18 when none is N/A); pass = at least 7/9 of that (14 of 18) and no scored dimension at 0.
Score 0 on every dimension if a new folder was written for an edit or for no artifact. Edits follow the route in SKILL.md: a direct edit (one bullet or one tightened sentence) marks dimensions 2 to 7 N/A, like the no-artifact case. An edit that runs the full process (a new section, a new table or more than about 10 lines) always scores dimensions 2 to 4 and scores dimensions 5 to 7 only on the lines the edit touches, marking them N/A when it touches none: dimension 2: evals updated or run before the edit, held-out cases run and a fresh leak audit done after the edit; dimension 3: trigger queries re-run, held-out ones included; dimension 4: baseline compared with the edited skill. When no artifact is the right action, mark dimensions 2 to 7 N/A.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Right action: new skill, edit of an existing one, one-line edit, or no artifact | wrong action | right action, wrong size | right action at the right size |
| 2 | Evals written before SKILL.md (compare modification times) | no evals, or written after | evals present, order unclear | five cases with traps and a rubric, all older than SKILL.md |
| 3 | Trigger queries | none | fewer than twenty, or no near misses | twenty, half near misses, eight held out |
| 4 | Baseline without the skill | not mentioned | planned, not run | run once per case, scores noted |
| 5 | Description | imperative, or no trigger phrases | third person but vague phrases | third person, capability then "Use when" with phrases a user types |
| 6 | SKILL.md shape | over 100 lines or no completion criteria | some steps lack a check | every step ends on a check; deterministic work sits in scripts; the validator passes |
| 7 | Self-sufficient | a home path, user name or personal tool hard-coded | one leak | none; a private tool is an optional environment variable documented in INSTALL.md |
| 8 | Report to the user | none | partial | folder tree, what ran with its result, description cost |
| 9 | Nothing the input decided was lost | a stated rule or constraint missing | a minor one dropped | all survive |

## Case-specific must-checks
Scoring branches: Case 3, 5: no-artifact scoring; Case 2: direct-edit scoring; Case 6: direct-edit scoring when the diff is one bullet or sentence, full-process edit scoring above that; Case 7, 8: full-process edit scoring; Case 1, 4: new-skill scoring.
- **Case 1:** dimension 2 = 0 if any evals file is newer than SKILL.md. Dimension 9 = 0 if any of the three corrections is missing.
- **Case 2:** dimension 1 = 0 if a new folder or new evals were written; 2 only for a diff of one bullet or one tightened sentence.
- **Case 3:** dimension 1 = 2 only when no artifact is produced and the reply says the evidence is a single instance.
- **Case 4:** dimension 7 = 0 if `pgq` is invoked directly anywhere outside INSTALL.md without an environment-variable fallback. Dimension 6 = 0 if the growth query lives only in prose.
- **Case 5:** dimension 1 = 0 if a new skill folder was written; 2 when the reply names the installed warm-build skill and says what, if anything, it would add to it.
- **Case 6:** dimension 1 = 0 if the fix goes to memory only, or the reply says the skill cannot be edited; 2 when the existing skill's reference file gets the working queries and the skill is re-run or a re-run is stated as the next check.
- **Case 7:** dimension 1 = 0 if a new skill duplicates the installed PR-description or cold-read skill; 2 when the reply states which job "this" means and extends an existing skill. Dimension 9 = 0 if a rule depends on the conversation ("shorter", "3/4") or keeps an empty claim such as "tests added".
- **Case 8:** dimension 1 = 0 if the change swaps one case-specific example for another or counts the earlier passes as proof; 2 when it replaces case-restating lines with general rules, names the passes that were overstated, and tests on held-out cases the edit never saw.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_ (N/A allowed)
TOTAL: _/<max>
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
