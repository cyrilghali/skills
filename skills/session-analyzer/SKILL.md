---
name: session-analyzer
description: Analyze Claude Code session transcripts to find gaps — missing skills, missing tools, repeated failures, wrong information, workflow friction. Produces a report and optionally creates tickets. Triggers on "analyze session", "session review", "what went wrong", "find gaps in my setup", "session postmortem".
disable-model-invocation: true
argument-hint: "[session-path or 'last']"
allowed-tools: Bash, Read, Grep, Glob, Write
---

# Session Analyzer

Analyze Claude Code session transcripts to identify gaps in the agent/skill/tool setup. Classify findings, produce a report, and optionally create tickets in a project tracker.

## Arguments

- **No args:** prompt for a session transcript path.
- **Path:** analyze the session transcript at that path.
- **`last`**: find the most recent session in `~/.claude/sessions/` or `~/.claude-code/sessions/`.

## Phase 1: Load Session

1. Locate the session transcript file.
   - If `last`, find the most recently modified session:
     ```
     ls -t ~/.claude/sessions/*.json 2>/dev/null | head -1
     ```
   - If a path is provided, read it directly.
2. Parse the session into a sequence of turns: user messages, assistant responses, tool calls, tool results.
3. Note the total turn count, duration, and tools used.

## Phase 2: Identify Gaps

Scan the session for patterns that indicate gaps. Classify each finding into exactly one category:

### Gap Categories

| Category | Signal | Example |
|----------|--------|---------|
| **missing_skill** | User asked for a workflow that required multi-step manual guidance; no skill was invoked | "Can you deploy this?" followed by 10 manual steps |
| **missing_tool** | Agent needed a capability it didn't have; user had to provide information manually | "I can't access that API" or user copy-pasting external data |
| **repeated_failure** | Same tool call failed 3+ times, or agent retried the same approach without adapting | Bash command failing in a loop with minor variations |
| **wrong_info** | Agent stated something incorrect that the user had to correct | Wrong file path, outdated API, incorrect flag |
| **workflow_friction** | Task completed but with unnecessary back-and-forth, extra confirmations, or wasted turns | 5 turns to do what should take 1, excessive "are you sure?" exchanges |

For each gap found, record:
- **Category** (from above)
- **Turns** involved (turn numbers)
- **Description** (one sentence)
- **Impact** (low / medium / high — based on time wasted or risk of recurrence)
- **Suggested fix** (new skill, new tool, config change, or documentation)

## Phase 3: Report

Write a report to `session-analysis-YYYY-MM-DD.md` (or print inline if short):

```markdown
# Session Analysis — YYYY-MM-DD

## Summary
- Session: <path>
- Turns: X | Duration: ~Y min
- Tools used: [list]
- Gaps found: X (A high, B medium, C low)

## Findings

### 1. [missing_skill] No deployment workflow
**Turns:** 14-28 | **Impact:** high
User asked to deploy. Agent walked through 10 manual steps that could be a single skill.
**Fix:** Create a `deploy` skill that wraps the deployment pipeline.

### 2. [repeated_failure] Flaky test retry loop
**Turns:** 30-42 | **Impact:** medium
Agent retried `npm test` 5 times without changing approach.
**Fix:** Add retry-with-backoff logic or a "diagnose test failure" skill.

## Recommendations
Prioritized list of improvements, grouped by effort (quick win / medium / large).
```

## Phase 4: Create Tickets (Optional)

After the report, ask: "Create tickets for these findings?"

Create tickets in your configured project tracker. Supports Linear MCP. If no tracker is available, output findings as a local report.

If the user confirms and Linear MCP is available:

1. For each high/medium finding, propose a ticket:
   - **Title:** `[gap-category] <short description>`
   - **Description:** finding details + suggested fix
   - **Priority:** map impact → urgent (high) / high (medium) / normal (low)
   - **Labels:** `session-gap`, gap category
2. Show all proposed tickets for approval.
3. On approval, create via Linear MCP `save_issue`.
4. Report created ticket IDs and URLs.

If no tracker is available, append a `## Tickets` section to the local report with the proposed ticket details.

**Done when:** Report is generated and tickets are created (or declined).
