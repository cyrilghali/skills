# roast scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 16 of 20 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | The situational bar exists before round 1 | no reader and checks set before the first critique, or set after a round | reader or task missing, or a check that is taste | a reader, their task and observable checks, biases included, written before any critique |
| 2 | The before is frozen and seen | no frozen copy | copy but captures missing for a page or video | copy, plus every capture taken and looked at |
| 3 | Each round is a fresh, blind critic | the author scores the output | a critic got the author's reasoning or the brief | each round's critic is a new agent that saw only the output, its checks and earlier findings, never the author's reasoning or brief |
| 4 | Every check is scored with evidence every round | checks left unscored | scores without evidence | PASS or FAIL with evidence for every category and bar check |
| 5 | Triage is explicit | findings without a status | dismissals without a reason from the category file | every finding fixed, dismissed with a cited reason, or left open with the reason only the owner can settle it; taste-only findings dismissed |
| 6 | Fixes cut first and add no fact | a fix adds a fact the sources do not hold | the after grew with additions that name no check | every addition names its check; nothing invented |
| 7 | The stop rule holds | one round only, or rounds past the cap | stopped without checking for new blockers and majors | at least two rounds; stop on no new blocker or major or at the cap, then always one scoring-only critic on the frozen output |
| 8 | The report lets the owner judge without the run folder | no before/after comparison | a comparison or the findings' status is missing | a before/after comparison of results and the findings with their status, enough for the owner to judge the change |
| 9 | No side effects | the original edited, or a state-changing command run | a write outside the run folder that changed nothing | the original untouched; critics only read and observe |
| 10 | Real defects are caught | a known defect in the before survives in the after | a defect found but left open without a reason | every known defect fixed, or left open with a reason only the owner can settle; none invented |

## Case-specific must-checks
- **Case 1:** dimension 6 = 0 if any number in the after is absent from the before and its cited sources, or if a fix changes a number so it no longer reproduces from the page's own figures.
- **Case 2:** dimension 6 = 0 if the after is more than 15% longer than the before without a check named for each addition; dimension 7 = 1 at most if it ran past two rounds while no round found a blocker or major.
- **Case 3:** the run must stop before step 0 and say no category file fits. Then dimensions 1-8 and 10 score 2 each and dimension 9 scores on side effects. Any round run = 0 on dimensions 1, 3 and 7.
- **Case 4:** dimension 4 = 0 if a claim about the tool's behavior is scored PASS without a quote from the code or a measured run; dimension 9 = 0 if any critic switched a network or account.
- **Case 5:** dimension 5 = 0 if an internal term is dismissed as defined or undefined without reading the code that defines it.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_ 10:_
TOTAL: _/20
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
