# grill-me eval cases

Each case gives a generation agent everything it needs WITHOUT asking questions.
The agent applies `SKILL.md` and returns only its next message to the user (plus, for cases 2 and 3, the fixture files it changed (or "none")). A judge scores it against `rubric.md`.
The `Trap` field names the failure mode the case is designed to catch.

## Case 1 — default mode, product plan, no repo

**Input:** "grill me on this: we want admins to be able to pause the reminder emails our training platform sends, for employees who are on leave. Pause starts when the admin sets it and ends on a date they pick."
**Context (pre-answered):** no codebase or documents are attached; this is a product-level plan.
**Trap:** asking every open question at once in numbered rounds, a bare open question with no recommendation, or drifting into database columns during a product grill.

## Case 2 — `--docs` mode, repo with CONTEXT.md

**Input:** run in a copy of `evals/fixture/`. The user typed "/grill-me --docs: members should be able to reserve a book that is on the shelf so staff put it aside for pickup, and renewals should be allowed even when someone is waiting, since members can only hold 3 loans anyway." The grill already ran one exchange:
- Assistant asked whether "reserve" here means the glossary's Reservation (a queue for a book fully on loan) or a new concept, recommending a new term, "Pickup hold".
- User answered: "New concept. Call it a Pickup hold. Reservation keeps its meaning."
The agent writes its next turn.
**Trap:** not writing "Pickup hold" into `CONTEXT.md` right away; putting implementation detail in the glossary; missing that the code allows 5 active loans while the glossary and the user say 3; missing that renewing with a waiting Reservation contradicts the glossary; asking more than one question; creating an ADR for a small, reversible choice.

## Case 3 — `--docs` mode, plan consistent with the glossary and code

**Input:** run in a copy of `evals/fixture/`. The user typed "/grill-me --docs: members should get an email reminder two days before a Loan is due. The Loan's due date is 21 days after checkout, and a Renewal pushes it back by another 21 days, so the reminder should move with it." The agent writes its first turn.
**Trap:** inventing a contradiction with the glossary or the code, writing a glossary entry before any term has settled, creating an ADR, or asking the user for a fact the glossary and code already give.
