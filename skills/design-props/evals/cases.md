# design-props eval cases

Each case gives a self-contained system state (no repository access needed) and a request.
The generation agent applies `SKILL.md`, plays every author and critic role itself in sequence,
and writes the finished study to a file. A judge scores it against `rubric.md`.
The `Trap` field names the failure the case is built to catch. Never show it to the generator.

All cases are synthetic, adapted from real design studies with every private name, table and figure replaced.

---

## Case 1: the load-bearing assumption is false (canonical)

**Source:** synthetic, shaped on a real analytics design study

**Input:** "Give me several designs for webhook usage statistics: failure rate over 30 days, median time to recover, endpoints that never recovered."

**Context (pre-answered):**
- `webhook_endpoints(id, url, disabled_at)` holds current state only.
- `webhook_deliveries(endpoint_id, status, attempted_at)`. The README says "deliveries are kept".
- A migration in the repo adds `PruneDeliveriesJob`, which runs `DELETE FROM webhook_deliveries WHERE attempted_at < now() - interval '7 days'` every night.
- `webhook_endpoints.failures_count` is a counter overwritten on every sync.
- Roadmap: per-customer reliability report next quarter; alerting on endpoints down for more than 24 hours.

**Trap:** building every design on "deliveries are kept" without noticing that the 7-day prune makes any 30-day metric impossible from current data. A good study checks that assumption first, marks the 30-day requirements as impossible today, and shows how each option changes that.

---

## Case 2: options that are the same philosophy

**Source:** synthetic

**Input:** "Three approaches to keep a history of permission changes: who granted which access, when, and when it was revoked."

**Context (pre-answered):**
- `permissions` holds current state and is written by upsert.
- `audit_log` is generic: an untyped JSON payload, 90-day retention.
- No typed events exist anywhere.
- Coming requirements: compliance asks for two years of retention; permission groups ship in six months.

**Trap:** three variants of one idea (three shapes of audit table) instead of distinct write strategies (for example a typed event log, a versioned stateful entity, extending the existing audit log), with no "change nothing on the write path" contender. A second trap: extensibility scored vaguely ("extensible: yes") instead of checked against the two-year retention and the permission groups, one by one.

---

## Case 3: a comparison with no decision

**Source:** synthetic

**Input:** "Compare pgvector against an external search service for semantic search over our documents, and tell us what to do."

**Context (pre-answered):**
- Managed Postgres 16 whose allowed extensions include pgvector.
- 2 million documents, and growth of up to ten times within 18 months is possible.
- No dedicated infrastructure engineer, and a tight budget.
- Target latency is under 200 ms at p95.

**Trap:** ending on a comparison table that never names the real choice. The study also lacks a phased path with explicit switch triggers, such as "start on pgvector, move when p95 passes 200 ms beyond N documents". The remaining decisions never become questions for the team.

---

## Case 4: an open question a run can settle

**Source:** synthetic

**Input:** "Propose several designs for resolving a user's effective permissions, with roles inherited from nested groups. Open question: can a recursive SQL query (recursive CTE) on every request sustain 2,000 resolutions per second, or do we need to materialize?"

**Context (pre-answered):**
- Postgres 16 with tables `groups(id, parent_id)`, `memberships(user_id, group_id)`, `grants(group_id, permission)`.
- Maximum observed nesting depth is 6, across 40,000 groups.
- The team wants an API `effective_permissions(user_id) -> set[str]` called by every controller.
- A local Postgres is available for measurement.

**Trap:** handing "CTE or materialized" back to the reader as a decision, when a run settles it (a script that loads data of the stated shape and measures throughput against 2,000 per second). A second trap: options without the caller sketch `effective_permissions(user_id)` and the public signatures each one implies.

---

## Case 5: no schema, a platform constraint (different domain)

**Source:** synthetic

**Input:** "Propose several designs for client-side state in a spreadsheet editor that can be open in several tabs, with offline editing and later resync."

**Context (pre-answered):**
- TypeScript web app. State lives in an in-memory store per tab, saved by a full POST every 30 seconds.
- The existing API `PUT /tables/:id` has no versioning.
- Product requirement: no edit is ever lost, including after the browser closes.
- The platform documentation says the target mobile webview purges local storage when the app closes.
- There is no database to design.

**Trap:** running the feasibility pass and critique lenses as for a data design (tables, queries, volumes) instead of checking the requirement against the runtime and platform facts given (storage purge, unversioned API). A study that adapts marks "no loss after close" impossible or degraded on the webview, and critiques concurrency between tabs and resync conflicts, not queries.
