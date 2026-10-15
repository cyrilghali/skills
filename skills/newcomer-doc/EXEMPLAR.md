# Pothole reports: understanding the four proposals

This document compares four ways to keep the history of a pothole report, so the city can publish the repair metrics the council asked for. Read it in order. It first explains how reports work today and why the metrics cannot be computed, then tells each proposal on the same example, and ends with a comparison and a recommendation.

The example and every figure in this document are illustrative. The document is a model of shape and tone, not a real project.

---

## 1. Where we start

### What exists today

A resident reports a pothole in the city app. Every night a job called the dispatcher reads the new reports and builds the crews' to-do list. That list is a table, `open_work_orders`: one row means "a crew must go to this place and fix this defect".

```
resident report  ──▶  dispatcher (nightly)  ──▶  open_work_orders
```

The table is a to-do list, not a register. Each night the dispatcher reconciles it with reality. It adds rows for new reports, and it **deletes** the rows that no longer apply: a crew marked the hole as filled, a second report of the same hole was merged into the first, or the resident withdrew the report.

```
resident report  ──▶  dispatcher (nightly)  ──▶  open_work_orders
                             ▲                          │
                             └──── crew marks "filled" ─┘
                                   (row deleted next night)
```

Two things are kept for good. The table `crew_visits` records every visit a crew makes, with its date and outcome ("filled", "needs heavy equipment", "not found"). The contractor invoices record the repairs the city paid an outside company to make.

### The problem, on an example

Let us follow one report. It will be our running example for the whole document.

> On 1 March, **Maria** reports a pothole outside 42 Elm Street. That night a row appears in `open_work_orders`. On 6 March a crew visits and notes "needs heavy equipment". On 12 March a second crew fills the hole, and the visit is written in `crew_visits`. That night the dispatcher deletes the work order: the to-do list is up to date.

Everything worked. Now let us ask the questions the council wants answered:

- *How long did Maria wait?* We cannot say. The row that held the report date, 1 March, was deleted. The visit of 12 March remains, with nothing to attach it to.
- *How many reports came in during March?* We cannot say. We see only the reports still open today and the visits made. A report that was merged as a duplicate left no trace.
- *What share of the early-March backlog was cleared?* We cannot say. Nobody photographed the backlog in early March.
- *Who fixed it: a city crew, a contractor, or nobody because it was a duplicate?* Only in part. The crew visit is visible, but contractor repairs live in the invoices with other conventions, and a merge leaves nothing.

This is the structural gap: **the life of a report is written nowhere**. Fixing the hole erases the information at the exact moment it becomes useful.

### What the city asks for

Two sources of pressure meet here.

**The council's dashboard brief** asks for six public metrics: reports received, share repaired, median and 90th-percentile time to repair, reports older than 30 days, repairs per district, and the split by who repaired (city crew, contractor, duplicate). Three of them need exactly what we erase: the date a report was born, and the state of the backlog at a past date.

**The new service standards** need it too, even without a dashboard. "Tell the resident at 14 days" needs the report's birth date. "Send it to a contractor after two failed crew visits" needs to know how many visits a report has survived. New kinds of defects are coming as well (broken streetlights, fallen signs), where today's table knows only potholes.

The four proposals answer one question, **where do we write the history of a report?**, with four levels of ambition.

---

## 2. Proposal 1: the event log

### The idea

We change nothing that exists. We add one table, `report_events`, where we write what *happens*, when it happens: an `opened` row when the dispatcher adds a work order, a `closed` row when it deletes one. Rows are only ever added, never changed or removed. The metrics are sums and counts over this log.

### On our example

On 1 March, when the dispatcher adds Maria's work order, it also writes an `opened` event. On 12 March, when it deletes the work order, it writes a `closed` event. It checks the recent crew visits and finds the "filled" visit, so it records the closer as `city_crew`. The log now holds the whole story: opened on 1 March, closed on 12 March, by a city crew. Eleven days. No existing table changed.

### What we must build

1. The table and its indexes. It is a pure addition, with no risk to what exists.
2. Two hooks in the dispatcher: write `opened` on insert, and write `closed` on delete with the closer found from recent visits.
3. A read endpoint for the dashboard, behind a switch that keeps it hidden until it is ready.
4. Later: the time-to-repair metrics, contractor repairs as a closer, and a daily summary table if a year of events becomes slow to query.

A first useful version takes about **6 person-days** for items 1 to 3.

### What it gives

**For the council**: reports received, repairs per district and the backlog age are exact from the first night. Time to repair becomes computable too, but only for reports opened after launch. The dashboard starts half empty and fills over the weeks.

**For residents**: nothing changes in the app. The log makes new things possible, such as "your report is 9 days old, the median in your district is 11".

### Where it breaks

- **History starts at launch.** Nothing before launch can be rebuilt, and the speed metrics take weeks to become credible.
- **The closer is a guess, not a fact.** We infer "a city crew fixed it" from a "filled" visit close in time. A hole filled by a utility company the day after a crew passed by would be credited to the crew.
- **The two-visit escalation is not covered.** A log records openings and closings. It cannot say "this report has survived two visits" without extra work.

**In one sentence**: the best value for the effort in the short term, reversible at any time, but not the foundation the service standards will need.

---

## 3. Proposal 2: the report as a living record

### The idea

Instead of logging events around a table that forgets, we give each report a life of its own: a table `street_reports` where each report is **one row that lives**. It is born with its date (`reported_at`), carries a status (`open`, then `repaired`, `duplicate` or `withdrawn`), and keeps who closed it. The to-do list is no longer a separate table. It is simply the reports whose status is still `open`, and `open_work_orders` fades out.

### On our example

On 1 March the dispatcher creates Maria's report with status `open`. On 6 March the failed visit adds one to its `visit_count`. On 12 March the same row moves to `repaired`, closed by `city_crew`. Nothing is deleted and nothing must be rebuilt: "how long did Maria wait?" is one date minus another. If the city later wants "tell the resident at 14 days" or "send to a contractor after two failed visits", everything is already on the row.

### What we must build

This is a change of model, not an addition.

1. Create `street_reports`.
2. **Double write**: the dispatcher keeps maintaining `open_work_orders` and, in parallel, creates and closes reports.
3. Connect every closing path: crew visits, contractor invoices and duplicate merges update the status.
4. **Backfill**: copy today's open work orders into reports. Their creation date becomes the birth date, an honest approximation for the existing stock.
5. Build the six metrics on the new table.
6. **Switch**: move the four screens that read the work orders (crew tablets, app, district view, planning) to `status = 'open'`, behind a switch.
7. Clean up: stop the double write and retire the old table.

The first sprint delivers items 1, 2 and 4 and three metrics. The full switch takes 3 to 4 sprints.

### What it gives

**For the council**: five of six metrics exact from the backfill. Time to repair is approximate only for the stock that existed before launch.

**For residents and crews**: every open report knows its age, so crews can sort by oldest first and the app can show "reported 16 days ago".

**For the service standards**: native support. The birth date never changes, the visit count lives on the row, and a `defect_type` column takes streetlights and signs without a new table.

### Where it breaks

- **This is the real cost**: a double write in the nightly job, a backfill, four screens to switch, and a rollback that gets harder after the switch.
- Reports closed before launch stay lost, as in every proposal.
- While both tables are written, they can drift apart, and someone must watch for it.

**In one sentence**: the destination, the only model that serves both the dashboard and the service standards, at the price of a real migration.

---

## 4. Proposal 3: the living record and its log

### The idea

This is Proposal 2 plus fine memory. `street_reports` holds the current state, and a second table, `report_transitions`, records **every change of status** with who made it, when, and on which visit.

### On our example

Maria's report is born on 1 March and closed on 12 March, as in Proposal 2. Here each step also leaves a row: `new → open` on 1 March, `open → escalated` on 6 March after the failed visit, `escalated → repaired` on 12 March by the second crew. Proposal 2 would keep only the final closer; this one keeps the path.

### What we must build, what it gives, where it breaks

Everything in Proposal 2, plus the transitions table and a write at each of the seven places in the code that change a status. That is **Proposal 2 plus about one sprint**, and the most places to get wrong.

It gives the richest picture: all six metrics exact and a full audit trail per report. But until escalation to contractors actually ships, **almost every report goes straight from open to closed**, which Proposal 2 already records. Its extra value appears only once the service standards are live.

**In one sentence**: the maximal version of Proposal 2, best kept as a later extension rather than a starting point.

---

## 5. Proposal 4: monthly snapshots

### The idea

Change no write path at all. A nightly job takes a photo at the end of each month, per district: open backlog and its age, visits made and by whom, contractor repairs paid. The photos pile up in `district_month_stats`, and the dashboard reads them.

### On our example

Maria's report appears in no photo. Born on 1 March and closed on 12 March, it lived and died *between* two monthly photos. The end-of-March photo shows the remaining backlog and counts the 12 March visit among "visits this month". The link between the two, the eleven days, even the fact that a report existed: all invisible. This is a limit of the design, not a bug: **a snapshot cannot see a life shorter than its period**.

### What we must build, what it gives, where it breaks

One table, one nightly job, one read endpoint: about **15 person-days**, in two independent changes, and removable at any time.

It gives two exact metrics (repairs per district, backlog older than 30 days), two honest approximations, and **two that are impossible by design**: share repaired and time to repair both need to follow single reports. The risk is close to zero, and that is exactly why it cannot learn anything new.

**In one sentence**: an honest complement for monthly trends, never an answer to the brief on its own.

---

## 6. Side by side

| | P1 Event log | P2 Living record | P3 Record and log | P4 Snapshots |
|---|---|---|---|---|
| Exact metrics (of 6) | 5 (speed ones after a few weeks) | 5 (old stock approximate) | 6 | 2 |
| First delivery | about 6 person-days | 1 sprint (switch: 3 to 4 sprints) | P2 plus 1 sprint | about 15 person-days |
| Service standards | 14-day notice approximate, escalation no | native | native, richest | no |
| Migration risk | low (pure addition) | medium (double write, switch) | high | very low |
| Rollback | full | until the switch | weak | full |

Three lessons come out of the comparison:

1. **The real choice is P1 against P2.** P4 is a complement and P3 is an extension of P2. The decision that shapes the project is: an event log now, or a living record now.
2. **P1 and P2 hook into the same two places** in the dispatcher. The first sprint's work is the same in both; only the destination of the writes changes. Starting with P1 therefore wastes nothing.
3. **Only P2 and P3 serve the service standards.** If escalation to contractors is in this year's plan, P1 alone is a dead end.

---

## 7. Recommendation

**Sprint 1: Proposal 1.** The log, the two dispatcher hooks and the hidden endpoint, about 6 person-days. Three metrics ship from the first night, and history starts piling up. Every week of delay is a week of history lost for good.

**Sprint 2: finish Proposal 1.** Share repaired, time to repair, and the split by closer, with contractor repairs connected.

**Sprint 3 and after: move to Proposal 2 as soon as one trigger fires**: contractor escalation enters the plan, or the crews ask to sort by age. The log stays the source of trends during the move, and Proposal 4 is no longer needed.

### The decisions to take as a team

1. **Is contractor escalation in this year's plan?** If yes, start Proposal 2 now instead of Proposal 1. This is the decision that changes the path.
2. **Do crews need to sort by report age within three months?** If yes, bring the Proposal 2 double write forward to sprint 2.
3. **Should we spend about 15 person-days on Proposal 4 alongside Proposal 1?** Only if trend queries become slow at city scale, which we can wait to observe.
4. **Do contractor repairs go in sprint 1 or sprint 2?** They are needed for the split by closer. Move them to sprint 1 if that metric must be in the first release.
