# comment-review scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 16 of 20 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Accuracy check | misses a claim that's now false, or flags a claim that's actually still true | catches the false claim but the rewrite doesn't fix it | every accuracy problem in scope is caught and the rewrite states the true behavior |
| 2 | Unguessable-only check | deletes a comment that names real undocumented behavior, or keeps one that only restates code | correct verdict, weak justification | correctly separates restating comments (delete) from unguessable ones (keep), with reasons |
| 3 | Problem-first check | misses count-enumeration or a missing-counterpart violation | flags it but doesn't name the specific counterpart/problem to fix it with | flags it and the rewrite names the real counterpart and the real reason |
| 4 | Contract-not-discussion check | accepts a discussion-rationale comment (names, meetings, "we decided") because it reads fluently or uses project jargon | flags it but the rewrite still carries some chat residue | flags it and the rewrite states only the neutral contract/invariant |
| 5 | Rot markers | misses a TODO/FIXME/reference that's already false given the stated context | flags it but doesn't say why (what changed that makes it stale) | flags it with the specific reason it's now stale |
| 6 | Missing-comment discipline | flags ordinary uncommented code as missing a comment (padding) | correctly stays silent but for a vague reason | flags nothing when nothing is bug-look-alike, or flags precisely and only a real bug-look-alike gap |
| 7 | Stale-outside-diff check | doesn't check outside the diff at all when told other files exist | checks but misses one of the two stale comments, or finds naming but not behavior staleness | finds every comment the diff's rename/behavior change made false, including ones that are wrong on substance not just on name |
| 8 | Report format | missing file:line, class, or rewrite/delete on a finding | has all fields but not grouped by file or missing the Sources/kept-as-is summary | file:line + class + concrete rewrite-or-delete per finding, grouped by file in priority order, kept-as-is count and Sources section present |
| 9 | No invented findings | manufactures a finding to appear thorough when the honest answer is none, or stays silent on a real issue to look lenient | correct call but doesn't say what was checked | says plainly "no findings" (case 2, 3) or lists every real one (case 1, 4, 5, 6) with nothing invented either way |
| 10 | Brevity check | flags a comment only for spanning several lines, or keeps a comment that carries several facts | right verdicts but the rewrite keeps more than the unguessable fact | flags only comments with more than one fact or restating lines, and the rewrite keeps only the unguessable fact |

## Case-specific must-checks

- **Case 1:** dimension 1 = 0 if the agent doesn't flag the `@doc "Returns the count..."` against the stated fact that `dropped` is hardcoded to 0 (whether or not this diff caused it — it's shown in the reviewed hunk). Dimension 5 = 0 if it misses the TODO rot marker (v1 endpoint already retired). Dimension 4 = 0 if it accepts the moduledoc's ticket/name framing. Dimensions 1, 4, and 5 must each score >=1 — those three classes are unambiguous in this case. Dimensions 2 and 3 are secondary here (the "three channels" line is primarily an accuracy problem; do not fail the report solely for classing it under accuracy instead of also tagging problem-first).
- **Case 2:** dimension 9 = 0 if the report proposes any change to the one comment shown, or invents a second finding. Dimension 6 = 0 if it flags the function for lacking a `@doc`.
- **Case 3:** dimension 10 = 0 if the report flags the two-line comment for length alone. Dimension 9 = 0 if the report contains any finding at all; it must state that every comment checked and none needs a change, and name what "unguessable" fact each one carries (so "nothing to do" reads as reviewed, not skipped).
- **Case 4:** dimension 7 = 0 if the report only addresses the two changed lines and never mentions `docs.ts` or the test file. Dimension 7 = 1 (not 2) if it catches the renamed-reference doc comment but not that the test comment's "covered separately below" claim is now substantively false, not just a name mismatch.
- **Case 5:** dimension 4 = 0 if the report treats the comment as acceptable because it uses the right ticket number and team vocabulary. The rewrite for dimension 4 must state the actual invariant visible in the code (the single `round` over the invoice sum means rounding happens once per invoice) — a rewrite that only strips the names/meeting references but still doesn't say what the single `round` is for scores 1, not 2. Dimension 1 (accuracy): the code given is complete, so a finding that hedges "unverifiable" instead of checking the claim against the shown `rates.get(invoice.currency) or rates.default` scores 0 — the fallback is fully checkable, there is nothing to hedge on.
- **Case 6:** dimension 10 = 0 if the report flags the `Reserve` comment for spanning two lines, or keeps the line-5 comment unchanged. The rewrite for line 5 must keep only the gateway quota-reset fact.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_ 10:_
TOTAL: _/20
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
