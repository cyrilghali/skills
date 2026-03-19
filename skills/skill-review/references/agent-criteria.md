# Agent-Specific Review Criteria

Criteria that apply **only to agents** (`.md` files in `.claude/agents/`). Source: code.claude.com/docs/en/sub-agents (March 2026).

## Contents

- [Official Spec Reference](#official-spec-reference) — frontmatter fields, location priority, design principles
- [Metadata (META)](#metadata-meta) — name validation
- [Description (DESC)](#description-desc) — existence, length
- [Tools (TOOLS)](#tools-tools) — tool list validation
- [Body (ABODY)](#body--agent-specific-abody) — output format, input spec, line count, failure handling
- [Scope (SCOPE)](#scope-scope) — single responsibility, boundaries
- [Permission & Safety (PERM)](#permission--safety-perm) — permission mode, maxTurns
- [Model Selection (MODEL)](#model-selection-model) — model-task match
- [Anti-Patterns](#agent-anti-patterns) — common mistakes

---

## Official Spec Reference

### Frontmatter Fields

| Field | Required | Default | Description |
|---|---|---|---|
| `name` | Yes | — | Identifier. Must match filename (without `.md`). |
| `description` | Yes | — | WHAT + WHEN. Used by orchestrators to decide delegation. |
| `tools` | Yes | — | Whitelist of tools. Comma-separated. |
| `disallowedTools` | No | — | Explicitly deny tools. Takes precedence over `tools`. |
| `model` | No | inherits | `haiku`, `sonnet`, or `opus`. |
| `permissionMode` | No | `default` | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan`. |
| `maxTurns` | No | — | Maximum turns before agent stops. |
| `skills` | No | — | Skills to preload into agent context. |
| `mcpServers` | No | — | MCP servers available to this agent. |
| `memory` | No | — | `user`, `project`, or `local`. |
| `background` | No | `false` | Run in background by default. |
| `isolation` | No | — | `worktree` for isolated git worktree. |
| `hooks` | No | — | Lifecycle hooks (PreToolUse, PostToolUse, Stop). |

### Location Priority

1. `--agents` CLI flag (session only)
2. `.claude/agents/<name>.md` or `.claude/agents/<name>/<name>.md` (project)
3. `~/.claude/agents/<name>.md` or `~/.claude/agents/<name>/<name>.md` (personal)
4. Plugin agents

### Design Principles

- **Single responsibility** — one type of task per agent
- **Minimal tools** — only grant what the agent actually needs
- **Structured output** — agents reporting to orchestrators need clear output formats
- **Context injection** — orchestrators inject context, agents don't search for it
- **Fail explicitly** — report what went wrong, don't silently succeed

---

## Agent-Specific Checklist

### Metadata (META)

**META-01** | `name` field valid | **error**
- `name` exists in frontmatter
- Lowercase letters, numbers, hyphens only
- Max 64 characters
- Must match the filename (without `.md`). E.g., `name: review-pr` in `review-pr.md`
- Fail: `name: ReviewPR`, name missing, or name/filename mismatch

**META-02** | `name` not reserved or vague | **warning**
- Does not start with `anthropic-` or `claude-`
- Not a generic word: `helper`, `utils`, `tools`, `assistant`, `agent`
- Pass: `review-correctness`, `deploy-staging`, `fix-flaky-test`
- Fail: `helper`, `claude-agent`, `tools`

### Description (DESC)

**DESC-01** | `description` exists and valid length | **error**
- `description` field present in frontmatter
- Under 1024 characters, not empty
- Pass: Any non-empty description under 1024 chars
- Fail: Missing, empty, or over 1024 chars

**DESC-02** | Description says WHAT and WHEN | **error**
- Contains what it does (capability)
- Contains when to use it ("Use when...", "Use in...", "Use after...", "Triggers on...")
- Pass: `"Builds CRUD endpoints. Use for CRUD endpoint tickets."`
- Fail: `"Builds endpoints"` (no when)

**DESC-03** | Third person voice | **warning**
- Uses third person ("Reviews...", "Orchestrates...", "Processes...")
- Imperative "Use when..." is acceptable (directive, not second-person)
- Not first person ("I review...", "I will...")
- Pass: `"Reviews PR for logic correctness."`
- Fail: `"I review PRs for logic correctness."`

**DESC-04** | Not vague | **error**
- Specific about capabilities — includes concrete actions or outputs
- Does not use vague phrases: "helps with", "does stuff", "works with", "handles"
- Pass: `"Extract text and tables from PDF files, fill forms, merge documents."`
- Fail: `"Helps with documents"`, `"Does stuff with files"`

### Tools (TOOLS)

**TOOLS-01** | `tools` field present | **error**
- `tools` list exists in frontmatter and is not empty
- Pass: `tools: Read, Grep, Glob, Bash`
- Fail: missing `tools` field

**TOOLS-02** | Tools are minimal | **warning**
- Agent only has tools it actually uses in its workflow
- Read-only agents should NOT have `Write`, `Edit`, or `Agent`
- Check body for tool usage patterns to validate
- Pass: Review agent with `tools: Read, Grep, Glob, Bash`
- Fail: Review agent with `tools: Read, Write, Edit, Bash, Grep, Glob, Agent`

**TOOLS-03** | `Agent` tool only for orchestrators | **warning**
- Only agents that dispatch subagents should have the `Agent` tool
- If `Agent` is in tools, the body must contain dispatch instructions
- Pass: Orchestrator with `Agent` tool and "Launch subagents..." instructions
- Fail: Leaf agent with `Agent` tool but no dispatch logic

**TOOLS-04** | MCP tools explicitly listed | **info**
- If the body references MCP tools (e.g., `mcp__github-gh__get_pr`), they must appear in `tools`
- Pass: `tools: Read, Grep, mcp__github-gh__pr_diff`
- Fail: Body references `mcp__github-gh__pr_diff` but it's not in `tools`

### Body — Agent-Specific (ABODY)

**ABODY-00a** | Has clear workflow/instructions | **error**
- Contains actionable steps, workflow, or procedures
- Not just a description — tells Claude what to DO
- Steps are numbered or clearly sequenced
- Pass: `## WORKFLOW`, numbered steps, clear directives
- Fail: Only background info with no actionable guidance

**ABODY-00b** | Imperative form, no second person | **warning**
- Uses imperative/infinitive form: "Extract text", "Run the command", "Validate inputs"
- Avoids "you should", "you can", "you need", "you will", "you must"
- Exception: "You are..." in an opening role statement is acceptable
- Pass: "Extract the data. Validate the schema. Generate the report."
- Fail: "You should extract the data. You can then validate the schema."

**ABODY-01** | Has structured output format | **error**
- Defines what the agent returns when done
- Format is concrete: template, example, or schema
- Pass: `## OUTPUT` section with a template
- Fail: "Return the results" with no format specification

**ABODY-02** | Has input specification | **warning**
- Defines what the agent receives via prompt
- Lists expected data: diff, ticket, file paths, etc.
- Pass: `## INPUT` section listing expected prompt contents
- Fail: Workflow references "the diff" but never specifies it should be provided

**ABODY-03** | Under 300 lines | **warning**
- Over 300 lines suggests doing too much or unnecessary explanation
- Pass: 80, 150, 280 lines
- Fail: 450 lines (suggest splitting responsibilities)

**ABODY-04** | Has failure handling | **warning**
- Defines what happens when things go wrong
- At minimum: what to do if the primary task fails
- Pass: `## FAILURE HANDLING` section or inline error handling
- Fail: No mention of failure — agent will improvise

**ABODY-05** | Has guard rails | **info**
- Defines critical constraints (things it must NEVER do, or always do)
- Pass: `## IMPORTANT` section with clear constraints
- Fail: No explicit constraints

### Scope (SCOPE)

**SCOPE-01** | Single responsibility | **warning**
- Handles one type of task or concern
- Body doesn't mix concerns (reviewing AND fixing, analyzing AND deploying)
- Pass: `review-correctness` only checks logic, not style or performance
- Fail: Agent that reviews code, fixes issues, AND pushes branches

**SCOPE-02** | Clear boundaries with related agents | **info**
- If similar agents exist, the description clarifies differentiation
- Pass: `"Reviews PR for logic correctness... Other reviewers handle style, performance, security."`
- Fail: Description overlaps significantly with another agent

### Permission & Safety (PERM)

**PERM-01** | Permission mode appropriate for scope | **warning**
- `bypassPermissions` only for trusted, well-scoped agents
- Agents with `Write`, `Edit`, or `Bash` that modify state should use `default` or `acceptEdits`
- Read-only agents can safely use `bypassPermissions`
- Fail: `Write, Edit, Bash` + `bypassPermissions` without `maxTurns`

**PERM-02** | `maxTurns` set for autonomous agents | **info**
- `bypassPermissions` or `dontAsk` agents should have `maxTurns`
- Leaf agents: 10-30 turns. Orchestrators: higher, but still capped.
- Fail: `bypassPermissions` with no `maxTurns`

### Model Selection (MODEL)

**MODEL-01** | Model matches task complexity | **info**
- `opus` for orchestration, complex reasoning, synthesis
- `sonnet` for straightforward analysis, pattern matching, implementation
- `haiku` for simple extraction, classification, formatting
- Omit to inherit from parent (usually fine)
- Fail: Simple formatter with `model: opus`, complex orchestrator with `model: haiku`

---

## Agent Anti-Patterns

### Missing Tools Field
```yaml
# BAD
name: code-reviewer
description: Reviews code for quality
# no tools field

# GOOD
name: code-reviewer
description: Reviews code for quality. Use after implementing features.
tools: Read, Grep, Glob, Bash
```

### Overly Broad Tool Access
```yaml
# BAD — review agent doesn't need write access
tools: Read, Write, Edit, Bash, Grep, Glob, Agent

# GOOD
tools: Read, Grep, Glob, Bash
```

### No Output Format
```markdown
# BAD
Return your findings.

# GOOD
Return findings as a structured list:
- **[<file>:<line>]** <Description>
  Category: <missing-requirement | edge-case | regression>
  Severity: <blocker | suggestion | nit>
```

### Mixed Responsibilities
```markdown
# BAD — 3 different jobs
1. Review the PR for issues
2. Fix all issues found
3. Push the fixed branch

# GOOD — single responsibility
1. Review the PR for issues
2. Return structured findings
```

### Dangerous Permission Mode
```yaml
# BAD
permissionMode: bypassPermissions
tools: Write, Edit, Bash
# no maxTurns

# GOOD
permissionMode: bypassPermissions
tools: Write, Edit, Bash
maxTurns: 25
```

### Agent Dispatching Without Agent Tool
```markdown
# BAD
tools: Read, Grep, Glob

## WORKFLOW
1. Launch the review-correctness subagent  # can't work

# GOOD
tools: Read, Grep, Glob, Agent
```
