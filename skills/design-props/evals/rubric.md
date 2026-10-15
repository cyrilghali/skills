# design-props scoring rubric

Score each dimension 0, 1 or 2. Every penalty quotes the exact passage at fault, or names the exact thing missing. A penalty without a quote does not count.

Read the case (input, context, trap) first, then the study, then score.

## Grid

Pass is a total of 14 or more out of 18, with no dimension at 0.

| # | Dimension | 0 | 1 | 2 |
|---|---|---|---|---|
| 1 | Feasibility per requirement | no per-requirement verdict | verdicts without reasons, or some requirements skipped | every requirement gets feasible, degraded or impossible, with the fact behind it |
| 2 | Load-bearing assumption | the case's false or limiting fact is swallowed | it is mentioned but the designs ignore it | it is named first, checked against the given facts, and every option is judged against it |
| 3 | Distinct philosophies | two or more options share one write strategy | options differ but no "change nothing" contender | each option is a different strategy, and a minimal contender is present |
| 4 | Shared template | options are described in different shapes | one template, but sections missing for some options | every option fills the same sections, including a caller sketch with public signatures, state or data model, write paths and migration |
| 5 | Costs and limits | an option has neither cost nor limits | costs or limits given, not both, or costs without an order of magnitude | each option has order-of-magnitude costs and a stated list of limits it accepts |
| 6 | Extensibility against the stated roadmap | a vague score ("extensible: yes") | some roadmap items checked | each stated future need is checked per option as native, simple extension or rewrite |
| 7 | Critique fits the design | no critique | critique uses data-design terms on a non-data design, or skips correctness | each option is attacked on codebase facts, roadmap and correctness or performance in the design's own terms |
| 8 | The real choice | a table with no cross-reading | the choice is named, but convergences or the option that keeps others open are missing | the real choice is named with its reason, convergences are listed, and the study says which option keeps the others open, or that none does |
| 9 | Path and open questions | a recommendation with no trigger and no question | triggers or questions, not both; or a question a measurement could settle is handed to the reader | a phased path with explicit switch triggers, and only product or preference decisions left, phrased as questions |

### Case-specific must-checks
- **Case 1:** dimension 2 is 0 if any 30-day metric is called feasible from current data.
- **Case 2:** dimension 3 is 0 if two options are both audit-table shapes; dimension 6 is 0 if two-year retention or permission groups go unchecked.
- **Case 3:** dimension 8 is 0 if the study ends on a table without naming what to do; dimension 9 is 0 without a numeric switch trigger.
- **Case 4:** dimension 9 is 0 if "CTE or materialized" appears among the decisions left to the reader. It scores 2 only if a measurement was run, or an exact protocol is given (data shape, metric, the 2,000 per second threshold) and the synthesis is conditioned on it. Dimension 4 is 0 if any option lacks the `effective_permissions(user_id)` caller sketch.
- **Case 5:** dimension 2 is 0 if "no loss after close" is called feasible on the mobile webview. Dimension 7 is at most 1 if the critique talks about tables or queries instead of tab concurrency and resync against an unversioned API.


## Output format (return exactly this)

```
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete fix, quoting the passage at fault>
```
