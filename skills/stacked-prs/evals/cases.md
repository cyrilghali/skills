# stacked-prs eval cases

Each case gives a generation agent everything it needs WITHOUT asking questions.
The agent applies `SKILL.md` and returns only the artifact. A judge scores it against `rubric.md`.
The `Trap` field names the failure mode the case is designed to catch.

## Case 1: plan a stack for a sample feature

**Input:** "I'm about to build webhook notifications for our API: customers register an HTTPS endpoint per workspace, we sign each payload with a per-endpoint secret, deliver security events (user.created, alert.raised, alert.resolved) through a background job with exponential retry up to 24h, expose CRUD endpoints plus a 'send test event' endpoint, and log every delivery attempt so support can see failures. It sits behind a feature flag. Rough guess is 1,800 lines with tests. How should I stack this?"
**Context (pre-answered):** Elixir/Phoenix backend with Oban jobs and Ecto migrations. Nothing is written yet. The team tracks work in a Linear project. Don't publish anything; the user wants the plan.
**Trap:** layers cut by file type ("all migrations", "all tests") or by one purpose split in two (the signing layer only makes sense next to the delivery layer). Sizes left out. More than five layers opened at once with no milestone slice.

## Case 2: a PR too small to stack

**Input:** "How big should this PR be? It fixes a timezone bug in the weekly digest scheduler: 60 lines of code plus 110 lines of tests, one module."
**Context (pre-answered):** One branch, one commit, CI green.
**Trap:** inventing a stack or a plan table for a 170-line single-purpose change.

## Case 3: a split request that should not split

**Input:** "Split this PR please. It's 340 lines: it renames `Account` to `Workspace` across 41 files, one mechanical commit, no behaviour change."
**Context (pre-answered):** The rename was done with a codemod; CI is green; nothing else in the PR.
**Trap:** splitting one reviewer decision into several layers because it touches many files, or splitting by directory so that no layer can be judged alone.

## Case 4: a large project with a deploy-gated follow-up

**Input:** "We're moving invoice PDFs from local disk to S3. Plan: add a storage adapter interface, an S3 implementation, a backfill job that copies existing PDFs, switch reads to S3 behind a flag, switch writes, remove the disk code, then drop the `invoices.pdf_path` column once prod no longer reads it. Probably 2,600 lines total. Give me the stack plan."
**Context (pre-answered):** Two engineers will work on it, and one of them restacks. Nothing is written yet. The team uses a Linear project with milestones.
**Trap:** putting all ten-plus layers into one open stack, deferring the column drop to "later" instead of planning it as a draft layer with its wait stated, and forgetting who owns the restack.

## Case 5: add a PR to someone else's stack from a worktree

**Input:** "Add my new PR to the stack: I'm in a separate worktree on branch `exports-email`, built on top of `exports-api` (PR 812). The stack is 810 → 811 → 812, stack number 810 in the GitHub UI. PR 805 below it is in a different stack. `gh stack view` here says the branch isn't part of a stack. Go ahead and push and link it."
**Context (pre-answered):** The user authorized pushing and opening a draft PR. The new branch has 230 changed lines.
**Trap:** rebuilding the chain by hand with `--base` only, running `gh stack link` with a partial list or including PR 805, skipping the base check afterwards, or treating the HTTP 422 bottom-base warning as a failure.

## Case 6: a two-purpose feature request that never mentions stacks

**Input:** "Implement CSV export for the audit log, and add a workspace setting that purges audit entries older than N days."
**Context (pre-answered):** Elixir/Phoenix backend. Nothing is written yet. The user said nothing about PRs or stacks; the agent is about to start coding.
**Trap:** coding both features on one branch as one PR, or asking whether to stack instead of producing the layer plan before the first commit.

## Case 7: a middle layer closed without merging

**Input:** "PR 811 got closed, we're not doing that approach. The stack is 810 → 811 → 812 (stack number 810), and 812 was built on top of 811's branch `exports-csv`. 810's branch is `exports-table`. Clean up the stack so 812 sits on 810."
**Context (pre-answered):** Local gh-stack tracking exists in the user's main checkout, but the agent works from a separate worktree without it. 812 is a draft. The user authorized pushing the rebased branch and editing PRs.
**Trap:** changing 812's base to `exports-table` before rebasing (the PR diff then shows 811's code), expecting `gh stack link` to drop 811, rebasing top-down, or leaving the titles at `[3/3]`.

## Case 8: move a ready PR onto a new base

**Input:** "PR 930 (branch `alerts-silence`, ready for review, not a draft) sits on `alerts-claim`. I've restructured: it now belongs on `alerts-purge`, and I've already rebased it locally onto `origin/alerts-purge`. Push it and retarget it."
**Context (pre-answered):** No gh-stack tracking in this worktree. `alerts-claim` and `alerts-purge` differ by 40 files, several of them owned in `CODEOWNERS` by a platform team; PR 930's own files are not owned. The old head of `alerts-silence` diffed against `alerts-purge` touches only PR 930's files and the purge layer's unowned files. The user authorized the push and the base edit, not a draft toggle.
**Trap:** the default "push first, then `gh pr edit --base`" order, which diffs the new head against `alerts-claim` and requests the platform team; converting the PR to draft without asking; or retargeting without checking the in-between diff.

## Case 9: plan a stack for a frontend change

**Input:** "I'm replacing the hard-coded colors in our React app with shared design tokens: define the token set and a theme provider, migrate the 25 shared components, migrate the 4 page layouts that use them, then delete the old color constants. About 1,500 lines. How should I stack this?"
**Context (pre-answered):** TypeScript monorepo, no backend or database involved. Nothing is written yet. The team uses GitHub milestones. Don't publish anything; the user wants the plan.
**Trap:** layers cut by directory or file type, inventing storage or API layers that this change does not have, sizes left out, or deleting the old constants before every consumer is migrated.

## Trigger check

A separate agent receives the name and description of every installed skill and, for each phrase below, names the one skill it would load. Pass: every phrase maps to `stacked-prs`, except the negative control, which must map elsewhere.

"stack these changes", "stacked PR", "stacked diffs", "split this PR", "gh stack submit is failing", "restack after my amend", "rebase the stack", "add a PR to the stack", "how big should this PR be", "chain these PRs", "plan the PRs for this", "implement audit-log CSV export and a 90-day retention purge".

Negative control: "fix the off-by-one in the pagination helper" must not map to `stacked-prs`.
