---
name: newcomer-doc
description: Writes documents for readers new to a subject - design docs, comparisons of options, decision docs, architecture notes, onboarding explainers and process walkthroughs - with context before jargon, one named example followed through every option or step, each option's real limits, and open decisions framed as questions. Load it first, before gathering material or drafting, for any such document: for new hires, another team or a product manager who don't know the system, from research or agent notes, or to rewrite a draft rejected as hard to follow or reading like a scorecard. Not for polishing prose that already exists (prose), producing design options to pick from (design-props), PR descriptions (intent-pr), READMEs, or short notes to experts.
metadata:
  category: write
---

# Newcomer doc

The reader is new to the subject. They must grasp the problem in 60 seconds and read the document in one sitting, without the code or the background in front of them.

## Structure, in this order

Sections 1 to 3 apply to every document. Sections 4 to 7 apply only when the document compares options or settles a choice. A document that explains a system with nothing to choose leaves them out. A short request merges or drops the sections it does not need. Headings and a reading guide exist for navigation: a document that fits on one screen needs neither. Each point gets the space its weight in the material warrants.

1. **Opening.** What the document compares or explains, and how to read it, in 4 to 6 lines.
2. **Where we start.** How the system works today, in plain words. No technical term before it has been introduced.
3. **The problem, on an example.** The running example (below), then the questions nobody can answer today, one by one.
4. **What is being asked.** The requirements, each tied to its source (a brief, a roadmap, a standard).
5. **The options.** One section per option still in play, all on the same template (below). An option the material already rules out gets no section: one sentence says why it is out.
6. **Comparison.** A table, then 3 to 5 lessons in prose ("the real choice is X against Y", "Z is a complement, not a rival").
7. **Recommendation.** A phased path, then **the open decisions phrased as questions**, each with what a yes changes ("Is escalation in this year's plan? If yes, start with option 2."). Open decisions come from the material; a request that arrives already decided ends on that decision.

Done when every section present earns its place for this request, and none is missing that the request needs.

## The running example

One concrete, named case ("Maria's report, filed on 1 March, fixed on 12 March") is introduced in the problem section and then **replayed in every option**: "on our example, here is what gets written, and where". It makes the model tangible. A reader does not understand a schema; they understand what happens to Maria. In a process with no options, the same case is followed through every step. A document that fits on one screen gives the example one sentence, inside the paragraph it illustrates.

Done when each option or step shows what happens to the named case.

## Template for each option

- **The idea.** Two or three sentences. No table or component name before it has been explained.
- **On our example.** The running example replayed in this design.
- **What we must build.** A numbered list in dependency order, with effort figures where the material gives them.
- **What it gives.** For each audience the option touches (users, teams, future product work).
- **Where it breaks.** The real limits, the worst one in bold. Every limit the material supplies appears here: the document's credibility comes from this section.
- **In one sentence.** The verdict.

## Diagrams, in layers

A diagram with three or more parts is never shown all at once: a reader cannot follow a system that arrives already assembled. Draw a short series instead, each one redrawing the last with one new part. For a flow A to B to C, draw A to B, then the same with C, then with the return path. A single complete diagram saved for the end is a reference, not teaching. A simple point needs no diagram.

## Prose rules

- Written prose in full sentences. Rewrite telegraph from the material (`A → B → fails`) into sentences; spell out abbreviations.
- Each technical term goes in `code` and is explained **at its first appearance**, the title and first sentence included.
- One idea per sentence. Split any sentence that needs a second read.
- Exact figures and units ("about 6 person-days", "31 figures") in place of "quickly" or "easily".
- A claim, limit or table cell the material does not support is labelled as your inference, or says "not measured". The reader must tell the sources' facts from your reasoning.
- Follow the typography of the document's language.

## Who writes the final pass

Subagents and research workflows produce the **material**: research, long proposals, summaries. The final pass is written in the main context by the one who holds all of it, sentence by sentence. Pasting or stitching subagents' compressed prose produces flat text that reads like a scorecard. To compress is to choose what to leave out, not to shorten sentences.

## Reference document

`EXEMPLAR.md`, next to this file, shows the full shape on a public subject: the tone, the running example, and the option template. Read it before a full comparison; skip it for a short memo.

## Finish

Aim for the length the subject needs: a rich comparison reads in 10 to 12 minutes, a short note in 2 to 3. Reread each section as a newcomer: "would they understand this without me?". When handing the document over, point the reader to the one or two sections that carry the decision.

## Sources

The layered-diagram rule adapts the teaching method of poteto's pstack (MIT, Lauren Tan).
