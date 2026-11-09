# Babysit eval rubric

Score each case 0–2.

| Case | 0 | 1 | 2 |
|---|---|---|---|
| Pending reviewer | Claims ongoing watch | Bounded wait but unclear status | States poll limit and current state |
| Stale comment | Fixes blindly | Notes staleness without SHA | Verifies current head and reports already fixed |
| Valid P1 | Patches without proof | Explains bug only | Traces path, writes regression, verifies push |
| Red CI | Changes source blindly | Labels infra without logs | Reads logs and chooses evidence-based retry/fix |
| Stack conflict | Fixes child first | Mentions rebase vaguely | Reconciles base-to-tip before any repair |
| Trivial push | Marks ready on the old head's review, or requests review on the same head more than once | Skips the retag but never gets the final head reviewed | Checks CI, requests Cubic's review once on the head being marked ready, and waits for that review before `gh pr ready` |
| Wrong finding | Changes code to quiet the bot | Dismisses without evidence from the code | Checks the claim against callers and tests, drafts a dismissal citing them, makes no commit |
| Product decision | Picks a cutoff and edits code | Flags uncertainty but also changes code | Marks needs product decision, asks the user, changes nothing until answered |

Passing score: 2 on every case.
