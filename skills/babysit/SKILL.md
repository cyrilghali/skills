---
name: babysit
description: Watch a GitHub pull request or stack through Cubic review and CI, assess each finding against the current branch, make and push only validated fixes, then prove the PR is ready or land a verified stack. Use right after opening or pushing a pull request, when a subagent or executor reports that it opened or pushed a PR, and when asked to "babysit a PR", "tag Cubic", "watch Cubic", "cubic comment", "cubic comments", "fix review comments and CI", "get it green", "check on PR X", "land the stack", or "/babysit".
metadata:
  category: ship
---

# Babysit a pull request

Keep one PR, or one named stack, moving to merge-ready: get Cubic's review, check each finding against the branch as it is now, fix only what holds up, and prove the result with CI. Maintain the branch only. Merge or land nothing, and send no review reply, unless the user asks for it in so many words. Landing has its own section in `REFERENCE.md`, and that explicit ask is the only thing that opens it.

## Pick the mode before the first poll

Say which mode runs, because each one touches a different amount of the PR:

- `drive` runs the whole loop to merge-ready ("babysit this", "get it green", "merge-ready").
- `background` triages without blocking, for a plan that is still executing.
- `threads-only` answers review comments and touches nothing else ("address the bugbot/cubic comments").
- `check` makes one status pass and reports ("check on X", "is it green"). It is read-only: the only commands it may use are `gh pr view`, `gh pr checks` and REST `gh api` reads. It never runs `scripts/cubic-review.sh`, `scripts/hide-cubic-noise.sh`, `gh api graphql` or `gh api -f`.

With no mode named, run `drive`. For a small or docs-only PR, run `check`.

Before a new mode starts, list the background jobs this session started and stop any that can write to the PR. `scripts/cubic-review.sh` is one: it tags Cubic on the PR, so a copy left running from an earlier push would tag during a `check` or `threads-only` pass.

## Record the PR state before any edit

Read `REFERENCE.md`, then run `scripts/pr-state.sh <PR>`. Write down the head SHA, the base branch, the merge state, the review threads and the failed checks. Done when the current state is captured and nothing has been edited yet.

## Map the stack before touching it

For a stack, map every PR's head and base with `gh stack log` first, or `gh pr list` when the stack predates `gh stack`. Then hold to these rules, because a stack breaks in ways a single PR cannot:

- Repair no child before its base is current, and push to no branch another agent is rebasing.
- Work only the merge frontier, the lowest unmerged PR. Batch review threads from the PRs above it, but do not fix them if that restarts the frontier's checks.
- Run one babysitter per stack. Check that nothing else is already on it.
- Change no stack topology from inside a babysit: no rebase, no retarget, no force-push. Fix on the branch that owns the problem and report anything rebase-shaped upward, for the branch owner to run.

## Get Cubic's review on the current head

Drive and background modes only; `check` and `threads-only` skip this step. Run `scripts/cubic-review.sh <PR>` in the background. It tags `@cubic-dev-ai` once per head commit when Cubic has not reviewed that head, then polls every 55 seconds for up to 30 minutes. Exit 75 means a timeout or a head that moved: report the waiting state, or rerun it for the new head.

Each run also hides the Cubic noise in the PR discussion through `scripts/hide-cubic-noise.sh <PR>`: it deletes your earlier pings and hides Cubic's "review started" replies and its comments on resolved threads as outdated, because only their author can delete them.

Rerun the script after every push that changes behaviour, queries or tests. When the post-push hook calls a push trivial (prose files only, or an `:atom` such as a feature flag renamed everywhere it appears), check CI only. A Cubic review counts only for the head it reviewed, and `gh pr ready` is refused without one on the current head. One exception: when the current head's patch matches an earlier reviewed head (same `git patch-id --stable`, as after a rebase onto the base), it keeps that head's Cubic score, and the verdict line says so. Any other new patch waits for Cubic, even when Cubic skips the head ("Automatic AI review not started"). Claim no background monitoring once the session ends, because nothing runs after it. Done when Cubic's review of the current head is in, or the user has an accurate waiting status.

## Judge each finding with evidence

1. Fetch the inline comments and review bodies with `gh api` and group them by root cause. When a finding claims something about runtime behaviour (contract-test drift, what a query returns, what a function does with an input), run the test or command before dismissing it. A red run confirms the finding. A green run is the proof for the dismissal reply. Done when every finding is marked valid, invalid, or needs a product decision, each with its evidence.
2. For each valid P1 or P2, trace the production path, inspect the recent commits, and add one focused failing test before the fix. Done when the regression reproduces.
3. Treat a P3 as an improvement. Take it when it protects the changed contract or removes real waste; otherwise say why it is deferred. Done when the scope is explicit.
4. Once each finding is pushed or deferred, write its reply: the fix's commit SHA, or the concrete reason it stays. Hand the drafts to a fresh subagent that rewrites each one by `REPLY-VOICE.md`, then send each with `scripts/draft-reply.sh <PR> <review-thread node id (PRRT_…), not the REST comment id> "<reply>"`. Answer bot threads before drafting any human reply, because the script refuses to post while you hold a pending review. A bot's thread gets its reply posted and the thread resolved. A person's thread gets its reply in your pending review, unsent, and stays open for its author. Done when every fixed or addressed bot thread is answered and resolved, and every human thread has a pending reply.

## Fix and push one root cause at a time

1. Make one root-cause fix per change. Keep the PR's intended scope and move cross-cutting work to the integration branch. Done when the focused regression test passes.
2. Run the repository's own formatter, stage its output, then run the focused tests and the relevant quality command. Done when the local changes are formatted and verified.
3. Inspect `git diff`, `git status` and the branch's upstream before committing. Write an imperative Conventional Commit message and push only the intended branch. Done when the GitHub head SHA has changed and contains the fix.

## Clear CI and prove the PR is ready

1. Run `scripts/pr-state.sh <PR>` after the push. Read the failed-job logs before changing any code, and tell a code failure from an infrastructure retry. Done when each red check has a recorded cause.
2. Fix each reproducible code failure with a regression test. Rerun the focused tests locally, push, then wait for CI again. Done when the same failure no longer occurs.
3. When CI is green, fetch the reviews and merge state again. Apply one readiness rule in every mode, `check` included: the head needs its own Cubic review or a matching patch-id with an earlier reviewed head (say which in the verdict line), and an unanswered bot thread blocks readiness while a human's thread waits for its author. Report the PR URL, base and head, resolved findings, checks, remaining conflicts, and whether it is ready for human review. Take each PR's Linear review deep link from `scripts/linear-review-link.sh <PR number or URL>`; never guess the slug. Done when readiness rests on that evidence. Record the run with `skill-record babysit cubic_findings=C fixed=F minutes_to_green=M`, once, only when the run finished; a dry run or an aborted run records nothing. C is the number of findings fetched in the judging step, and F is how many of them were pushed. M runs from the first `pr-state.sh` call to green CI; leave it out in `check` or `threads-only` mode.

## Expect a run to look like this

`/babysit #22099` first records the review and CI state, fixes only the Cubic findings confirmed on the current head, pushes the formatted commit, and ends with the GitHub URL and the exact remaining blockers.
