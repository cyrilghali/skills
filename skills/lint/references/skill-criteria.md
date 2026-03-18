# Skill-Specific Review Criteria

Criteria that apply **only to skills** (`SKILL.md` files in `.claude/skills/`). Source: code.claude.com/docs/en/skills (March 2026).

---

## Official Spec Reference

### Frontmatter Fields

| Field | Required | Default | Description |
|---|---|---|---|
| `name` | No | Directory name | Lowercase letters, numbers, hyphens. Max 64 chars. |
| `description` | Recommended | First paragraph | WHAT + WHEN. Max 1024 chars. |
| `argument-hint` | No | — | Hint for autocomplete. Example: `[issue-number]` |
| `disable-model-invocation` | No | `false` | `true` prevents Claude auto-loading. |
| `user-invocable` | No | `true` | `false` hides from `/` menu. |
| `allowed-tools` | No | — | Tools allowed without permission when skill is active. |
| `model` | No | — | `haiku`, `sonnet`, or `opus`. |
| `context` | No | — | `fork` runs in isolated subagent. |
| `agent` | No | `general-purpose` | Subagent type when `context: fork`. |
| `hooks` | No | — | Hooks scoped to skill lifecycle. |

### Invocation Control Matrix

| Frontmatter | User invokes | Claude invokes | Loaded when |
|---|---|---|---|
| (default) | Yes | Yes | Description in context; full skill on invocation |
| `disable-model-invocation: true` | Yes | No | Loads only when user invokes |
| `user-invocable: false` | No | Yes | Description always in context |

### String Substitutions

| Variable | Description |
|---|---|
| `$ARGUMENTS` | All arguments passed when invoking |
| `$ARGUMENTS[N]` / `$N` | Specific argument by 0-based index |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing SKILL.md |

### Progressive Disclosure Rules

- SKILL.md is the entry point (required)
- Keep SKILL.md under 500 lines
- Move details to reference files in the same directory
- References one level deep only (no chains)
- Link references from SKILL.md with load context

### Location Priority

Enterprise > Personal (`~/.claude/skills/`) > Project (`.claude/skills/`) > Plugin

---

## Skill-Specific Checklist

### Description — Skill-Specific (SDESC)

**SDESC-01** | Includes trigger phrases | **warning**
- Contains 3+ concrete phrases a user would naturally say
- Phrases match how users talk, not technical jargon
- Pass: `"Triggers on 'review this skill', 'check my skill', 'audit SKILL.md'"`
- Fail: `"Use for document processing"` (too generic, only 1 trigger)

### Body — Skill-Specific (SBODY)

**SBODY-01** | Under 500 lines | **warning**
- If over 500, content should be split into reference files
- Pass: 120, 350, 499 lines
- Fail: 650 lines (suggest splitting into references/)

**SBODY-02** | Has success criteria | **warning**
- Defines how to know the skill executed correctly
- Can be explicit ("This is complete when...") or implicit (clear output format)
- Pass: Output template, checklist, completion statement
- Fail: No indication of what "done" looks like

**SBODY-03** | No Windows paths | **warning**
- All file paths use forward slashes
- Pass: `scripts/validate.py`
- Fail: `scripts\validate.py`

### Structure (STRUCT)

**STRUCT-01** | All referenced files exist | **error**
- Every markdown link `[text](path)` to a local file resolves to an existing file
- Skip URLs (http://, https://)
- Resolve relative to SKILL.md's directory
- Fail: `[reference](reference.md)` but file doesn't exist

**STRUCT-02** | References one level deep | **warning**
- Reference files do not themselves link to other reference files
- SKILL.md -> reference.md is fine
- SKILL.md -> reference.md -> details.md is too deep

**STRUCT-03** | Supporting files referenced with load context | **warning**
- Files in the skill directory are linked from SKILL.md
- Links include guidance on WHEN to load ("For API details, see...")
- Orphan files (present but never referenced) are flagged

### Invocation Control (INV)

**INV-01** | Side-effect workflows have `disable-model-invocation: true` | **warning**
- If the skill performs side effects (file writes, git ops, API calls, deployments), it should not be auto-triggered
- Side effects = anything that changes state outside the conversation
- Pass: Deploy skill has `disable-model-invocation: true`
- Fail: Deploy skill can be auto-triggered by Claude

**INV-02** | `context: fork` has actionable content | **warning**
- If `context: fork` is set, SKILL.md must contain a concrete task
- The content becomes the subagent's prompt — guidelines alone produce no output
- Pass: `context: fork` with "Research $ARGUMENTS thoroughly: 1. Find files..."
- Fail: `context: fork` with "Follow these API conventions when writing code"

**INV-03** | `allowed-tools` appropriately scoped | **info**
- Should be minimal — only tools the skill genuinely needs
- Overly broad: `Bash(*)` when only `Bash(git *)` is needed
- Pass: `Read, Grep` for a read-only skill
- Fail: `Bash(*)` for a skill that only reads files

### Progressive Disclosure (QUAL)

**QUAL-03** | Progressive disclosure for complex skills | **info**
- Complex skills (multiple workflows, large reference material) should split into reference files
- SKILL.md serves as overview + navigation
- Simple skills (< 200 lines, one workflow) can be single-file
- Fail: 600-line monolithic SKILL.md

---

## Skill Anti-Patterns

### Deep Reference Nesting
```
# BAD (3 levels)
SKILL.md -> advanced.md -> details.md -> examples.md

# GOOD (1 level)
SKILL.md -> advanced.md
SKILL.md -> details.md
SKILL.md -> examples.md
```

### Missing Invocation Control
```yaml
# BAD — deploy can be auto-triggered
name: deploy
description: Deploy to production

# GOOD
name: deploy
description: Deploy to production
disable-model-invocation: true
```

### Dynamic Context Executing During Load
```markdown
# BAD — executes during skill loading
Load status with: !`git status`

# GOOD — space prevents execution
Load status with: ! `git status` (remove space in actual usage)
```

### Overly Broad Tool Access
```yaml
# BAD
allowed-tools: Bash(*)

# GOOD
allowed-tools: Read, Grep, Bash(git status)
```
