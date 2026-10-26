# explainer-script scoring rubric

Each dimension is 0-2. Read beats.json and claims.json first, script.md and second-read.json as supporting evidence, run `scripts/claims.py <folder> --final`, and open at least three sources named in claims.json.
Return per-dimension scores, a total, pass/fail (pass = total >= 14 of 18 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | The narration states one idea and carries it through one concrete example | missing | one of the two, or vague | both, specific |
| 2 | Each beat holds one or two sentences and one point, in an order that reads aloud as one story | a list of facts | some beats carry two points or break the story | every beat |
| 3 | Written for the ear: short sentences, numbers and symbols spelled as spoken, each term explained in plain words on first use, plain text only | reads like a document | mostly | throughout |
| 4 | The structure fits the length: hook, case, build, rule and payoff for a full video, fewer parts for a short ask | a lecture structure forced on a short ask, or no structure in a long one | partly | fits |
| 5 | Length fits the target at about 2.6 spoken words a second: the named length ±25%, else 60-120 s | more than 50% outside | up to 50% outside | inside |
| 6 | Every claim traces to a source someone else could open, and `claims.py --final` passes | no claims.json, or the script fails | entries exist but a source is vague or unopened | every source opens and supports its verdict |
| 7 | A second reader that did not see the author's reasoning judged every claim, and each difference is resolved from the source | no second read | partial | complete |
| 8 | A premise in the request that the source contradicts is corrected in the narration and named to the user | repeated as fact | corrected silently | corrected and named |
| 9 | beats.json is valid: a list of `{"id", "text"}` with unique ids, text that a voice can read as is | invalid or missing | minor defects | valid |

## Case-specific must-checks
- **Case 1:** dimension 5 = 0 if the narration holds more than 104 words (40 seconds). Dimension 4 = 0 if it holds a separate recap or general-rule beat after the payoff.
- **Case 2:** dimension 3 = 0 if "jitter", "2^attempt" or "discarded state" is spoken without a plain explanation on first use.
- **Case 3:** dimension 6 = 0 if the narration states "20 attempts", or if no `claims.json` exists, or if the claim about the attempt limit lists no source or a verdict of true against a source that says 12.
- **Case 4:** dimension 6 = 0 if the folder holds no `remake.md`, or if it lists fewer than the 14 old claims, or if a claim is marked "dropped on purpose" without a reason, or if an accidental drop is neither restored nor written up as a note.
- **Case 5:** dimension 8 = 0 if the narration says the Wall can be seen from space or orbit with the naked eye, or calls it the only human-made thing visible. Dimension 6 = 0 if a claim about the Wall's size, age or visibility names no source that can be opened. Dimension 7 = 0 if no second read was recorded.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_
TOTAL: _/18
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
