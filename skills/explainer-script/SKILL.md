---
name: explainer-script
description: 'Writes the narration of a narrated explainer video beat by beat and checks every fact it states against a source anyone can open: pins the viewer and the one idea, carries it through one concrete example, orders the beats for the ear, fits the length, has a blind second reader re-check every claim, and hands over a beats.json ready to animate and voice. Use when the user asks to "write the script" or "draft the narration" or "voiceover" for an explainer video, to "fact-check the narration" or "check every claim" of an explainer, to remake or shorten an episode "without losing a fact", to say "what the video should say", or to "make a video explaining X" when no finished narration exists yet.'
metadata:
  category: write
---

# Writing an explainer's narration

Write what an explainer video says, so it teaches one idea and every fact in it holds. The picture comes later and carries the idea; the voice says what to look at. The output is `beats.json`, one or two sentences per beat:

```json
[{"id": "intro", "text": "This small light is a planet."},
 {"id": "orbit", "text": "Gravity bends its path into a circle around the sun."}]
```

Work in one folder: `script.md` for the plan, `beats.json` for the narration, `claims.json` for the fact check.

## Pin the viewer and the idea

1. **Pin the viewer and the idea.** Write three things in `script.md`:
   - the viewer: who watches and what they already know;
   - one sentence: what the viewer can do or see after the video that they could not before;
   - one concrete example that carries the whole video, such as two specific vectors or one real request through the system.

   When the viewer is technical and the topic is their own code, speak as a peer, use the code's own names instead of metaphors, and note the module, function or `path:line` each beat is about, so the picture can label it. Unless the user names a length, aim for about 90 seconds inside a 60 to 120 second range. The voice speaks about 2.6 words a second, so 90 seconds is about 230 words. For a longer episode, plan chapters of about two minutes (`REFERENCE.md`). For a series, finish the pilot episode end to end before writing the others: a format change after that throws their scripts away. Done when the viewer, the sentence, the example and the word target are in `script.md`.

## Write the beats

2. **Write the beats.** In `script.md`, make a table with one row per beat: the narration, and the thing the picture should show or change while it is spoken. Name that thing in the narration, so the picture can move on the word. Follow the beat order and voice rules in `REFERENCE.md`, and scale them to the length: a short video drops the parts it has no time for. Copy the narration into `beats.json`. Done when every row holds one idea in one or two sentences, the rows read aloud as one story, and the word count falls inside the target.

## Check every claim

3. **Check every claim.** The viewer trusts the voice, so every fact it states must trace to a source someone else could open: code at `path:line`, a document section, a web page, a book page, a dataset with the query run on it, a measurement with its command and output, or a named person with the date they confirmed it. Memory, the request itself and "everyone knows" are not sources; a premise in the request is a claim like any other. Write `claims.json` beside `beats.json`: one entry per claim, with `beat`, `claim` in plain words, `source` and `verdict` (true, partly, false, outdated or unverifiable), and read the source before writing the entry. Fix a false or outdated claim in the narration; cut an unverifiable one or reword it so it asserts nothing. Then run `python3 scripts/claims.py <folder>` until it passes, and have a reader who has not seen your reasoning check every claim again (`REFERENCE.md`, "Check every claim"). When the narration replaces an earlier version, audit the old claims too ("Remaking a narration"). Done when `scripts/claims.py <folder> --final` passes and every disagreement is settled from the source.

## Hand over the narration

4. **Report it.** Give the user the folder path, the beat count, the word count with the length it gives at 2.6 words a second, the number of claims and the second read's result, and each premise of the request the sources contradicted. Done when the report holds all five.
