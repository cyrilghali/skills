# series-planner scoring rubric

Score the plan's outcomes, not its file names or format. A prose plan, a table or a `plan.json` with briefs can each score full marks.

Before scoring, walk the case's fact key (`fixtures/<case>.facts.md`) line by line. For each true fact, find the one unit that teaches it. For each fact marked to catch, check that the plan drops or flags it. Fill the COVERAGE line from that walk.

Each dimension is 0-2. Pass = total >= 14 of 18 AND no dimension at 0. Give one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Coverage: every true fact sits in a unit, or is dropped with a reason that is not depth (off-goal, duplicate). A fact placed in two units is scored on dimension 4, not here | 3 or more true facts missing, or any fact dropped as too deep, too detailed or too technical | 1 or 2 true facts missing | every true fact placed or dropped for a stated non-depth reason |
| 2 | Tiers run broad to deep, and each unit of the first tier stands alone | no tiers where audiences differ, or deep units come before broad ones | tiers exist but a first-tier unit leans on another unit, or one unit is in the wrong tier | broad tier first, each of its units makes sense alone, deeper tiers after |
| 3 | Prerequisites point only backward | a unit needs a later unit | a prerequisite is implied but unnamed | every prerequisite is named and comes earlier |
| 4 | No unit re-teaches what an earlier unit taught | a fact is taught in full in two or more units | one fact repeated beyond a one-clause recall | each fact taught once; later units recall at most in a clause |
| 5 | One idea per unit, stated as what the viewer (or reader) can do after it | units are topic labels only | some units have an outcome, others a topic or several ideas | every unit has one outcome sentence |
| 6 | Each unit has a brief a maker could start from: audience, tier, prerequisites, the one idea, the facts it must say with their source | no per-unit brief | briefs miss one or two of these parts | every brief has all five |
| 7 | The goal is stated as what the audience can do at the end, before the units | no goal, or a goal that names the content ("cover X") | a goal stated after the units, or for only one audience | an audience-outcome goal opens the plan and covers each audience |
| 8 | False and outdated facts are caught | a false or outdated fact is taught as true | caught but with no reason given, or only one of two caught | every one dropped or flagged as wrong, with the reason |
| 9 | Size fits the input: no unit exists without facts and an outcome of its own | padding units (intro, recap, "welcome", "summary") or a series where one unit does the job | one unit could merge into a neighbour with no loss | every unit carries facts no other unit has, and the count fits the source |

## Case-specific must-checks

- **Case 1:** dimension 1 = 0 if any engineering fact (F10 to F26) is dropped or marked optional for depth. Dimension 2 = 0 if a first-tier unit lists a prerequisite or says "after watching the previous video". Dimension 4 = 0 if a deep-dive unit re-teaches the three expense states (F04) or the match rule (F07).
- **Case 2:** dimension 9 = 0 if the plan has more than one unit and gives no reason that comes from the source (time on the job, a different audience). Dimensions 2 and 3 score 2 for a single unit that stands alone with no prerequisites.
- **Case 3:** dimension 1 = 0 if any hauler or plant fact (F14 to F25) is dropped, or placed in no unit, because residents need things simple. Dimension 2 = 0 if a resident unit requires a hauler unit.
- **Case 4:** dimension 1 = 0 if even one true fact is missing. High stakes allow no gap.
- **Case 5:** dimension 5 = 0 if units are named after code modules with no reader outcome. Dimension 8 = 0 if `RateLimiter(calls=10, period=1)` appears as the current API.
- **Case 6:** dimension 3 = 0 if a core lesson needs a quantitative lesson. Dimension 8 = 0 if "underground rivers" is taught as how groundwater moves, rather than as a misconception to correct.

## Output format (return exactly this)

```
CASE: <n>
COVERAGE: placed once _ / placed in 2+ units _ / dropped-with-reason _ / missing _ of _ true facts; caught _ of _ false or outdated
MISSING: <fact ids, or none>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
```
