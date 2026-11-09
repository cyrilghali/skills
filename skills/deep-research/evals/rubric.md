# deep-research scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail (pass = total >= 14 of 18 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Answer first, as the first sentence, with its status | buried or absent | present but late or unstatused | first sentence, statused |
| 2 | Every cited link was read (the claim quotes or paraphrases what the page says) | a link the page does not support | one weak anchor | every link anchored |
| 3 | Load-bearing claims triangulated or marked single-source | a decisive claim on one unnamed source | one claim unmarked | every claim statused |
| 4 | Vendor bias named | a vendor claim reported as fact | bias line present but incomplete | each vendor claim flagged |
| 5 | Disagreement reported, not averaged | contradiction hidden | mentioned without both sides | both sides with dates and sources, or none invented where the sources agree |
| 6 | Numbers carry date and source | undated numbers | some dated | all dated and sourced |
| 7 | Proportion: stops when widening stops paying | padded with redundant sources, or one source where two were needed | slightly off | fits the question |
| 8 | Register: written in the question's language, answer reachable without the process trail, one why, details scannable in a table | two or more breaches | one breach | clean |
| 9 | Honesty on the unknown | invented or laundered | hedged into vagueness | what is unknown is stated as unknown, with the nearest real figure and what it measures |

A dimension the case does not reach (no unknown, no disagreement, no vendor) scores 2 when the artifact invents none. Em dashes, bold emphasis and heading style are a non-scoring lint note, never a deduction.

## Case-specific must-checks
- **Case 1:** dimension 5 = 0 if one brand is declared the winner without the competing claim; dimension 2 = 0 unless at least one independent tester's own test page (not a brand page or a retailer listing) is among the read sources.
- **Case 2:** dimension 7 = 0 if more than three sources are cited; dimension 2 = 0 if the documentation page is not the primary source.
- **Case 3:** dimension 9 = 0 if a percentage is given as the answer; dimension 9 = 2 only if the nearest published figure is named with what it measures.
- **Case 4:** dimension 3 = 0 unless the lock claim carries two independent sources; dimension 2 = 0 if the PostgreSQL documentation is absent.
- **Case 5:** dimension 9 = 0 if any web page is cited as answering the internal question; dimension 4 and 6 score 2 when the artifact correctly cites nothing.
- **Case 6:** dimension 7 = 0 if more than three sources are cited; dimension 2 = 0 if the official EU text is not the primary source; dimension 8 = 0 if the artifact is not in French; dimensions 5 and 9 score 2 when the artifact invents no dispute or unknown.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
