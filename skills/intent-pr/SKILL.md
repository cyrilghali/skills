---
name: intent-pr
description: Writes an intent-based pull request description, a `## Why` of one to three short paragraphs on the product gap the PR fills, and gives the author a first-person risk certification in the reply instead of the PR. Recommends a split when a branch mixes purposes. Use when asked to "write the PR description", "draft the PR body", "open a PR with a proper description", "write an intent-based PR", "certify this PR", or a PR that "directs the reviewer" or makes review faster than a diff summary. Not for commit messages, release notes, reviewing someone else's PR, replying to review comments, or listing what a diff could break.
metadata:
  category: ship
---

# Intent-based PR description

A pull request is the "I intend to..." moment of code (L. David Marquet, *Turn the Ship Around!*). The author holds the context, states the intent and certifies the risks. The reviewer then validates or blocks the intent instead of rebuilding it from the diff.

The skill produces two outputs for two readers:

| Output | Reader | Holds |
|---|---|---|
| PR body | the reviewers | the product gap and the intent, in a few short paragraphs |
| Certification | the author, in the reply | what was checked, the risk each check covers, where to look hardest |

The body stays short enough to read like a good chat answer to "what gap does this PR fill?".

## Process

1. **Read the diff and the linked ticket.** The ticket gives motivation and the link; the body is your own answer, never a paste of it. Done when you can say the PR's purpose in one sentence. When you need two sentences joined by "and also", the branch mixes purposes: recommend a split, one PR per purpose, each named in one line, and write no body.
2. **Fill gaps by asking.** Ask the author one question at a time, motivation first, at most three, each with two to four likely answers drawn from the diff. Skip a question the conversation or ticket already answers. Done when you know why the change exists and what the author checked.
3. **Write the Why** (format below). Done when it passes the decisive test.
4. **Write the certification** in the reply (format below).
5. **Add a section only when one applies.** A database query change or a production bug fix each gets one section; see [SECTIONS.md](SECTIONS.md). Any other section waits for the author to ask, and then climbs the cut ladder in the same file first.
6. **Hand over.** When asked to open the PR, open it as a draft and pass the body with `--body-file`. In a repo that checks PR bodies, keep `## Why` as a visible heading. If a `prose` skill is installed, run the Why through it first.

## The Why

The body opens with `## Why`: one to three short plain paragraphs, no subheadings. Together they answer three questions:

- **What happens today, and what is missing?** Link the ticket here.
- **What does the PR add?** Describe the behavior a person meets, in words a product manager would use. Code names stay in the diff: no file, function, table, column or flag.
- **Does anyone see a change yet?** Say what users see after merge, or which later PR makes it visible.

Points can share a paragraph, and each point appears once. Each paragraph is a few sentences, never one crammed line. Numbers and checks that prove the change safe belong in the certification; the body keeps the decision they support.

```markdown
## Why

A support ticket that waits on the customer stays open until an agent closes it by hand. Agents spend the first hour of each shift on that cleanup ([HELP-310](https://example.com/HELP-310)).

This PR closes a ticket on its own after 14 days with no customer reply, and sends the customer a note that any reply reopens it. Tickets with an open refund are never closed this way.

Nobody sees a change at merge: the rule ships switched off, and the next PR turns it on for one team.
```

A real change in behavior is named as one. "Cleanup" or "refactor" framing never hides it. A change that is honestly risk-free says so in one plain sentence; it gains no invented danger and no filler.

The readers are the reviewers. Talk between the author and their tools ("my agent", "before handover") and questions already settled stay out of the body.

## The certification

The reply to the author, in the first person, as the one who vouches for the work:

- One line per check: what I checked, folded with the risk it covers. "I ran the closing rule over last month's tickets and none with an open refund closed, so refunds stay safe."
- The tests that ran and their result. When no test covers the changed behavior, say so.
- What I did not check, plainly.
- Last, the one or two places a reviewer should look hardest, and why.

## The decisive test

Could a reviewer approve from the Why plus the diff, without rebuilding the intent? If they would hunt for why the change exists, rewrite the Why. "Can you look at this?" asks for permission; an intent-based PR says "here is my intent, block it if you see a hole."
