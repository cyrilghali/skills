# Default style

These defaults have no research behind them; `REFERENCE.md` says which. Replace any of them with the user's own style file. The hard rules in `SKILL.md` stay whatever this file says.

## Tiers

- Name tiers by depth: `overview` for everyone, then `deep-dive` for the audience that changes or runs the thing. Another series may sort by need instead (learn, do, look up, understand).
- A prerequisite sits in the same tier or a broader one. `scripts/plan.py` enforces this; change the script with this line.

## Units

- One idea per unit: the `idea` sentence names one thing the viewer can do or see after it.
- Lengths, by kind of unit:

| Kind | Default length | Note |
|---|---|---|
| Video, overview tier | about 2 minutes | Keep every video under about 6 minutes. |
| Video, deeper tier | about 4 minutes | |
| Lesson | the course's own slot | Use the length the user gives; a lesson cannot run past it. |
| Page | one task or one question | Split a page the reader must scroll through for two jobs. |

- A fact takes about 20 seconds of narration with its picture. The cap for a video is about 6 minutes; a unit that runs longer gets chapters of a few minutes each, and its `length` says so ("about 8 minutes, in three chapters").

## Cues

- A cue to an earlier fact is one clause: "the password rule from the first video". When real recall matters, ask the fact as a question and pause before giving it.
