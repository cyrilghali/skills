# Drawn explainer

This is the default style, `ink-on-paper`. To use another look, rewrite this file and the tokens in `theme.ts`; the timing, word cues and layout marks stay the same.

Pen and coloured pencil on warm paper. One drawing holds the whole story, and the camera moves through it the way a hand-drawn documentary moves over a large illustrated map. Beauty comes from the drawing, not from depth or glow.

## Palette

| Token | Value | Use |
|---|---|---|
| `paper` | `#efe5cf` | The sheet; also the backing behind every label |
| `paperDeep`, `paperShade` | `#e2d4b6`, `#c9b48f` | Fibres, shading, the warm vignette |
| `ink` | `#2b241c` | Every line and every word; never pure black |
| `inkSoft`, `inkFaint` | `ink` at 60% and 20% | Resting outlines, hatching at rest, secondary marks |
| `earth` | `#4b3a29` | A large dark mass such as ground in a cut-away |
| `blue`, `amber`, `green`, `rust` | `#1f6d9e`, `#dc9a24`, `#1f8a66`, `#c95a26` | Actor hues: one per actor for the whole video |

## Type

| Role | Font | Size at 1080p |
|---|---|---|
| Label beside an object | Gaegu (`hand`) | 32 to 40 px |
| The beat's note, bottom left | Gaegu (`hand`) | 46 px |
| Code names, `path:line`, numbers | JetBrains Mono (`mono`) in a `Tag` | 24 to 30 px |

Labels are lowercase, a few words, and only words the voice says in that beat. They type on as the voice says them.

## Line, tone and colour

| Element | Treatment |
|---|---|
| Paper | Baked mottling, fibres and tooth (`Background`), with moving grain and a warm vignette on top (`Finish`) |
| Line | Ink at 1.5 to 3 px on screen, wobbled by the `ink` filter, which boils a few times a second |
| Tone | Pen hatching (`Hatch`) or a pattern fill, never a gradient; cross-hatch for the darkest tone |
| Actor | Drawn in ink; hatched in its hue only while lit (`dim(lit)` for the rest of the time) |
| Crowd or mass | Many small marks (`personPath`, `filePath`) at low contrast, so the one that matters can stand out |
| Arrow or thread | A thin ink curve with an open arrowhead (`marker-end="url(#arrow)"`), dashed when it is weak or temporary |
| Guide | A small ink character (`Guide`) that stands in for the narrator: it looks at what the voice names, and can travel with the camera |

## Camera and motion

- Build one world in world coordinates, larger than the frame. Every object keeps its place; beats change what is lit, drawn or moved, never which slide is shown.
- Move the camera between shots with eased moves (`move`) of 1 to 2 seconds; zoom in on the part that matters, then pull back to show where it sits.
- Things appear by being drawn as `p` goes from 0 to 1: lines grow, hatching fills, labels type on. Entrances take 0.6 to 0.9 s.
- After a reveal, hold still for at least half a second so the viewer can look.
- Keep line weight steady on screen as the camera zooms (`width / cam.s ** 0.6`).

## Sound

| Layer | Treatment |
|---|---|
| Music | The pad loop at low level, ducked under the voice, faded in and out |
| Cues | A tick for a small arrival, a whoosh for a camera move, a swell before a reveal, a chime on the payoff; at most one per sentence |

## Detail list

Check each mid-motion frame against every row.

| Detail | Holds when |
|---|---|
| Colour | At most two actors are lit; everything else is ink on paper |
| World | The objects from the last shot are still there, moved or dimmed, not swapped for new ones |
| Paper | Grain and vignette show; no flat digital fill anywhere |
| Labels | Lowercase, said by the voice, at least 24 px, each on its own paper backing where it sits on hatching or a crowd, none over an icon |
| Motion | The object sits between two states, never a cut |
| Space | About 100 px stays clear at every edge for anything the shot is about |

## Do

- Show abundance (hundreds of people, files or houses) as small low-contrast marks, so scale reads at a glance.
- Give each actor one hue and keep it for the whole video.

## Don't

- Use glow, drop shadows, gradients or 3D shading; the drawing carries the look.
- Put a sentence on screen; the voice carries it.
- Light more than two actors at once.
