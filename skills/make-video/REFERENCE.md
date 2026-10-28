# Video production reference

The scene is React that draws SVG. Each frame, `scripts/render.mjs` renders the scene to one SVG document and [resvg](https://github.com/linebender/resvg) turns it into pixels, with no browser. So the scene is SVG only: no HTML elements, no CSS layout, and only the fonts `scripts/setup.sh` downloads.

## Swap the default style

The skill ships one default style, named `ink-on-paper`. It is a taste, not a rule: every part below can change without touching the render pipeline, the word cues or the layout check.

| Part | Default | Where it lives | To swap it |
|---|---|---|---|
| Look | Pen hatching and ink on warm paper, one drawn world the camera moves through | `template/src/DESIGN.md`, the palette and fonts in `theme.ts`, the drawing primitives in `look.tsx` | Write a new `DESIGN.md` with its own palette, type and detail list, change the tokens in `theme.ts`, and draw with your own primitives |
| Style check | The `STYLE:` lines enforce the default look: paper, ink filter, grain, a moving camera | `scripts/lint.py` | Under another look, a `STYLE:` line about paper, ink or grain does not apply; the lines about time (`useState`, `word()`) still do |
| Voice | Kokoro `af_heart` locally; ElevenLabs George when a key works | Environment variables in "Settings" below | Set `KOKORO_VOICE`, or `ELEVENLABS_VOICE_ID` and `ELEVENLABS_MODEL` |
| Music | A generated low pad, ducked under the voice | `public/sound/music.wav` in the project | Replace the file with your own score, at least as long as the video |
| Pacing | Pauses after questions and before chapters, after Grant Sanderson's 3Blue1Brown videos | `src/beats.ts` | Change the pause values there |


## Chapters and series

When the narration runs in chapters, each beat id carries its chapter as a prefix (`c2-ask`). Keep every chapter in the same world, and open each one with a camera move to the part of the world it is about.

When an episode ends on a beat that lists the next episode's questions, show them as a numbered list on a plain page, and write each one in as the voice asks it.

## How a scene is built

`src/Explainer.tsx` is one component for the whole video. It reads the time `t` in seconds and computes every object's position, size, colour and opacity from it. The world is one SVG group in world coordinates; the camera moves over it. Objects are always rendered; beats change their properties. This keeps one object on screen while it moves, splits or zooms, instead of cutting between slides.

```tsx
<svg width={1920} height={1080}>
  <InkDefs seed={boilSeed(frame)} />
  <g filter="url(#ink)">
    <g transform={cam.view}>{/* the world, drawn once */}</g>
  </g>
</svg>
<Label x={cam.screen(px, py).x} y={cam.screen(px, py).y - 40} p={at(t, "id", word("id", "planet"), 0.5)} text="a planet" />
```

| Helper (`src/beats.ts`, `src/kit.tsx`) | What it gives |
|---|---|
| `at(t, "beatId", delay, dur)` | 0 → 1, eased, starting `delay` seconds into the beat, over `dur` seconds: for an entrance |
| `move(t, "beatId", delay, dur)` | Like `at`, eased in and out: for an object or the camera travelling to a new place |
| `word("beatId", "phrase")` | Seconds into the beat when the voice says the phrase; pass it as `delay`. Measured word times when the render has them (see the `voice:` line), estimated from the text otherwise |
| `mix(p, a, b)`, `chain(start, [[p1, v1], ...])` | A value between two states; a value moved through several in order |
| `BEATS.id.start`, `.end`, `.seconds` | Beat timing, for an animation that should last the whole sentence |
| `useCurrentFrame()`, `random(seed)`, `interpolate` (`src/kit.tsx`) | The frame being drawn; a repeatable random number for jitter; a value mapped between ranges |
| `<Background />` | The paper colour; it goes first |
| `export const sound: Sound = { music, cues }` | The music bed's level, and the cues, each `{ beat, delay, sound, volume }`: a tick, whoosh, swell or chime `delay` seconds into the beat. The narration needs no entry: every beat's clip plays at the beat's start |
| `<Label x y p text>` | A lowercase hand-lettered label on its own paper backing, typed on as `p` goes 0 to 1 |
| `<Note t id phrase text>` | The beat's note, bottom left, typed on as the voice says `phrase`, gone at the next beat |
| `<Tag x y opacity>` | A monospace chip for a code name, a `path:line` or a value |
| `color`, `HUES`, `hand`, `mono` (`src/theme.ts`) | The palette, the four actor hues, the two fonts |

| Helper (`src/look.tsx`) | What it gives |
|---|---|
| `camera([[p, {x, y, s}], ...])` | A camera moved through shots; `view` is the world group's transform, `screen(x, y)` maps a world point to pixels |
| `<InkDefs seed>`, `boilSeed(frame)` | The `ink` wobble filter, `hatch-<hue>` patterns, crowd fills (`pat-dots`, `pat-rows`, `pat-cross`) and an open arrowhead |
| `<Hatch id d box stroke p>` | Pen hatching clipped to the path `d`, drawn on as `p` grows; `cross` for darker tone |
| `dim(lit)` | Opacity for an actor: full when lit, a soft pencil grey at rest |
| `personPath(h)`, `filePath(w, h)`, `housePath(w)` | Path data for a small person, a sheet with a folded corner, a house |
| `<Guide x y r tint lit look blink ping>` | The small ink character that stands in for the narrator |
| `<Counter value p>` | A number that counts up as `p` goes from 0 to 1; put it inside a `Tag` or a `<text>` |
| `<g transform={pose(p, from, to)}>` | Moves a shape drawn around (0, 0) between two poses `{x, y, rot}` as one rigid piece |
| `<Finish />` | Marks where the paper texture, grain and warm vignette go; the render multiplies them over the frame |

Draw world objects in world coordinates inside `cam.view`; place labels in screen pixels with `cam.screen`, so their type stays the same size while the camera zooms. To move a piece, draw it once around (0, 0) and wrap it in `pose()`; moving its corners one by one bends it out of shape halfway. To morph one shape into another, write both paths with the same commands in the same order and `mix` their numbers.

The render bakes the paper and six grain frames into `public/tex/` once (about 35 MB, under 2 s); delete that folder after changing `PaperTexture` or `GrainTexture`.

## Reference videos

When the user links a reference video (an X post, a YouTube link), fetch it yourself. Do not ask them to paste its text or describe it.

```sh
yt-dlp -o ref.mp4 <url>
yt-dlp --print description <url>
ffmpeg -i ref.mp4 -vf "fps=1,scale=480:-1,tile=4x3" sheet.png
```

The first line downloads the video, the second prints its caption, and the third tiles one frame per second into a contact sheet you can read. Put each of the three in its own new, empty folder. If the video has burned-in captions, OCR them instead of transcribing the audio.

## Free assets

The look is drawn in code and needs no asset. When an icon or a texture would take longer to draw than to fetch, these libraries allow commercial use; keep the licence notice where one is required:

| Library | What | Licence |
|---|---|---|
| [Lucide](https://lucide.dev) | Line icons as SVG paths | [ISC](https://github.com/lucide-icons/lucide/blob/main/LICENSE): keep the notice |
| [Tabler Icons](https://tabler.io/icons) | Line icons as SVG paths | [MIT](https://github.com/tabler/tabler-icons/blob/main/LICENSE): keep the notice |
| [Phosphor](https://phosphoricons.com) | Icons in six weights | [MIT](https://github.com/phosphor-icons/core/blob/main/LICENSE): keep the notice |
| [Open Peeps](https://www.openpeeps.com) | Hand-drawn people built from parts | CC0 (stated on the site) |
| [ambientCG](https://ambientcg.com) | Paper, card and fabric textures | [CC0](https://ambientcg.com/license) |
| [Poly Haven](https://polyhaven.com) | Textures | [CC0](https://polyhaven.com/license) |
| [Kenney](https://kenney.nl) | 2D game asset packs, icons included | CC0 ([support page](https://kenney.nl/support)) |

Redraw a fetched icon in the video's ink: take its path data, stroke it with `color.ink` inside the `ink` filter, and mark it `data-layout="icon"`.

## Music

The render writes a generated pad to `public/sound/music.wav` once and keeps any file already there. For a video that will be sold or published, replace that file with a score made for this video, at least as long as the video. Suno Pro or Premier, or ElevenLabs Music, grant commercial use on paid plans; free plans do not.

## What the layout check reads

The render prints a `LAYOUT:` line for each problem it sees in the camera frame at the end of a beat. It sees only marked elements:

| Mark | Put it on | Reported when |
|---|---|---|
| `data-layout="text"` | Every element holding words or numbers; `Label`, `Note` and `Tag` already carry it | It crosses a shape's edge, overlaps other text or an icon, leaves the frame, sits on texture without a paper backing, or is a backed label with no visible shape within 160 px |
| `data-layout="shape"` with `data-name` | Every drawn object the viewer must see whole: a box, a dot, a person, an SVG group | It is cut by the frame edge |
| `data-layout="icon"` with `data-name` | Every small pictogram | Any text touches it, or the frame edge cuts it |
| `data-layout="texture"` with `data-name` | Hatching (`Hatch` marks itself), a crowd or any dense pattern | Text without a paper backing sits on it |

The floating rule counts shapes and icons drawn at more than 20% opacity; a texture is not something to label, and the beat's `Note` is exempt because it sits alone bottom left. A raw `<text>` without a backing is not checked for it.

The `SHOWN:` line also compares each text with the narration, word by word: it ends with a verdict when the voice never says the text, or says it more than 2 s after the text appears. A text with no letters in it (`25%`, `1 / 4`) gets no verdict.

Anything wholly outside the frame is off camera and not reported; anything the frame cuts is. Text wholly inside a shape (a number in its box) is fine. A single `path`, `rect` or `circle` is judged by its fill and stroke, so a label inside a round shape is fine; a group is judged by its box, so a flag on a round group can be a false alarm. Confirm it on a `scripts/still.sh` frame.

## Visual rules of the default style

- Light at most two actors at once; the rest is ink on paper.
- Plan positions so the shot's subject fills the frame and about 100 px stays clear at every edge.
- Labels are 32 to 40 px, the note 46 px, code chips 24 to 30 px. At most the note and two labels are on screen at once; the voice carries the rest.
- Spend about 60% of a beat on the motion and leave the rest for the viewer to look.
- `src/beats.ts` leaves a longer silence after a beat that ends on a question and before a new chapter, so the viewer can take in what was said. Keep it when a video runs long rather than trimming the pauses.
- The template holds the last frame for 2.5 seconds, so the payoff stays on screen after the voice ends.

## Long videos and many episodes

The measurements behind the render pipeline are in RESEARCH.md.

- Every frame is drawn flat and gets the paper afterwards: `scripts/finish.sh` bakes the paper texture, vignette and grain once per size with `scripts/finish-tex.py` into the cache, and the render multiplies them over the frames in ffmpeg in planar RGB (`format=gbrp`, `blend=all_mode=multiply:shortest=1`). Inked areas pick up a faint paper texture. On a farm, run the pass on each chunk as it lands and phase the grain loop on the chunk's first frame; `blend` without `shortest=1` never ends when the grain input loops, and even with it ffmpeg never ends if its raw input closes before the first frame, so the render loops the grain only as many seconds as the video lasts.
- The ink wobble is not filtered per frame: its noise depends only on the boil seed, so the render builds one pixel map per seed and moves each frame's pixels by it. Labels are drawn after, as they sit outside the `ink` group. Equal frames (a hold cycles through the 12 seeds) are drawn once, and every attribute number is rounded to three decimals so the tail of an easing settles into equal frames.
- For 720p, run `scripts/render.sh <folder> 720p`. It draws 1280x720 frames, between the preview and the final.
- For a long series, render at 24 fps: set `"fps": 24` in `src/timeline.json` (re-voicing keeps it). Every move is timed in seconds, so nothing shifts, and there are a fifth fewer frames to draw.
- The sound is mixed apart from the frames: the render writes the sound list (each beat's clip and each cue with its start) to `out/audio.json` from the scene's `sound` export and the beats, and `scripts/mix.py` mixes it with numpy in about a second.
- Profile before splitting a slow render across machines. Time a 90-frame sample with each heavy layer turned off in turn. Run the baseline before and after the variants on the same host state, and treat any gap smaller than the baseline's own drift as noise. Label each row for what the command did: deleting a layer is not a gain, so time the pass that adds the removed layer back before quoting a net multiplier. Guessing the per-frame cost was wrong four times under the old browser renderer. Build the farm only if the sample shows the cost is not one layer you can remove or bake.
- To split frames across machines, weight each chunk by the machine's measured frames per second and take the frame count from `DURATION` in `src/beats.ts`, never from a second copy of the pause rule. Join the chunks with ffmpeg's concat and `-shortest`, since AAC pads the audio by about 36 ms.
- While the user waits for the first result, put every machine on one episode, in story order. Spreading episodes across machines made the first episode take about 3 hours; with all machines on one episode it took about 50 minutes.
- Name each remote work folder by a unique project id (for example the episode slug), never by the local folder name: every episode's project folder is called `video`, so two episodes sent to one machine collide. Before an unattended run on several machines, test two real projects at once.
- Wrap a long-running shell script's body in `{ ... exit; }`: bash reads a script as it runs, so editing it mid-run corrupts the running copy.
- When the episode order changes, rename the episode folders to match, so every reply uses one number per episode (a folder named e08 that holds episode 7 caused three corrections).
- When others will edit the video, give it a folder that works without your setup: instructions for their agent, the narration and a timed transcript, the drawings, the assets, and this skill. Prove the folder on a machine without the skill or your setup (a clean container, or a second computer): render one short clip there before calling it self-sufficient, because a test on your own machine finds nothing missing.

## resvg notes

- Draw everything as SVG. Text is a `<text>` element with `fontFamily`, `fontSize` and `fill`; it does not wrap, so keep each line short. HTML elements and CSS (`div`, `style` layout, `box-shadow`) draw nothing; the render prints a `LAYOUT:` line naming any HTML element it finds.
- Write math with Unicode (`a² + b²`, `log₂ n`), and a raised or lowered part with `<tspan baselineShift="super">` or `"sub"` and a smaller `fontSize`.
- Fonts come from the files in the cache's `fonts/` folder, which `scripts/setup.sh` fills. For another font, add its TTF there under a name that starts with the family name without spaces (`JetBrainsMono-…` for `JetBrains Mono`), and put the family name in `src/theme.ts`. The render stops when a family in the theme has no file, since resvg would draw it in another font.
- Every animation is a pure function of `t`: no `useState`, no `setTimeout`.
- `scripts/still.sh <folder> <frame> <png>` renders one finished frame in a few seconds; use it to watch a moment while you work.

## Settings

| Variable | Effect | Default when unset |
|---|---|---|
| `ELEVENLABS_API_KEY` | Uses ElevenLabs for every clip; when ElevenLabs answers 401 or quota exceeded, the whole render falls back to Kokoro and the `voice:` line says why | Kokoro, a free local voice |
| `ELEVENLABS_VOICE_ID` | ElevenLabs voice | `JBFqnCBsd6RMkjVDRZzb` (George) |
| `ELEVENLABS_MODEL` | ElevenLabs model | `eleven_v4_turbo` |
| `KOKORO_VOICE` | Kokoro voice, such as `af_heart` or `bm_george` | `af_heart` |
| `KOKORO_DIR` | Folder holding the Kokoro model files | `.cache/kokoro` in the home folder |
| `WHISPER_MODEL` | faster-whisper model that times Kokoro's words | `small.en` |
| `EXPLAINER_WORKERS` | Threads that draw frames at once | One per CPU |
| `EXPLAINER_CACHE` | Folder holding the fonts and the baked paper, grain and finish frames; the bake is keyed on `look.tsx` and `theme.ts`, so a new project with the same look skips it | `.cache/make-video` in the home folder |

Kokoro speaks English only in this setup. For another language, use ElevenLabs with the multilingual model.
