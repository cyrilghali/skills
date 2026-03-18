---
name: handover
description: Generate a structured handover document capturing current work state, decisions, and next steps for the incoming engineer or future session. Triggers on "handover", "write a handover", "create handover doc", "session handover", "end of day handover", "EOD summary".
disable-model-invocation: true
argument-hint: "[output path]"
allowed-tools: Bash, Read, Grep, Glob, Write
---

# Handover

Generate a structured handover document that captures the current state of work so another engineer (or a future session) can pick up seamlessly.

## Arguments

- **No args:** output to `docs/handover/YYYY-MM-DD.md` (create directory if needed).
- **Path provided:** write the handover to that path.

## Phase 1: Gather Context

Collect information from the current working state:

1. **Git state:**
   ```
   git log --oneline -20
   git diff --stat
   git branch -vv
   git stash list
   ```
2. **Open PRs** on the current repo:
   ```
   gh pr list --author @me --state open --json number,title,baseRefName,headRefName,isDraft,reviewDecision
   ```
3. **Recent commits** on the current branch with full messages:
   ```
   git log --format="%H%n%s%n%b%n---" -10
   ```
4. **Changed files** not yet committed:
   ```
   git status --short
   ```
5. **TODO/FIXME/HACK markers** in recently changed files:
   ```
   git diff --name-only HEAD~10 | xargs grep -n "TODO\|FIXME\|HACK" 2>/dev/null
   ```

## Phase 2: Analyze and Synthesize

Review the gathered data and identify:

- **What was accomplished** — summarize completed work from recent commits
- **What is in progress** — uncommitted changes, draft PRs, open branches
- **Decisions made** — extract rationale from commit messages and PR descriptions
- **Blockers and risks** — failing CI, unresolved review comments, merge conflicts
- **Next steps** — what should happen next based on the current trajectory

## Phase 3: Write the Handover

Use this template:

```markdown
# Handover — YYYY-MM-DD

## Status
One sentence: what state is the work in right now.

## Completed
- Bullet list of what got done, with PR/commit references

## In Progress
- What's mid-flight: branch names, PR numbers, description of state

## Decisions
- Key decisions made and their rationale
- Trade-offs considered and why this path was chosen

## Blockers
- Anything preventing forward progress
- Who or what is needed to unblock

## Next Steps
- [ ] Prioritized checklist of what to do next
- [ ] Include specific file paths, branch names, PR numbers

## Context
- Links to relevant PRs, issues, docs
- Anything the next person needs to know that isn't obvious from the code
```

## Voice and Tone

- Write in **third person**, past tense for completed work, present for current state.
- Be **specific**: include file paths, function names, PR numbers, branch names.
- Be **concise**: one sentence per bullet. No filler.
- Assume the reader has **repo context but no session context**.
- Prefer "X was done because Y" over just "X was done".

**Done when:** Handover document is written to the output path and its location is reported to the user.
