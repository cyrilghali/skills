# Mutation operators and report format

## Operators that pay

Each row is a fault a real regression could introduce. Start with the rows that touch the riskiest logic in the diff.

| Family | Mutants |
|---|---|
| Comparison and bounds | `>=` to `>`, `<` to `<=`, `==` to `!=`; off-by-one on a constant or an index; flipped sign |
| Guards and filters | delete a guard clause, an early return, a filter or a `where` condition; invert a negation |
| Domain values | swap two enum values, status strings, event names or keys the code maps |
| Arithmetic | `+` to `-`, `*` to `/`, a constant or a default value changed |
| Side effects | skip a write, an emit or a call; apply it to the first item of a list only |
| Query strings (SQL and similar) | drop a `WHERE` or `JOIN` condition; `ASC` to `DESC`; `EXISTS` to `NOT EXISTS`; drop `LIMIT` or `DISTINCT`; change a `PARTITION BY` or `GROUP BY` column; widen an interval; null-safe equality to `=` |

Query strings are prime targets: they parse, they compile inside the host language, and tests rarely pin every clause.

## Report

Write for someone who has not seen the run. One sentence on the method, the score, then only the real survivors, each as "what survives, and the assertion that would kill it", located by `file:line`. Cosmetic survivors get a count. Killed mutants share one line that names the test behind each kill, so every verdict traces to a run. No table of every mutant, no empty section. With zero real survivors, the report is two lines plus the final status.

```markdown
**Mutation testing.** I changed the branch's new code in N places (removed filters, flipped comparisons, swapped values) and checked that a test fails each time. Score: K/N killed.

Baseline: `<test command>` green, T tests. Killed: <mutant> by <test>; <mutant> by <test>; ...

M survivors would let a real bug ship:

- `path/file.ext:LINE`: <the mutation, in one clause> fails no test.
  Assertion to add: <the concrete test that would kill it>.

Production bug suspected: <behavior, file:line, why it looks wrong>. Not fixed, not asserted.

Cosmetic survivors left out: C.

Final `git status --porcelain`: <output, identical to the start>
```

Drop the "Production bug suspected" line when there is none.

## Several branches

Score each branch (killed out of total) and give an overall score. List real survivors per branch, each with the production bug it would hide.
