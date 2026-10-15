# prose scoring rubric

Score a rewritten text against the case's source text. Each dimension is 0-2. Return per-dimension
scores, a total out of 18, a verdict (PASS = total of 14 or more AND no dimension at 0), and one
concrete rewrite suggestion per dimension under 2. A rewrite that reads well but lost a decision
fails dimension 9.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | **Heading is a question with its stake** (score 2 when the source had no heading and none was added) | Statement or punchline heading | Question, but the alternatives it settles are not visible | A question the reader could have asked, naming what is at stake |
| 2 | **Answer first** | Answer buried after context or justification | Answer in the first paragraph but not the first sentence | First sentence is the decision or the fact |
| 3 | **One why, no proof trail** | Verification steps, counts, dates, who agreed, or a rejected alternative detailed when the source had already decided | Trail mostly gone, one leftover | One reason that changes how the reader implements or reads; nothing on how the author got convinced |
| 4 | **Details in a table when parallel** (3 or more parallel facts; score 2 when the source has none) | Parallel facts left as a sentence chain or a wall | Table present but rows mix levels, or prose repeats the rows | Each parallel fact one row, prose does not repeat the rows |
| 5 | **No emphasis, no tells, no em dashes** | Bold for emphasis, "note that", "essentially", "clearly", "it is worth noting", "in other words", em dashes, a "not X, it's Y" reframe, a dramatic fragment, a label and colon standing in for a sentence, a dangling "this", sentence-start glue, emoji, exclamation, closing offer | One slip | Clean |
| 6 | **One idea per sentence** | A sentence over about 35 words, or clauses chained with "and if ... and if" | One long sentence left | Every sentence carries one idea, under about 25 words |
| 7 | **A cold reader can follow** | Terms the stated audience does not know are used undefined, or given an invented definition | One undefined term | Every term the audience lacks is defined at first use, replaced, dropped, or marked for the author |
| 8 | **Register matches the audience** | A session reply lost its first person, or a short note grew a heading or a table | Slight over- or under-structuring | Document: decision register. Session reply: first person, what I checked, a directed ask. Short note: stays short |
| 9 | **Nothing decided was lost** | A decision, transition or constraint of the source is missing | A minor fact dropped | Every decision and constraint survives, in fewer words |

## Case-specific must-checks

- **Case 1:** the rejected `invoice_pdfs` table's columns are gone; "a template change triggers no re-render" survives. Dimension 3 = 0 if the row count, the agreement date or the colleague's name remains, or if the rejected table's columns appear anywhere.
- **Case 2:** output is two or three sentences, no heading, no table. Dimension 8 = 0 otherwise.
- **Case 3:** "I verified" (or an equivalent first-person check) survives and the reply ends on a directed ask. Dimension 8 = 0 if the first person was stripped, the closing offer kept, or a heading or table added. Dimension 5 = 0 if the test count appears in prose or "Window:" or "Result:" survive as label-colon fragments.
- **Case 4:** all five transitions (open, close as resolved, unreadable, left the group, replay) are present, plus the impact-preview constraint and the idempotence requirement. The heading is a question. Dimension 4 = 0 if the transitions are still one sentence. Dimension 5 = 0 if "This ensures", "That said", the checkmark or the exclamation survive.
- **Case 5:** every term (window, hold, credit, tier, grace period) is defined, replaced or dropped, and the punchline is gone; the three outcomes and their conditions survive. Dimension 7 = 0 if two or more terms remain undefined, or if a number the source never gave (a day count, a percentage) is stated as fact.

## Output format (return exactly this)

```
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
WORD COUNT: _
FIXES:
- dim <n>: <one concrete rewrite suggestion>
```
