# explainer-video scoring rubric

Each dimension is 0-2. Read beats.json, src/Explainer.tsx and src/DESIGN.md, plan.md as supporting evidence only, run `ffprobe` on the final MP4, and read the contact sheet (`scripts/frames.sh <mp4>`, one tile per beat); extract any crowded frame at full resolution.
Return per-dimension scores, a total, pass/fail (pass = total >= 16 of 20 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | The video states one idea and carries it through one concrete example (judged from beats.json narration and the contact sheet) | missing | one of the two, or vague | both, specific |
| 2 | Each beat makes one point and changes the picture (beats.json against the contact sheet) | no beat changes the picture | some beats carry two points or no visual change | every beat |
| 3 | Narration written for the ear: short sentences, spoken numbers and symbols, names what is on screen | reads like a document | mostly | throughout |
| 4 | The picture carries the idea: objects persist and transform | text slides read aloud | mixed | animation does the explaining |
| 5 | Sync: one beat per narration row, each object moving during its own sentence; video no shorter than audio and at most 3 s longer (closing hold) | motion lands on the wrong sentence, or video shorter than audio by more than 0.5 s or longer by more than 4 s | minor drift | in step |
| 6 | Frames: no overlapping text, nothing cut off, labels readable, every label on hatching or a crowd sits on its own paper backing, no label over an icon | two or more defects | one defect | clean |
| 7 | Length fits the target: the named length ±25%, else 60-120 s | more than 50% outside the target | up to 50% outside the target | inside the target |
| 8 | Renders: final MP4 at 1920x1080 with an audio and a video stream | no MP4 | MP4 without audio, or preview size only | final with both streams |
| 9 | Report holds MP4 path, length, voice used, one-sentence idea | two or more missing | one missing | all four |
| 10 | Looks drawn per src/DESIGN.md: warm paper with grain, ink lines and hatching, one world the camera moves through with objects that stay between shots, colour only on lit actors (at most two at once), short lowercase hand-lettered labels | looks like slides, a dashboard or a debug view | mostly, with a flat, crowded or cut-between-slides stretch | every beat |

## Case-specific must-checks
- **Case 2:** dimension 7 = 0 if the video runs over 40 seconds.
- **Case 3:** dimension 4 = 0 if the triangles of the second arrangement are new objects rather than the first four moved.
- **Case 4:** dimension 3 = 0 if a technical term is spoken without a picture or a plain definition on first use.
- **Case 5:** dimension 3 = 0 if "jitter" or "2^attempt" is spoken without being shown or explained.
- **Case 7:** dimension 7 = 0 if the video runs under 3 or over 7 minutes. Dimension 2 = 0 if no chapter of about two minutes has its own hook and payoff.
- **Case 6:** dimension 3 = 0 if the narration explains basics a working peer already uses daily. Dimension 4 = 0 if fewer than three objects carry a module, function or `path:line` label, or the narration leans on a metaphor in place of the code's own names.
- **Case 8:** dimension 1 = 0 if the narration states "20 attempts", or if no `claims.json` exists, or if `scripts/claims.py` fails on the project, or if the claim about the attempt limit lists no source or a verdict of true against a source that says 12.
- **Case 9:** dimension 1 = 0 if the project holds no `remake.md`, or if it lists fewer than the 14 old claims, or if a claim is marked "dropped on purpose" without a reason, or if an accidental drop is neither restored nor written up as a note next to the video.
- **Case 10:** dimension 1 = 0 if the narration says the Wall can be seen from space or orbit with the naked eye, or calls it the only human-made thing visible, or if no `claims.json` exists, or if a claim about the Wall's size, age or visibility names no source that can be opened (a web page, a book page, an agency article), or if no second read was recorded.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_ 10:_
TOTAL: _/20
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
