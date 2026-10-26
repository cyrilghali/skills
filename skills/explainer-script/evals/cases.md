# explainer-script eval cases

Each case gives a generation agent everything it needs without asking questions.
The agent applies `SKILL.md` in its own empty folder, with the case's fixture files copied in, and returns its report.
A judge scores the folder (script.md, beats.json, claims.json, second-read.json and any remake.md) against `rubric.md`, and runs `scripts/claims.py <folder> --final` on it.
The `Trap` field names the failure mode the case is designed to catch.

## Case 1 — a tiny request

**Source:** synthetic.
**Input:** Write the narration for a 20 second video showing what 25% of something means.
**Context (pre-answered):** For a ten-year-old. No source document; the agent may search the web.
**Trap:** Inflating a 20-second ask into a two-minute lecture with a hook, a general rule and a recap.

## Case 2 — written from inside a project

**Source:** synthetic.
**Input:** Write the script for a video explainer of how our job runner retries failed jobs: it waits 2^attempt seconds plus jitter, max 20 attempts, then moves the job to the discarded state. The notes are in `jobs.md`.
**Context (pre-answered):** Audience is a new engineer on the team. Fixture: `fixtures/jobs.md`.
**Trap:** Repeating the input's shorthand ("2^attempt", "jitter", "discarded state") in the narration without explaining it in plain words.

## Case 3 — a fact-check trap

**Source:** real use: an onboarding-series episode was voiced from a source document that the narration had drifted away from (a count and a default value were wrong), and nobody noticed until a person re-read it.
**Input:** Write the narration for a 90 second video on how our job runner retries failed jobs, for a new engineer. The source is `retry.md`, in the working folder. It gives up after 20 attempts.
**Context (pre-answered):** Fixture: `fixtures/retry.md`, which says the limit is 12. The "20 attempts" in the request comes from an older version.
**Trap:** The narration repeats "20 attempts" from the request without reading `retry.md`, and no claims file exists, or `claims.json` lists the claim as true with the source left blank.

## Case 4 — a remake

**Source:** real use: a remake of a series episode lost 34 in-scope facts that a later audit of the old captions found.
**Input:** Rewrite the narration of episode 3 of our onboarding series, shorter. The old version's captions are in `old/captions.srt`; its source document is `episode.md`.
**Context (pre-answered):** Fixtures: `fixtures/old/captions.srt` (14 distinct factual claims) and `fixtures/episode.md`. The old cut runs nearly two minutes; the new one must run about 60 seconds.
**Trap:** The new narration silently drops claims while trimming, with no list of what the old version said, so lost facts are never noticed.

## Case 5 — a topic with no code and a popular myth in the request

**Source:** real use: the fact check was first built for videos about a codebase; the owner asked that it hold for any topic, because the source is not always code.
**Input:** Write a 90 second explainer script for ten-year-olds: the Great Wall of China is the only human-made thing you can see from space with your own eyes. Show why it is so easy to spot.
**Context (pre-answered):** No source document is given; the agent may search the web.
**Trap:** The narration repeats the premise of the request as fact, or states history and sizes from memory, with no source anyone could open and no second reader.
