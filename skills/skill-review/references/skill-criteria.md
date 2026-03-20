# Skill-Specific Review Criteria

Criteria that apply **only to skills** (`SKILL.md` files in `.claude/skills/`). Sources: code.claude.com/docs/en/skills, Anthropic skill authoring best practices.

## Contents

- [Official Spec Reference](#official-spec-reference) — frontmatter fields, invocation control, string substitutions
- [Metadata (META)](#metadata-meta) — name validation
- [Description (DESC)](#description-desc) — existence, length
- [Description — Skill-Specific (SDESC)](#description--skill-specific-sdesc) — trigger phrases, voice, specificity
- [Body (SBODY)](#body-sbody) — workflow, voice, line count, success criteria, scripts, terminology, patterns, templates
- [Structure (STRUCT)](#structure-struct) — file existence, reference depth, load context
- [Invocation Control (INV)](#invocation-control-inv) — side effects, fork, tool scope
- [Progressive Disclosure (QUAL)](#progressive-disclosure-qual) — splitting complex skills
- [Anti-Patterns](#skill-anti-patterns) — common mistakes

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

### Context Budget

- Skill descriptions share a budget of 2% of context window (fallback: 16,000 chars)
- Skills exceeding the budget are excluded from context
- Check with `/context` for warnings about excluded skills
- Override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var

---

## Skill-Specific Checklist

### Description — Skill-Specific (SDESC)

**SDESC-01** | Includes trigger phrases | **warning**
- Contains 3+ concrete phrases a user would naturally say
- Phrases match how users talk, not technical jargon
- Pass: `"Triggers on 'review this skill', 'check my skill', 'audit SKILL.md'"`
- Fail: `"Use for document processing"` (too generic, only 1 trigger)

**SDESC-02** | Written in third person | **warning**
- Description is injected into system prompt; inconsistent POV causes discovery problems
- Pass: `"Processes Excel files and generates reports"`
- Fail: `"I can help you process Excel files"` or `"You can use this to process..."`

**SDESC-03** | Specific with key terms | **warning**
- Includes both WHAT the skill does and specific triggers/contexts for WHEN to use it
- Must provide enough detail for Claude to select from 100+ available skills
- Not vague — no "helps with", "does stuff", "works with", "handles"
- Pass: `"Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction."`
- Fail: `"Helps with documents"` or `"Processes data"`

### Metadata (META)

**META-01** | `name` field valid | **error**
- `name` exists in frontmatter
- Lowercase letters, numbers, hyphens only
- Max 64 characters
- Must match the directory name. E.g., `name: deploy` in `deploy/SKILL.md`
- Fail: `name: ReviewPR`, name missing, or name/directory mismatch

**META-02** | `name` not reserved or vague | **warning**
- Does not start with `anthropic-` or `claude-`
- Not a generic word: `helper`, `utils`, `tools`, `assistant`, `agent`, `documents`, `data`
- Prefer gerund form (verb + -ing): `processing-pdfs`, `analyzing-spreadsheets`
- Acceptable alternatives: noun phrases (`pdf-processing`), action-oriented (`process-pdfs`)
- Pass: `review-correctness`, `fix-flaky-test`, `deploy-staging`
- Fail: `helper`, `claude-agent`, `tools`

### Description (DESC)

**DESC-01** | `description` exists and valid length | **error**
- `description` field present in frontmatter
- Under 1024 characters, not empty
- Pass: Any non-empty description under 1024 chars
- Fail: Missing, empty, or over 1024 chars

### Body (SBODY)

**SBODY-00a** | Has clear workflow/instructions | **error**
- Contains actionable steps, workflow, or procedures
- Not just a description — tells Claude what to DO
- Steps are numbered or clearly sequenced
- Pass: `## WORKFLOW`, numbered steps, clear directives
- Fail: Only background info with no actionable guidance

**SBODY-00b** | Imperative form, no second person | **warning**
- Uses imperative/infinitive form: "Extract text", "Run the command", "Validate inputs"
- Avoids "you should", "you can", "you need", "you will", "you must"
- Exception: "You are..." in an opening role statement is acceptable
- Pass: "Extract the data. Validate the schema. Generate the report."
- Fail: "You should extract the data. You can then validate the schema."

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

**SBODY-04** | Feedback loops for quality-critical tasks | **warning**
- Quality-critical workflows include a validate → fix → repeat loop
- Pattern: run validator, fix errors, re-validate until passing
- Pass: "Run validate.py. If errors, fix and re-run. Only proceed when validation passes."
- Fail: Complex document editing with no validation step

**SBODY-05** | Workflow checklists for complex multi-step tasks | **warning**
- Multi-step workflows (4+ steps) provide a copy-paste checklist Claude can track
- Helps both Claude and user track progress through complex operations
- Pass: "Copy this checklist: - [ ] Step 1... - [ ] Step 2..."
- Fail: 8-step workflow with no progress tracking mechanism

**SBODY-06** | Dependencies listed for skills with scripts | **warning**
- If the skill references executable scripts or libraries, required packages are listed
- Pass: "Install required: `pip install pdfplumber`" before usage
- Fail: "Use pdfplumber to extract text" with no install instruction

**SBODY-07** | Scripts handle errors, don't punt to Claude | **warning**
- Only applies to skills that bundle executable scripts
- Scripts should handle error conditions explicitly (try/except, fallbacks) instead of failing and letting Claude figure it out
- Pass: Script catches FileNotFoundError and creates a default file
- Fail: Script does `open(path).read()` with no error handling

**SBODY-08** | No voodoo constants in scripts | **info**
- Only applies to skills that bundle executable scripts
- Magic numbers and configuration values must be justified with comments explaining why that value was chosen
- Pass: `TIMEOUT = 30  # HTTP requests typically complete within 30s`
- Fail: `TIMEOUT = 47` with no explanation

**SBODY-09** | Script intent clarity (execute vs read) | **warning**
- Only applies to skills that bundle executable scripts
- Instructions must make clear whether Claude should execute each script or read it as reference
- Pass: "Run `analyze_form.py` to extract fields" or "See `analyze_form.py` for the algorithm"
- Fail: "Use `analyze_form.py` for field extraction" (ambiguous — run it or read it?)

**SBODY-10** | Concise — only adds what Claude doesn't know | **warning**
- Claude is already very smart; only include context it doesn't already have
- Challenge each paragraph: "Does Claude really need this explanation?"
- Don't explain what PDFs are, how libraries work, or basic concepts
- Pass: 50-token code snippet with usage
- Fail: 150-token paragraph explaining what a PDF is before showing the snippet

**SBODY-11** | Appropriate degrees of freedom | **info**
- Match specificity to task fragility and variability
- High freedom (text-based heuristics): multiple valid approaches, context-dependent decisions
- Medium freedom (pseudocode/parameterized scripts): preferred pattern exists, some variation acceptable
- Low freedom (exact scripts, no params): fragile operations, consistency critical, specific sequence required
- Pass: Database migration with exact commands (low freedom); code review with general guidelines (high freedom)
- Fail: Fragile deployment with vague "deploy however you want"; simple review with rigid step-by-step script

**SBODY-12** | Consistent terminology | **warning**
- Pick one term for each concept and use it throughout the skill
- Pass: Always "API endpoint", always "field", always "extract"
- Fail: Mixing "API endpoint" / "URL" / "API route" / "path" for the same concept

**SBODY-12b** | Default with escape hatch, not option lists | **info**
- Recommends ONE default approach, provides ONE escape hatch
- Does not list 5+ alternatives and say "choose based on your needs"
- Pass: "Use pdfplumber. For scanned PDFs, use pdf2image instead."
- Fail: "You can use pypdf, pdfplumber, PyMuPDF, pdf2image, pdfminer..."

**SBODY-12c** | Verifiable intermediate outputs for destructive/batch ops | **info**
- Complex or destructive workflows produce an intermediate plan (e.g., JSON, checklist) that gets validated before execution
- Pattern: analyze → create plan → validate plan → execute → verify
- Pass: "Generate `changes.json`, validate with `validate.py`, then apply"
- Fail: Batch-modifying 50 files with no intermediate validation step

**SBODY-13** | No time-sensitive information | **info**
- Avoid dates, deadlines, or conditional logic based on when the skill is used
- If historical context is needed, use an "old patterns" collapsible section
- Pass: "Use the v2 API endpoint" with deprecated v1 in a details/summary block
- Fail: "If you're doing this before August 2025, use the old API"

**SBODY-14** | Concrete examples over abstract descriptions | **info**
- Use input/output pairs when output quality depends on seeing examples
- Examples help Claude understand desired style and detail level better than descriptions alone
- Pass: 2-3 examples showing input → expected output format
- Fail: Lengthy prose describing the desired output without any concrete example

**SBODY-15** | MCP tools use fully qualified names | **warning**
- Only applies to skills that reference MCP tools
- Format: `ServerName:tool_name` (e.g., `BigQuery:bigquery_schema`)
- Without the server prefix, Claude may fail to locate the tool
- Pass: "Use the GitHub:create_issue tool"
- Fail: "Use the create_issue tool"

**SBODY-16** | `$ARGUMENTS` referenced if skill accepts input | **info**
- If the skill is designed to accept arguments (per `argument-hint` or usage pattern), the body should reference `$ARGUMENTS`, `$ARGUMENTS[N]`, or `$N`
- If `$ARGUMENTS` is absent, arguments are appended as `ARGUMENTS: <value>` (less controlled)
- Pass: `"Fix GitHub issue $ARGUMENTS following our standards"`
- Fail: Skill with `argument-hint: [issue-number]` but body never references the argument

**SBODY-17** | Dynamic context injection used correctly | **warning**
- Only applies to skills using `` !`command` `` syntax
- Commands run BEFORE skill content is sent to Claude (preprocessing)
- Should not be confused with something Claude executes at runtime
- Ensure injected commands are fast and reliable (avoid slow/flaky commands)
- Pass: `` !`gh pr diff` `` to inject PR data into context
- Fail: `` !`curl slow-api.example.com/data` `` that may timeout during skill loading

**SBODY-18** | Conditional workflow pattern for multi-path skills | **warning**
- Skills with multiple valid paths should use decision-tree branching, not a single linear flow
- Pattern: "Determine the task type: Creating? → follow X. Editing? → follow Y."
- For large conditional workflows, push each branch into a separate reference file
- Pass: "1. Determine modification type: Creating? → Creation workflow below. Editing? → Editing workflow below."
- Fail: Single linear workflow that tries to cover both creation and editing with inline conditionals

**SBODY-19** | Template pattern (strict vs flexible) | **warning**
- Output-sensitive skills should provide a template for the expected output format
- Mark templates as strict ("ALWAYS use this exact structure") or flexible ("sensible default, adapt as needed")
- Strict: API responses, data formats, reports with fixed structure
- Flexible: Analysis, reviews, context-dependent output
- Pass: "ALWAYS use this exact template structure:" + template block
- Fail: "Generate a report" with no format guidance for a skill that produces structured output

**SBODY-20** | Description budget awareness | **warning**
- All skill descriptions share a budget of 2% of context window (fallback: 16,000 chars)
- Skills exceeding the budget are excluded from context entirely
- Descriptions over ~500 chars risk crowding out other skills
- Pass: 200-char description covering WHAT + WHEN concisely
- Fail: 800-char description that could be halved without losing signal

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

**STRUCT-04** | Table of contents in long reference files | **info**
- Reference files over 100 lines should include a TOC at the top
- Ensures Claude can see the full scope even when previewing with partial reads
- Pass: 150-line reference.md with `## Contents` section listing all sections
- Fail: 200-line reference file with no navigation aid

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

### Too Many Options Without a Default
```markdown
# BAD — confusing, no guidance
"You can use pypdf, or pdfplumber, or PyMuPDF, or pdf2image, or..."

# GOOD — default with escape hatch
"Use pdfplumber for text extraction.
For scanned PDFs requiring OCR, use pdf2image with pytesseract instead."
```

### Time-Sensitive Logic
```markdown
# BAD — will become wrong
"If you're doing this before August 2025, use the old API."

# GOOD — old patterns section
"## Current method
Use the v2 API.

<details><summary>Legacy v1 API (deprecated 2025-08)</summary>
The v1 endpoint is no longer supported.
</details>"
```

### Verbose Explanations of Basic Concepts
```markdown
# BAD — 150 tokens explaining what a PDF is
"PDF (Portable Document Format) files are a common file format that
contains text, images, and other content. To extract text from a PDF..."

# GOOD — 50 tokens, straight to the point
"Use pdfplumber for text extraction:
```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```"
```

### Inconsistent Terminology
```markdown
# BAD — same concept, 4 different names
"Create an API endpoint... configure the URL... add the route... set the path"

# GOOD — one term throughout
"Create an API endpoint... configure the endpoint... add the endpoint"
```

### MCP Tools Without Server Prefix
```markdown
# BAD — may fail with multiple MCP servers
"Use the create_issue tool"

# GOOD
"Use the GitHub:create_issue tool"
```
