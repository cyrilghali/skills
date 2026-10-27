# Why does the make-video renderer look the way it does?

Read this before you change `scripts/render.sh` or the renderer. It records how the render was measured, which fixes held up, and why the renderer is moving from [Remotion](https://www.remotion.dev) to [resvg](https://github.com/linebender/resvg). The move is decided but not shipped: `render.sh` still renders with Remotion, and the resvg numbers come from a prototype that rebuilt one scene by hand.

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

One gotcha cost 28 minutes. ffmpeg's `blend` never ends when one input loops (`-stream_loop -1`) unless the filter gets `shortest=1`. The first finish pass ran for 1,714 s before it was stopped. `render.sh` now passes `blend=all_mode=multiply:shortest=1`.

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

| | Remotion | Manim | resvg |
|---|---|---|---|
| Scene code | React and CSS | Python | SVG strings from one function |
| Text | CSS boxes | Ported, with a bolder label backing | Boxes from font metrics; strokes look lighter and thinner than Chrome's |
| Layout check | Boxes plus a point-in-fill test (does a label sit on a filled shape?) | Boxes only | Boxes only; flags the planted cases, misses a label inside a shape |
| Shown-text probe (which words are on screen at each beat) | Yes | Not built | Not built |
| Beat timings | Yes | Ported | Ported |
| Ink and hatching | SVG `feTurbulence` and `feDisplacementMap` | Per-vertex wobble in Python, a different noise | Same filter, seeds and hatching as Remotion |
| Audio | Mixed in the render | Copied from the reference track; the mix is not built | Copied from the reference track; the mix is not built |
| Kit rebuilt | | 413 lines | 371 lines |
| Same pixels on two runs | not measured | not measured | not measured |

On frame 240, resvg's cached ink differs from resvg's own filter in 68,810 of 8,294,400 bytes (mean 0.31 levels), mainly on anti-aliased edges.

## Why resvg?

The rule for the choice is output quality and speed only. The cost of a port does not count, because a port can be rebuilt. That rule overturned the first recommendation, which kept Remotion on porting cost.

- **Speed decides.** resvg takes 23 to 25 s against 81 s for the final, and 9 to 10 s against 36 s for a preview. The agent renders a video three or four times, final included, so previews dominate. Manim is 2 to 4 s faster on the final but 3 to 4 s slower on every preview.
- **Quality does not separate resvg from Manim by measurement.** Both score under 40 dB for the same reason, pixel shifts, and Manim scores 2 dB higher. By eye, resvg keeps Remotion's ink filter, seeds and hatching, but draws text lighter. Manim draws a bolder label backing and a different wobble.

Projected in a straight line from these runs, a 90-second video with two previews and a final takes about 13 minutes in Remotion after the fix, 3.3 minutes in Manim and 2.9 minutes in resvg. Each tool's startup sits in the scaled part, so long videos come out a few percent high.

The port must rebuild:

- The point-in-fill check: render each shape alone and sample its alpha under each label box. resvg exposes the pixels; this is not built yet.
- Label boxes from font metrics. The prototype already does this. The kit's three text components (`Label`, `Note`, `Tag`) all use `whiteSpace: "nowrap"`, so no text wrapping is lost.
- The shown-text probe and the audio mix.

The port gives up Remotion Studio, the live preview in a browser, and anything driven by the DOM or CSS in a future scene, such as a formula rendered to HTML with KaTeX.

## How do I re-measure on my machine?

The benchmark script is not shipped, and the Manim and resvg prototypes are not either. You can reproduce the Remotion rows with the shipped scripts.

1. Time both modes twice each and note the load:

   ```
   time scripts/render.sh <project> preview; uptime
   time scripts/render.sh <project> final;   uptime
   ```

   On the machine above, at load about 15, a warm run of a 16-second video took 36 s for the preview and 81 s for the final. On a quiet machine the two runs should agree within a few seconds; on the shared machine, two runs of the old script differed by 57 s.
2. Point `EXPLAINER_CACHE` at an empty folder and delete `<project>/public/tex`, then run the preview again. The bake adds about 21 s.
3. To split the render, run its command by hand from the project folder and read the log's `Rendering frames done in` and `Stitching done in` lines:

   ```
   pnpm exec remotion render Explainer out/flat.mp4 --scale=0.5 --props='{"flat":true}' --crf=16 --x264-preset=veryfast --concurrency=2 --log=verbose 2>&1 | grep -E 'Rendering frames|Stitching'
   ```

   Expect drawing near 15 s at preview on a comparable machine.
4. For the floor, render the same command on a copy of the project whose scene draws nothing. Expect about 25 ms a frame at 2 tabs.
5. For one layer's cost, copy the project once per layer and remove that layer. Run the full scene before, between and after the variants. A change smaller than the full-scene spread is noise.

A result that contradicts this paper: a flat preview that does not draw in well under half the time of the old finished one, or a floor far above 25 ms a frame at 2 tabs.

Noise on the machine these numbers came from:

| Measure | Spread | 1-minute load |
|---|---|---|
| Remotion preview drawing, three full runs | 40 to 53 s | 11 to 19 |
| Old script, same preview, two runs | 73 s and 130 s | 18 and 27 |
| resvg tuned, three runs each | 1 to 2.6 s | not recorded |
| Manim tuned, two runs each | 16.3 and 16.4 s; 7.7 and 7.6 s | 4 to 12 |

## What is still open?

- The merged `render.sh` was not re-timed. The before and after runs used the commit just before the merge, which doubled the baked grain loop from 15 to 30 frames.
- The `veryfast` encode of the flat render saved about 6 s of encoding in one run each. That is inside the noise, so it is not ranked.
- The drawing-only "before" figure (53 s) is the slowest of three full-scene runs; the others took 42 and 40 s.
- The cold preview after the fix took 78 s against 36 s warm. It also voiced the clips afresh, and its split between bake and voice was not measured.
- Rendering the React scene files to SVG was never timed.
- No pipeline was checked for identical pixels across two runs.
- REFERENCE.md's 24 fps advice, GPU note and audio-mixing note were not measured here.
