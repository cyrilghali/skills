# Hand-off formats

What this skill reads and writes. The brief format is condensed from the series-planner skill's `FORMAT.md`; this copy keeps only the fields a script needs.

## In: the brief

A brief is one Markdown file per video. A series planner writes it; without one, write the same fields yourself at the top of `script.md`, under the same headings, so `claims.py --brief script.md` can read the facts table.

| Field | What the script does with it |
|---|---|
| Audience, with what it already knows | Sets the words that need no definition and the ones that do |
| Tier, and whether it stands alone | A unit that stands alone defines every term it uses; a later tier may lean on its prerequisites |
| The one idea | The sentence the video exists for |
| Length | The word budget |
| Prerequisites | Earlier units the viewer has seen |
| Facts this unit must say (id, fact, source) | Each one is said in the narration, and its claim entry cites the given source |
| Facts the viewer already has | Cued in a clause when the story needs them, or asked as a question when the viewer should recall one; never taught again |

## Out: script.md

The plan, with one row per beat:

| id | narration | words on screen | what the picture shows or changes |
|---|---|---|---|

The words on screen are short labels, numbers or names the narration says in that beat. The narration carries the sentence.

## Out: beats.json

The narration alone, one or two sentences of plain spoken text per beat, in the order of `script.md`:

```json
[{"id": "intro", "text": "This small light is a planet."},
 {"id": "orbit", "text": "Gravity bends its path into a circle around the sun."}]
```

Only `id` and `text`. A beat id may carry a chapter prefix (`c2-ask`). The text is read aloud as written: no Markdown, no brackets, no stage directions.

## Out: claims.json

One entry per fact the narration states, written and checked as `REFERENCE.md` describes. An entry for a brief fact carries its id in `fact`.
