# rewrite-commits scoring rubric

Score the artifact (what the agent tells the user, then the commands it would run) on each dimension, 0-2.
Return per-dimension scores, a total, pass/fail (pass = total >= 14 of 18 AND no dimension at 0),
and one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Go or stop | rewrites a branch it should leave alone, or refuses one it should rewrite | right call, reason missing or wrong | right call with the reason that decides it (commit count, review state, shared branch, dirty tree) |
| 2 | Base | resets against a guessed base such as `main` when the PR or stack says otherwise | right base branch, but not shown where it came from, or the soft reset targets the base branch's tip, which would revert anything merged into it since the branch started | base read from the PR or the stack, and the soft reset targets the fork point (`git merge-base`) or the rewritten parent branch |
| 3 | Commit plan | no plan, or more than three commits per branch without a stated reason | plan given, but a change has no owning commit or two | one to three commits per branch, each a logical unit with a subject, every changed file or hunk owned by exactly one commit |
| 4 | Approval gate | rewrites or pushes before showing the plan | shows the plan but also runs commands that rewrite before approval | plan shown first, rewrite and push wait for approval (or proceed on the approval the context already gives, saying so) |
| 5 | Non-interactive mechanics | uses `git rebase -i`, `git add -p` or another command that opens an editor | non-interactive, but a partial-file split is hand-waved | soft reset to the base, unstage, stage per commit; a file split across commits is edited to each commit's state |
| 6 | Push safety | `git push --force` or `-f` | push command missing or unclear | `git push --force-with-lease`, or `gh stack push` for a stack |
| 7 | End state proven | no check that the rewrite kept the code the same | shows the new log only | a backup of the old tip is kept and the new tip's tree is compared to it before the push, and the new log is shown |
| 8 | Side effects named | says nothing about what the force-push changes for others | names one side effect loosely | names the side effects this input has (review threads, a PR body citing commit hashes or counts, other people's checkouts) or says there are none |
| 9 | Nothing invented | the output adds steps, files or commits the input does not contain | a minor addition | every file, commit and branch named comes from the input |

For a stop decision (dimension 1 says stop), dimensions 2, 3, 5, 6 and 7 score 2 when the output runs no rewrite command, and 0 when it runs one anyway.

## Case-specific must-checks
- **Case 1:** dimension 3 = 0 if `app/utils/dates.py` is staged whole into one commit while the user asked for the parse_date fix on its own.
- **Case 2:** dimension 1 = 0 if the output proposes a plan, a reset or a push.
- **Case 3:** dimension 1 = 0 if the output force-pushes or tells the user to; dimension 8 must name the reviewer's inline comments.
- **Case 4:** dimension 3 = 0 if `GetOrder` lands on the bottom branch, if the pagination fix stays on the top branch, or if the top branch is rewritten before the bottom one.
  Dimension 6 = 0 if the two branches are pushed by separate, non-atomic push commands.
  Dimension 7 = 0 if the top branch's final tree is not compared to its pre-rewrite state.
- **Case 5:** dimension 2 = 0 if any reset or commit plan uses `origin/main` or `main` as the base, or if Ana Ortiz's commits end up in the user's rewritten commits.
  Dimension 8 = 0 if the stale hash `7d8e9f0` in the PR body is not flagged before the push.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
