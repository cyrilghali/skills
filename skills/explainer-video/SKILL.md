---
name: explainer-video
description: 'Turns any topic into a narrated explainer video drawn in pen and ink on warm paper - hatching, hand-lettered labels, one drawn world the camera moves through. Writes the narration beat by beat, animates it in Remotion (React rendered to video), voices it with ElevenLabs when a key works or a free local voice otherwise, keeps every animation in step with the word that names it, checks every fact the narration states against a source anyone can open, checks the layout automatically, and renders an MP4. Use when the user asks for an "explainer video", a "3b1b style video", to "make a video explaining X", to "animate this concept", for a "video explainer" of a topic, codebase or paper, or for the next episode of an explainer video series. Also use when an existing render is too slow or too costly: "make the render faster", "render cost", "render farm", "split the render across machines", "render in parallel", "lower the render scale".'
metadata:
  category: write
---

# Making an explainer video

Teach the viewer one idea in one to three minutes, or longer when the user names a length. Let the picture carry the idea and let the voice say what to look at. Take the look from `template/src/DESIGN.md`: one world drawn in ink on paper, with colour only on the actor the voice is about.

Write two files per project. `beats.json` holds the narration, one or two sentences per beat:

```json
[{"id": "intro", "text": "This small light is a planet."},
 {"id": "orbit", "text": "Gravity bends its path into a circle around the sun."}]
```

`src/Explainer.tsx` draws every object as a function of time and moves it on cue:

```tsx
const t = useCurrentFrame() / FPS;
const lit = at(t, "intro", word("intro", "planet"), 0.8);   // 0 → 1 as the voice says "planet"
<g data-layout="shape" data-name="planet"><Hatch id="planet" d={ball} box={box} stroke={color.blue} opacity={dim(lit)} /></g>
```

The render voices each beat, lays the beats end to end with a pause that grows after a question and before a new chapter, and plays each clip at its beat's start. It reuses voice clips already made for the same text, so only changed sentences cost time or API credit.

## Start the project and pin the idea

1. **Start the project.** Run `scripts/setup.sh`, then `scripts/new.sh <folder>`. Read `src/DESIGN.md` and `src/Explainer.tsx` in the new project. Done when `new.sh` prints the project path. If setup prints a `missing:` line, it names a tool to install from `INSTALL.md`; stop there.
2. **Pin the viewer and the idea.** Write three things in `plan.md`:
   - the viewer: who watches and what they already know;
   - one sentence: what the viewer can do or see after the video that they could not before;
   - one concrete example that carries the whole video, such as two specific vectors or one real request through the system.

   For a series, finish one pilot episode first and get the user's yes on its format before scripting, auditing or rendering the others. A format change after the other episodes render throws those renders away.

   When the viewer is technical and the topic is their own code, map the idea to the source. Keep the module, function and `path:line` labels on screen beside the objects they name. Speak as a peer and use the code's own names instead of metaphors. Unless the user names a length, aim for about 90 seconds inside a 60 to 120 second range. For a longer episode, plan chapters of about two minutes, each with its own hook and payoff (`REFERENCE.md`). The voice speaks about 2.6 words a second, so 90 seconds is about 230 words. For a series or any video over 10 minutes, measure the render cost before fixing the scope and the look: render a 5-second sample in the planned look with `scripts/render.sh`, multiply its seconds per frame by the planned frame count, and write the total and the machine that will render it in `plan.md`. If the total is more than a few hours, cut the scope or pick a cheaper look before writing beats. Done when the viewer, the sentence and the example are in `plan.md`, plus the render estimate for a long video.

## Write the beats and the scene

3. **Write the beats.** In `plan.md`, make a table with one row per beat and three columns. The first holds the narration. The second holds the words shown on screen, only words the narration says. The third names the object already on screen that moves, splits, zooms or lights up. Let a new object enter only in the beat whose narration names it, so the eye and the ear meet on the same thing. Follow the beat order and voice rules in `REFERENCE.md`. Copy the narration into `beats.json`. Done when every row has one idea and one changing object, the rows read aloud as one story, and the word count falls inside the length target.
4. **Check every claim.** The viewer trusts the voice, so every fact it states must trace to a source someone else could open: code at `path:line`, a document section, a web page, a book page, a dataset with the query run on it, a measurement with its command and output, or a named person with the date they confirmed it. Memory, the request itself and "everyone knows" are not sources; a premise in the request is a claim like any other. Write `claims.json` beside `beats.json`: one entry per claim, with `beat`, `claim` in plain words, `source` and `verdict` (true, partly, false, outdated or unverifiable), and read the source before writing the entry. Fix a false or outdated claim in the narration; cut an unverifiable one or reword it so it asserts nothing. Then run `scripts/claims.py <folder>` until it passes, and have a reader who has not seen your reasoning check every claim again (`REFERENCE.md`, "Check every claim"). When the video replaces an earlier one, audit the old claims too (same section). Done when `scripts/claims.py <folder> --final` passes and every disagreement is settled from the source.
5. **Write `src/Explainer.tsx`.** Replace the example scene. Build it as `REFERENCE.md` describes: one component, one world in world coordinates under one camera, and every object a function of `t`. Use the kit for paper, voice, music, labels and notes, and the look primitives for ink, hatching, lit actors, the guide and the camera. Cue each key move to the word that names it with `word()`. Put a `Cue` on each key moment, `<Finish />` last, and a `data-layout` mark on every element. Done when every beat in the table moves its object.

## Render a preview and fix what the checks find

6. **Render a preview and look at it.** Run `scripts/render.sh <folder> preview`. It prints the MP4 path and one line per finding:

   | Line | What it reports | What to do |
   |---|---|---|
   | `STYLE:` | A break of the design rules | Fix it, every time |
   | `LAYOUT:` | In the camera frame: text that crosses a shape's edge, overlaps other text or an icon, or sits on texture without paper behind it; anything the frame edge cuts | Fix it, or confirm on a full-resolution frame that it is a false alarm; never hide a visible object from the check |
   | `SHOWN:` | When each text first appears, and what the voice is saying then | Fix text that appears before the voice nears its words; cue it with `word()` |

   Then run `scripts/frames.sh <mp4>` and read the PNG it prints: one tile per beat, taken as the beat ends. Fix and re-render until no line is left unexplained, every beat's tile shows the change its row in `plan.md` names (including any camera move), every label is large enough to read, and the length falls inside the target. Done when one render passes all four checks.

   For a long video, skip the repeat preview renders. After the first preview, check each fix on stills: run `pnpm exec remotion still Explainer <png> --frame=<n>` for the beat's end frame (the `LayoutProbe` in `src/kit.tsx` prints that beat's `LAYOUT:` lines for the frame it renders), and read the stills as a contact sheet. Keep the full render for the final.
7. **Make a detail pass.** Take one frame from the middle of each beat's motion with `ffmpeg -ss <seconds> -i <mp4> -frames:v 1` and check it against the detail list in `src/DESIGN.md`. Fix what fails and re-check on stills for a long video, or re-render once for a short one. Done when every item on the list holds on every frame you took.

## Render the final and report it

8. **Render the final.** Run `scripts/render.sh <folder> final`. Check with `ffprobe` that the video ends no more than one frame before the audio stream and no more than 3 seconds after it (the closing hold). Report the MP4 path, its length, the voice used (service and voice name, from the render's `voice:` line, with any fallback it names), and the one-sentence idea. Done when the report holds all four. When the video goes to a channel where posts can be replaced, post each render that passes the checks above, even with a known flaw you will fix next; say the flaw in the post. Fold notes that arrive later into the next version. Never cancel a render in flight because notes arrived.

## Keep the work inside the project

Keep every file inside the project folder. Give the video to the user as a file path; the user opens it.
