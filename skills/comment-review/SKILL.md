---
name: comment-review
description: Reviews every added or changed comment in a diff, file, or directory (docstrings, @moduledoc/@doc, JSDoc, TODOs) for accuracy, value, and rot, plus stale comments the change left false elsewhere in the repo. Language-agnostic. Use when asked to "review comments", "comment review", "are these comments useful", "check for stale comments", "comment rot", or before finalizing a PR that adds or edits comments.
metadata:
  category: verify
---

# Review the comments in a change

Read each comment the way a skeptical maintainer reads it months later. Ask two things: does the claim still hold, and would a competent reader have needed it written down at all. Report what fails, with a fix, to the person who asked for the review.

## Pick the comments to review

- With no path given, review the diff: `git diff` against the merge base, or the PR's diff. Take every comment line the diff adds or changes, plus any comment shown as context in the same hunk. A comment next to the change counts when it is already wrong, whether or not this diff broke it.
- With a file or directory, review every comment in it.
- For a diff, also look outside it. Grep the repo for every function, field and type name the diff renamed, removed or changed the behavior of. A comment elsewhere that references one of them is data to verify, not scope creep.

## Run each comment through all seven checks

One comment often fails more than one check. Report every class that applies, in this priority order, not only the first one found.

1. **Accuracy.** Check that every claim matches the code as it is now: signatures, behavior, referenced names exist, edge cases handled, complexity claims true. A comment fails this even if it was true when written. Check only the claims the given code can prove or disprove, and report an accuracy finding only when the shown code proves the claim false. A claim the shown code cannot settle is not a finding.
2. **Unguessable-only.** Keep a comment only when a competent reader could not guess it from the signature and body alone. Delete one that restates the code, narrates the diff or lists what the lines below do. Keep a provider's undocumented behavior, a magic number's origin, or anything that would look like a mistake without the one line explaining it. Name the specific fact that earns each kept comment its place, because "kept" with no reason is a skipped check, not a passed one.
3. **Problem-first.** A comment that justifies an exception, deviation or asymmetry must name the problem before the fix: name the counterpart it differs from and why ("unlike X, which needs *reason*"). Name the items, never a count ("all three metrics"). A rewrite that swaps one unexplained verdict for another still fails; it must state the mechanism. When the shown code proves the mechanism, state it as fact.
4. **Contract, not discussion.** Reject chat-derived rationale: "we chose X over Y", "as discussed", a name, a meeting, or a ticket used as the only justification. That belongs in the commit or PR body. The comment states the neutral contract and invariant the discussion produced.
5. **Rot markers.** Flag a TODO or FIXME already resolved in the code, a reference to code that no longer exists, a "temporary" or "for now" state with no expiry, and a ticket number with no context a reader can use. A ticket number alone is not rot.
6. **Missing comment.** Flag a missing comment only where a reader would plausibly mistake intended behavior for a bug. Leave ordinary uncommented code alone, because this class catches silent traps and never pads the report.
7. **Brevity.** A kept comment carries one fact in as few lines as that fact needs. Flag it only when it carries more than one fact or has lines that restate the code, and give the shorter rewrite that keeps only the unguessable fact. A multi-line comment that carries one fact passes, and so do generated API docs whose param or return lines each carry a fact a caller needs.

Hold every kept or rewritten comment to this style: no em dashes, one line preferred.

## Write the report

Give each finding its real `file:line`. Compute it from the diff's hunk header when the input does not spell it out: `@@ -a,b +c,d @@` means the new file's shown lines start at `c`. Fall back to a stable text anchor, the comment's nearest function or symbol name, only when neither a hunk header nor a line number is available. Never invent a placeholder like `:1`.

After the location, give the class or classes from the list above, then either a concrete one-line rewrite or `delete`. A rewrite must satisfy the class it fixes, not only remove the bad part. When you cannot state the missing technical reason from what you were given, say so plainly instead of shipping a rewrite that only removes the offending wording.

Group findings by file, in the priority order above within each file, one entry per comment even when it hits several classes. Make the findings count you state equal the count you listed. End with:

- A **Kept as-is** count (comments checked and left alone), so "no findings" reads as reviewed, not skipped.
- A **Sources** section (see below).

When nothing in scope has a problem, say so plainly. Never invent findings to fill the report. Record the run with `skill-record comment-review comments_reviewed=N flagged=F`, once, only when the run finished; a dry run or an aborted run records nothing. F is the findings count the report states. N is that count plus the Kept as-is count.

## Calibrate on these two examples

TypeScript, before: `// increments the counter by one` above `count += 1;`. Verdict: delete (unguessable-only: restates the code).

Elixir, before: `# retry because sometimes it fails` above a retry block calling a payment provider, where the input includes the provider's docs saying a 200 can precede settlement. Verdict: rewrite to `# a 200 can precede settlement; retry confirms the charge landed` (problem-first: names the mechanism the input supplies). Without that input, say the reason is missing and ask the author what failure the retry covers.

`REFERENCE.md` has the full worked examples in both languages.

## Sources

Put this exact text in your report's Sources section, unchanged. Add no license claim and guess nothing about the credited project.

> Checks 1, 2, and 5 (accuracy, unguessable-only, rot markers) adapt Anthropic's `pr-review-toolkit` `comment-analyzer` agent (https://github.com/anthropics/claude-code/tree/main/plugins/pr-review-toolkit). Checks 3 and 4 (problem-first, contract-not-discussion) are original to this skill.
