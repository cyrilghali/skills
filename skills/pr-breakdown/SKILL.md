---
name: pr-breakdown
description: Writes an ownership briefing for a pull request a model wrote, so its owner can defend every design decision and implementation choice without opening the diff - who made each decision (the owner or the model), the option not taken, whether it was checked, every part of the diff traced to a decision, what was left out, the worst case, and the reviewer's likely questions with answers ready. Reads the diff, the review threads, the ticket and the session transcript that built the PR. Plain words, no technical detail. Use when asked to "break down this PR", "PR breakdown", "what did the model decide in this PR", "help me own this PR", "can I defend this PR", or before answering a reviewer on a PR a model wrote.
metadata:
  category: ship
---

# Breaking down a model-written PR

Hand the owner every decision in the PR up front, with who made it. Without this, the owner meets the decisions one line at a time, usually when a reviewer asks "why?". Work in decisions, not files. The decisions the owner made are already theirs. The ones the model made alone, and the questions nobody answered, are what the briefing exists for.

## Gather the sources

1. **Read the PR**: title, body, diff, review threads, and the linked ticket.
2. **Read the conversation that built it.** Run `scripts/sessions.sh list <pr-url>`, then `scripts/sessions.sh dump <session>` on each session marked `built`. Subagent transcripts sit in a `subagents/` folder beside the session file. When a piece of the diff has no trace in the main conversation, read the brief of the subagent that wrote the code.
3. **Read code at the PR's version** with `git show <ref>:<path>` or `git grep <ref>`. Leave the owner's working tree untouched, because a checkout, restore or stash there can destroy uncommitted work.

Done when every source is read or named as missing. With no session found, write "unknown, no session found" for every "who decided", never a guess.

## List the decisions

Walk the dump in time order. Give each choice the first provenance that fits:

- **you**: the owner stated it before the model did
- **you picked the model's option**: the owner accepted a proposal, in a message or a question-prompt answer; quote it
- **model, told you**: the model announced it and the owner neither accepted nor objected
- **model, left open**: the model asked, and no answer followed
- **model, not shown to you**: the choice is in the diff or a subagent brief and nowhere in the conversation

Let the owner's latest word on a decision win, because a later message can reverse an earlier answer. Search the whole dump for each decision before calling it "not shown". Take provenance only from this PR's sessions, threads and ticket, dated before the PR merged; a rule or note written afterwards decided nothing. Count as a decision only a choice that changes what the PR does. Leave out choices about commits, titles and the description, because they are process. Record each decision with the option not taken, including the obvious one the model never offered.

Done when every owner message and answer that states, accepts or rejects something maps to a row.

## Check every claim

Treat a claim from the conversation, the PR body or a review reply as a premise until the code, a test, or data confirms it. Mark each row `tested`, `checked in code`, `prod data`, or `reasoned only`. Cite a source only after finding the claim in that exact source. Copy numbers from it with their exact meaning: a duration names what started and stopped the clock. Cite a ticket, test or follow-up with its id only after checking it exists and what state it is in today. Check what happened after the PR too: a linked ticket closed, a later PR that changed the picture. Drop a claim the sources contradict, and name it in one line with what is true instead.

Done when no row rests on the model's word alone.

## Trace the diff

Split the diff into the pieces a reader sees: a new step, a new job, a changed rule, a changed number, a changed text. Map each piece to a decision. A piece that maps to nothing stated is an **orphan**: bold it.

Done when every piece maps to a decision or is marked as an orphan.

## Probe what a reviewer will probe

Write the worst case, and each left-out item, with its class (works as designed, rare edge case, gap, bug), how it recovers, and whether a test covers it. Give the volume: when `$PR_BREAKDOWN_SQL` is set, count the affected rows with a read-only query; otherwise give the bound the code implies and mark it reasoned. Define every domain word a cold reviewer would stop on. Then write the reviewer questions: first every question a reviewer actually asked on the PR, then the ones the categories in [REFERENCE.md](REFERENCE.md) predict. Make each answer what the owner says to the reviewer, current as of today.

Done when each question has an answer the sources support.

## Write it in plain words

Use the template in [REFERENCE.md](REFERENCE.md). Describe behavior, not code. Name every part by what it does ("the nightly step that emails a reminder for each overdue invoice"), never by its name in the code, file, commit or an internal label; the diff-trace table follows the same rule. Keep a technical choice only when it changes behavior, data, or the cost of reversing it. Collapse review and fix rounds into one line. Sort decisions most costly to reverse first.

Let the length follow the decisions. Write one table row or bullet as one sentence. Give a PR carrying one or two decisions the example and the decisions table only, under 20 lines. Keep every other section only when it holds something a reviewer would ask about; drop the rest, header included.

Save the draft to a scratch file, run `scripts/plain-check.sh <draft.md>`, and rewrite every line it prints.

Done when the check exits 0 and a reader who never opened the diff could answer every reviewer question in the last section.

## Have it checked cold

Hand the draft, the PR link and the session paths to a fresh reviewer: a subagent when the host has one, otherwise a second pass of your own after a pause. Give it one job: check every "who decided" against the dump, every number and ticket against its source, and the diff for pieces the trace table missed. Apply what it confirms.

Done when the reviewer finds nothing false.

## Deliver in the conversation

Give the breakdown to the owner in the conversation. Post it on the PR only when the owner asks. Record the run with `skill-record pr-breakdown decisions=D claims_checked=C claims_dropped=X`, once, only when the breakdown was delivered; a dry run or an aborted run records nothing. D is the number of decision rows, C the claims marked in "Check every claim", X the claims dropped as contradicted.

## Follow this example

A decisions row from a breakdown of a PR that splits a reward into a payment on claim and a bonus on a confirmed fix:

| Decision | Option not taken | Who decided | Checked? |
|---|---|---|---|
| Only a claimed case earns the bonus: someone who fixes without clicking "I fixed it" gets nothing extra | Pay every case a scan confirms as fixed | model, not shown to you | Tested |

and a diff row for an orphan:

| Part of the diff | Traces to |
|---|---|
| The payment gives up after 10 tries, about 20 minutes | **Nothing stated.** The model picked the number. |
