---
name: write-video-script
description: 'Writes what one narrated video says, beat by beat, from a brief or a bare topic: the narration, the few words shown on screen in each beat, and a fact check that ties every claim to a source. Writes script.md, beats.json (id and text only) and claims.json. Use when the user asks to write the script, narration or voiceover for an explainer or teaching video, to turn a brief or notes into beats, to fact-check a video narration against its source before recording, or to shorten or remake an episode without losing a fact.'
metadata:
  category: write
---

# Video script

Write what one video says, so it teaches one idea and every fact in it holds. The voice carries the explanation. The screen shows the picture and a few labels.

Three files sit beside this one:

- `BRIEF.md`: the brief this skill reads and the files it writes.
- `REFERENCE.md`: the rules backed by published research, with sources, and the claim check.
- `STYLE.md`: the default style (beat order, default length, tone). It is taste, not research. A user who has a house style replaces `STYLE.md` with their own file; the steps stay the same.

Work in one folder: `script.md`, `beats.json`, `claims.json`.

## Steps

1. **Read the brief.** With no brief, write its fields at the top of `script.md` under the headings `BRIEF.md` lists: the audience and what it already knows, whether the video stands alone, the one idea, the length, a `## Facts this unit must say` table (id, fact, source), and a `## Facts the viewer already has` table. Choose what the request leaves open, from the source and the place the video will play, and say so in the report. Unless the request or brief sets a length, take the default from `STYLE.md`.
   Open every source the brief cites and check each must-say fact against it. When they disagree, the narration says what the source says, and the report names the conflict. A claim is only as sure as its source: what the source hedges, the narration hedges or cuts.
   Set the word budget: seconds times 2.6 (`REFERENCE.md`, length). When the job remakes an earlier version, list its claims in `remake.md` now (`REFERENCE.md`, "Remaking a narration").
   Done when `script.md` holds every brief field, the word budget, and one line per conflict found.

2. **Plan the story.** Write four things in `script.md`:
   - the question the viewer cannot answer yet, which the video answers by its end;
   - one concrete case that carries the whole video: one specific thing the viewer can picture, followed from start to end, never a generic "a user" or "a thing";
   - the wrong idea this audience likely holds, when the source gives one;
   - a plain-words definition for each term the audience does not know, and a short cue for each known fact the story needs.

   Done when all four are written.

3. **Write the beats.** In `script.md`, make one row per beat:

   | id | narration | words on screen | what the picture shows or changes |
   |---|---|---|---|

   - **One point per beat**, in one or two short sentences, each under about 20 words.
   - **So or but.** Each beat follows from the one before by cause or contrast, never by "and then".
   - **Define at first use.** A term the audience does not know gets its plain meaning in the beat that first says it. A fact the viewer already has gets a clause or a question, never a beat of its own.
   - **Every must-say fact, in full.** Keep its numbers, conditions and limits; never blur it into something vaguer.
   - **Cut the rest.** A detail that does not help answer the question goes, even when it is true and sourced. Cut hardest in the opening. Fit the budget, landing at or under it.
   - **Words on screen** are one to four words: a label, number or name that this beat's narration says, placed next to the thing it names. Never the narration sentence.
   - **Spoken text.** Write numbers and symbols as they are said ("forty percent", "x squared"), code names as spoken words, and no Markdown, brackets or stage directions: the voice reads every character.
   - **Order and tone** follow `STYLE.md`, scaled to the length: a short video keeps the question, the case and the answer, and drops the rest.

4. **Write `beats.json`**: a JSON list of `{"id", "text"}` objects, one per row, in order, `text` copied from the narration column. Then run `python3 scripts/beats.py <folder>`: it lists each beat with more than two sentences, with no words on screen, or with a word on screen its narration does not say, and any drift between `beats.json` and the table. Fix the table, copy it again, and rerun.

   Done when `beats.py` prints `ok:`, every must-say fact sits in a beat, and the narration word count is within the budget.

5. **Check every claim.** Write `claims.json` as `REFERENCE.md` ("Check every claim") describes: one entry per fact the narration states, with `beat`, `fact` (the brief's id when it is a brief fact), `claim`, `source` and `verdict`. Open the source before writing each entry. Run `python3 scripts/claims.py <folder> --brief <brief>` (pass `script.md` when there is no brief) and fix the narration until it passes. Then run the blind second read. Done when `python3 scripts/claims.py <folder> --brief <brief> --final` passes.

6. **Report.** Give the user, in plain words:
   - the folder, the beat count, the narration word count and its length at 2.6 words a second;
   - the claim count and the second read's result;
   - each conflict between the brief, the request and the source, and what the narration says instead;
   - the brief fields you chose, when there was no brief;
   - for a remake, each claim kept, moved or dropped, with the reason for each drop.

   End with one line: `beats.json` is the narration a video production skill takes, if one is installed, or any text-to-speech tool.
   Done when the report holds every item that applies.
