---
name: which-skill
description: Finds the installed skill that fits a task and reminds the user which skill names are worth knowing, from a short shortlist plus a live scan of every skill folder on the machine. Use when the user asks "which skill should I use", "is there a skill for", "what skills do I have", "remind me the skill names", "skill cheat sheet", or cannot remember a skill's name.
metadata:
  category: agent
---

# Which skill

Answers one question: which installed skill does this job, and how do I call it. The shortlist (`SHORTLIST.md`) holds the names the user chose to know by heart; the scan (`scripts/list-skills.sh`) is the source of truth for everything installed. `CATEGORIES.md` defines the categories the inventory is grouped by.

## Steps

1. **Classify the ask.**
   - *Reminder* ("cheat sheet", "what should I remember", "remind me the names"): print `SHORTLIST.md` as it is, then stop.
   - *Match* ("which skill for X", "is there a skill that…"): go to step 2.
   - *Inventory* ("what skills do I have", "list my skills"): go to step 4.
   Done when the ask sits in exactly one branch.

2. **Match against the scan.** Run `scripts/list-skills.sh` from this folder and list every skill whose description covers the task. Done when each scan line was kept or ruled out.

3. **Pick the most specific.** Keep the skill whose description names the task itself over one that covers it as a step of a larger job; when two are equally specific, prefer the one listed in `SHORTLIST.md`. Read the first 30 lines of the pick's `SKILL.md` to confirm it does the job, and name a close runner-up in one line. Done when the pick is confirmed from its own file, or no description covers the task.

4. **Inventory.** Run the script and group its lines by their category column, in the order of `CATEGORIES.md`, then `plugin`, then `uncategorized` when it has members; names only, manual-only ones marked. Done when every line of the scan sits under exactly one category.

5. **Answer** in this shape:

   ```
   <skill-name>: <what it does, in one line>
   Call it: /<skill-name> in Claude Code, $<skill-name> in Codex
   ```

   Add `(manual-only: it starts only when you call it)` when the scan says `manual`. When nothing fits, say so and name the closest skill, with what it lacks and its call line. Done when every skill named appears in the scan or the shortlist.

## Example

User: "is there a skill to check that my tests are actually strong?"
The scan shows mutation-test (names the task) and torture-test (covers it as one axis of a larger QA pass); mutation-test is more specific:

```
mutation-test: mutates the code and reports which mutants the tests fail to catch.
Call it: /mutation-test in Claude Code, $mutation-test in Codex
```

## Rules

- **Named from the scan.** Every skill named comes from the scan or the shortlist, spelled as the scan prints it.
- **One answer.** One skill, or two when the task splits cleanly between them; the full inventory only on an inventory ask.
- **The shortlist is the user's.** Change it only when the user asks; a skill missing from the scan but listed there gets flagged as not installed.
