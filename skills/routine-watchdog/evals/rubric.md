# routine-watchdog scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 9 of 10 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Every flagged routine named individually | flagged routines merged into one vague statement | some named, one dropped or merged | each flagged label is named with its own evidence, never merged with another |
| 2 | Evidence quoted, not paraphrased away | evidence dropped or replaced with a vaguer restatement | evidence present but trimmed to the point of losing the cause | the tail/log path/PATH value from the input appears in the reading, verbatim or near-verbatim |
| 3 | "Not loaded" kept separate from the four numbered checks | reported with the same severity as a nonzero exit regardless of context, or softened regardless of context | flagged as different but without using the job's context to justify the reading | named as outside checks 1-4, and the job's context given is used to reach the reading it supports (ambiguous, or a real problem with that evidence cited) |
| 4 | All-healthy stays flat | invents a caveat, a "minor concern," or a suggestion when nothing was flagged | mostly flat but adds one unearned hedge | one plain sentence, no padding, when the input is the healthy line |
| 5 | Root cause named, not the symptom | "the script crashed" or "a bug in the routine" for a PATH/schedule finding | correct cause named but buried under generic troubleshooting advice | names the actual mechanism (PATH gap, schedule vs. log age ratio) as the check itself already states it |

## Case-specific must-checks
- **Case 1:** dimension 1 = 0 if either label or its own tail is dropped or merged away. A shared-cause guess is allowed when labelled as a hypothesis.
- **Case 2:** dimension 4 = 0 if any concern, hedge, or next step is added.
- **Case 3:** dimension 3 = 0 if migrate-once is called broken or failed outright.
- **Case 4:** dimension 5 = 0 if the "~1m schedule" context is dropped, making the 3-day staleness look mild.
- **Case 5:** dimension 5 = 0 if the reading blames weekly-weeding's code instead of the plist's PATH.
- **Case 6:** dimension 3 = 0 if the reading calls the job ambiguous or expected to be unloaded, or omits the evidence that it should be loaded.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_
TOTAL: _/10
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
