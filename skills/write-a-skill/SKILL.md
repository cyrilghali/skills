---
name: write-a-skill
description: Builds or changes an agent skill - a new one, an edit to an installed one, or a recurring correction turned into a skill edit - with evals written first that prove it beats no skill and fires on the right requests, as a self-sufficient, shareable folder. Use before changing any skill's files, and whenever the user asks to create, extend, fix, turn something into, or share a skill.
metadata:
  category: agent
---

# Write a skill

Build a skill as a folder someone else can drop into their own `skills/` directory and use the same day. Put everything it needs inside the folder, so nothing depends on the machine it was written on.

## Build the skill in this order

1. **Pin the job.** Write one sentence: what the skill does, and the two or three phrases a user types that should reach it. Ask the user only what changes the work; state a default for the rest.
2. **Check what exists.** List the installed skills, with the name and a one-line description of each. Follow symlinks, so none is missed. If one already covers the job, extend that skill instead of writing a new one. If a new skill is still the right call, say in one line why the overlap does not cover it.
3. **Name the category.** Every skill carries one: the phase of work the user is in when they call it. Reuse a category the installed skills already carry (`grep -rhs '^  category:' <skills-dir>/*/SKILL.md | sort | uniq -c`). A new category needs the user's approval. Put it in the frontmatter as `metadata:` then `  category: <name>`. Done when the frontmatter holds exactly one category.
4. **Lay out the folder.** Create only the files the job needs:

   ```
   skill-name/
   ├── SKILL.md        steps and rules, under 100 lines
   ├── REFERENCE.md    material consulted on demand (one level deep, any name)
   ├── scripts/        deterministic work: validation, formatting, extraction
   ├── hooks/          a gate the harness runs; INSTALL.md then shows the settings entry
   ├── INSTALL.md      only when a hook, a settings entry or a dependency is needed
   └── evals/          cases.md, rubric.md, triggers.md and baseline.md
   ```

5. **Write the evals first**, from `templates/evals.md`: five cases, taken from real use first, each with a named trap; a 0-2 rubric with case-specific must-checks and a fixed output format; twenty trigger queries, half of them near misses. Run every case once with no skill loaded and record the scores in `evals/baseline.md`. When the skill makes a costly artifact (a render, a video, a long run), record each run's time or cost beside its score, and get the user's go before a change that raises it. Done when the four files exist before SKILL.md does, because what the model already gets right needs no instruction.
6. **Write SKILL.md** with `WRITING.md` open. Make the description the pointer that fires the skill. Put the steps first and push reference material to a sibling file. State positive targets rather than bans. Give each meaning one home. End every step on a checkable completion criterion. Write only what closes the gaps the baseline showed. Done when this skill's `scripts/validate.sh <skill-folder>` passes.
7. **Run the evals.** When the skill being edited is the tool a live task is waiting on (a video render, a browser session), run its evals on a machine that task is not using, such as a spare server, or after the task finishes; never on the one render slot or browser the user is waiting for. If the Workflow tool lists a saved workflow that takes a skill folder through its own evals, run it with the skill's path. Otherwise follow the Running section of `templates/evals.md` by hand. Done when every case passes on all three runs and beats its baseline, the two judges agree, the held-out cases passed after the last refinement, a fresh agent's leak audit of every round found no line restating a case, and the trigger queries pass, held-out ones included.
8. **Audit for leaks.** This skill's `scripts/validate.sh` already greps for home paths. Add a grep for the user's name and for the names of other personal skills, outside `evals/`, where real transcripts may name them. Done when both greps return nothing. `INSTALL.md` may name the install target under the home folder.
9. **Prove it travels.** Copy the folder to a scratch directory and run one script or hook from the copy. Done when it works from there.
10. **Show the user** the folder tree as `find` prints it after the last write, and the eval scores. Ask what is missing.
11. **Commit the skill.** Resolve the skill folder's real path: follow the symlink from the skills directory to where the folder actually lives. If that path is inside a git repository, `git add` only the skill folder. Commit with one imperative line, such as `Add <skill> skill` or `Update <skill> skill: <what changed>`. Push only if the current branch already has an upstream and was already pushing there. Never force-push, and never set up a new remote. If the folder itself has no repo, look for a known mirror instead: a folder in another repo that a backup routine fills from the skills directory.

   | Mirror situation | Action |
   |---|---|
   | Scoped to this one skill | Add and commit it the same way |
   | Part of an indiscriminate whole-directory backup | Leave it to that routine's own schedule; say so in the report |
   | User explicitly asked for this skill's change committed now | Stage and commit only that skill's path inside the mirror |
   | Neither the folder nor a scoped mirror is in a repo | Say so plainly |

   Done when `git status` in the repo that owns the commit shows the skill folder clean, or the report states no repo was found.
12. **Report the description's cost.** Divide the characters in the final `description` field by 4. Report the result as the estimated token count added to every session where the skill is installed.

## Turn a recurring correction into a skill edit

Treat a correction as a candidate for a skill edit only when it repeats: two or more instances, not a one-off you happened to hit once. Rate its confidence first: strong (an explicit, repeated user preference), medium (an accepted workflow you saw work more than once), or weak (agent-chosen behavior with no direct feedback). Give weak evidence no artifact: say what you noticed and why it is too thin to encode, and stop there. When the evidence points in incompatible directions, call it contradicted and ask the user before encoding anything. Route what is left before touching prose:

- Prefer a lint rule, script or metadata flag that enforces the correction over an instruction, and drop the instruction once it does.
- Edit directly when the change is a one-line bullet or a tightened sentence.
- Run the full process above when the change is a new section, a new pattern table, or more than about 10 lines.
- Sharpen the description's "Use when" phrases instead of the body when the skill already covers it but did not fire.

A skill edit affects every future run of the skill. Apply the edit, then show it in the reply so the user can revert what they reject.

## Keep these rules in every skill

- **Give a skill that must prove real app behavior a feature map.** One file per feature (what it is, how to reach it, how it is driven, what state proves it works), plus an index, not one monolithic script.
- **Make the description the whole trigger.** Write it in the third person: what it does, then "Use when" with phrases the user actually types.
- **Write a script for anything deterministic.** Validation, formatting, extraction, a gate: written once, run every time, with explicit errors.
- **Keep time-bound content out.** Dates, versions and "currently" go stale. The environment (a config file, `--help`) is the source of truth for what it can answer.
- **Use one vocabulary.** Use the same word for the same thing across the description, the steps and the reference.
- **Keep the skill self-sufficient.** No user names, no home paths, no reliance on another personal skill, plugin or hook. Condense what the skill needs from elsewhere into a sibling file and credit its source.
- **Turn a personal tool into a role, not a blocker.** When a capability needs a private tool (a database client, an internal CLI), name the role and read the command from an environment variable (`<SKILL>_SQL`, `<SKILL>_CLI`). Check it in the steps with `command -v "$VAR"`; when it is unset, say in the output what was done without it. Document the variable as optional in `INSTALL.md`. Each machine exports it in the shell file every non-interactive shell reads (`.zshenv` for zsh), never in the skill.

## Model the folder on this example

A writing-style skill shows the shape: `SKILL.md` (register rules and process), `VOICE.md` (the human-voice pass condensed from public anti-slop guides), `hooks/style-gate.sh` (the mechanical checks, self-locating), `INSTALL.md` (two settings entries and a smoke test), `evals/` (five cases, all passing). Unpacked into a scratch directory, the gate ran and pointed at the copy's own `SKILL.md`.

## Sources

The recurring-correction routing and the feature-map rule adapt ideas from poteto's `pstack` (MIT, Lauren Tan). The confidence ladder (strong/medium/weak/contradicted) adapts cursor-team-kit's `workflow-from-chats` (MIT, Cursor).

Originally from github.com/mattpocock/skills (forked 25/09/2026; no longer tracked upstream).
