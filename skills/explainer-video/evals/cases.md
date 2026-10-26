# explainer-video eval cases

Each case gives a generation agent everything it needs without asking questions.
The agent applies `SKILL.md` in its own empty folder and returns the report from step 8.
A judge scores the folder (plan.md, beats.json, src/Explainer.tsx, the final MP4 and its contact sheet) against `rubric.md`.
The `Trap` field names the failure mode the case is designed to catch.

## Case 1 — a classic algorithm

**Source:** synthetic, the request shape from the post that prompted this skill ("Create a 3b1b style video explainer on X").
**Input:** Create a 3b1b style video explainer on binary search.
**Context (pre-answered):** Audience is a junior developer. No length given.
**Trap:** Slides of bullet text read aloud, instead of an array that shrinks on screen as the voice speaks.

## Case 2 — a tiny request

**Source:** synthetic.
**Input:** Make me a 20 second video showing what 25% of something means.
**Context (pre-answered):** For a ten-year-old.
**Trap:** Inflating a 20-second ask into a two-minute lecture with a hook, a general rule and a recap.

## Case 3 — a geometric proof

**Source:** synthetic.
**Input:** Animate why the Pythagorean theorem is true, and show the formula a² + b² = c².
**Context (pre-answered):** Audience is a curious adult.
**Trap:** Fading the triangles out and drawing new ones for the second arrangement, so the viewer never sees the same pieces move.

## Case 4 — a non-technical reader, high stakes

**Source:** synthetic.
**Input:** I need a 2 minute video explaining how HTTPS keeps a password safe on the way to a website, for our board of directors.
**Context (pre-answered):** The board is not technical. It will be shown in a meeting.
**Trap:** Jargon (handshake, certificate, symmetric key) used without a picture or a plain definition, or text walls the board must read.

## Case 5 — written from inside a project

**Source:** synthetic.
**Input:** Do a video explainer of how our job runner retries failed jobs: it waits 2^attempt seconds plus jitter, max 20 attempts, then moves the job to the discarded state.
**Context (pre-answered):** Audience is a new engineer on the team.
**Trap:** Repeating the input's shorthand ("2^attempt", "jitter", "discarded state") in the narration without showing or explaining it.

## Case 6 — a technical viewer asks about their own code

**Source:** real use: an engineer asked for a video on the core of their policy engine and judged the first, fully abstract version as unusable because nothing on screen pointed back to the source.
**Input:** Make a video explaining how the retry scheduler in this repo works: which module plans the next attempt, where the backoff is computed, and where a job is given up.
**Context (pre-answered):** The viewer is the engineer who asked, and works in this code daily. The agent gets a short fact sheet with module names, function names and `path:line` references.
**Trap:** A simplified picture with toy metaphors ("imagine a mailbox") and no module, function or `path:line` label on screen, so the viewer cannot map the video back to the files.

## Case 7 — a long episode of a series

**Source:** real use: an engineer making a 4 to 9 minute onboarding series judged the first episode, built as glowing cards on a dark background, as slides, and kept the remake drawn in ink on paper with one world the camera moves through.
**Input:** Make episode 2 of our onboarding series: how a public library lends a book, from the reader asking for it to the book coming back to the shelf. About five minutes.
**Context (pre-answered):** The viewer is a new library volunteer. The series looks hand-drawn; no other style guide.
**Trap:** One five-minute run with no chapter structure, so the middle drags, or a slide deck of cards that cut from one to the next instead of one drawn world.

## Case 8 — a fact-check trap

**Source:** real use: an onboarding-series episode was voiced from a source document that the narration had drifted away from (a count and a default value were wrong), and nobody noticed until a person re-read it.
**Input:** Make a 90 second video on how our job runner retries failed jobs, for a new engineer. The source is `retry.md`, in the working folder.
**Context (pre-answered):** `retry.md` says: the runner waits 2^attempt seconds plus jitter, gives up after 12 attempts (the default is 12, not 20), and moves the job to `discarded`. The task message also says "20 attempts", from an older version.
**Trap:** The narration repeats "20 attempts" from the request without reading `retry.md`, and no claims file exists, or `claims.json` lists the claim as true with the source left blank.

## Case 9 — a remake

**Source:** real use: a remake of a series episode lost 34 in-scope facts that a later audit of the old captions found.
**Input:** Remake episode 3 of our onboarding series, shorter and in the drawn look. The old version's captions are in `old/captions.srt`; its source document is `episode.md`.
**Context (pre-answered):** The old captions hold 14 distinct factual claims. The new cut must be about 3 minutes instead of 5.
**Trap:** The new narration silently drops claims while trimming, with no list of what the old version said, so lost facts are never noticed.

## Case 10 — a topic with no code and a popular myth in the request

**Source:** real use: the fact check was first built for videos about a codebase; the owner asked that it hold for any topic, because the source is not always code.
**Input:** Make a 90 second explainer for ten-year-olds: the Great Wall of China is the only human-made thing you can see from space with your own eyes. Show why it is so easy to spot.
**Context (pre-answered):** No source document is given; the agent may search the web. No style guide beyond the skill.
**Trap:** The narration repeats the premise of the request as fact, or states history and sizes from memory, with no source anyone could open and no second reader.
