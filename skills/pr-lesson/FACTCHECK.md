# Fact-check a written lesson

`check-record.py` proves that each cited line exists. It does not prove that the sentence about that line is true. So an agent that did not write the lesson reads every sentence against the code. Hand this file to a fresh agent with the record's path, the store and the checkouts. The agent that wrote the record never runs it.

1. **Read** the record, its area file (`<store>/areas/<area>.json`) and `RECORD.md`. Done when you know which commit each citation is read at.

2. **Check each sentence about the code before the change.** Open its citation with `git -C <checkout> show <sha>:<path>`, read 15 lines on each side, and open the functions that line calls when the sentence is about their effect. Check, in this order: every step's `text` and `label`; every cell of `state`; every node, the `title` and the `caption` of the area map; then `intro`, `screen`, `no_screen` and the other captions, each claim against a line you opened. Done when every sentence has a verdict and a line that decides it.

3. **Check each sentence about the change.** Read the diff with `gh pr diff <number> -R <owner/repo>`. Check `headline` and every paragraph of `guess.answer` against it. A statement that a person can now do something is true only when this diff alone makes it reachable. Done when each has a verdict and the diff line that decides it.

4. **Judge strictly.** A sentence is false when a reader who trusts it predicts the wrong behaviour. Test a count against the full list. Test "every", "each", "all", "only", "always" and "never" against every case, not the one the path follows. Test a time, a limit and a unit against the line that sets it. A plain word must name what the code does: say what is spent, removed, skipped or delayed, as the code does it.

5. **Correct.** Rewrite each false sentence where it lives, the record or the area file, to say what the code does, within the limits of `RECORD.md` and in literal English. Leave a true sentence as it is. Move a citation only when a true sentence points at the wrong line.

6. **Record the check.** Set `"factcheck": {"sentences": <how many you checked>, "corrected": <how many you rewrote>}` in the record. Write `<store>/work/<slug>.factcheck.md` with one line per correction: the field, the sentence before, the sentence after, and the `file:line` that decides.

7. **Check and render.** Run `scripts/check-record.py` until it exits 0, then `scripts/render.py <record> --home <store>`. When you changed the area file, render again every other record that the area's `lessons` name, from `<store>/records/`. Done when each render printed its row. Reply `OK <corrected> of <sentences>`.
