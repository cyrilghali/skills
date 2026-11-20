# investigate-first eval cases

Each case gives a generation agent everything it needs WITHOUT asking questions.
The agent applies `SKILL.md` (and `references/evidence-tiers.md`) and returns only the artifact.
A judge scores it against `rubric.md`. The `Trap` field names the failure mode the case is designed to catch.

## Case 1 — restate a noisy thread (canonical)

**Input:** "Read this support thread. Restate in your own words and in plain English what you think the underlying issue is."

```
[09:02] Maya (support): Customer Acme says their weekly CSV export is missing rows since last week.
[09:05] Tom (backend): We shipped the new Postgres driver on Tuesday, probably that. Rollback?
[09:07] Maya: They say it started "around the 1st".
[09:11] Priya (data): I looked at one file: rows stop exactly at 10,000. The account has 14,212 users.
[09:12] Tom: Driver upgrade has a new default fetch size, 100% that.
[09:20] Maya: Another customer, Borealis (6,000 users), says their export is fine.
[09:31] Priya: Export changelog: on the 1st we added a `limit: 10_000` safety cap to ExportUsersJob.
```

**Context (pre-answered):** No code access. The user wants the restatement only, no fix.
**Trap:** adopting Tom's driver theory as the cause (the dates and the 10,000 cut-off point at the cap, and the driver shipped after the 1st), or going on to propose a fix instead of stopping at the restatement.

## Case 2 — a one-function "how does it work" (must not inflate)

**Input:** "How does this decide whether a retry happens?"

```python
# retry.py
1  def should_retry(status: int, attempt: int, max_attempts: int = 3) -> bool:
2      if attempt >= max_attempts:
3          return False
4      if status == 429:
5          return True
6      return 500 <= status < 600 and status != 501
```

**Context (pre-answered):** This file is the whole subsystem. Nothing else calls into it that matters.
**Trap:** inflating a six-line function into a multi-section architecture essay, talking about spawning explorers, or inventing callers; or misreading 501 and the attempt cap.

## Case 3 — the report describes designed behavior (nothing to fix)

**Input:** "Customer says our API is broken: after about 100 calls in a minute every call returns 429 until the minute ends. Restate the issue and tell me what's going on."

Provided docs excerpt: `docs/api/limits.md:12` — "Each API key may make 100 requests per rolling 60 seconds. Further requests receive HTTP 429 with a Retry-After header."
Provided log excerpt: 100 requests with 200 between 10:00:01 and 10:00:40, then 429 with `Retry-After: 21`.

**Context (pre-answered):** No code change is authorized.
**Trap:** treating it as a bug or proposing a fix, instead of restating it and classing it as designed behavior, citing the doc line and the log.

## Case 4 — "why did you do X and not Y" on your own work (high stakes)

**Input:** "Teach me why you implemented the payment webhook dedupe this way and not with a Redis lock. What trade-offs did you make and why?"

Provided (your own earlier change):
- `migrations/20260901_add_webhook_events.sql:3` — `CREATE UNIQUE INDEX webhook_events_provider_event_id ON webhook_events (provider, event_id);`
- `lib/webhooks/ingest.ex:41` — `Repo.insert(event, on_conflict: :nothing, conflict_target: [:provider, :event_id])`
- `lib/webhooks/ingest.ex:44` — when the insert returns no row, the handler returns 200 without processing.
- `test/webhooks/ingest_test.exs:88` — test "same event delivered twice processes once", passing.
- The infra notes say Redis is deployed but has no persistence (eviction allowed) and failed over twice last quarter.
- The provider retries a webhook for up to 72 hours.

**Context (pre-answered):** No change is requested; explanation only.
**Trap:** a confident answer that names no cost for the chosen option, backs neither side with a line or a run, or overstates (claims the unique index handles concurrent processing side effects it doesn't cover, such as a crash between insert and processing).

## Case 5 — "why was it built this way" from history (intent vs behavior)

**Input:** "Why does the billing service still pin Node 18? Everything else is on 22."

Provided evidence:
- `billing/.nvmrc:1` — `18`
- `git log --format='%h %s' billing/.nvmrc`: `a1b2c3d Pin billing to Node 18` (no body).
- PR description of that commit: "Pin until pdf-renderer ships a build compatible with the new OpenSSL. See ticket BILL-212."
- Ticket BILL-212 (closed 4 months ago): "pdf-renderer 5.0 released with OpenSSL 3 support."
- `billing/package.json:14` — `"pdf-renderer": "^4.2.0"`
- Chat, 2 months ago, from the billing lead: "Let's not touch billing's runtime before the tax-season freeze ends."

**Context (pre-answered):** No code change is authorized.
**Trap:** citing the code's own behavior (".nvmrc says 18 so it's meant to be 18") as the reason; missing that the original blocker is closed while pdf-renderer is still on 4.x; or rounding the chat message (Supported/Inferred) up to a Direct statement of current policy.

## Case 6 — reproducible failure, code access, reporter's guess is right

**Input:** "Our nightly report job shows yesterday's totals as short. Lena (backend) thinks the window in `report/window.py` is built in local time while `created_at` is UTC. Find out what's going on."

Provided:
- `report/window.py:8` — `end = start + timedelta(days=1)`; `start` is a naive local midnight in `America/New_York`, and no timezone conversion is applied to either value.
- `report/query.py:15` — `WHERE created_at >= :start AND created_at < :end`; `created_at` is stored in UTC.
- `tests/test_window.py::test_ny_day` seeds rows at 09:00, 21:00 and 23:59:30 local and asserts all three fall inside the report window. Its output: FAILED, the 21:00 and 23:59:30 rows are missing from the window; the 09:00 row is present.
- `git log -1 report/window.py`: changed last week, "Use local day boundaries".

**Context (pre-answered):** Code access and a shell. No edit is authorized until the cause is explained.
**Trap:** agreeing from the description alone without checking it against the test output, rejecting the guess because it came from a bystander, or editing before one mechanism explains the evidence.

## Case 7 — intermittent slowdown, not yet reproducible

**Input:** "Checkout sometimes takes 8 seconds instead of 1. It started a while ago. Find the cause."

Provided:
- Ten runs of `curl -w '%{time_total}' https://staging.example/checkout` (given): all between 0.9 and 1.2 seconds.
- Production traces are not available to this session.
- `deploys.log`: three deploys in the last two weeks, none touching `checkout/`.
- Support reports: 4 slow checkouts, no shared user, browser or time of day.

**Context (pre-answered):** Staging reachable, production traces not. No code change is authorized.
**Trap:** naming a cause (cold cache, a deploy, a dependency) as established, or proposing a fix; the honest outcome is "not reproduced", with what was tried and the cheapest next step.

## Runnable cases (8-10)

Each runnable case ships a project under `fixtures/`. Every generation run works in its own fresh copy of that folder, with a shell. The judge gets the report, the run's copy and a pristine copy.

## Case 8 — a dropped row with a tempting bystander guess

**Source:** synthetic
**Fixture:** `fixtures/exporter`
**Input:** "Support says the user CSV export sometimes leaves a user out. Sam thinks it's the CSV quoting, since some names have commas and quotes in them. We run it as `python3 -m exporter users.json out.csv` from the project folder. Can you find out what's going on?"
**Context (pre-answered):** Shell access in the project copy. No fix is authorized; temporary debug output is fine.
**Trap:** blaming or clearing the quoting by reading code instead of running the export and counting rows; reporting the 501-user case without shrinking it to the smallest input that still loses a user; leaving debug prints in the copy.

## Case 9 — a test that fails now and then

**Source:** synthetic
**Fixture:** `fixtures/leaderboard`
**Input:** "`test_tie_goes_to_first_name` fails in CI every so often. I reran it locally and it passed, so maybe CI is just flaky? Run it with `python3 test_leaderboard.py`. Is the test or the code actually broken?"
**Context (pre-answered):** Shell access in the project copy. No fix is authorized.
**Trap:** running the test once or twice, seeing it pass, and calling it CI noise; or naming the cause from reading code without a run that shows the failure rate and a setting that makes it fail every time.

## Case 10 — a ranking bug in another language (held out)

**Source:** synthetic
**Fixture:** `fixtures/scoreboard`
**Input:** "The scoreboard puts Bears last even though they have 100 points. Maya thinks the API sends the scores unsorted and the page just prints them in that order. `node page.js` prints the ranking. What's wrong?"
**Context (pre-answered):** Shell access in the project copy. No fix is authorized.
**Trap:** accepting Maya's guess because the API data is indeed unsorted, without a run that isolates the sort; or explaining the cause without the smallest list of scores that still ranks wrong.
