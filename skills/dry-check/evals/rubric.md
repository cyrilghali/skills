# dry-check scoring rubric

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail
(pass = total >= 14 of 18 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Only pairs with a side on a line the branch added | lists pairs the branch did not touch, or misses a branch pair | one stray or one missed pair | exactly the branch's pairs |
| 2 | One row per pair, marked NEW, NEW rows first | one row per tool issue, or no NEW mark | marked but unordered or doubled once | one row per pair, ordered |
| 3 | Both locations as file:start-end | one side missing | a start line only | both sides with a span |
| 4 | Fix names a shared helper or reuse and the module both sides reach | no fix | "extract a function" with no home | helper, home module and call sites |
| 5 | Final line `new=<N> threshold=<score> min_lines=<L>` | absent | present, a field wrong | exact |
| 6 | Right tool and run shape for the language | wrong tool, or a path argument to the Elixir check, or `--changed` | works but only the changed files are compared | whole source tree compared, filtered to branch lines |
| 7 | Repo left byte-identical | leaves tool output in the repo or edits a tracked file | removes it only afterwards | never writes there |
| 8 | Gate record written for the head commit | no record | record with a wrong first line or path | `new=<N>` first line, one line per NEW row, correct path |
| 9 | Honest scope | claims more than the tool proved (exact Elixir match called "similar", a branch called fully checked) | one overclaim | states the limit and the sibling checks to run |

## Case-specific must-checks
- **Case 1:** dimension 1 = 0 if the older `parse_header/1` pair appears. Dimension 2 = 0 if the pair appears as two rows.
- **Case 2:** dimension 1 = 0 if the 4-line pair is reported or the minimum is lowered.
- **Case 3:** dimension 8 = 0 if no record is written; dimension 1 = 0 if any old pair is listed.
- **Case 4:** dimension 6 = 0 if `--changed` is used. Dimension 7 = 0 if `.metrics/` is left behind. The score must read 0.93, not 1.0.
- **Case 5:** dimension 9 = 0 if the sibling checks (`crap-check`, `mutation-test`) go unmentioned. Dimension 4 = 0 if the fix edits only one loader.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
