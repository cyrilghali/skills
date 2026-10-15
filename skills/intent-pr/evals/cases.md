# intent-pr eval cases

Each case gives a generation agent everything it needs WITHOUT asking questions: the questions
the skill would ask are pre-answered in **Context**. The agent returns two outputs:
(1) the PR body markdown, or a split recommendation when the change does not fit one PR, and
(2) its reply to the author. A judge scores both against `rubric.md`: dimensions 3, 4 and 9 on
the reply, all others on the PR body. The **Trap** field names the failure mode the case catches.

Cases 1, 2 and 4 come from real use, with names, code and data rewritten. Cases 3 and 5 are
synthetic; case 5 moves to a front-end stack.

## Case 1: a feature flag replaced by a column (canonical)

**Source:** transcript, rewritten
**Input:** "Write the PR description for my branch." Diff summary:
- New column `reports_enabled_at` (timestamp) on `accounts`
- The dashboard reads the column instead of the `:advanced_reports` feature flag to decide whether to show the reports tab
- A data migration fills `reports_enabled_at` for accounts that have the flag on today
- Tests updated
**Context (pre-answered):**
- Ticket: ACME-412.
- Why: the `:advanced_reports` flag meant two things, "this account may buy reports" and "the reports tab is visible". Turning it on for a sales trial also exposed the tab before the account was set up.
- Goal: show the tab only from an explicit date per account.
- What the author checked: the migration fills the column for every account that has the flag today (412 accounts, count matched before and after on a copy of production data); the full test suite passes. The flag stays in place for the billing meaning.
**Trap:** a body that lists the column, the migration and the tests, buries the migration risk, and gives the reviewer no direction.

## Case 2: a one-line timeout fix (trivial input)

**Source:** transcript, rewritten
**Input:** "Can you write up the PR for this?" Diff: the call that fetches invoices from the billing provider gains `timeout: 5_000`; before, it used the HTTP client's default of no timeout.
**Context (pre-answered):**
- Ticket: BILL-88.
- Why: when the billing provider stalls, the request hangs with no end and users see an empty invoices page with no error.
- What the author checked: p99 latency of that call over 30 days is 1.2 s, so 5 s leaves headroom; a test with a stalled fake server now fails after 5 s with an error the page shows.
**Trap:** treating a one-line diff as too small to explain, with no why and no risk; or inflating it into a long body.

## Case 3: a branch that mixes unrelated purposes

**Source:** synthetic
**Input:** "Open a PR for everything on this branch." Diff summary:
- CSV export on the invoices page
- A rewritten password-reset email
- An upgrade of the background-job library across the repo
- A renamed config key read by three services
**Context (pre-answered):**
- The author batched a week of work on one branch; each item has its own ticket (ACME-501, ACME-502, ACME-503, ACME-504).
- The author tested each item alone, never all four together.
**Trap:** forcing four purposes into one body, short or long, instead of recommending a split.

## Case 4: an irreversible data deletion (high stakes)

**Source:** transcript, rewritten
**Input:** "Write the PR description." Diff summary:
- A migration deletes `audit_events` rows older than 18 months and adds a partial index on the rest
- One `purged_at` record per workspace notes the purge
**Context (pre-answered):**
- Ticket: DATA-77.
- Why: the table passed 400 million rows; the audit page now takes 9 s to load. The retention policy only requires 18 months.
- What the author checked: a dry run logs the count first (310 million rows). Deletion runs in batches of 10,000 to avoid long locks. A code search found no feature that reads events older than 18 months. The nightly backup keeps 30 days.
**Trap:** under-stating a dangerous change: no mention that the deletion cannot be undone, no safeguards, no targeted review ask; or pasting the whole verification into the PR body.

## Case 5: a user-visible change in a front-end stack

**Source:** synthetic
**Input:** "PR description please." Diff summary:
- The React settings screen gains a "Dark mode" toggle saved in local storage
- The Tailwind config adds dark palette tokens
- No API change
**Context (pre-answered):**
- Ticket: UI-230.
- Why: support received repeated requests from users who work at night.
- Known gap: the billing and the onboarding screens have no dark tokens yet, so they stay light.
- What the author checked: the toggle in Chrome and Firefox; the setting survives a reload.
**Trap:** a body that lists components and config keys, and says nothing about what users see or which screens stay light.
