# intent-pr scoring rubric

Score a generated pair of outputs against the skill's contract: the PR description and the session certification reply.
Dimensions 3, 4 and 9 score the session reply; every other dimension scores the PR description. Each dimension is 0–2.
Return per-dimension scores, a total /18, a pass/fail (pass = total ≥ 14 AND no dimension = 0),
and one concrete rewrite suggestion per dimension scoring < 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | **Intent present & well-formed** | Missing, or a noun phrase | Present but vague or restates the diff | Opening paragraph states the gap and the decision, not the mechanics |
| 2 | **Why = undeducible context** | Missing, or pure restatement of the diff | Present but thin or leaks implementation detail | Gives the trigger/motivation a reviewer could not infer from the code |
| 3 | **Blast radius certified** | Absent | Present but vague ("should be fine") | Names what could break AND what the author checked; "isolated, nothing risky" is full marks IF the change is genuinely safe |
| 4 | **Review ask is directional** | Absent, or "review everything" | Present but generic | Points the reviewer at the 1–2 things that matter most |
| 5 | **No micro leakage** | Names files/functions/modules, or enumerates changes | One slip | Stays macro throughout |
| 6 | **Not a brief / not a changelog** | Reads as "here's what I did" list | Mixed | Reads as the product gap and intent ("what gap this fills"), not a list of changes; risk certification stays out of the body (a `## Query` section's same-rows check and plans are allowed) |
| 7 | **Decisive test** | Reviewer would have to reconstruct the intent | Partial | A reviewer could approve from the Why plus the diff without reconstructing the intent |
| 8 | **Concision** | Walls of text, a section longer than a short paragraph, or certification/proof pasted into the PR | Some padding or hedges | Why paragraphs are a few sentences each, every sentence earns its place, bullets are one line each |
| 9 | **First-person certification voice** | Passive throughout ("tests were updated", "is green") | Mixed | Checks stated in first person ("I verified…", "I confirmed…") that vouch for the work |

## Structure check

The Why opens the body and is one or two short plain sentences on what a person sees today and why that is wrong, followed by the ticket link; an example table may show the change. Subheadings inside the Why, more than two sentences of prose, or over 50 words each cap dimension 1 at 1.

## Case-specific must-checks

- **Case 2:** must NOT be skimped because the diff is one line — why and blast radius both required.
- **Case 3:** blast radius should honestly say "no functional risk" — penalize BOTH fake danger and filler padding.
- **Case 4:** blast radius MUST mention irreversibility + the safeguards (dry-run, batching, retention check). Missing any → dimension 3 capped at 1.
- **Case 5:** the security advisory is the real "why" — if it's written as a version-bump changelog line, dimension 6 = 0.
- **Case 6:** the honest output is a recommendation to split, with the purposes named; no long body. Any single body, long or short, instead of a split recommendation scores 0 on dimensions 7 and 8; dimensions 1, 2, 5 and 6 score the split recommendation. Naming each purpose in one line of the split recommendation is not micro leakage for dimension 5. The structure check does not apply; dimensions 7 and 8 score 2 when the recommendation names each purpose as its own PR in a few lines. Dimensions 3, 4 and 9 still score the session reply as usual, with blast radius covering what the author did not check.
- **Case 7:** the body must carry one `## Query` section: purpose in one sentence, the same-rows check, and before and after plans. Missing the section, or the same-rows check, caps dimension 7 at 1. Plan blocks must hold plan text the author supplied, or clearly marked placeholders; invented plan output scores dimension 2 at 0. Dimensions 6 and 8 do not penalize the `## Query` section: its same-rows check and collapsed plan blocks are exempt from the length and proof rules.
- **Case 8:** score what a user sees. The Why must say who sees the change and when; naming files or components scores dimension 5 per the table. The Why must say that two older screens stay light; missing it caps dimension 1 at 1.

## Output format (return exactly this)

```
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
WORD COUNT: _ (PR description)
FIXES:
- dim <n>: <one concrete rewrite suggestion>
```
