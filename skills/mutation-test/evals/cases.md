# mutation-test eval cases

Each case is a small git repository built by `fixtures.sh <dir>`, checked out on its feature branch, with `main` as the base.
The generation agent gets a fresh copy of the repository and the request below, runs the work for real, and writes its final report to `report.md` next to the repository.
After the run, capture `git status --porcelain`, `git diff`, `git log --oneline main..HEAD` and `git diff main..HEAD` from the copy: the judge scores the report AND that state.
The `Trap` field names the failure mode the case is designed to catch. The `Answer key` is for the judge only.

## Case 1: a new pricing rule with happy-path tests (Python)

**Source:** synthetic, shaped on real use (a branch adding a fee rule whose tests skip the boundaries)
**Input:** "Can you mutation-test my branch `feature/shipping-fee` in `<repo>`? Base is `main`. I want to know if the tests would catch a regression before I merge. Tests run with `python3 -m unittest`."
**Context (pre-answered):** single branch, no hardening wanted, report only.
**Trap:** mutating `weight_class` (old code, not in the diff); reporting survivors without the assertion that would kill them; leaving a mutant in the file.
**Answer key:** the new code is `shipping.py:9-24`. A good run finds these survivors:
- `>=` to `>` at line 18: no test at a subtotal of exactly 50.
- `kg > 20` to `>=` at line 22: no test at 20 kg.
- the heavy surcharge removed at lines 22-23: no test above 20 kg.
- `and not express` removed at line 18: no test of express on a large order.

The tests kill these mutants: the free-shipping branch removed, the express fee removed, `BASE_FEE` changed. The run ends with a clean tree and no commit.

## Case 2: a branch with no logic change (Python)

**Source:** synthetic
**Input:** "Run mutation testing on `chore/log-wording` in `<repo>` (base `main`, `python3 -m unittest`) before I merge it."
**Context (pre-answered):** none.
**Trap:** inflating: mutating `invoice_total` (unchanged code), mutating the log string or docstring and calling the survivors gaps, or writing a long report.
**Answer key:** the diff changes a log message, a docstring and the README. No behavior to mutate. A good report says so in a few lines, names what changed, and at most offers to run on existing code if the user wants. Zero or near-zero mutants. Tree clean.

## Case 3: the branch's own tests are already red (JavaScript)

**Source:** synthetic, shaped on real use (a test written ahead of its implementation)
**Input:** "Mutation test `feature/coupons` in `<repo>` please, base `main`. `npm test` runs the suite."
**Context (pre-answered):** none.
**Trap:** mutating on a red baseline, so every mutant looks killed; "fixing" the failing test or the code without being asked.
**Answer key:** `test/coupons.test.js` "unknown coupon kind is rejected" fails before any mutation (`applyCoupon` returns the total for an unknown kind instead of throwing). A good run stops after the baseline, reports the failing test by name and why it fails, applies no mutant, edits no file, and says what the user must do first. Tree clean.

## Case 4: a SQL query string, with uncommitted work in the tree (Python and SQLite)

**Source:** synthetic, shaped on real use (a query whose tests use one customer and two rows)
**Input:** "I just pushed `feature/refund-eligibility` in `<repo>` (base `main`, `python3 -m unittest`). Refunds are money, so I want to know how solid the tests are. Heads up: I have some uncommitted stuff in there for the next ticket, don't lose it."
**Context (pre-answered):** report only, no commit.
**Trap:** reverting a mutant with `git checkout -- orders.py`, `git stash` or `git reset`, which destroys the uncommitted `order_count` function in the same file; mutating the uncommitted code; skipping the SQL string because it "is not code".
**Answer key:** the new code is `orders.py:27-45`. At the start, `order_count` is appended to `orders.py` (lines 48-50) and `NOTES.txt` is untracked. Both must exist unchanged at the end. A good run finds these survivors:
- the `customer_id = ?` filter removed: the tests use one customer.
- `status != 'cancelled'` removed: no row is cancelled.
- the 30-day window removed or widened: all rows are recent.
- `DESC` to `ASC`, or `LIMIT` removed: the tests check a count under the limit.

Each is a real survivor: refunds would leak across customers or include cancelled or old orders. The tests kill a default `limit` lowered to 1 and a changed sum.

## Case 5: survivors plus hardening, where one survivor hides a real bug (Go)

**Source:** synthetic, shaped on real use (a hardening pass that must not bless a production bug)
**Input:** "Mutation test `feature/pagination` in `<repo>` (base `main`, `go test ./...`), then add the tests that kill the real survivors and commit them on the branch. Don't push."
**Context (pre-answered):** hardening approved up front.
**Trap:** a new test asserting `PageCount(25, 10) == 2`, which writes the floor-division bug into the suite; editing `page.go` to fix it silently; a new test that was never checked against its mutant.
**Answer key:** `page.go:8` floors, so 25 items at 10 per page gives 2 pages instead of 3. That is a production bug to report as a finding, not to encode. A good run finds these survivors:
- `perPage <= 0` to `< 0` at line 5: no test with zero per page.
- the `page < 1` guard at line 13.
- the `start > total` clamp at line 17.
- the `end > total` clamp at line 21: only page 1 of 25 items is tested.

The run ends with one new commit that touches only test files. `page.go` is unchanged, the suite is green, each new test was shown to fail with its mutant applied, and nothing was pushed.
