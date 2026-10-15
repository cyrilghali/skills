# prose eval cases

Each case gives a generation agent a text and its audience, nothing else. The agent applies
`SKILL.md` and returns only the rewritten text. A judge scores it against `rubric.md`, and
`hooks/prose-gate.sh doc` runs on the output file as the mechanical half.

The `Trap` field names the failure mode the case is designed to catch. Cases 1 to 4 come from
real use, rewritten so they carry no private names, code or data. Case 5 is synthetic and from
a different domain (retail customer service).

---

## Case 1: a decision paragraph carrying its proof trail

**Source:** transcript, rewritten
**Audience:** a technical appendix in the project tracker, read cold by a backend engineer joining the project.

**Input:**

> **Storing the rendered invoices**
>
> After checking the code, the `invoices` table already has a `rendered_payload` jsonb column that keeps the last payload the PDF service returned, and I verified on production (48 210 rows) that it is filled for every invoice ever sent, which is corroborated by `RenderInvoiceJob`, which writes it on every successful attempt. It is therefore clearly pointless to create a dedicated table: the PDF will be **rebuilt on read** from `rendered_payload` and the current template, exactly as `render_preview/1` already does for draft invoices. Note that this decision was agreed on 04/09 with Dana, after we considered an `invoice_pdfs` table (columns `storage_key`, `checksum`, `rendered_at`, `size_bytes`), rejected because it would duplicate the payload — in other words, we keep one source of truth. Consequence: a template change triggers no re-render job, which is important for cost.

**Trap:** keeping the trail (the verification, the row count, who agreed and when, the rejected table's columns) and the emphasis words. The rewrite keeps the decision (rebuild on read, no new table), the one why (a table would duplicate the payload) and the consequence (a template change triggers no re-render), and drops the rest.

---

## Case 2: a three-line README note

**Source:** transcript, rewritten
**Audience:** a developer reading the repository README.

**Input:**

> Note that `make check` is essentially the same as running format, lint, tests and the type checker one after the other — it's not a different pipeline, it's just the shortcut. Importantly, it clearly fails fast on the first failing step.

**Trap:** over-rewriting. Three lines do not warrant a question heading or a table. The rewrite is two plain sentences with the tells and the "not X, it's Y" reframe removed, nothing added.

---

## Case 3: a session reply reporting a pull request

**Source:** transcript, rewritten
**Audience:** the requester, in the chat session, right after the agent pushed a draft pull request.

**Input:**

> I've gone ahead and pushed the draft PR #812, which essentially adds the nightly rescan job. It is worth noting that I took great care to ensure that the job only enqueues scans for confirmed accounts — I verified this with a test that seeds one unconfirmed and one confirmed account and asserts a single enqueued job. Tests were updated and are green (412 tests, 0 failures). Formatting was also run. Window: read from the published config, as decided. Result: the job only fires for confirmed accounts. In other words, the rescan is now fully in place and ready for your review! Let me know if you'd like any changes.

**Trap:** over-applying the no-proof-trail rule. A session reply keeps the first person: what I checked, where the requester should look. The rewrite strips the tells, the passive "tests were updated", the two label-colon fragments ("Window:", "Result:"), the closing offer and the test count, but keeps "I verified" and ends on a directed ask.

---

## Case 4: a ticket paragraph with a statement heading and a wall of transitions

**Source:** transcript, rewritten
**Audience:** a ticket that a fresh agent will implement from, with no other context.

**Input:**

> **Sole writer, not two.**
>
> The scan side becomes the single open/close writer for this kind of case. When a scan evaluation finishes, it looks up the open case for the account (there is at most one, the partial unique index guarantees it), and if the risk is open and no case exists it opens one with the account as subject and no assignee, and if the risk is resolved and a case exists it closes it with outcome resolved and no actor, and if the risk is unreadable it touches nothing, and if the account has left the monitored group the case is closed as cleared by the generic reconciliation, which is the only thing the generic compute still does for this kind since its detections are empty. This ensures a single open case. That said, the impact preview keeps reading the compute module for its counts. Idempotence matters: replaying the same evaluation twice must not open a second case or close the same one twice, which the index and a status guard on close both ensure. Note that the rescan job is a separate ticket ✅. This ticket is essentially the heart of the rule!

**Trap:** the heading is a punchline, not a question; five transitions are packed into one long sentence and belong in a table; "Note that", "essentially", the dangling "This ensures", the "That said" glue, the checkmark, the exclamation and the closing flourish are tells. The rewrite must keep every transition, the impact-preview constraint and the idempotence requirement.

---

## Case 5: a customer email written from inside the company

**Source:** synthetic, retail domain
**Audience:** a first-time customer outside the company, reading a reply about their return.

**Input:**

> Your parcel falls inside the usual window, so it goes through the standard hold: we check it, release the credit, and you pick the tier. If it lands in the grace period instead, the hold is skipped but the credit is capped. Past that, nothing moves. That's the whole policy.

**Trap:** curse of knowledge for an outside reader. Window, hold, credit, tier and grace period are never defined; the last two fragments are a punchline. The rewrite defines or replaces each term for that reader without inventing numbers the source never gives (unknown values stay marked for the author), keeps the three outcomes (inside the window, in the grace period, past it) and ends on content.
