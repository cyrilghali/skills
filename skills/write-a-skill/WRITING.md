# Writing for an agent

Levers that make a skill behave the same way on every run. Condensed from Matt Pocock's writing-for-agents skill (mattpocock-skills plugin), which carries the full argument.

## The description is a pointer

The description sits in context on every turn, whether or not it fires. It states what the material is and lists the branches that should reach it: one trigger per branch, the leading word first, nothing the body already carries. A must-have skill behind a weakly worded description is a variance bug: sharpen the wording before inlining anything.

## Where each piece sits

| Tier | Content | Cost |
| -- | -- | -- |
| In-file step | what the agent does, in order | read every run |
| In-file reference | rules and facts consulted on demand | read every run, attention thins |
| Sibling file behind a pointer | what only some runs need | read when the pointer fires |

Inline what every run needs; push behind a pointer what only some runs reach. Keep a concept's definition, rules and caveats under one heading. A file that is long even though every line is live still fails: attention thins across the excess.

## Steps end on a completion criterion

Each step names the condition that says it is done, checkable and demanding: "every modified model accounted for" drives work that "produce a change list" does not. A fuzzy bound invites finishing early, with the later steps pulling attention forward.

## Leading words

A compact word the model already knows (tracer bullet, tight loop, cold read) anchors a behaviour in one token and recruits what the model already holds about it. Repeat the word, never the sentence that defines it. Hunt for a triad spelled out three times and collapse it into one word.

## Positive targets

State the behaviour wanted ("write one-line comments") rather than the one banned: a prohibition drags the banned behaviour into context and makes it more available. Keep a ban only as a hard guardrail that has no positive phrasing, and pair it with the target.

## Pruning

- One home per meaning. Duplication costs tokens and inflates a meaning's rank.
- The environment is a source of truth: a config file or `--help` output the agent can read is not restated. Write down only what it cannot find: the unwritten convention, the reason, the gotcha.
- Every line still bears on the job, or it goes. Stale layers settle because adding feels safe and removing feels risky.
- A sentence the model already obeys by default says nothing: delete the sentence, not a few of its words.

## Invocation

A skill with a description can be fired by the agent and by other skills, at the price of permanent context load. A skill with `disable-model-invocation: true` fires only when the user types its name, at no context cost, and no other skill can reach it. Pick model invocation only when the agent or another skill must reach it alone.
