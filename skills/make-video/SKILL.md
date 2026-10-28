---
name: make-video
description: 'Turns a finished narration into an explainer video: draws it, animates it, voices it and renders it. Ships a default style you can swap (pen and ink on warm paper, one drawn world the camera moves through). Plans what moves in each beat, animates it as SVG drawn by React, voices it with ElevenLabs when a key works or a free local voice otherwise, keeps every animation in step with the word that names it, checks the layout automatically, and renders an MP4. Use when the user asks for an "explainer video", a "3b1b style video", to "make a video explaining X", to "animate this concept", for a "video explainer" of a topic, codebase or paper, for the next episode of an explainer video series, or to fix the look, layout, camera, timing or voice of one. Also use when an existing render is too slow or too costly: "make the render faster", "render cost", "render farm", "split the render across machines", "render in parallel", "lower the render scale".'
metadata:
  category: write
---

# Producing an explainer video

Turn a finished narration into a video where the picture carries the idea and the voice says what to look at. The look, voice and music come from the default style: `template/src/DESIGN.md` draws one world in ink on paper, with colour only on the actor the voice is about. To use another look or voice, follow `REFERENCE.md`, "Swap the default style".

The input is a finished `beats.json`: one or two sentences of plain spoken text per beat. Writing it is the step before this skill; a write-video-script skill does it from a brief, when one is installed.

```json
[{"id": "intro", "text": "This small light is a planet."},
 {"id": "orbit", "text": "Gravity bends its path into a circle around the sun."}]
```

`src/Explainer.tsx` draws every object as a function of time and moves it on cue:

```tsx
const t = useCurrentFrame() / FPS;                          // from ./kit
const lit = at(t, "intro", word("intro", "planet"), 0.8);   // 0 → 1 as the voice says "planet"
<g data-layout="shape" data-name="planet"><Hatch id="planet" d={ball} box={box} stroke={color.blue} opacity={dim(lit)} /></g>
```

The render voices each beat, lays the beats end to end with a pause that grows after a question and before a new chapter, and plays each clip at its beat's start. It reuses voice clips already made for the same text, so only changed sentences cost time or API credit.

## Start the project and set the length

1. **Start the project.** Run `scripts/setup.sh`, then `scripts/new.sh <folder>`, and copy the finished `beats.json` over the template's. Read `src/DESIGN.md` and `src/Explainer.tsx` in the new project. A project keeps the kit files it was made with; to render an older project with a newer skill, copy `kit.tsx`, `look.tsx`, `beats.ts`, `frame.ts` and `theme.ts` from the template again. Done when `new.sh` prints the project path and the project's `beats.json` is the finished narration. If setup prints a `missing:` line, it names a tool to install from `INSTALL.md`; stop there.
2. **Set the length and the render budget.** The voice speaks about 2.6 words a second, so divide the narration's word count by 2.6 and write the expected length in `plan.md`. Unless the user names a length, the target is 60 to 120 seconds; when the narration falls outside it, say so before animating, because the narration changes, not the pace. When the beat ids carry chapter prefixes, plan the picture by chapter (`REFERENCE.md`, "Chapters and series"). For a series, finish one pilot episode and get the user's yes on its format before rendering the others; a format change after they render throws those renders away. For a series or any video over 10 minutes, measure the render cost before fixing the look: render a 5-second sample in the planned look with `scripts/render.sh`, multiply its seconds per frame by the planned frame count, and write the total and the machine that will render it in `plan.md`. If the total is more than a few hours, pick a cheaper look or a shorter cut before drawing. Done when the expected length is in `plan.md`, plus the render estimate for a long video.

## Plan the picture and build the scene

3. **Plan what moves.** In `plan.md`, make a table with one row per beat of `beats.json` and three columns: the beat id, the words shown on screen (only words the narration says; take them from the script's table when a `script.md` came with the narration), and the object already on screen that moves, splits, zooms or lights up. Let a new object enter only in the beat whose narration names it, so the eye and the ear meet on the same thing. When the topic is the viewer's own code, give each object the module, function or `path:line` label it stands for. When a beat gives the picture nothing to change, name that beat to the user rather than adding a beat or rewording it. Done when every row has one changing object and every new object's name is in its beat's narration.
4. **Write `src/Explainer.tsx`.** Replace the example scene. Build it as `REFERENCE.md` describes: one component, one world in world coordinates under one camera, and every object a function of `t`. Use the kit for paper, labels and notes, and the look primitives for ink, hatching, lit actors, the guide and the camera. Cue each key move to the word that names it with `word()`. Before rendering, check that every string in a `Label`, `Note`, `Tag` or `Counter` is words the narration says; a number on screen is fine, with or without its unit. Export `sound` with the music level and a cue on each key moment. Put `<Finish />` last and a `data-layout` mark on every element. Done when every beat in the table moves its object.

## Render a preview and fix what the checks find

5. **Render a preview and look at it.** Run `scripts/render.sh <folder> preview`. It prints the MP4 path and one line per finding:

   | Line | What it reports | What to do |
   |---|---|---|
   | `STYLE:` | A break of the default style's rules | Fix it, every time; under a swapped style, fix the lines its own `DESIGN.md` still holds |
   | `LAYOUT:` | In the camera frame: text that crosses a shape's edge, overlaps other text or an icon, or sits on texture without paper behind it; a label with no visible shape near it; anything the frame edge cuts | Fix it, or confirm on a full-resolution frame that it is a false alarm; never hide a visible object from the check |
   | `SHOWN:` | When each text first appears, and what the voice is saying then; the line ends with a verdict when the voice never says the text or says it more than 2 s later | Reword the text to the narration's words, or cue it with `word()`; fix text that appears before the voice nears its words |

   Then run `scripts/frames.sh <mp4>` and read the PNG it prints: one tile per beat, taken as the beat ends. Fix and re-render until no line is left unexplained, every beat's tile shows the change its row in `plan.md` names (including any camera move), every label is large enough to read, and the length falls inside the target. Done when one render passes all four checks.

   For a long video, skip the repeat preview renders. After the first preview, check each fix on stills: run `scripts/still.sh <folder> <frame> <png>` for the beat's end frame (it takes a few seconds and prints that frame's `LAYOUT:` lines), and read the stills as a contact sheet. Keep the full render for the final.
6. **Make a detail pass.** Take one frame from the middle of each beat's motion with `scripts/still.sh` (frame = seconds × fps) and check it against the detail list in `src/DESIGN.md`. Fix what fails and re-check on stills for a long video, or re-render once for a short one. Done when every item on the list holds on every frame you took.

## Render the final and report it

7. **Render the final.** Run `scripts/render.sh <folder> final`. Check with `ffprobe` that the video ends no more than one frame before the audio stream and no more than 3 seconds after it (the closing hold). Report the MP4 path, its length, and the voice used (service and voice name, from the render's `voice:` line, with any fallback it names). Done when the report holds all three. When the video goes to a channel where posts can be replaced, post each render that passes the checks above, even with a known flaw you will fix next; say the flaw in the post. Fold notes that arrive later into the next version. Never cancel a render in flight because notes arrived.

## Keep the work inside the project

Keep every file inside the project folder. Give the video to the user as a file path; the user opens it.
