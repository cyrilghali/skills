# video-script eval cases

Each case gives a generation agent everything it needs without asking questions.
The agent works in its own empty folder holding only the case's fixture files, applies `SKILL.md` (or no skill, for the baseline), and writes its output there. Its final reply is saved beside the output as `reply.md`.
A judge scores the folder and the reply against `rubric.md`, with the fixture source open.
The `Trap` field names the failure mode the case is designed to catch.

Every Input names `beats.json` as the hand-over, because the next step of a real pipeline reads that file and its user knows so. The schema (only `id` and `text`) and the rules for on-screen words are left to the skill.

Speaking rate for every length check: 2.5 spoken words a second (150 a minute). Only narration words count; on-screen words do not.

Larkmoor City and the Harbour Museum of Port Ellery are fictional. Their fixture is the only source; the judge does not search the web for them. The other sources hold mainstream facts that a judge may check.

## Case 1 — a brief fact its own source contradicts

**Source:** real use: an onboarding episode was voiced with a count that its source document had already changed, and nobody noticed until a person re-read it.
**Domain:** software.
**Input:** Here's the brief for the retries episode of our onboarding series, `brief.md`, with its source notes in `source.md`. Write the narration and the on-screen words for each beat, and hand the narration over as `beats.json` for the video step.
**Fixture:** `fixtures/retries/` (`brief.md`, `source.md`).
**Context (pre-answered):** Fact f11 in the brief says the runner gives up after 20 attempts. `source.md`, which f11 cites, says 12, and that 20 was the old default.
**Trap:** The narration says 20 because the brief says so, or says 12 without telling the user that the brief was wrong. A second trap rides along: the source's shorthand (`2^attempt`, jitter, `discarded`, `max_attempts`) is read aloud as written.

## Case 2 — a deep dive whose viewer already knows the basics

**Source:** synthetic.
**Domain:** biology (public health).
**Input:** Next up in the vaccine series is the immune memory episode. Brief is `brief.md`, reviewer notes in `source.md`. Can you write what it says, beat by beat, with the on-screen words, and give me the narration as `beats.json`?
**Fixture:** `fixtures/immune-memory/` (`brief.md`, `source.md`).
**Context (pre-answered):** The brief's second table lists six facts taught in the two earlier episodes: antigens, what a vaccine shows the body, B cells and antibodies, what antibodies do, clonal growth, T cells.
**Trap:** The script spends its opening beats teaching again what an antigen, an antibody or a B cell is, so the new idea (memory makes the second response faster and stronger) gets squeezed or arrives late.

## Case 3 — a standalone overview for non-specialists, from a jargon-heavy source

**Source:** synthetic.
**Domain:** cooking.
**Input:** I'm making a one-minute video for home bakers on why bread rises. The brief is in `brief.md` and the course handout it's based on is `source.md`. Write the narration with what goes on screen per beat, and save the narration as `beats.json`.
**Fixture:** `fixtures/bread/` (`brief.md`, `source.md`).
**Context (pre-answered):** The source uses Saccharomyces cerevisiae, glycolysis, amylase, glutenin, gliadin, viscoelastic, proofing, gelatinises and coagulate. The audience has no chemistry.
**Trap:** Source terms reach the narration or the screen undefined, or the on-screen words are full sentences copied from the handout instead of short labels the narration says.

## Case 4 — a 30-second ask

**Source:** synthetic.
**Domain:** city services.
**Input:** The council wants a 30 second clip for social media on how the sorting plant handles blue-bin recycling. Brief: `brief.md`; the council page: `source.md`. Write it, beats plus on-screen words, narration as `beats.json`.
**Fixture:** `fixtures/recycling/` (`brief.md`, `source.md`).
**Context (pre-answered):** The brief asks for three facts. The source also holds collection days, paper screens, glass, a 17% contamination figure and what happens to bales, none of which the brief asks for.
**Trap:** The 30 seconds grow into a minute: a hook, a "why recycling matters" beat, the extra source facts, a recap or call to action. Each extra fact is sourced, so only the length and the one idea catch it.

## Case 5 — a topic with no brief

**Held out:** yes
**Source:** synthetic.
**Domain:** local history.
**Input:** We're putting a short narrated video on the screen in the museum lobby about how the museum started. All I've got is the history page from our website, `source.md`. Can you write it? The video tool takes the narration as `beats.json`.
**Fixture:** `fixtures/museum/` (`source.md` only).
**Context (pre-answered):** No brief, audience line, idea or length is given. Lobby visitors are the general public and the video must stand alone.
**Trap:** The source reports a local legend (the founder pulled the Marianne figurehead from the harbour) and says no record confirms it. The script states the legend as fact, or adds dates, names or numbers from nowhere to fill out the story. With no brief, the script also has no stated audience, idea or length to be judged against.

## Case 6 — a shorter remake that must keep every fact

**Held out:** yes
**Source:** real use: a remake of a series episode lost 34 in-scope facts, which a later audit of the old captions found.
**Domain:** library operations.
**Input:** Episode 3 of the volunteer series is too long. Remake it at about 75 seconds; the brief is `brief.md`, the current narration is `old/captions.srt` and the head librarian's notes are `source.md`. I need the new narration as `beats.json` with on-screen words per beat.
**Fixture:** `fixtures/returns/` (`brief.md`, `source.md`, `old/captions.srt`).
**Context (pre-answered):** The old narration states 14 facts, one per caption, and runs about 110 seconds. Each matches a numbered line of `source.md`. 75 seconds is about 188 words, which is enough for all 14 when each is said once.
**Trap:** Trimming drops or blurs facts with no list of what changed: "alphabetically by the author's last name", "every Friday", "within 24 hours" or "seven days" vanish, or two facts merge into one that says less.
