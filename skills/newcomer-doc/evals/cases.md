# newcomer-doc eval cases

Each case gives a generation agent everything it needs to write the document WITHOUT asking questions.
The agent applies `SKILL.md` and returns only the final markdown. A judge scores it against `rubric.md`.
The `Trap` field names the failure the case is built to catch; never show it to the generation agent.

---

## Case 1: agent notes to rewrite (the canonical case)

**Source:** correction (a compressed agent-assembled draft was rejected as unreadable; rewritten here on a public subject)
**Input:** "Write the comparison document on the product cache invalidation strategy, for the wider team. Two of them are new and don't know the system. Here are the notes the research agents produced:"
- Current system: `product_cache` (Redis, TTL 1h) → API read; invalidation = TTL only → staleness window 0-60min; support incidents x3/month.
- Opt A "short TTL": TTL→2min; DB load x8 (measured on staging); 0 rework; residual staleness 2min.
- Opt B "event invalidation": post-update product hook → `DEL`; covers 90% of writes (bulk imports off path → staleness persists on imports); 2 sprints; risk: hook forgotten on future write paths.
- Opt C "write-through": cache written at the source, reads never stale; write-path rework (4+ sprints); high migration risk; KNOWN DEFECT: bulk imports (30% of updates) go through direct SQL COPY → bypass write-through, full staleness on that flow until the import is rewritten.
**Context (pre-answered):** markdown output; the team will pick one option.
**Trap:** copying the telegraph (`TTL→2min; DB load x8`), using "staleness", "TTL" or "write-through" before explaining them, hiding option C's bulk-import defect, no running example.

---

## Case 2: specialist subject for a product reader

**Source:** synthetic
**Input:** "Explain to Sarah (product manager, not technical) why the counters on the admin screen sometimes show stale values right after an action, and the two ways we could fix it."
- Reads go to a replica (lag 1-3 s) after writes go to the primary.
- Option A: read from the primary for these 3 screens (cost: more load on the primary, 0 extra days).
- Option B: read-your-writes through a 5 s sticky session (2 days, covers every future screen too).
**Context (pre-answered):** a short document Sarah reads before a 15-minute meeting.
**Trap:** unexplained jargon (replica, lag, sticky session), no concrete example of a person clicking and seeing the wrong number, the full seven-section template for a subject that needs four.

---

## Case 3: short memo that must stay short

**Source:** synthetic
**Input:** "Short note for the team: why we're moving the cleanup jobs from shell cron scripts to Oban. There isn't really a serious alternative."
- The current shell cron has no retry and no monitoring; it caused 2 silent incidents.
- Oban (a database-backed job queue) is already in the stack.
- The only alternative considered was Quantum, rejected because it does not persist runs.
**Context (pre-answered):** one page at most.
**Trap:** running the seven-section template and a named running character on a one-page, one-option memo; or the mirror failure, telegraphic bullets in the name of brevity.

---

## Case 4: explaining an existing process, no options

**Source:** synthetic
**Input:** "Write a document for the two people joining the support team that explains how a customer refund request moves through our company, from intake to payout."
- The customer writes through the web form.
- A support agent checks the order and classifies the request: under 50 EUR, approved directly; 50 EUR or more, a manager must approve within 48 hours.
- Finance executes transfers every Thursday.
- The customer gets one email at approval and a second at payout.
- Requests with no customer reply after 7 days are closed.
- No alternative is under study and no decision is expected.
**Context (pre-answered):** markdown, read on their first day.
**Trap:** inventing options, a comparison table or a recommendation for a document that only explains; undefined jargon; no single request followed end to end.

---

## Case 5: a process decision outside software (different domain)

**Source:** synthetic
**Input:** "Prepare a comparison for the leadership team on how to handle supplier invoices: manual entry by accounting, or an automatic reading tool with a human check. The readers don't know the current process."
- Today 400 invoices a month are typed in by hand, about 6 minutes each, with 1 amount error in 50.
- The tool costs 9 EUR per processed invoice below 500 invoices a month.
- It reads 95% of standard-format invoices correctly, but only 70% of handwritten scans, which are 15% of the volume.
- A human check stays necessary on those scans, so the real time saved is lower than the vendor's claim.
- Setup takes 3 weeks.
**Context (pre-answered):** markdown; leadership will decide at the next meeting.
**Trap:** hiding or softening the handwritten-scan limit, undefined accounting jargon, no single invoice followed through each option, final decisions not phrased as questions.
