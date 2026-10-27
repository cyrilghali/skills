# make-video eval cases

Each case gives a generation agent everything it needs without asking questions.
The agent applies `SKILL.md` in its own empty folder, starting from the case's finished `beats.json` in `fixtures/`, and returns the report from step 7.
A judge scores the folder (plan.md, beats.json, src/Explainer.tsx, the final MP4 and its contact sheet) against `rubric.md`.
The `Trap` field names the failure mode the case is designed to catch.

## Case 1 — a classic algorithm

**Source:** synthetic, the request shape from the post that prompted this skill ("Create a 3b1b style video explainer on X").
**Input:** Create a 3b1b style video explainer on binary search. The narration is done: `beats.json`.
**Context (pre-answered):** Fixture: `fixtures/case-1-binary-search.json`. Audience is a junior developer. About 45 seconds.
**Trap:** Slides of bullet text read aloud, instead of an array that shrinks on screen as the voice speaks.

## Case 2 — a tiny request

**Source:** synthetic.
**Input:** Make me a 20 second video showing what 25% of something means, from this narration.
**Context (pre-answered):** Fixture: `fixtures/case-2-quarter.json`. For a ten-year-old.
**Trap:** Padding a 20-second ask with a title card, an intro or long holds until it runs well past 20 seconds.

## Case 3 — a geometric proof

**Source:** synthetic.
**Input:** Animate why the Pythagorean theorem is true, and show the formula a² + b² = c². Here is the voiceover.
**Context (pre-answered):** Fixture: `fixtures/case-3-pythagoras.json`. Audience is a curious adult. About 45 seconds.
**Trap:** Fading the triangles out and drawing new ones for the second arrangement, so the viewer never sees the same pieces move.

## Case 4 — a non-technical viewer, high stakes

**Source:** synthetic.
**Input:** I need a one minute video explaining how HTTPS keeps a password safe on the way to a website, for our board of directors. The script is approved.
**Context (pre-answered):** Fixture: `fixtures/case-4-https.json`. The board is not technical. It will be shown in a meeting.
**Trap:** Terms the voice defines (handshake, certificate, key) appear as text on screen with no picture, or text walls the board must read.

## Case 5 — a mechanism with a hidden moving part

**Source:** synthetic.
**Input:** Do a video explainer of how our job runner retries failed jobs, from this narration.
**Context (pre-answered):** Fixture: `fixtures/case-5-retries.json`. Audience is a new engineer on the team. About 50 seconds.
**Trap:** The doubling wait and the jitter are spoken but nothing on screen shows the wait grow or the crowd of jobs spread out.

## Case 6 — a technical viewer asks about their own code

**Source:** real use: an engineer asked for a video on the core of their policy engine and judged the first, fully abstract version as unusable because nothing on screen pointed back to the source.
**Input:** Make a video of how the retry scheduler in this repo works, from this narration.
**Context (pre-answered):** Fixture: `fixtures/case-6-scheduler.json`. The viewer works in this code daily. Fact sheet: `Runner.Worker.perform` at `lib/runner/worker.ex:31`, `Retry.Scheduler.plan` at `lib/retry/scheduler.ex:12`, `Retry.Backoff.compute` at `lib/retry/backoff.ex:8`, `Retry.Scheduler.give_up` at `lib/retry/scheduler.ex:40`. About 45 seconds.
**Trap:** A simplified picture with toy shapes and no module, function or `path:line` label on screen, so the viewer cannot map the video back to the files.

## Case 7 — a long episode of a series

**Source:** real use: an engineer making a 4 to 9 minute onboarding series judged the first episode, built as glowing cards on a dark background, as slides, and kept the remake drawn in ink on paper with one world the camera moves through.
**Input:** Make episode 2 of our onboarding series: how a public library lends a book, from the reader asking for it to the book coming back to the shelf. The narration is final, about four minutes.
**Context (pre-answered):** Fixture: `fixtures/case-7-library.json` (three chapters and a preview beat). The viewer is a new library volunteer. The series looks hand-drawn; no other style guide.
**Trap:** A slide deck of cards that cut from one to the next instead of one drawn world the camera travels through, chapter by chapter.
