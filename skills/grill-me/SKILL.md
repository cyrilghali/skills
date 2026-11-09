---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree one question at a time, then publish the decisions as an appendix document in the project (Linear). With `--docs`, also challenges the plan against the project's domain language and keeps CONTEXT.md and ADRs current as terms and decisions settle. Use when the user wants to stress-test a plan, get grilled on their design, mentions "grill me", or wants the plan checked against the project's language, glossary, CONTEXT.md or ADRs.
metadata:
  category: plan
---

# Grill me

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

## How does the grill run?

- Ask the questions **one at a time**, root of the tree first: answer each before the next, and pick the next question from what the last answer unlocked.
- Every question comes with the real options and **your recommendation, argued**, never a bare open question.
- If a question can be answered by exploring the codebase, the database, or the project's existing documents, **explore instead of asking**, and verify a claim there before asserting it in a question.
- Keep a **state table** of the grill (question / status). Reshow it whenever the user asks where we are, answers out of order, or the thread tangles.
- Stay at the level the user set (product vs technical). If the grill drifts into enums, columns, or module names during a product grill, pull back and park the point for the technical pass.
- When the user's answer reverses one of their earlier decisions, say so and re-pose the affected question cleanly instead of silently stacking both.
- The grill is done when every branch of the tree is visited and nothing is left silently assumed.

## What does `--docs` add?

When invoked with `--docs`, or when the user asks to check the plan against the project's language, glossary, `CONTEXT.md` or ADRs, run the same one-at-a-time grill and call the Skill tool with `domain-modeling`, then follow it for the whole session. If that skill is not installed, apply its core in place:

- Read `CONTEXT.md` (or `CONTEXT-MAP.md` and each context's `CONTEXT.md`) and `docs/adr/` before the first question.
- Challenge any term that conflicts with the glossary, and propose one canonical term for any fuzzy one; each becomes a question with your recommendation.
- Check the user's claims about how the system works against the code, and surface contradictions as questions.
- Write each resolved term into `CONTEXT.md` the moment it settles (a glossary only, no implementation detail), creating the file lazily.
- Offer an ADR only for a decision that is hard to reverse, surprising without context, and the result of a real trade-off.

The glossary and ADR edits are the domain trace; the decisions appendix below still records the grill itself.

## What does the grill produce?

When the tree is exhausted (or the user asks), recap the shared understanding, then offer to publish the minutes as **one appendix document in the project** (Linear document attached to the project; same spirit anywhere else). Never rewrite the project's existing documents: the appendix is the trace, and revising the docs is a separate step.

The appendix follows this format:

- It opens with one line giving the session date, the scope, and where the deltas live.
- **Each point is the question in bold, the decision as the answer.** Any decision that reverses an existing document carries its date and what the document said before.
- Three buckets, always:
  1. the decisions, grouped by actor or theme (employee side / admin side…);
  2. what to reconfirm with product, each as a question;
  3. the gaps with existing documents, named per document and per ticket. This bucket has the most value. When no existing document was read, or none disagrees with the decisions, it says so in one line and names what was compared.
- Exact lists become **tables** (a settings-per-level table beats prose every time).
- Section headers, including the three buckets, are questions in the user's language; no em dashes; keep interface copy in the product's language and annotations in the user's.
- After publishing, give the link and point the user's eyes at the one or two sections that go to someone else.

`design-props` owns technical arbitrages and produces its own Design Decisions document. This appendix owns **product** arbitrages. One project can hold both; never merge them.

Originally from github.com/mattpocock/skills (forked 26/09/2026; no longer tracked upstream).
