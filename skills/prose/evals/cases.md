# prose eval cases

Each case gives a generation agent a text and the audience, nothing else. The agent applies
`SKILL.md` and returns only the rewritten text. A judge then scores it
against `rubric.md`, and `hooks/prose-gate.sh doc` runs on the output as the
mechanical half.

The `Trap` field names the failure mode the case is designed to catch.

---

Cases 1, 2, 3 and 6 came from private work and live in `private/cases.md` when present.

## Case 4 — a three-line README note

**Audience:** a developer reading the repo README.

**Text:**

> Note that `mix ci` is essentially the same as running format, compile, tests, credo and gettext one after the other — it's not a different pipeline, it's just the shortcut. Importantly, it clearly fails fast on the first failing step.

**Trap:** over-rewriting. Three lines do not warrant a question heading or a table. The rewrite is two plain sentences with the tells and the "not X, it's Y" reframe removed, nothing added.

---

## Case 5 — a customer email written from inside the company

**Audience:** a first-time customer outside the company, reading a reply about their return.

**Text:**

> Your parcel falls inside the usual window, so it goes through the standard hold: we check it, release the credit, and you pick the tier. If it lands in the grace period instead, the hold is skipped but the credit is capped. Past that, nothing moves. That's the whole policy.

**Trap:** curse of knowledge for an outside reader. Window, hold, credit, tier and grace period are never defined; the last two fragments are a punchline. The rewrite defines or replaces each term for that reader, keeps the three outcomes (inside the window, in the grace period, past it) and ends on content.

---

## Case 7 — a paragraph already in register

**Audience:** a visitor reading the site's parking notice.

**Text:**

> **Can a visitor park overnight in the staff lot?**
>
> No. The lot closes at 20:00 and the gate locks, so a car left inside cannot leave until 07:00. Visitors use the street spaces on Mill Road, which are free after 18:00.

**Trap:** rewriting text that needs no change. The honest output is the same text, or one line changed with no fact added or lost; nothing added.
