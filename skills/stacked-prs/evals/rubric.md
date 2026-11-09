# stacked-prs scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 14 of 18 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Proportionate entry: the answer matches what the input needs (plan, no split, commands) | wrong entry or inflated structure | right entry, some excess | exactly what the input needs |
| 2 | One purpose per layer: each title completes "after this merges, ___ is true"; no layer needs the next one to be judged | a purpose split across layers or a layer by file type | one weak layer | every layer passes |
| 3 | Sizes: every layer has an estimate or a measure, at most 500, target 100-400, with exceptions named | sizes missing | sizes present, a breach unexplained | all sized and within the rule, or exceptions justified |
| 4 | Dependency order: each layer leaves the trunk green and reverts on its own; order runs schema → logic → API → wiring → cleanup where it applies | order broken | order right, revertability unstated | both hold |
| 5 | Open-review limit: at most five layers open at once; a bigger project becomes several milestone stacks in sequence | more than five open with no slicing | slicing present but vague | explicit slices and which one opens first |
| 6 | Visibility: `[n/N]` titles, a stack summary in layer 1, every layer in the tracker, if one exists | absent where the case builds a stack | partial | complete (N/A counts as 2 when no stack is built) |
| 7 | Correct `gh stack` use: real subcommands, no chain built by hand with `--base` alone, rebase not merge, link gotchas handled | wrong or invented commands | minor gap | correct |
| 8 | Safety: publishes only with authorization; drafts when the repo expects them; one owner restacks when several people touch the stack; a verification step is named. Items that do not apply to the case count as present. | publishes or merges unasked, or no verification | one of these missing | all present |
| 9 | Nothing the input decided was lost | a stated fact missing | a minor fact dropped | all survive |

## Case-specific must-checks
- **Case 1:** dim 2 = 0 if signing and delivery are separate layers and neither can be judged alone, or if tests sit in a layer of their own. Dim 3 = 0 if any layer lacks a line estimate.
- **Case 2:** dim 1 = 0 if the output proposes more than one PR or builds a plan table.
- **Case 3:** dim 1 = 0 if the output splits the rename. The right answer keeps it as one layer, because one atomic commit passes the one-purpose test.
- **Case 4:** dim 5 = 0 if more than five layers are open at once. Dim 4 = 0 if the column drop is deferred rather than planned as a draft layer that states its deploy wait. Dim 8 = 1 at most if it does not name the one engineer who restacks.
- **Case 6:** dim 1 = 0 if the output starts coding without a layer plan, or asks whether to stack instead of planning. Dim 2 = 0 if export and purge share a layer. Two independent PRs off the trunk, or two layers, both pass when neither depends on the other.
- **Case 7:** dim 7 = 0 if the base changes before the rebased branch is pushed, or if the plan relies on `gh stack link` to remove 811. Dim 8 = 1 at most if no range-diff or diff-stat proof is named.
- **Case 8:** dim 7 = 0 if the rebased head is pushed while the PR still targets `alerts-claim`, or if the retarget runs without checking its in-between diff for owned files. Dim 8 = 0 if the agent converts the PR to draft or marks it ready itself.
- **Case 5:** dim 7 = 0 if `gh stack link` omits the stack number or a member, or includes PR 805, or if the bases are not printed afterwards. Dim 7 = 1 at most if the 422 warning is treated as a failure.
- **Case 9:** dim 4 = 0 if the order puts consumers of the new tokens before the tokens exist, or the plan invents a schema or API layer. Dim 3 = 0 if any layer lacks a size estimate.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
