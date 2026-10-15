# newcomer-doc scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 11 of 14 AND no dimension at 0), and one concrete fix per dimension under 2.
Every penalty quotes the faulty passage word for word. A penalty without a quote does not count.
Read the case (material and trap) first, then the document, then score dimension by dimension.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Running example: one concrete, named case (a person, an order, an invoice) introduced early and replayed in every option or every step | none | present but not replayed, or generic ("a user") | named, introduced early, replayed everywhere it applies; a one-page memo needs only a one-sentence example |
| 2 | Context before jargon: every technical term is explained at its first use; the case's reader grasps the problem within the first screen | two or more terms used before they are explained | one term late or unexplained | every term explained at first use |
| 3 | Honest verdicts: each option states its real limits; every limit or defect the material supplies is visible and weighed | a supplied defect is hidden or softened | limits present but the worst one is not singled out | each option has its limits, the worst one is marked, nothing invented |
| 4 | Written prose: full sentences, no telegraph or fragments copied from the material, no invented abbreviations | two or more telegraphic blocks copied | one telegraphic passage | prose throughout (tables may hold short cells) |
| 5 | Proportion: the structure fits the request (full structure for a rich comparison, tight for a short request, no option, comparison or recommendation sections when there is nothing to choose) | full template on a short memo, invented options, or a rich comparison with no structure | one section too many or too few | structure matches the request |
| 6 | Decision framing: when there is a choice, a recommendation plus the open decisions phrased as questions with what each answer changes; when there is none, nothing is invented and the close points the reader to what matters | a choice with no recommendation, or decisions invented for a no-choice request | recommendation present but open decisions not phrased as questions | complete for the case's shape |
| 7 | Nothing lost and nothing vague: every number and unit from the material survives, no "quickly" or "easily" in place of a figure | a supplied figure missing or changed | one vague word where a figure existed | all figures exact |

## Case-specific must-checks
- **Case 1:** dimension 3 = 0 if option C's bulk-import defect (30% of updates bypass the cache) is absent or presented as minor. Dimension 2 = 0 if two of "TTL", "staleness", "write-through" appear before they are explained.
- **Case 2:** dimension 2 = 0 if "replica", "lag" or "sticky session" is never explained. Dimension 5 = 1 at most if it carries a full template (a "what the product asks" section and a comparison table for two options).
- **Case 3:** dimension 5 = 0 if it has per-option sections, a comparison table, or a named character replayed across sections. Dimension 4 = 0 if it is mostly bullet fragments.
- **Case 4:** dimensions 5 and 6 = 0 if it contains options, a comparison table or a recommendation. Dimension 1 = 0 if no single request is followed from intake to payout.
- **Case 5:** dimension 3 = 0 if the handwritten-scan limit (70% accuracy on 15% of volume, human check still needed) is absent or minimised. Dimension 6 = 0 if no open decision is phrased as a question.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_
TOTAL: _/14
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion, with the quoted passage>
