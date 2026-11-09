# Session map

Pick the row that matches why you opened the session, then follow its path left to right.
Call a skill with /name in Claude Code or $name in Codex. (manual) = starts only when called.
poteto-mode runs underneath every engineering path; you never call it yourself.

## Which path fits this session?

| I want to… | Path |
|---|---|
| Build a feature | grill-me → to-prd → prototype (if a fork is open) → write-plan → harden-plan → stacked-prs → **Code** → **Ship** |
| Fix a bug | debug-systematically → **Code** → **Ship** |
| Understand code or a failure | investigate-first (why for "why is it like this") — ends with an answer, no code |
| Handle a prod incident | incident-triage → Fix a bug |
| Check a merged PR in prod | deploy-watch |
| Split tickets for others | to-tickets (manual) |

## What does "Code" mean?

an isolated worktree → tdd → prove it on a running copy of the app → domain-review

## What does "Ship" mean?

comment-review (if comments added) → rewrite-commits (manual) → intent-pr → babysit (Cubic + CI) → mutation-test (risky lib/ logic)

## Now and then

| Job | Skill |
|---|---|
| Move a session to another machine | hand-off-session (manual) |
| Prune merged branches and worktrees | clean-git-repo (manual) |
| Architecture redesign session | improve-codebase-architecture (manual) |
| Reclaim disk space | free-disk-space (manual) |

Can't place the session? Ask "which skill fits <task>?"
