# torture-test eval cases

Each case is a runnable project under `fixtures/`. The generation agent gets a
scratch copy of the folder and the request below, applies `SKILL.md`, and
returns its final triage plus the exact content of every test file it touched.
A judge scores the result against `rubric.md`. The `Trap` field names the
failure mode the case is designed to catch; never show it to the generation
agent.

Run the Python fixtures with `uv run --with pytest pytest`; no fixture
declares Hypothesis. Run the Elixir fixtures with `mix deps.get && mix test`.
Cases 1 and 5 are Elixir, the rest Python, so the skill is tested on two
languages and two property libraries (present in case 1, absent in case 5).

## Case 1: round-trip invariant with the property library present

**Source:** synthetic, modeled on a real cursor bug.
**Input:** `fixtures/1-cursor-roundtrip/`. Request: "Torture test the pagination
cursor module (`lib/cursor.ex`). Clients of the public endpoint
`GET /posts?after=<cursor>` send the cursor back unchanged."
**Context (pre-answered):** the agent may run `mix test`; no commit.
**Seeded bug:** `decode/1` splits on every `|`, so a title containing `|` does
not round-trip. `decode(encode(%{title: "|", id: 1}))` returns
`{:error, :invalid_cursor}`.
**Trap:** a generic string generator (`string(:printable)`, `string(:utf8)`)
rarely produces `|`, so the property passes on the bug and the agent falls
back to a fixed example. Verified: `string(:printable)` passes in 100 runs,
`string(:ascii)` fails and shrinks to `title: "|"`.

## Case 2: a trivial function the pass must not inflate

**Source:** synthetic.
**Input:** `fixtures/2-is-weekend/`. Request: "Run a torture test on
`is_weekend`; we use it to grey out delivery days."
**Context (pre-answered):** the agent may run the tests; no commit.
**Seeded bug:** none. `date.weekday()` has no time zone, no DST and no locale.
**Trap:** the agent runs time zone, DST or 29 February attacks on a value that
carries no time, or writes a property that restates the implementation
(`is_weekend(d) == (d.weekday() >= 5)`), which is an invented invariant.
A good pass runs one or two short attacks and adds zero tests.

## Case 3: healthy code, the honest answer is "nothing to add"

**Source:** real use, rewritten.
**Input:** `fixtures/3-slugify/`. Request: "Torture test `slugify` before we
expose it in the URL editor."
**Context (pre-answered):** the agent may run the tests; no commit.
**Seeded bug:** none. Verified: idempotence `slugify(slugify(x)) ==
slugify(x)` holds on hostile inputs; underscores survive by design (`\w`).
One documented behavior is a fair product gap to raise: a title with no
Latin letters (`"你好"`) produces an empty slug.
**Trap:** padding. The agent adds tests for attacks that pass, or adds
Hypothesis to write the idempotence property. The project does not declare
Hypothesis, so the property axis is reported as not covered.

## Case 4: money, retry storm, must be exhaustive on the risky axis

**Source:** real use, rewritten.
**Input:** `fixtures/4-wallet/`. Request: "Torture test `debit_wallet` before
one-click payment goes live."
**Context (pre-answered):** the agent may run the tests; no commit.
**Seeded bugs:** a retry after a timeout can debit twice. The balance is
written before the transaction is recorded, so a failure between the two
writes raises after the money moved, and the caller retries. The
read-check-write has no lock, so two concurrent debits both pass the funds
check. The docstring promises no idempotency, so the missing idempotency key
is fair to raise as a product gap. The stateless mock (`get_wallet` always
returns the same balance) hides all of it.
**Trap:** a retry or race test written on the stateless mock passes on the
bug; the killer test needs a stateful fake, and a race test timed with sleeps
passes on some runs. Tests for zero or negative amounts duplicate the
existing suite.

## Case 5: request written from inside the project, library absent

**Source:** synthetic, modeled on a real request.
**Input:** `fixtures/5-payouts/`. Request: "Torture `Payouts.split/2` before we
ship GO payouts v2, it's what goes out to merchants in the Thursday batch."
**Context (pre-answered):** the agent may run `mix test`; no commit. "GO"
means group order.
**Seeded bugs:** `div/2` drops the remainder, so `split(100, 3 merchants)`
pays 99 cents; a repeated merchant id collapses in the map, so
`split(100, ["a", "a"])` pays 50. Both reproduced.
**Trap:** the agent adds `stream_data` to `mix.exs` to write the conserved-sum
property, or reuses "GO payouts v2" and "Thursday batch" in the triage
without saying what a merchant sees (a cent missing from each payout).

## Case 6: wide branch, one module whose baseline is red

**Source:** synthetic.
**Input:** `fixtures/6-branch/` (two independent modules, `billing/` and
`search/`, each run with `uv run --with pytest pytest` from its own folder).
Request: "Torture test this branch (both modules) before the release."
**Context (pre-answered):** the agent may run the tests and launch parallel
agents; no commit.

**Setup:** the scratch copy is initialized as a clean git repo
(`git init && git add -A && git commit`) before the run, so only the `billing/`
baseline is red.

**Seeded condition:** the `billing/` baseline is red before any attack (one
existing test fails on the current code). `search/` is healthy and has no bug.
**Trap:** the agent attacks `billing/` on a red baseline and counts it as a
torture passed, or fixes the failing test, or drops the module silently.
A good pass reports `billing/` as BLOCKED, lists its axes under axes not
covered, and treats `search/` on its own merits.
