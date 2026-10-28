# Why does the make-video renderer look the way it does?

Read this before you change `scripts/render.sh` or the renderer. It records how the render was measured, which fixes held up, and why the renderer moved from [Remotion](https://www.remotion.dev) to [resvg](https://github.com/linebender/resvg). The move has shipped. `render.sh` now renders the React scene to one SVG per frame and draws it with resvg on worker threads, with no browser. The comparison with Manim used a prototype that rebuilt one scene by hand; the shipped port's own numbers are under "What does the shipped port measure?".

Every number comes from one test video: a 16-second scene (15.73 s, 472 frames at 30 fps) in which a pizza splits into quarters and then becomes a 10 by 10 grid. Two sizes appear throughout:

- **Preview**: 960x540, the half-scale render the agent checks while it works.
- **Final**: 1920x1080, the render it delivers.

| Machine fact | Value |
|---|---|
| Computer | 10-core Apple M4 Mac, shared with other agents while the runs took place |
| Date | 27 October 2026 |
| Browser tabs | 2 for every Remotion number unless a row says otherwise (the `render.sh` default) |
| Manim | Community v0.22.0 |
| RAM, OS, Node, Chrome, Remotion and ffmpeg versions | not recorded |

## What was slow, and by how much?

`render.sh` runs these stages in order. Before the fix (https://github.com/cyrilghali/skills/pull/18), Chrome also drew the paper finish (paper image, film grain and vignette) inside the render stage. Now it renders flat and ffmpeg lays the finish on afterwards.

```
voice ──▶ sound ──▶ lint ──▶ type-check ──▶ texture bake ──▶ render (Chrome) ──▶ finish (ffmpeg) ──▶ checks
                                            once per look      one screenshot     multiply paper,      LAYOUT: and SHOWN:
                                            then cached        per frame          grain, vignette      lines from the log
```

Wall seconds, one run each:

| Stage | Preview, before | Final, before | After the fix |
|---|---|---|---|
| Voice | 0.6 | 0.6 | same; 25.8 s when the voice model loads cold, once per session |
| Sound | 2.6 | 2.6 | same |
| Lint | 0.1 | 0.1 | same |
| Type-check | 1.8 | 1.8 | same |
| Texture bake | 36.7 | 36.7 | 16.4 s for paper and grain plus 4.6 s for the finish frames, once per look; then 0 |
| Render command | 49.8 (drawing 41, stitching 5) | 133.8 (drawing 110, stitching 20) | preview drawing 15 s in a separate pass |
| Finish in ffmpeg | inside Chrome | inside Chrome | 2.8 s at preview; final not measured separately |
| Checks | read from the render log | read from the render log | not timed apart |

The render command was 91% of a warm preview and 96% of a warm final, counting voice, sound, lint, type-check and render. Inside it, Chrome drawing frames took 82% to 88% in the two runs above and the three full-scene runs below.

The finish was the biggest layer inside Chrome. With paper, grain and vignette on, the preview's drawing took 40 to 53 s in three runs. With all three off it took 15 s. The finish was 62% to 72% of every frame; grain and vignette alone were 55% to 66%.

## Which fixes held up, and which did not?

The 40 to 53 s spread comes from a clean pass in which the full scene ran first, middle and last. An earlier pass ran while two installs were going on; its full scene drew in 99 s, so its rows compare only within that pass.

Kept, ranked by seconds saved:

| Fix | Before | After | Runs and load |
|---|---|---|---|
| Render flat, multiply the finish in ffmpeg | Preview 73 s, final 155 s (whole script) | Preview 36 s, final 81 s | Old and new scripts back to back on one project, one run each, 1-minute load 13 to 18 |
| Same fix, drawing only (preview) | 53 s | 15 s flat + 2.8 s ffmpeg | Clean pass, one run per variant |
| Cache the baked textures per machine | 21 s bake | 0 s (copied) | Two unrelated projects baked byte-identical PNGs (checked with `cmp`; not kept in a data file) |
| Bake all stills from one bundle | 36.7 s | 16.4 s (2.3 bundle + 14.1 stills) | One run each |
| Encode the flat render at `veryfast` | 129 s final, 6 tabs | 116 s final, 6 tabs | One run each; encoding fell 13 to 7 s. Shipped, not ranked: one run each is inside the noise |

Dropped, with the number that ruled each one out:

| Idea | Before | After | Runs |
|---|---|---|---|
| Muted audio (on this 16-second scene) | 49.8 s | 49.9 s | One each |
| 4 tabs instead of 2 | 41 s drawing | 40 s drawing | One each |
| 6 or 8 tabs | 49.8 s | 65.5 s and 74.3 s | One each |
| Hardware encoder (final, 6 tabs) | 128.8 s | 127.6 s; encoding fell 13 to 5 s but drawing rose 112 to 119 s | One each |
| Quarter-scale draft | 40 to 53 s drawing | 38 s; the finish costs per frame, not per pixel | Clean pass |
| Draft mode (flat, no ink, quarter scale) | 21.7 s whole run, flat | 22.7 s whole run (12 s drawing) | Clean pass |
| Ink noise baked into PNGs | 99 s drawing | 143 s (+44%) | Earlier pass |
| Skip the layout check | 40 to 53 s | 51 s, inside the spread | Clean pass |
| Drop the ink wobble | 40 to 53 s; 99 s in the earlier pass | 46 s, inside the spread; 75 s in the earlier pass | One per pass. On the flat render, shapes, hatching and ink together cost 3 s |

One gotcha cost 28 minutes. ffmpeg's `blend` never ends when one input loops (`-stream_loop -1`) unless the filter gets `shortest=1`. The first finish pass ran for 1,714 s before it was stopped. `render.sh` now passes `blend=all_mode=multiply:shortest=1`. That is not enough when the render dies before its first frame: `blend` then waits forever for a first pair while the grain keeps looping, and each crash left an ffmpeg using a core. The port bounds the loop to the video's length in seconds and kills its ffmpeg when it exits, throws or gets SIGINT or SIGTERM. After a resvg panic and after a SIGINT, no ffmpeg was left 5 s later.

## What does the browser cost by itself?

A blank scene of the same length sets Remotion's floor: one headless-Chrome screenshot per frame.

| Tabs | Blank scene, drawing | Whole run |
|---|---|---|
| 2 | 12 s (about 25 ms a frame) | 23.9 s |
| 6 | 5 s | 9.1 s |

So the screenshot floor is at most 12 s of the preview. Once the finish moved out, the real scene drew in 15 s. At 2 tabs, at most 3 s of Chrome drawing was left to win, and more tabs slowed the real scene. A faster render from here has to stop taking a browser screenshot per frame. At this point the plan was still to keep Remotion and test a hybrid: scenes written in React, drawn by resvg.

## How do the alternatives compare at their best?

The same scene was rebuilt in [Manim](https://www.manim.community) and in resvg, and each was tuned as far as it would go:

- **Manim (OpenGL renderer)**: three worker processes split by frame range, the texture bake run in parallel, the finish multiply at `veryfast`. Five workers were no faster: each process pays 2.2 s of startup and all share one GPU.
- **resvg, tuned**: one SVG string per frame, rasterized in ten worker threads and streamed to one ffmpeg. The finish is the same ffmpeg multiply as Remotion. Hatching is cut to each shape's box. The ink displacement map depends only on its seed (12 values), so it is built once per seed and reused.

Each time below covers the tool's drawing, finish and encode, plus 5 s of voice, sound and checks that every pipeline pays. Texture bakes and the contact sheet are left out. The runs were not back to back: Remotion ran at 1-minute load 13 to 18, Manim tuned at 4 to 12, and resvg's load was not recorded.

| Pipeline | Final | Preview | Own stages, final / preview | PSNR |
|---|---|---|---|---|
| Remotion, before | 139 to 155 s | 55 to 73 s | | 36 dB |
| Remotion, after the fix | 81 s | 36 s | | reference |
| Manim, tuned | 21 s | 13 s | 16.3 / 7.7 s; untuned on the same basis 37 to 38 / 17 to 24 s | 31 dB |
| resvg, tuned | 23 to 25 s | 9 to 10 s | 17.5 to 20.2 / 4.1 to 4.7 s with repeated frames drawn once; 22.1 to 23.2 s final without | 29 dB |

The low end of each "before" range is a render on a quiet machine plus 5 s; the high end is a whole run under load. A 130 s preview that also baked and voiced from scratch is left out.

PSNR compares each whole video with the Remotion final after the fix. Above 40 dB two images look the same; two Chrome renders of this scene differ at 54 dB. The resvg and Manim scores are low mainly because hand-drawn lines and text shift by about a pixel. An earlier two-frame check against the older reference gave resvg 26 to 27 dB.

The fix itself changed the look. Filled shapes now pick up the paper weave and sit darker. On a 1080p crop 8 seconds in, they are 7 to 9 grey levels (of 255) darker inside the pizza fill, 1 to 3 on bare paper and about 4 over the whole crop. That is why "Remotion, before" scores 36 dB. Every pipeline that uses the ffmpeg multiply shares it, so it is not a difference between renderers.

What each keeps and loses against Remotion:

Manim is the prototype; resvg is the shipped port unless a cell says prototype.

| | Remotion | Manim | resvg |
|---|---|---|---|
| Scene code | React and CSS | Python | The same React components, drawing SVG only; the prototype used SVG strings from one function |
| Text | CSS boxes | Ported, with a bolder label backing | Boxes from font metrics; strokes look lighter and thinner than Chrome's |
| Layout check | Boxes plus a point-in-fill test (does a label sit on a filled shape?) | Boxes only | Boxes plus a fill test: each shape is drawn alone and its alpha sampled under the label. Passes the layout test's planted cases |
| Shown-text probe (which words are on screen at each beat) | Yes | Not built | Built |
| Beat timings | Yes | Ported | Ported |
| Ink and hatching | SVG `feTurbulence` and `feDisplacementMap` | Per-vertex wobble in Python, a different noise | Same filter, seeds and hatching as Remotion |
| Audio | Mixed in the render | Copied from the reference track; the mix is not built | Mixed apart in `scripts/mix.py` from the sound list the render writes |
| Kit rebuilt | | 413 lines | 371 lines (prototype) |
| Same pixels on two runs | not measured | not measured | Yes: two preview runs gave the same digest of every frame's pixels and byte-identical files, twice |

On frame 240, the prototype's cached ink differed from resvg's own filter in 68,810 of 8,294,400 bytes (mean 0.31 levels), mainly on anti-aliased edges. The shipped cache differs in 58,008 bytes (mean 0.009 levels), and no pixel by more than 8 levels.

## Why resvg?

The rule for the choice is output quality and speed only. The cost of a port does not count, because a port can be rebuilt. That rule overturned the first recommendation, which kept Remotion on porting cost.

- **Speed decides.** resvg takes 23 to 25 s against 81 s for the final, and 9 to 10 s against 36 s for a preview. The agent renders a video three or four times, final included, so previews dominate. Manim is 2 to 4 s faster on the final but 3 to 4 s slower on every preview.
- **Quality does not separate resvg from Manim by measurement.** Both score under 40 dB for the same reason, pixel shifts, and Manim scores 2 dB higher. By eye, resvg keeps Remotion's ink filter, seeds and hatching, but draws text lighter. Manim draws a bolder label backing and a different wobble.

Projected in a straight line from these runs, a 90-second video with two previews and a final takes about 13 minutes in Remotion after the fix, 3.3 minutes in Manim and 2.9 minutes in resvg. Each tool's startup sits in the scaled part, so long videos come out a few percent high.

The port rebuilt:

- The point-in-fill check. Each shape is drawn alone, and its alpha is sampled on a 13 by 5 grid under the label box.
- Label boxes from font metrics. resvg measures each line of text once and the render caches the width. The kit's three text components (`Label`, `Note`, `Tag`) never wrapped, so no wrapping was lost.
- The shown-text probe and the audio mix.
- The timing helpers scenes import (`useCurrentFrame`, `interpolate`, `Easing.bezier`, `random`), with the same values, so a scene ports by changing one import line.

The port gave up Remotion Studio, the live preview in a browser, and anything drawn with HTML or CSS, such as a formula rendered with KaTeX. One of the two test scenes drew its cell numbers as HTML boxes; after the port they draw nothing, and the render prints a `LAYOUT:` line naming the element.

## What does the shipped port measure?

Same scene, same machine, same day. The machine was busier than for the earlier rows: an ffmpeg left over from a test used about six cores through every run, and other agents shared the machine.

| Measure | Preview | Final | 1-minute load |
|---|---|---|---|
| `render.sh`, warm, whole run | 17.2 and 18.0 s; 31.5 s on the first run | 41.2 and 41.5 s | 19 to 28 at the start |
| `render.sh`, warm, whole run, re-timed the next day with the orphaned ffmpeg gone | 13.1 and 10.5 s | 24.3 and 24.8 s | 16 to 33 |
| Render step alone at 1080p, libx264 crf 18, two runs | | 21.7 and 22.6 s | 31 to 45 |
| Render step alone: draw, probes, finish, encode | 11.4 to 12.2 s, four runs | 34.1 and 37.3 s | 27 to 38 |
| Texture bake (paper and six grain frames) | 1.5 s, against 16.4 s in Chrome | | not recorded |
| One finished 1080p frame (`scripts/still.sh`) | | 2.6 to 3.9 s | up to 52 |
| PSNR against an older Remotion final | | 26.4 dB | |

Of 472 frames, 241 are drawn; the other 231 repeat an earlier frame and reuse its pixels. Per preview frame, React's markup takes about 5 ms, rounding attribute numbers 3.6 ms, resvg's scene 44 ms and the label layer 25 ms. A frame that gets the shown-text probe adds about 29 ms of probe and 15 ms of XML parsing. In one run, scanning every frame took about 3.5 s of the 12 s preview step.

The re-timed final matches the prototype's 23 to 25 s, so the 41 s of the first day was the leftover ffmpeg, not the port. The machine never went quiet for that re-time: Spotlight indexing held the 1-minute load at 16 for over an hour, and the script gave up waiting after 40 minutes.

The hardware encoder does not earn its place. On the same frames, `h264_videotoolbox` at libx264's bitrate (10.6 Mbit/s) took 15.8 and 15.5 s for the 1080p render step against libx264's 21.7 and 22.6 s, but scored 37.9 dB against a lossless encode of the same frames where libx264 scored 39.5 dB. At 16 Mbit/s it reached 38.5 dB in 15.9 s with a file 55% larger. A third off the render step for 1 to 1.7 dB less quality fails the rule that a renderer choice rests on quality or speed alone, so libx264 stays.

The older Remotion final is the one the eval runs used. It was rendered before the flat-render fix was committed; which pipeline drew it was not checked. Against it, the prototype's two-frame check also gave 26 to 27 dB, so the port scores where the prototype did. Drawn with the textures Chrome baked, the port scores 26.8 dB, so the texture bake is not where the gap comes from. The resvg paper alone scores 32.7 dB against Chrome's.

resvg 2.6 aborts the whole process when a group that needs its own layer (opacity or a filter) has nothing inside a nested `<svg>`'s box. The 2.7 alpha has the same bug and only turns the abort into an error. Scenes wrap everything in a nested `<svg>` the size of the frame, so the render turns that one into a plain group. The preview before and after that change scores 45 dB PSNR, too little to see, and the score against Remotion stayed at 26.4 dB.

The same panic hits any element with its own layer (opacity below 1, a filter, a clip or a mask) that lies wholly outside the box from -2 to +3 canvases: a half-transparent rect at x = 3850 aborts, one at 3800 does not. A filter whose region is set in user space, like the ink filter, is exempt. The camera's world puts shapes there all the time: moving the test scene's grid to x = 4400 aborted frame 0. So the render measures each such element with resvg and drops it when it lies more than a canvas away, where it draws nothing. Measured boxes are cached by markup. Elements at opacity 0 are dropped without measuring. The cull costs about 21 ms a frame on one thread at load 100, and paired preview runs with and without it took 31.6 and 31.5 s against 32.0 and 33.0 s, with the same pixel digest. The moved grid now renders, and its frame 285 scores 28.1 dB against the old pipeline's.

## How do I re-measure on my machine?

The benchmark script is not shipped, and the Manim and resvg prototypes are not either. The Remotion rows need the commit before the port. The commands below reproduce the shipped port's rows.

1. Time both modes twice each and note the load:

   ```
   time scripts/render.sh <project> preview; uptime
   time scripts/render.sh <project> final;   uptime
   ```

   On the machine above, at load 16 to 33, a warm run of a 16-second video took 10 to 13 s for the preview and 24 to 25 s for the final. On a quiet machine the two runs should agree within a few seconds.
2. Point `EXPLAINER_CACHE` at an empty folder (with the `fonts` folder copied in) and delete `<project>/public/tex`, then run the preview again. The paper and grain bake adds about 1.5 s; the finish frames are baked once more per size.
3. To time the render step alone, run it by hand from the skill folder:

   ```
   time node scripts/render.mjs <project> video 0.5 "$(scripts/finish.sh <project> 0.5)" /tmp/t.mp4 | grep '^frames'
   ```

   It prints `frames: 472 (241 drawn), sha1 …`. Expect near 12 s at preview on a comparable machine, and the same digest on every run.
4. For one layer's cost, copy the project once per layer and remove that layer. Run the full scene before, between and after the variants. A change smaller than the full-scene spread is noise.

A result that contradicts this paper: a preview render step far above 12 s on a quiet machine, or two runs that print different digests.

Noise on the machine these numbers came from:

| Measure | Spread | 1-minute load |
|---|---|---|
| Remotion preview drawing, three full runs | 40 to 53 s | 11 to 19 |
| Old script, same preview, two runs | 73 s and 130 s | 18 and 27 |
| resvg tuned, three runs each | 1 to 2.6 s | not recorded |
| resvg port, preview render step, four runs | 11.4 to 12.2 s | 27 to 38 |
| resvg port, `render.sh` final, two runs | 41.2 and 41.5 s | 19 to 28 |
| resvg port, `render.sh` final, two runs the next day | 24.3 and 24.8 s | 16 to 33 |
| resvg port, `render.sh` preview, two runs the next day | 13.1 and 10.5 s | 16 to 29 |
| Manim tuned, two runs each | 16.3 and 16.4 s; 7.7 and 7.6 s | 4 to 12 |

## What is still open?

- The merged `render.sh` was not re-timed. The before and after runs used the commit just before the merge, which doubled the baked grain loop from 15 to 30 frames.
- The `veryfast` encode of the flat render saved about 6 s of encoding in one run each. That is inside the noise, so it is not ranked.
- The drawing-only "before" figure (53 s) is the slowest of three full-scene runs; the others took 42 and 40 s.
- The cold preview after the fix took 78 s against 36 s warm. It also voiced the clips afresh, and its split between bake and voice was not measured.
- ~~Rendering the React scene files to SVG was never timed.~~ About 5 ms a frame; see "What does the shipped port measure?".
- ~~No pipeline was checked for identical pixels across two runs.~~ The resvg port gives identical pixels.
- ~~The port's final took 41 s against the prototype's 23 to 25 s.~~ Re-timed with the leftover ffmpeg gone: 24.3 and 24.8 s, the prototype's figure. No timing in this paper comes from a quiet machine; the lowest 1-minute load at the start of a run was 16.
- A nested `<svg>` other than the full-frame one can still hit the resvg 2.6 abort. No scene has one yet.
- The 90-second projection was not re-run with the shipped port.
- REFERENCE.md's 24 fps advice was not measured here.
- A drawn frame stays in memory until its last repeat. A frame repeated at both ends of a long video is held for the whole run, about 8 MB each at 1080p; this was not measured on a long video.
- On the far-grid final, ffmpeg once logged "Truncating packet of size 8294400 to 65536" under load 110 to 135. The file still has all 472 frames. A repeat run with a byte counter in the pipe sent exactly 472 full frames (3,914,956,800 bytes) and logged nothing; the cause was not found.
