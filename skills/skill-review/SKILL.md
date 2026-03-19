---
name: skill-review
description: Lints Claude Code agents and skills against official best practices. Runs type-specific criteria (skill-criteria.md or agent-criteria.md), produces pass/warn/fail report with grades and actionable fixes. Triggers on "lint skill", "lint agent", "review this skill", "review this agent", "check my skill", "audit skill", "claude best practices".
disable-model-invocation: true
argument-hint: "<name-or-path>"
allowed-tools: Read, Glob, Grep
---

# Skill Review

Review Claude Code agents and skills against official best practices (code.claude.com).

## Workflow

### Step 1: Resolve Target

Resolve `$ARGUMENTS` into a file path and detect its type.

**If empty:** list all available agents and skills, ask which to lint.

Use Glob to find them:
- Agents: `**/.claude/agents/*.md` and `**/.claude/agents/**/*.md`
- Skills: `**/.claude/skills/*/SKILL.md`

Also check `~/.claude/agents/` and `~/.claude/skills/` for personal ones.

**If path** (starts with `.`, `/`, or `~`):
1. Resolve to absolute path
2. If it contains `/agents/` → type is **agent**
3. If it contains `/skills/` or filename is `SKILL.md` → type is **skill**
4. If ambiguous, check file content for agent frontmatter (`tools:`) vs skill frontmatter (`allowed-tools:`)

**If bare name** (e.g. `review-pr`, `deploy`):
1. Search agents first:
   - `./.claude/agents/$ARGUMENTS.md`
   - `~/.claude/agents/$ARGUMENTS.md`
   - `./.claude/agents/$ARGUMENTS/$ARGUMENTS.md`
   - `~/.claude/agents/$ARGUMENTS/$ARGUMENTS.md`
2. Then search skills:
   - `./.claude/skills/$ARGUMENTS/SKILL.md`
   - `~/.claude/skills/$ARGUMENTS/SKILL.md`
3. If found in both, ask which to lint.
4. If not found, list similar names and ask.

**If qualified name** (e.g. `backend/deploy`):
1. Split on `/` → repo + name
2. Try `{repo}/.claude/skills/{name}/SKILL.md`
3. Try `{repo}/.claude/agents/{name}.md`

Record: **resolved path**, **type** (agent or skill), **name**.

### Step 2: Read Target Content

1. Read the resolved file completely
2. Parse frontmatter (YAML between `---` markers) and body separately
3. Count total lines
4. **If skill:** list all files in the skill directory

### Step 3: Load Review Criteria

Load the criteria file:

1. **If skill:** load [references/skill-criteria.md](references/skill-criteria.md) — META, DESC, SDESC, SBODY, STRUCT, INV, QUAL criteria
2. **If agent:** load [references/agent-criteria.md](references/agent-criteria.md) — META, DESC, TOOLS, ABODY, SCOPE, PERM, MODEL criteria

### Step 4: Evaluate

For each criterion in the loaded rubrics:
1. Check the condition against the target content
2. Record pass, warning, or failure with specific evidence
3. For failures/warnings, draft a concrete fix suggestion

**Agent evaluation tips:**
- TOOLS-02: compare `tools` list against what the body actually references. Unused tools are wasteful.
- ABODY-01: agents returning to orchestrators need structured output — check for `## OUTPUT` or equivalent.
- SCOPE-01: count distinct concerns in the body. More than 2-3 is a red flag.
- PERM-01: if the agent has `Write`/`Edit`/`Bash` + `bypassPermissions`, flag unless `maxTurns` is set.

**Skill evaluation tips:**
- SDESC-01: check if description includes natural-language trigger phrases a user would say.
- SBODY-00b: look for "you should", "you can", "you need" — these indicate second person in the body.
- SBODY-18: if the skill has multiple valid paths (e.g., create vs edit, bug vs feature), check for decision-tree branching.
- SBODY-19: if the skill produces structured output, check for a template marked as strict or flexible.
- SBODY-20: measure description length — warn if over ~500 chars.
- INV-01: look for Bash commands, file writes, git ops, API calls — side effects need `disable-model-invocation: true`.
- STRUCT-01: verify every `[text](path)` link resolves to an existing file.

### Step 5: Cross-Reference Usage

Search for how this agent/skill is used:

1. Use Grep to search for the name across skills and agents:
   - Pattern: `<name>` in `.claude/skills/` and `.claude/agents/` (glob `*.md`)
2. **If agent:** check if referenced as `subagent_type` in any orchestrator
3. Note if unused (orphaned) — informational, not a failure

### Step 6: Generate Report

```
## Lint: {name} ({type})
Path: {resolved-path}
Lines: {line-count}{" | Files: " + file-count if skill}

### Summary
Score: {pass}/{total} passing | {errors} errors, {warnings} warnings, {infos} info
Grade: A (0 errors) / B (0 errors, 1-2 warnings) / C (1 error or 3+ warnings) / D (2-3 errors) / F (4+ errors)

### Failures ({count})
- **{ID}** {criterion}: {specific issue found}
  Fix: {concrete action — include rewritten frontmatter/text when possible}

### Warnings ({count})
- **{ID}** {criterion}: {specific issue found}
  Fix: {concrete action}

### Info ({count})
- **{ID}**: {observation}

### Passing ({count})
- {ID}: {brief confirmation}

### Usage
- Referenced by: {list of skills/agents, or "none found"}
```

**Example failure finding:**
```
- **DESC-02** Description says WHAT and WHEN: description says "Builds endpoints" but never states when to use it.
  Fix: Append "Use for CRUD endpoint tickets." to the description.
```

**Done when:** Report is printed with grade, all criteria evaluated, and user asked about fixes.

After the report, ask: "Want me to fix the issues found?"
- If yes, apply fixes directly to the file
- If "fix all", apply all fixes without per-item confirmation
