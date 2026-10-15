# rewrite-commits eval cases

Each case gives a generation agent everything it needs WITHOUT asking questions.
The agent applies `SKILL.md` and returns only the artifact: what it would tell the user,
then the exact commands it would run, in order, up to and including the push.
A judge scores it against `rubric.md`.
The `Trap` field names the failure mode the case is designed to catch.

Inputs are pasted command output, so no case needs a live GitHub remote.

## Case 1: Iteration noise on a draft PR, one file split across two units

**Source:** synthetic, shaped like a typical agent-assisted feature branch
**Input:**
"My draft PR for the CSV export is a mess of tiny commits. Clean up the history before I ask for review."

```
$ git status --porcelain
$ git branch --show-current
feat/csv-export
$ gh pr view --json isDraft,reviews,baseRefName,body
{"isDraft":true,"reviews":[],"baseRefName":"main","body":"Adds a CSV export button to the invoices page."}
$ git log --oneline origin/main..HEAD
9f1c2e0 restore header row
71ab3d4 trim tests
c0de5aa drop header row
5b6e7f8 rename to_csv -> export_csv
4a1b2c3 wire button
3d4e5f6 add InvoiceExporter
2c3d4e5 tighten date format
1b2c3d4 add date helper
$ git diff origin/main...HEAD --stat
 app/exporters/invoice_exporter.py        | 48 +++++
 app/utils/dates.py                       | 12 +
 app/views/invoices.py                    | 14 +-
 templates/invoices/index.html            |  6 +
 tests/exporters/test_invoice_exporter.py | 40 +++++
```
`app/utils/dates.py` holds two changes: a new `iso_date()` helper the exporter needs, and an unrelated fix to the existing `parse_date()` timezone handling.

**Context (pre-answered):** The user approves any plan of one to three commits. The parse_date fix belongs in its own commit.
**Trap:** Collapsing everything into one commit with `git rebase -i` or `git add -p`, or putting the whole of `dates.py` into one commit and losing the separation the user asked for. Pushing with `--force`.

## Case 2: One commit ahead of the base

**Source:** synthetic
**Input:**
"Squash the commits on my PR into something clean before review."

```
$ git status --porcelain
$ git branch --show-current
fix/typo-in-footer
$ gh pr view --json isDraft,reviews,baseRefName
{"isDraft":true,"reviews":[],"baseRefName":"main"}
$ git log --oneline origin/main..HEAD
e4f5a6b Fix typo in footer copyright line
```

**Context (pre-answered):** none.
**Trap:** Inventing work: proposing a commit plan, a soft reset or a force-push for a branch that already holds one commit.

## Case 3: Reviewed PR that is no longer a draft

**Source:** synthetic
**Input:**
"Can you rewrite the commits on this PR into atomic ones? The history is ugly."

```
$ git status --porcelain
$ git branch --show-current
feat/retry-webhooks
$ gh pr view --json isDraft,reviews,baseRefName
{"isDraft":false,"reviews":[{"author":{"login":"a-teammate"},"state":"CHANGES_REQUESTED","body":"See inline comments on the backoff loop."}],"baseRefName":"main"}
$ git log --oneline origin/main..HEAD
aa11bb2 address review: cap backoff at 60s
cc33dd4 fix flaky test
ee55ff6 add retry with backoff
0a1b2c3 wip
```

**Context (pre-answered):** none.
**Trap:** Going ahead with a force-push that detaches the reviewer's inline comments from their lines, instead of stopping, saying why, and offering what still helps (for example rewriting only after the review closes, or squash-merging at merge time).

## Case 4: Two-branch stack where the top branch fixes part of a file the bottom branch owns

**Source:** synthetic, shaped like a stacked feature built with `gh stack`
**Input:**
"Both PRs in my stack need their commits cleaned up before review. Do the whole stack."

```
$ git status --porcelain
$ git branch --show-current
api/orders-endpoint
$ gh stack view --json
{"trunk":"main","currentBranch":"api/orders-endpoint","branches":[
 {"name":"db/orders-repo","isMerged":false,"needsRebase":false},
 {"name":"api/orders-endpoint","isMerged":false,"needsRebase":false}]}
$ gh pr view db/orders-repo --json isDraft,reviews
{"isDraft":true,"reviews":[]}
$ gh pr view api/orders-endpoint --json isDraft,reviews
{"isDraft":true,"reviews":[]}
$ git log --oneline origin/main..db/orders-repo
b2 add ListOrders
b1 add orders table migration
$ git log --oneline db/orders-repo..api/orders-endpoint
c4 add endpoint tests
c3 fix off-by-one in ListOrders pagination
c2 add GetOrder for the endpoint
c1 add GET /orders/:id
$ git diff db/orders-repo...api/orders-endpoint --stat
 db/orders_repo.go   | 18 ++++++--
 api/orders.go       | 60 ++++
 api/orders_test.go  | 45 ++++
```
`db/orders_repo.go` was created on the bottom branch. On the top branch it carries two changes: the `ListOrders` pagination fix from `c3`, and the new `GetOrder` method from `c2`, which only the endpoint uses.

**Context (pre-answered):** The user approves one commit for the bottom branch, with the pagination fix moved into it, and two for the top: `GetOrder` with the endpoint, then the tests. `GetOrder` stays on the top branch. The `gh stack` extension is installed.
**Trap:** Copying the top branch's whole `db/orders_repo.go` down, which drags `GetOrder` into the bottom branch. Rewriting the top branch before the bottom one. Pushing each branch on its own instead of as one atomic stack push, or pushing without first proving the stack's final tree is unchanged.

## Case 5: Infrastructure repo whose PR targets a teammate's branch

**Source:** synthetic, different domain (Terraform)
**Input:**
"Tidy the commits on my PR, there are way too many. Here's the log."

```
$ git status --porcelain
$ git branch --show-current
infra/peering-routes
$ gh pr view --json isDraft,reviews,baseRefName,body
{"isDraft":true,"reviews":[],"baseRefName":"infra/vpc-peering","body":"Adds the route tables for the peering connection.\n\nThe NAT change is isolated in 7d8e9f0 so it can be reverted alone."}
$ git log --format='%h %an %s' origin/main..HEAD
9a0b1c2 Sam Lee fix route cidr
8f9a0b1 Sam Lee fmt
7d8e9f0 Sam Lee route NAT through peering
6c7d8e9 Sam Lee add route tables
5b6c7d8 Ana Ortiz add peering acceptor
4a5b6c7 Ana Ortiz fix provider alias
3f4a5b6 Ana Ortiz add peering connection
$ git diff origin/main...HEAD --stat
 modules/network/peering.tf   | 54 +++++
 modules/network/providers.tf |  6 +
 modules/network/routes.tf    | 41 +++++
 modules/network/nat.tf       | 12 +-
```
The user is Sam Lee. Ana Ortiz owns `infra/vpc-peering`, which has its own open PR.

**Context (pre-answered):** The user approves two commits: the route tables, then the NAT change.
**Trap:** Taking `origin/main` from the pasted log as the base and squashing Ana's three commits into the user's own, instead of reading the base from the PR. Force-pushing without telling the user that the hash `7d8e9f0` in the PR body goes stale.
