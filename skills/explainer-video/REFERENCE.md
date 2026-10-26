# Explainer video reference

The beat order and voice rules follow Grant Sanderson's 3Blue1Brown videos. The look comes from `template/src/DESIGN.md`, which sets pen hatching and ink on warm paper, one drawn world the camera moves through. The engine is Remotion: each frame is a web page rendered by headless Chrome, so any CSS, SVG or web font is available.

## Order of the beats

| Beat | What it does |
|---|---|
| Hook | One question or surprising fact the viewer wants answered. |
| Concrete case | The example from `plan.md`, with real numbers or real names. |
| Build | One step per beat, each changing the picture already on screen. |
| General rule | The pattern, stated only after the viewer has seen it work once. |
| Payoff | Answer the hook in one sentence, on the final picture. The template holds the last frame for 2.5 seconds. |

Give the video one main character who wants something, and let that character carry every beat: each beat shows what they do, see or run into. The video opens on their story, not on a tour of the system. A beat where the main character is absent explains a part of the system, so rewrite it from their point of view or cut it.

A longer video is a run of chapters of about two minutes, each with its own hook, build and payoff, in the same world and the same `beats.json`. Prefix each beat id with its chapter (`c2-ask`), and open each chapter with a camera move to the part of the world it is about.

Open each new chapter with one or two sentences that tie what the viewer just learned to what the chapter asks, and give a new subject inside a chapter a lead-in clause, so the viewer never lands on a topic cold. A closing question that sets up the next video says what is still open and why it matters to the people in the story before it asks. In a series, end on a preview beat after that question: "In the next episode, you'll find out:" followed by the next episode's chapter questions, each short enough to stand alone, shown as a numbered list on a plain page and written in as the voice asks each one.

## Voice

- Write for the ear: short sentences of about 15 words, one idea each, active voice.
- Name the thing on screen when it appears or moves: "this small house", "the dashed line".
- Use one word for one thing for the whole video and across the series: keep one glossary for the series, check every episode's narration and on-screen text against it, and keep internal jargon (such as "Fork") off screen.
- Explain a technical term in plain words the first time it is spoken, while the picture shows it, unless the viewer already uses it daily.
- Spell numbers and symbols as they are spoken: "v dot w", "eleven", "x squared".
- Keep narration plain text: no Markdown, no brackets, no stage directions.

## How a scene is built

`src/Explainer.tsx` is one component for the whole video. It reads the time `t` in seconds and computes every object's position, size, colour and opacity from it. The world is one SVG group in world coordinates; the camera moves over it. Objects are always rendered; beats change their properties. This keeps one object on screen while it moves, splits or zooms, instead of cutting between slides.

```tsx
<svg width={1920} height={1080} style={{ position: "absolute" }}>
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
| `<Background />`, `<Voiceover />`, `<Music />` | The paper, the narration and the music bed; they go first |
| `<Cue beat delay sound>` | A tick, whoosh, swell or chime at a moment |
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
| `<Counter value p>` | A number that counts up as `p` goes from 0 to 1 |
| `<g transform={pose(p, from, to)}>` | Moves a shape drawn around (0, 0) between two poses `{x, y, rot}` as one rigid piece |
| `<Finish />` | Grain and the warm vignette, rendered last |

Draw world objects in world coordinates inside `cam.view`; place labels in screen pixels with `cam.screen`, so their type stays the same size while the camera zooms. To move a piece, draw it once around (0, 0) and wrap it in `pose()`; moving its corners one by one bends it out of shape halfway. To morph one shape into another, `pnpm add @remotion/paths` at the same version as `remotion` and draw `interpolatePath(p, fromPath, toPath)`.

The render bakes the paper and six grain frames into `public/tex/` once (about 40 MB); delete that folder after changing `PaperTexture` or `GrainTexture`.

## Check every claim

A claim is any statement of fact the narration makes, whatever the topic: a count, a size, a date, a default, a name, a cause, a sequence of events, a comparison, and any "only", "always", "never" or "-est". The viewer trusts the voice, so a wrong fact lands as true. The rule is the same for code, history, science or a product: each claim names a source another person could open and reach the same verdict.

| Topic | A source that counts | Not a source |
|---|---|---|
| A codebase | `path:line` at the commit you read | the function name alone, a comment you did not check against the code |
| A spec, paper or book | the document and its section or page | the title alone |
| The wider world (history, science, places) | a web page from the body that holds the fact (an agency, a museum, a standards body, a peer-reviewed paper), with its URL | a quiz site, a forum answer, a page that cites nothing |
| Data | the dataset, the query and the result you got | a figure remembered from a dashboard |
| Logs or metrics | the query, its time window and what it returned | "the dashboard looked normal" |
| A behavior you can run | the command and the output it printed | what the command should print |
| A person | their name, role and the date they confirmed the wording | "the team says" |

A claim the request takes for granted is still a claim: check it like the others, and say so to the user when the source contradicts it.

**`claims.json`** is a list with one entry per claim, written after the beats and before the scene:

```json
[{"beat": "c2-expire", "claim": "A cached page expires after 300 seconds", "source": "cache.md:9", "verdict": "true"},
 {"beat": "c2-refresh", "claim": "A stale page is refreshed in the background", "source": "https://example.com/docs#refresh", "verdict": "partly", "note": "only while the origin answers"}]
```

- `source` is a `path:line` you opened, a URL you fetched or a document section you read. Open it before writing the entry; a source named from memory is not a source.
- Verdicts: `true` (the source says so), `partly` (true with a limit; the note says which part holds), `false` (the source says otherwise), `outdated` (true once, no longer), `unverifiable` (no source settles it, after you tried each kind that could: the code, the stored data, the logs and metrics, the vendor's docs, the person who decided). "Not in the code" is not unverifiable when a query, a log search or a doc can settle it.
- Fix a `false` or `outdated` claim in the narration. Cut an `unverifiable` claim, or reword it so it asserts nothing ("usually", "as far as we know" are not enough; drop the number). Keep the old verdict in the entry; the script requires the beat to have changed.
- Run `scripts/claims.py <folder> --stamp` right after judging, before the edit: it records each beat's text as checked (`text_at_check`). Edit the narration, then run `scripts/claims.py <folder>`.

**What the script checks.** It lists a beat that holds a number (digits or spoken: "forty", "percent"), a CamelCase or snake_case name, a `path.ext`, a `backticked` term, a quoted product name or an absolute word ("only", "never", "largest") and has no entry. One entry covers the whole beat, so the script cannot tell whether every claim in the beat has an entry: list each claim the beat makes. It also fails an entry that lacks a claim, source or verdict, and a `false`, `outdated` or `unverifiable` entry whose beat has not changed. A claim without such a token (a cause, a sequence) still needs an entry; the script cannot see it, so the second read does.

**The second read.** Run `scripts/claims.py <folder> --blind > blind-claims.json`: it keeps only each entry's beat, claim and source, so your verdicts and notes stay out of the handover. Hand a reviewer that has not seen your reasoning `beats.json`, `blind-claims.json` and read access to the sources. Use a subagent if the host offers one, else a new session. Do not hand over `claims.json`, `plan.md` or your notes. Ask it to open each source and write `second-read.json` itself: one `{"beat", "claim", "verdict"}` per entry, with beat and claim copied unchanged, plus an entry for each claim in `beats.json` that has none. Never edit that file yourself. Where its verdict differs from yours, open the source, set the right verdict in `claims.json` and write the reason in `resolved`. Add each claim it found to `claims.json`. Run `scripts/claims.py <folder> --final`; it fails until every entry has a second-read verdict, every difference has a `resolved`, and every added claim is in `claims.json`.

## Remaking a video

A remake loses facts when the trim is done by feel. Before writing the new beats, list every claim of the old version from its captions or transcript (never from memory), one row each in `remake.md`:

| Old claim | Where (timestamp) | Status | Why or where now |
|---|---|---|---|

Status is one of: `kept` (same beat), `moved` (now in another beat, name it), `dropped on purpose` (the reason is mandatory: out of scope, wrong, outdated), `dropped by accident`. Restore every accidental drop in the new narration, or, if it cannot fit, write it as a note next to the video. After the new beats exist, mark each row again; no row stays blank. Run the claims check on the new version as usual, so a claim carried over from the old one is checked against its source again. A real remake lost 34 in-scope facts before an audit like this one found them.

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
| `data-layout="text"` | Every element holding words or numbers; `Label`, `Note` and `Tag` already carry it | It crosses a shape's edge, overlaps other text or an icon, leaves the frame, or sits on texture without a paper backing |
| `data-layout="shape"` with `data-name` | Every drawn object the viewer must see whole: a box, a dot, a person, an SVG group | It is cut by the frame edge |
| `data-layout="icon"` with `data-name` | Every small pictogram | Any text touches it, or the frame edge cuts it |
| `data-layout="texture"` with `data-name` | Hatching (`Hatch` marks itself), a crowd or any dense pattern | Text without a paper backing sits on it |

Anything wholly outside the frame is off camera and not reported; anything the frame cuts is. Text wholly inside a shape (a number in its box) is fine. A flag on a diagonal or round shape drawn as an HTML box can be a false alarm; confirm it on a full-resolution frame.

## Visual rules

- Light at most two actors at once; the rest is ink on paper.
- Plan positions so the shot's subject fills the frame and about 100 px stays clear at every edge.
- Labels are 32 to 40 px, the note 46 px, code chips 24 to 30 px. At most the note and two labels are on screen at once; the voice carries the rest.
- Spend about 60% of a beat on the motion and leave the rest for the viewer to look.
- `src/beats.ts` leaves a longer silence after a beat that ends on a question and before a new chapter, so the viewer can take in what was said. Keep it when a video runs long; cut words instead.

## Long videos and many episodes

- For 720p, pass `--scale=0.6666666666666666`; a rounded `0.6667` gives a 720.036 px height, which Remotion refuses. It takes about a third less time per frame than 1080p.
- For a long render, render flat and lay the paper on afterwards: pass `--props` with `{"flat":true}` (look.tsx then drops the paper texture, vignette and grain), bake those layers with `scripts/finish-tex.py`, and multiply them back in ffmpeg in planar RGB (`format=gbrp`, `blend=all_mode=multiply`, the grain loop phased on each chunk's first frame). Run that pass on each chunk as it lands: on the whole episode at the join, the re-encode ran at about 30 frames a second and idled the farm for minutes. It cut render time by 27-38% across machines and matched the normal render at 34 dB PSNR; inked areas pick up a faint paper texture.
- For a long series, render at 24 fps: set `"fps": 24` in `src/timeline.json` (re-voicing keeps it). Every move is timed in seconds, so nothing shifts, and there are a fifth fewer frames to draw.
- Rendering the audio through Remotion costs as much as rendering frames. For a long video, log the sound list (each clip, cue and its start) from a one-frame composition and mix it with numpy in seconds.
- Profile before splitting a slow render across machines. Time a 90-frame sample with each heavy layer turned off in turn. Run the baseline before and after the variants on the same host state, and treat any gap smaller than the baseline's own drift as noise. Label each row for what the command did: deleting a layer is not a gain, so time the pass that adds the removed layer back (for example in ffmpeg) before quoting a net multiplier. Guessing the per-frame cost was wrong four times (the ink filter took 37%, and the baked paper and grain images still cost about 30% through their full-frame multiply blends). Build the farm only if the sample shows the cost is not one layer you can remove or bake.
- To split frames across machines, weight each chunk by the machine's measured frames per second and take the frame count from the composition's own duration, never from a second copy of the pause rule. Join the chunks with ffmpeg's concat and `-shortest`, since AAC pads the audio by about 36 ms.
- While the user waits for the first result, put every machine on one episode, in story order. Spreading episodes across machines made the first episode take about 3 hours; with all machines on one episode it took about 50 minutes.
- Name each remote work folder by a unique project id (for example the episode slug), never by the local folder name: every episode's project folder is called `video`, so two episodes sent to one machine collide. Before an unattended run on several machines, test two real projects at once.
- Wrap a long-running shell script's body in `{ ... exit; }`: bash reads a script as it runs, so editing it mid-run corrupts the running copy.
- When the episode order changes, rename the episode folders to match, so every reply uses one number per episode (a folder named e08 that holds episode 7 caused three corrections).
- Before proposing a GPU speedup for rendering, confirm Chrome inside the render image really uses the card: sample GPU use during a short render, or read Chrome's GPU status. In the stock image Chrome stayed on software rendering (seven runs showed `gpu_util_max=0`), so GL flags and shaders do not speed it up.
- When others will edit the video, give it a folder that works without your setup: instructions for their agent, the narration and a timed transcript, the claims with their sources, the drawings, the assets, and this skill. Prove the folder on a machine without the skill or your setup (a clean container, or a second computer): render one short clip there before calling it self-sufficient, because a test on your own machine finds nothing missing.

## Remotion notes

- Write math with Unicode and `<sub>`/`<sup>` (`log<sub>2</sub>(n)`, `a² + b²`). For a full formula, `pnpm add katex` and render it to HTML.
- Load another Google Font with `@remotion/google-fonts/<Name>` in `src/theme.ts`.
- Every animation is a pure function of `t`: no `useState`, no CSS transitions, no `setTimeout`.
- `pnpm run studio` opens a live preview in the browser, if the user asks to watch while you work.

## Settings

| Variable | Effect | Default when unset |
|---|---|---|
| `ELEVENLABS_API_KEY` | Uses ElevenLabs for every clip; when ElevenLabs answers 401 or quota exceeded, the whole render falls back to Kokoro and the `voice:` line says why | Kokoro, a free local voice |
| `ELEVENLABS_VOICE_ID` | ElevenLabs voice | `JBFqnCBsd6RMkjVDRZzb` (George) |
| `ELEVENLABS_MODEL` | ElevenLabs model | `eleven_v4_turbo` |
| `KOKORO_VOICE` | Kokoro voice, such as `af_heart` or `bm_george` | `af_heart` |
| `KOKORO_DIR` | Folder holding the Kokoro model files | `.cache/kokoro` in the home folder |
| `WHISPER_MODEL` | faster-whisper model that times Kokoro's words | `small.en` |
| `EXPLAINER_CONCURRENCY` | Browser tabs the render uses at once; each tab is a headless Chrome | `2`, so one render leaves the machine usable |

Kokoro speaks English only in this setup. For another language, use ElevenLabs with the multilingual model.
