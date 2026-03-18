# Shared Review Criteria

Criteria that apply to **both** agents and skills. Source: code.claude.com (March 2026).

---

## Metadata (META)

**META-01** | `name` field valid | **error**
- `name` exists in frontmatter
- Lowercase letters, numbers, hyphens only
- Max 64 characters
- **Agent:** must match the filename (without `.md`). E.g., `name: review-pr` in `review-pr.md`
- **Skill:** must match the directory name. E.g., `name: riot-api` in `riot-api/SKILL.md`
- Fail: `name: ReviewPR`, name missing, or name/filename mismatch

**META-02** | `name` not reserved or vague | **warning**
- Does not start with `anthropic-` or `claude-`
- Not a generic word: `helper`, `utils`, `tools`, `assistant`, `agent`
- Pass: `review-correctness`, `riot-api`, `fix-flaky-test`
- Fail: `helper`, `claude-agent`, `tools`

---

## Description (DESC)

**DESC-01** | `description` exists and valid length | **error**
- `description` field present in frontmatter
- Under 1024 characters, not empty
- Pass: Any non-empty description under 1024 chars
- Fail: Missing, empty, or over 1024 chars

**DESC-02** | Description says WHAT and WHEN | **error**
- Contains what it does (capability)
- Contains when to use it ("Use when...", "Use in...", "Use after...", "Triggers on...")
- Pass: `"Builds CRUD endpoints in parrot. Use for CRUD endpoint tickets."`
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

---

## Body Content (BODY)

**BODY-01** | Has clear workflow/instructions | **error**
- Contains actionable steps, workflow, or procedures
- Not just a description — tells Claude what to DO
- Steps are numbered or clearly sequenced
- Pass: `## WORKFLOW`, numbered steps, clear directives
- Fail: Only background info with no actionable guidance

**BODY-02** | Imperative form, no second person | **warning**
- Uses imperative/infinitive form: "Extract text", "Run the command", "Validate inputs"
- Avoids "you should", "you can", "you need", "you will", "you must"
- Exception: "You are..." in an opening role statement is acceptable
- Pass: "Extract the data. Validate the schema. Generate the report."
- Fail: "You should extract the data. You can then validate the schema."

---

## Content Quality (QUAL)

**QUAL-01** | Concise — no unnecessary explanation | **warning**
- Does not explain concepts Claude already knows
- Paragraphs justify their token cost
- Challenge: "Does Claude really need this explanation?"
- Pass: "Use pdfplumber for text extraction:" + code example
- Fail: "PDF files are a common file format..."

**QUAL-02** | Default with escape hatch, not option lists | **info**
- Recommends ONE default approach, provides ONE escape hatch
- Does not list 5+ alternatives and say "choose based on your needs"
- Pass: "Use pdfplumber. For scanned PDFs, use pdf2image instead."
- Fail: "You can use pypdf, pdfplumber, PyMuPDF, pdf2image, pdfminer..."

---

## Anti-Patterns (shared)

### Vague Description
```yaml
# BAD
description: Helps with code

# GOOD
description: Reviews PR for logic correctness. Checks requirements match, identifies missing edge cases. Use in review-pr pipeline.
```

### First/Second Person
```yaml
# BAD
description: I can help you process Excel files

# GOOD
description: Processes Excel files and generates reports. Use when analyzing spreadsheets.
```

### Too Many Options
```markdown
# BAD
You can use pypdf, pdfplumber, PyMuPDF, pdf2image, pdfminer, or tabula-py.

# GOOD
Use pdfplumber for text extraction. For scanned PDFs, use pdf2image instead.
```
