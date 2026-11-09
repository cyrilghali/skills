# grill-me scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 10 of 12 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | One question per turn | several questions or a numbered round | one main question with side questions | exactly one question |
| 2 | Root first | a leaf detail while the root is open | a mid-level question | the question every other one hangs off |
| 3 | Options plus argued recommendation | bare open question | options or recommendation without reasoning | real options and a recommendation with its reason |
| 4 | Explores instead of asking | asks for a fact it could look up | looks some things up | every discoverable fact looked up, none asked |
| 5 | Level and state | wrong level (columns in a product grill) and no state table where the skill's conditions call for one | one of those two slips | stays at the user's level, and shows the state table when the skill's conditions call for it (no penalty when they do not) |
| 6 | Mode-specific duty | see must-checks | partial | complete |

## Case-specific must-checks
- **Case 1:** dimension 6 = 2 when nothing is published or written yet and the turn does not end the grill early; 0 when it publishes an appendix or declares the grill done.
- **Case 2:** dimension 6 = 0 if `CONTEXT.md` lacks a "Pickup hold" entry, or the entry names files, columns or functions. Dimension 6 = 1 if the entry is there but neither the 3-versus-5 loan contradiction nor the renewal-with-Reservation contradiction is raised in the turn or queued in the state table. Dimension 4 = 0 if the agent asks the user how many loans a member may hold. An ADR created in this turn caps dimension 6 at 1.
- **Case 3:** dimension 6 = 2 when the turn reads `CONTEXT.md` and the code, raises no contradiction between the plan and them, writes no glossary entry for a term that has not settled, and creates no ADR. Dimension 6 = 0 when the turn claims a contradiction between the plan and the fixture that the fixture does not contain.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_
TOTAL: _/12
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
