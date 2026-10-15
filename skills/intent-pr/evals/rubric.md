# intent-pr scoring rubric

Score the two outputs against the skill's contract: the PR body and the reply to the author.
Dimensions 3, 4 and 9 score the reply; every other dimension scores the PR body. Each dimension is 0-2.
Return per-dimension scores, a total /18, pass/fail (pass = total >= 14 AND no dimension at 0),
and one concrete rewrite suggestion per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | **Intent stated** | Missing, or a noun phrase | Present but vague, or restates the diff | The opening paragraph states the gap and what the PR decides, not the mechanics |
| 2 | **Why a reviewer cannot infer** | Missing, or a restatement of the diff | Thin, or leaks implementation detail | Gives the trigger or motivation the code does not show |
| 3 | **Risk certified (reply)** | Absent | Vague ("should be fine") | Names what could break AND what the author checked; "no real risk" earns 2 when the change is genuinely safe |
| 4 | **Review ask points somewhere (reply)** | Absent, or "review everything" | Generic | Points the reviewer at the one or two things that matter most |
| 5 | **No file-level detail** | Lists the diff's changes step by step, or names two or more code identifiers (files, functions, tables, flags) | One identifier or one mechanism detail | Describes behavior throughout |
| 6 | **Product gap, not a changelog** | Reads as "here is what I did" | Mixed | Reads as the gap the PR fills; verification and test plans stay out of the body |
| 7 | **Decisive test** | A reviewer would have to reconstruct the intent | Partial | A reviewer could approve from the body plus the diff alone |
| 8 | **Concision** | Walls of text, a section longer than a short paragraph, or proof pasted into the body | Some padding or hedges | Short paragraphs, every sentence earns its place |
| 9 | **First-person certification (reply)** | Passive throughout ("tests were updated") | Mixed | Checks stated in the first person ("I checked...", "I ran...") |

## Structure check

The body opens with `## Why`: one to three short plain paragraphs that cover what happens today and what is missing, what the PR adds, and whether anyone sees a change yet. Subheadings inside the Why, more than three paragraphs, a single crammed sentence, or a `## Summary` / `## Test plan` / `## Changes` section each cap dimension 1 at 1.

## Case-specific must-checks

- **Case 1:** the body must say whether anyone sees a change at merge (accounts with the flag keep the tab). The reply must name the backfill as the risk. Missing either caps dimension 3 or 1 at 1.
- **Case 2:** a body with no why scores dimension 2 at 0; a body over three paragraphs scores dimension 8 at 0.
- **Case 3:** the honest output is a recommendation to split, each purpose named as its own PR in a line. Any single body scores 0 on dimensions 7 and 8. Dimensions 1, 2, 5 and 6 score the split recommendation; naming each purpose in one line is not file-level detail. The structure check does not apply. The reply's risk names that the four items were never tested together.
- **Case 4:** the reply must name irreversibility and the safeguards (dry-run count, batching, the code search, the backup window). Missing any caps dimension 3 at 1. The body must say the deletion cannot be undone; counts and batch sizes in the body cap dimension 8 at 1.
- **Case 5:** the Why must say who sees the change and that the billing and onboarding screens stay light; missing the light screens caps dimension 1 at 1. Naming React components or config keys scores dimension 5 per the table.

## Output format (return exactly this)

```
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
WORD COUNT: _ (PR body)
FIXES:
- dim <n>: <one concrete rewrite suggestion>
```
