---
name: skill-review
description: Lints Claude Code skills against official best practices. Runs all criteria from skill-criteria.md, produces pass/warn/fail report with grades and actionable fixes. Triggers on "lint skill", "review this skill", "check my skill", "audit skill", "claude best practices".
disable-model-invocation: true
argument-hint: "<name-or-path>"
allowed-tools: Read, Glob, Grep
---

# Skill Review

Review Claude Code skills against official best practices (code.claude.com).

## Workflow

### Step 1: Resolve Target

Resolve `$ARGUMENTS` into a file path.

**If empty:** list all available skills, ask which to lint.

Use Glob to find them:
- Skills: `**/.claude/skills/*/SKILL.md`

Also check `~/.claude/skills/` for personal ones.

**If path** (starts with `.`, `/`, or `~`):
1. Resolve to absolute path
2. Verify it contains `/skills/` or filename is `SKILL.md`

**If bare name** (e.g. `deploy`, `onboarding`):
1. Search skills:
   - `./.claude/skills/$ARGUMENTS/SKILL.md`
   - `~/.claude/skills/$ARGUMENTS/SKILL.md`
2. If not found, list similar names and ask.

**If qualified name** (e.g. `backend/deploy`):
1. Split on `/` → repo + name
2. Try `{repo}/.claude/skills/{name}/SKILL.md`

Record: **resolved path** and **name**.

### Step 2: Read Target Content

1. Read the resolved file completely
2. Parse frontmatter (YAML between `---` markers) and body separately
3. Count total lines
4. List all files in the skill directory

### Step 3: Load Review Criteria

Load [references/skill-criteria.md](references/skill-criteria.md) — META, DESC, SDESC, SBODY, STRUCT, INV, QUAL criteria.

### Step 4: Evaluate

For each criterion in the loaded rubrics:
1. Check the condition against the target content
2. Record pass, warning, or failure with specific evidence
3. For failures/warnings, draft a concrete fix suggestion

**Evaluation tips:**
- SDESC-01: check if description includes natural-language trigger phrases a user would say.
- SBODY-00b: look for "you should", "you can", "you need" — these indicate second person in the body.
- SBODY-18: if the skill has multiple valid paths (e.g., create vs edit, bug vs feature), check for decision-tree branching.
- SBODY-19: if the skill produces structured output, check for a template marked as strict or flexible.
- SBODY-20: measure description length — warn if over ~500 chars.
- INV-01: look for Bash commands, file writes, git ops, API calls — side effects need `disable-model-invocation: true`.
- STRUCT-01: verify every `[text](path)` link resolves to an existing file.

### Step 5: Cross-Reference Usage

Search for how the skill is used:

1. Use Grep to search for the name across skills:
   - Pattern: `<name>` in `.claude/skills/` (glob `*.md`)
2. Note if unused (orphaned) — informational, not a failure

### Step 6: Generate Report

```
## Lint: {name} (skill)
Path: {resolved-path}
Lines: {line-count} | Files: {file-count}

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
- Referenced by: {list of skills, or "none found"}
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
