# Explainer script reference

The beat order and voice rules follow Grant Sanderson's 3Blue1Brown videos.

## Order of the beats

| Beat | What it does |
|---|---|
| Hook | One question or surprising fact the viewer wants answered. |
| Concrete case | The example from `script.md`, with real numbers or real names. |
| Build | One step per beat, each changing the picture already on screen. |
| General rule | The pattern, stated only after the viewer has seen it work once. |
| Payoff | Answer the hook in one sentence, on the final picture. |

Give the video one main character who wants something, and let that character carry every beat: each beat shows what they do, see or run into. The video opens on their story, not on a tour of the system. A beat where the main character is absent explains a part of the system, so rewrite it from their point of view or cut it.

A longer video is a run of chapters of about two minutes, each with its own hook, build and payoff, in the same `beats.json`. Prefix each beat id with its chapter (`c2-ask`).

Open each new chapter with one or two sentences that tie what the viewer just learned to what the chapter asks, and give a new subject inside a chapter a lead-in clause, so the viewer never lands on a topic cold. A closing question that sets up the next video says what is still open and why it matters to the people in the story before it asks. In a series, end on a preview beat after that question: "In the next episode, you'll find out:" followed by the next episode's chapter questions, each short enough to stand alone.

## Voice

- Write for the ear: short sentences of about 15 words, one idea each, active voice.
- Name the thing on screen when it appears or moves: "this small house", "the dashed line".
- Use one word for one thing for the whole video and across the series: keep one glossary for the series, check every episode's narration against it, and keep internal code names out of the voice unless the viewer uses them daily.
- Explain a technical term in plain words the first time it is spoken, while the picture shows it, unless the viewer already uses it daily.
- Spell numbers and symbols as they are spoken: "v dot w", "eleven", "x squared".
- Keep narration plain text: no Markdown, no brackets, no stage directions. The voice reads every character.

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

**`claims.json`** is a list with one entry per claim, written after the beats and before the narration is voiced:

```json
[{"beat": "c2-expire", "claim": "A cached page expires after 300 seconds", "source": "cache.md:9", "verdict": "true"},
 {"beat": "c2-refresh", "claim": "A stale page is refreshed in the background", "source": "https://example.com/docs#refresh", "verdict": "partly", "note": "only while the origin answers"}]
```

- `source` is a `path:line` you opened, a URL you fetched or a document section you read. Open it before writing the entry; a source named from memory is not a source.
- Verdicts: `true` (the source says so), `partly` (true with a limit; the note says which part holds), `false` (the source says otherwise), `outdated` (true once, no longer), `unverifiable` (no source settles it, after you tried each kind that could: the code, the stored data, the logs and metrics, the vendor's docs, the person who decided). "Not in the code" is not unverifiable when a query, a log search or a doc can settle it.
- Fix a `false` or `outdated` claim in the narration. Cut an `unverifiable` claim, or reword it so it asserts nothing ("usually", "as far as we know" are not enough; drop the number). Keep the old verdict in the entry; the script requires the beat to have changed.
- Run `scripts/claims.py <folder> --stamp` right after judging, before the edit: it records each beat's text as checked (`text_at_check`). Edit the narration, then run `scripts/claims.py <folder>`.

**What the script checks.** It lists a beat that holds a number (digits or spoken: "forty", "percent"), a CamelCase or snake_case name, a `path.ext`, a `backticked` term, a quoted product name or an absolute word ("only", "never", "largest") and has no entry. One entry covers the whole beat, so the script cannot tell whether every claim in the beat has an entry: list each claim the beat makes. It also fails an entry that lacks a claim, source or verdict, and a `false`, `outdated` or `unverifiable` entry whose beat has not changed. A claim without such a token (a cause, a sequence) still needs an entry; the script cannot see it, so the second read does.

**The second read.** Run `scripts/claims.py <folder> --blind > blind-claims.json`: it keeps only each entry's beat, claim and source, so your verdicts and notes stay out of the handover. Hand a reviewer that has not seen your reasoning `beats.json`, `blind-claims.json` and read access to the sources. Use a subagent if the host offers one, else a new session. Do not hand over `claims.json`, `script.md` or your notes. Ask it to open each source and write `second-read.json` itself: one `{"beat", "claim", "verdict"}` per entry, with beat and claim copied unchanged, plus an entry for each claim in `beats.json` that has none. Never edit that file yourself. Where its verdict differs from yours, open the source, set the right verdict in `claims.json` and write the reason in `resolved`. Add each claim it found to `claims.json`. Run `scripts/claims.py <folder> --final`; it fails until every entry has a second-read verdict, every difference has a `resolved`, and every added claim is in `claims.json`.

## Remaking a narration

A remake loses facts when the trim is done by feel. Before writing the new beats, list every claim of the old version from its captions or transcript (never from memory), one row each in `remake.md`:

| Old claim | Where (timestamp) | Status | Why or where now |
|---|---|---|---|

Status is one of: `kept` (same beat), `moved` (now in another beat, name it), `dropped on purpose` (the reason is mandatory: out of scope, wrong, outdated), `dropped by accident`. A row is `kept` or `moved` only when the new narration itself states the claim; a claim left to the picture or a note is `dropped on purpose`, with that as its reason. Restore every accidental drop in the new narration, or, if it cannot fit, write it as a note to go next to the video. After the new beats exist, mark each row again; no row stays blank. Run the claims check on the new version as usual, so a claim carried over from the old one is checked against its source again. A real remake lost 34 in-scope facts before an audit like this one found them.

When the old version is a video with burned-in captions, OCR its frames instead of transcribing the audio.
