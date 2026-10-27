# video-script scoring rubric

Read the case entry, the fixture files, every file in the output folder and `reply.md` (the agent's final reply). Judge the narration in `beats.json` first; when it is missing, judge the narration wherever the output holds it and score dimension 11 at 0.

Each dimension is 0-2. Return per-dimension scores, a total, pass/fail (pass = total >= 18 of 22 AND no dimension at 0), and one concrete fix per dimension under 2.

Terms used below:
- **Brief fact:** a row of the brief's "Facts this unit must say" table. In case 5, which has no brief, read it as: a fact the narration states.
- **Sourced:** found in the brief, in the fixture source, or in an external source the output names that a reader could open. A claim with none of these, stated as fact, is unsourced.
- **Reported:** named in plain words in `reply.md` or in a notes file in the output folder. A field inside a data file that the user would have to dig for does not count.
- **On-screen words:** text the viewer reads on screen. A description of the picture is not on-screen words; when on-screen labels sit inside such a description, score the labels, and when none can be told apart, score dimension 8 at 0.
- **Word count:** the words of the narration only, at 2.5 spoken words a second. On-screen words do not count.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | Every brief fact is said in the narration, and said correctly (as the source has it) | two or more missing or wrong | one missing, wrong or blurred into something vaguer | all said and correct |
| 2 | No unsourced claim is stated as fact | a number, date, name or causal claim with no source | an unsourced claim that is minor and true | every claim sourced |
| 3 | A premise that the source contradicts (in the brief, the request or a hedged line of the source) is not narrated as fact, and the conflict is reported. When the case plants no conflict, score 2 unless the narration states something its source contradicts | the false premise is narrated as fact | corrected in the narration but not reported | corrected and reported |
| 4 | One idea, carried by one concrete example the viewer can picture | no single idea, or no concrete example | the idea or the example is vague, or the example changes midway | both, specific |
| 5 | Each beat holds one point in one or two sentences, and the beats read aloud in order as one story | a list of facts, or most beats hold three or more sentences | some beats carry two points or three sentences, or the order breaks | every beat |
| 6 | Each term this audience does not know is defined in plain words at its first use, in narration or on screen | two or more terms undefined | one term undefined, or defined one beat late | every term defined, or none needed |
| 7 | Facts the audience already has are recalled in a clause, never taught again. When the brief lists none, score against what its audience line says the viewer knows | an already-known fact gets its own beat or more | an already-known fact gets more than a clause | recalled briefly, or not needed |
| 8 | On-screen words are short labels, numbers or names that the narration says in that beat | missing, or full sentences | some too long, or not said in the narration | all short and said |
| 9 | Length fits the target (the brief's length, or the length the output states in case 5) within ±25% | more than 50% off | 25% to 50% off | within ±25% |
| 10 | The narration is plain spoken text: no Markdown, brackets, stage directions, symbols or code; numbers and symbols written as they are said | reads like a document | one or two lapses | throughout |
| 11 | The narration is handed over as `beats.json`: a JSON list of objects holding only `id` and `text`, unique ids, in story order | missing or not valid JSON | valid but with extra fields, duplicate ids or a beat out of order | valid |

Taste is not scored: the form of the hook, whether a character appears, the number of chapters and the visual style score nothing unless a case's brief asks for them.

## Case-specific must-checks

- **Case 1:** dimension 3 = 0 if the narration states twenty attempts as the limit. Dimension 3 = 1 if it says twelve without reporting that the brief's f11 says 20 and its source says 12. Dimension 1 counts f11 as said and correct only when it says twelve. Dimension 10 = 0 if `2^attempt`, `max_attempts` or a caret appears in the narration; dimension 6 = 0 if "jitter" or "discarded" is spoken with no plain meaning.
- **Case 2:** dimension 7 = 0 if any of f01 to f06 gets a beat of its own, or if the first three beats spend more than one sentence on what an antigen, an antibody or a B cell is. Dimension 6 = 0 if "affinity maturation" or "secondary response" is spoken with no plain meaning (using neither is fine).
- **Case 3:** dimension 6 = 0 if two or more of Saccharomyces, glycolysis, amylase, glutenin, gliadin, viscoelastic, gelatinise or coagulate appear in narration or on screen without a plain meaning; = 1 if one does. "Gluten" and "oven spring" count as terms to define. Dimension 8 = 0 if any on-screen text runs past eight words.
- **Case 4:** dimension 9 = 0 if the narration holds more than 112 words (45 seconds); = 1 from 95 to 112 words. Dimension 4 = 1 at most if the narration holds a beat on why recycling matters, a recap or a call to action. Dimension 2 is not lowered for an extra source fact; dimension 9 catches it.
- **Case 5:** dimension 1 scores whether every fact narrated matches the source, and whether the output states the audience, the one idea and the length it chose. Dimension 1 = 1 at most if it does not state those three. Dimension 3 = 0 if the narration says Rowe pulled the figurehead from the harbour, or that it was the first object, without marking it as a legend. Dimension 2 = 0 for any date, name or number that the source does not hold.
- **Case 6:** dimension 1 = 0 if two or more of the 14 caption facts are missing or blurred, and = 1 if one is; "alphabetically by last name", "every Friday", "within 24 hours", "seven days", "three times a day" and "by floor" each count as a fact detail that must survive.

## Output format (return exactly this)

CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_ 10:_ 11:_
TOTAL: _/22
VERDICT: PASS | FAIL
WORDS: <narration word count>
FIXES:
- dim <n>: <one concrete rewrite suggestion>
