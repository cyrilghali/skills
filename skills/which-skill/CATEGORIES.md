# Skill categories

Every skill carries one category: the phase of work you are in when you call it.

| Category | Holds the skills you call to |
|---|---|
| plan | decide what to build before any code: grilling, backlog triage, specs, plans, prototypes, module and design options |
| build | write or change code: test-first work, fixes, refactors, debugging, frontend |
| verify | prove work is correct: acceptance checks, reviews, adversarial and mutation testing, browser and CLI drivers |
| ship | take a change from branch to production: PR bodies, commits, review bots, stack splits, deploy follow-up |
| operate | watch production and run recurring routines: incidents, regressions, scheduled scans, machine upkeep |
| write | shape prose a human reads: register, de-slop, pedagogical documents |
| research | get a sourced answer from outside the code: web research, product quality, cited facts |
| agent | tune the agent itself: skills, context, handoffs, model advice, token cost |

Two more groups appear in the inventory but are never assigned by hand: `plugin` (skills a plugin ships, recognised by their path or a `plugin:name` form) and `uncategorized` (anything with no category yet).

## Which category wins when a skill fits two?

The phase you are in when you reach for it. `deploy-watch` checks production, but you call it right after merging, so it is `ship`; `debug-systematically` proves a root cause, but you call it while fixing code, so it is `build`.

## Where does the category live?

- A skill you own: `metadata.category` in its `SKILL.md` frontmatter.

  ```yaml
  metadata:
    category: verify
  ```

- A skill installed from someone else's repository, whose files an update overwrites: one line in `categories.tsv` beside this file, `name<TAB>category`.
