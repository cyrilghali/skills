---
name: intent-pr
description: 'Write an intent-based PR: a `## Why` body of one or two short sentences that answers the product gap, with the full risk certification delivered to the author in session rather than in the PR. Use when asked for an "intent-based PR", "certify a PR", a PR that "directs the reviewer", or when a PR body should make review faster instead of dumping a diff summary.'
argument-hint: "[branch] [repo]"
metadata:
  category: ship
---

# Writing an intent-based PR

Treat the PR as the "I intend to…" moment of code (L. David Marquet, *Turn the Ship Around!*). You hold the context, so announce the intent and certify the risks yourself. The reviewer then only validates or blocks that intent instead of rebuilding the change in their head. Approval becomes almost mechanical, not because work was hidden, but because you already did the reviewer's thinking.

Produce two separate things. The certification is long-form, written in first person, and goes to the author in the session. The PR body reads like a good chat answer to "what product gap does this PR fill". Keep verification and certification out of the PR, because a full certified body is too verbose to review.

## Write one or two sentences under `## Why`

Open the body with `## Why`. Write one or two plain sentences, at most 50 words, with no subheadings: what a person sees today and why that is wrong. When the change shows on screen, carry it with a small before/after table instead of more prose. Close the Why with the ticket link. Leave implementation choices out unless a cold reviewer would question them. Aim for two sentences a teammate would type in chat: plain words, the person's situation first, no code names or jargon, as if restating it to someone who did not follow.

```markdown
## Why

When a card payment fails, a subscription can only be cancelled or retried every day forever, and [Customer] wants it paused quietly until the card is updated.

| After a failed payment | Subscription after it |
| -- | -- |
| Cancel | Ended, the customer is emailed |
| Pause | Kept but not billed, resumed when the card is updated |

[TEAM-123](https://example.com/TEAM-123)
```

Other sections, such as Stack or `## Query`, keep their own rules below.

## Add `## Query` when the PR changes a database query

Add one `## Query` section. State the query's purpose in one plain sentence, then whether the change keeps it, with the same-rows check that proves it. Below that, paste the before and the after `EXPLAIN (ANALYZE, BUFFERS)`, ids masked, each in a collapsed ` ```diff ` block: mark the costly before lines with `-` (red) and the after lines that replaced them with `+` (green).

## Add `## What the logs show` when the PR fixes a bug seen in production

Add one `## What the logs show` section. Write one sentence that links the log explorer (Datadog or the repo's equivalent) to the failures the PR fixes, with their count and window. Below it, put one real log line in a code block: timestamp, error, and the stack frame the PR changes. Before you paste the link, check its query against the tier the browser reads, filtered to the code path the PR fixes. Leave the causes the PR does not touch on the ticket.

## Add any other section only when the author asks

Keep such a section short, and climb the cut ladder below before you add it.

## Keep `## Why` visible for the gate

Some repos run a `pr-description` gate (`enforce-pr-description-format.sh`) that requires a visible `## Why`. It is the intent section, so merge any "Objectif" content into it. Never hide it in an HTML comment like `<!-- ## Why -->`: the hook blocks it, and a bypassed gate is a gate lied to. Pass the body with `--body-file`, because the hook reads the file, after the `prose` pass on the Why text.

## Write for the team

Address the human reviewers. Keep the agent-to-author process ("my implementation agent", "before handover", "my run") in the session. Drop any question that pre-review already settled.

## Follow these steps

1. **Read the diff and the linked Linear issue** (`ENG-`, `OPS-`, …). Use the ticket for motivation and links; the description is your answer, not a paste of it. If the change does not fit two short sentences and an example table, recommend splitting the PR instead of writing a longer body.
2. **Gather the missing context** with `AskUserQuestion`, one question at a time, motivation first. Stop at 2 to 3 questions, each with 2 to 4 answer options inferred from the diff. Skip a question only when the conversation or the ticket already answers it.
3. **Write the Why**, one or two short sentences of at most 50 words, then the session certification: what you checked, folded with the risk it covers, closing on the 1 to 2 things you want scrutinised. Name the actual behavior change in the Why; never fold it into "cleanup" or "refactor" framing. Report the tests you actually ran and their outcomes. If no focused test exists for the changed behavior, say so.
4. **Apply the decisive test** below, then open the PR as `--draft`. Record the run with `skill-record intent-pr gate_rejections=R`, once, only when the PR is open; a dry run or an aborted run records nothing. R is how many times the PR gate refused the body before it passed, 0 when it passed first time.

## Apply the decisive test

Check that a reviewer could approve from the Why plus the diff, without reconstructing the intent. If they would have to hunt for why the change exists, the Why failed, so rewrite it. Marquet draws the line this way: "can you look at this?" is still leader-follower, while the intent-based PR says "here is my intent, block if you see a hole."

## Climb the cut ladder before adding any section beyond the Why

Bodies accrete over their life: review deltas, stack maps, status notes. Climb the ladder before adding one, and stop at the first rung that holds.

1. **The diff already shows it.** Delete it. The body states intent; it never narrates changes.
2. **It does not change how the reviewer reads the diff.** Delete it. Status belongs in comments.
3. **A link can replace the content.** Link to the ticket, doc or other PR instead.
4. **It is a re-review delta** ("since your last review"). Keep it to three lines at most: what moved, why, and where to re-look. Give the reviewer the delta, not the work done.
5. **It is shared boilerplate** (stack map, project banner). Generate it with a script, keep it to one screen at most, and keep it identical everywhere.

Prefer deletion over addition: a body a reviewer scrolls is a body that failed.
