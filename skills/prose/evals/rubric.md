# prose scoring rubric

Score a rewritten text against the skill's contract. Each dimension is 0–2. Return per-dimension
scores, a total /18, a pass/fail (pass = total ≥ 14 AND no dimension = 0), and one concrete
rewrite suggestion per dimension scoring < 2. Judge against the source text of the case: a
rewrite that reads well but lost a decision fails dimension 9.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | **Heading is a question with its stake** (only if the source had a heading) | Statement or punchline heading | Question, but the alternatives it settles are not visible | A question the reader could have asked, carrying what is at stake |
| 2 | **Answer first** | Answer buried after context or justification | Answer in the first paragraph but not the first sentence | First sentence is the decision or the fact |
| 3 | **One why, no proof trail** | Verification steps, counts, dates, who agreed, rejected alternatives detailed | Trail mostly gone, one leftover | One reason that changes how the reader implements or reads; nothing about how the author got convinced |
| 4 | **Details in a table when parallel** (≥ 3 parallel facts) | Parallel facts left as a sentence chain or a wall | Table present but rows mix levels or prose duplicates it | Each parallel fact one row, prose does not repeat the rows |
| 5 | **No emphasis, no tells, no em dashes** | Bold for emphasis, "note that", "essentially", "clearly", "it is worth noting", "in other words", em dashes, "not X, it's Y" reframes, dramatic fragments, or any other item of the VOICE.md checklist (label and colon, dangling "this", sentence-start glue, emoji, exclamation, closing offer) | One slip | Clean |
| 6 | **One idea per sentence** | Sentences over ~35 words, clauses joined by "and if … and if" | One long sentence left | Every sentence carries one idea, under ~25 words |
| 7 | **Cold reader can follow** | Terms the stated audience does not know are used undefined | One undefined term | Every term the audience lacks is defined at first use, replaced, or dropped |
| 8 | **Register matches the audience** | Session reply lost its first-person certification, or a three-line note grew a heading and a table | Slight over- or under-structuring | Document: decision register; session reply: first person, what I checked, directed ask; short note: stays short |
| 9 | **Nothing decided was lost** | A decision, transition or constraint of the source is missing | A minor fact dropped | Every decision and constraint of the source survives, in fewer words |

## Case-specific must-checks

- **Case 1:** the rejected `linkedin_exposures` table and its columns must be gone; "level change triggers no rescrape" must survive. Dimension 3 = 0 if any count, date or name of a person remains.
- **Case 2:** all five transitions (open, close secured, unreadable, left audience, replay) must be present and the idempotence requirement named. Heading must be a question. Dimension 4 = 0 if the transitions are still one sentence. Dimension 5 = 0 if "This ensures", "That said", the checkmark or the exclamation survive.
- **Case 3:** "I verified" (or equivalent first-person check) must survive and the reply must end on a directed ask. Dimension 8 = 0 if the certification voice was stripped, the closing offer kept, or a heading or table added. The test count must not appear in prose. Dimension 5 = 0 if "Window:" or "Résultat :" survive as label-colon fragments.
- **Case 4:** output is two or three sentences, no heading, no table. Dimension 8 = 0 otherwise.
- **Case 5:** every term (kind, chain, threshold, recheck, rescan, window, aura, cycle) is defined, replaced or dropped, and the punchline is gone. Dimension 7 = 0 if two or more remain undefined.
- **Case 6:** no quoted phrase remains in the heading unless it is UI text; the why states the carry-over fact (an unfinished course returns in every later mission of the year) instead of a comparison to an undefined threshold; "waiting for December" and any other image are gone; the decision (completed, or presented twice without completion) survives. Dimension 7 = 0 if the coined phrase or the undefined comparison survives; dimension 3 = 0 if the why is still an image or a resemblance.

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
