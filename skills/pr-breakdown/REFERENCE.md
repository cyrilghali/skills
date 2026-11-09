# PR breakdown reference

## Template

Headers are questions. A section with nothing to say is left out, and so is its header.

```markdown
## [<PR title>](<PR URL>)

### What changes, in one example?
<Before, then after, told through one concrete case: who does what, what they see, what they get. Use real numbers when the change has any.
Name what the user sees on screen, or say who or what is affected and that nothing on screen changes.>

### Which decisions does this PR carry?
| Decision | Option not taken | Who decided | Checked? |
|---|---|---|---|
<one row per decision, most costly to reverse first>

### Does every part of the diff trace to a decision?
| Part of the diff | Traces to |
|---|---|
<one row per visible piece; orphans in bold, "**Nothing stated.**" plus who picked it>

### What was left out?
<scope cuts and unanswered questions, one bullet each: bold lead, class, recovery, test coverage>

### What is the worst case?
<one bullet per failure: its class first, then what happens, how it recovers, whether a test covers it>

### How much does it touch, and what do the terms mean?
<volume with its source (query and date, or "bound from the code, reasoned"); one line per term>

### What will a reviewer ask, and what is your answer?
| Question | Your answer |
|---|---|
```

End with at most one line on review rounds ("automated review raised three payment-safety issues, each fixed and tested") and one line per claim you dropped because the code contradicts it.

## Column vocabulary

| Column | Values |
|---|---|
| Who decided | you · you picked the model's option · model, told you · model, left open · model, not shown to you · unknown, no session found |
| Checked? | tested · checked in code · prod data · reasoned only |
| Worst-case class | works as designed · rare edge case · gap · bug |

## What reviewers and owners ask

The sections come from two readings of real model-written PRs: 84 reviewer comments across 43 PRs that exposed a gap in what the PR explained, and 71 messages where the owner discovered a model's decision late. Use the categories to write the reviewer questions in step 5.

| Category | Reviewer comments | Owner discoveries | Section that answers it |
|---|---|---|---|
| A line, comment or branch nobody can explain | n/a | 18 | Diff trace |
| Rejected alternative not explained ("why not X?") | 18 | 12 | Decisions, option not taken |
| Data model or domain rule in doubt | 13 | n/a | Decisions, terms |
| Scope changed without saying: something added or cut | 12 | 9 added, 5 cut | Diff trace, left out |
| Behavior change not stated | n/a | 11 | One example |
| Failure modes and concurrency | 10 | n/a | Worst case |
| Unverified claim stated as fact | n/a | 8 | Checked? column |
| Owner could not answer the reviewer | n/a | 8 | Reviewer questions |
| Volume and scale | 8 | n/a | Volume |
| Undefined term | 7 | n/a | Terms |
| Product decision hidden in the diff | 7 | n/a | Decisions, "model, not shown to you" |

Owners ask, in their own words: what was the behavior before; why does this line exist; why not X; what does a user see differently; what was left out; what if it fails; what was verified and what was only reasoned; what do I answer the reviewer. They ask for plain words and a worked example with numbers.

## Plain words

| Technical | Plain, by effect |
|---|---|
| A new optional callback in the shared reconcile module | A new step in the case-closing routine every rule shares; only this rule uses it |
| An idempotency check under an advisory lock | A check that makes a second run pay nothing |
| `occurred_at: item.ended_at` | The payment is dated when the case closed, not when it was paid |
| Oban job, max_attempts 10, default backoff | A background payment that gives up after 10 tries, about 20 minutes |
