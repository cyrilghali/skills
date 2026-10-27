# make-video scoring rubric

Each dimension is 0-2. Read beats.json against the case's fixture, src/Explainer.tsx and src/DESIGN.md, plan.md as supporting evidence only, run `ffprobe` on the final MP4, and read the contact sheet (`scripts/frames.sh <mp4>`, one tile per beat); extract any crowded frame at full resolution.
Return per-dimension scores, a total, pass/fail (pass = total >= 16 of 20 AND no dimension at 0), one concrete fix per dimension under 2.

| # | Dimension | 0 | 1 | 2 |
|---|-----------|---|---|---|
| 1 | The narration is voiced as given: every beat of the fixture, in order, word for word | beats added, cut or rewritten | one beat changed | verbatim |
| 2 | Each beat changes the picture, and what the voice names is what moves (beats.json against the contact sheet) | no beat changes the picture | some beats show no change, or move something the voice does not name | every beat |
| 3 | On-screen words: only words the narration says, short, each appearing as the voice nears it (the render's `SHOWN:` lines) | text walls or words the voice never says | one long or early text | throughout |
| 4 | The picture carries the idea: objects persist and transform | text slides read aloud | mixed | animation does the explaining |
| 5 | Sync: one beat per narration row, each object moving during its own sentence; video no shorter than audio and at most 3 s longer (closing hold) | motion lands on the wrong sentence, or video shorter than audio by more than 0.5 s or longer by more than 4 s | minor drift | in step |
| 6 | Frames: no overlapping text, nothing cut off, labels readable, every label on hatching or a crowd sits on its own paper backing, no label over an icon | two or more defects | one defect | clean |
| 7 | Length follows the narration: the named length ±25%, with nothing added beyond the pause rule and the closing hold | more than 50% outside the target | up to 50% outside the target | inside the target |
| 8 | Renders: final MP4 at 1920x1080 with an audio and a video stream | no MP4 | MP4 without audio, or preview size only | final with both streams |
| 9 | Report holds MP4 path, length and voice used | two or more missing | one missing | all three |
| 10 | Looks drawn per src/DESIGN.md: warm paper with grain, ink lines and hatching, one world the camera moves through with objects that stay between shots, colour only on lit actors (at most two at once), short lowercase hand-lettered labels | looks like slides, a dashboard or a debug view | mostly, with a flat, crowded or cut-between-slides stretch | every beat |

## Case-specific must-checks
- **Case 2:** dimension 7 = 0 if the video runs over 30 seconds.
- **Case 3:** dimension 4 = 0 if the triangles of the second arrangement are new objects rather than the first four moved.
- **Case 4:** dimension 3 = 0 if any on-screen text holds more than six words. Dimension 2 = 0 if "handshake", "certificate" or "key" is spoken while nothing on screen pictures it.
- **Case 5:** dimension 2 = 0 if the doubling wait or the jitter is spoken while nothing on screen shows it.
- **Case 6:** dimension 4 = 0 if fewer than three objects carry a module, function or `path:line` label from the fact sheet.
- **Case 7:** dimension 7 = 0 if the video runs under 3 or over 6 minutes. Dimension 10 = 0 if a chapter opens on a cut to a new card instead of a camera move in the same world.

## Output format (return exactly this)
CASE: <n>
SCORES: 1:_ 2:_ 3:_ 4:_ 5:_ 6:_ 7:_ 8:_ 9:_ 10:_
TOTAL: _/20
VERDICT: PASS | FAIL
FIXES:
- dim <n>: <one concrete rewrite suggestion>
