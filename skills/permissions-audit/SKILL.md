---
name: permissions-audit
description: Analyze recent Claude Code sessions for repeated permission approvals and suggest allowlist rules to reduce prompt fatigue. Classifies commands by risk level (green/yellow/red). Triggers on "permissions", "allowlist", "too many prompts", "permission fatigue", "allow commands", "reduce prompts".
disable-model-invocation: true
argument-hint: "[scan | apply | log]"
allowed-tools: Bash, Read, Grep, Glob, Edit
---

# Permissions Audit

Reduce permission prompt fatigue by analyzing what commands engineers repeatedly approve, then suggesting targeted allowlist rules.

```
Sessions → Scan transcripts for approved tool calls → Count repeated patterns →
Classify risk (green/yellow/red) → Suggest allowlist rules → Engineer approves → Apply to settings
```

No external API keys required. Claude Code reads its own session transcripts and updates its own settings.

## Arguments

- `scan` or (no argument) — Scan recent sessions and suggest allowlist rules
- `apply` — Re-show the last suggestions and apply selected rules
- `log` — Show history of past audits and applied rules

## Scan (default)

### Step 1: Find Session Transcripts

Locate recent Claude Code session transcript JSONL files:

```
find ~/.claude/projects/ -name "*.jsonl" -mtime -7 -type f 2>/dev/null
```

For each file, extract all Bash tool_use entries that were successfully executed (followed by a tool_result without error). Count command pattern frequency across sessions.

Only report patterns approved 3+ times across sessions.

### Step 2: Read Existing Allowlist

Read the engineer's current permission configuration:

```
cat ~/.claude/settings.json 2>/dev/null | jq '.permissions.allow // []'
cat .claude/settings.json 2>/dev/null | jq '.permissions.allow // []'
```

Filter out patterns already covered by existing allowlist rules. A pattern is "covered" if an existing rule would match it (e.g., `Bash(mix format:*)` covers `mix format --check`).

### Step 3: Classify by Risk Level

For each remaining command pattern, classify its risk:

**Green (safe — recommend allowing globally in `~/.claude/settings.json`):**
- Read-only: `git status`, `git diff`, `git log`, `git branch`, `ls`, `cat`, `head`, `tail`, `wc`, `tree`
- Formatters: `mix format`, `prettier`, `eslint --fix`, `rubocop -a`, `black`, `gofmt`
- Linters: `mix credo`, `eslint`, `tsc --noEmit`, `rubocop`, `flake8`, `clippy`
- Test runners: `mix test`, `npm test`, `jest`, `vitest`, `rspec`, `pytest`, `go test`
- Build/compile: `mix compile`, `npm run build`, `tsc`, `cargo build`, `go build`
- Dependency checks: `mix deps`, `npm list`, `npm outdated`

**Yellow (moderate — recommend allowing per-project in `.claude/settings.json`):**
- Package install: `mix deps.get`, `npm install`, `npm ci`, `yarn install`, `bundle install`, `pip install`
- Database dev ops: `mix ecto.migrate`, `mix ecto.rollback`, `rails db:migrate`
- Git staging: `git add`
- Dev servers: `mix phx.server`, `npm run dev`, `npm start`
- Code generation: `mix phx.gen.*`, `mix ecto.gen.migration`, `rails generate`

**Red (high risk — explain but let engineer decide):**
- Git push/pull: `git push`, `git pull`, `git fetch`
- Destructive git: `git reset`, `git checkout --`, `git clean`
- File deletion: `rm`, `rmdir`
- Network access: `curl`, `wget`
- Arbitrary execution: `eval`, `exec`, `source`
- Production commands: anything with `prod` or `production` in the path
- Package publishing: `mix hex.publish`, `npm publish`, `cargo publish`

### Step 4: Generate Allowlist Rules

Convert each command pattern into Claude Code allowlist format:

- Bash commands → `Bash(command_prefix:*)`
  - `mix test` approved 12 times → `Bash(mix test:*)`
  - `git status` approved 8 times → `Bash(git status:*)`

Group rules by risk level in the output.

### Step 5: Present Recommendations

```
## Permission Audit Results

Scanned: 14 sessions (Mar 11-18)
Repeated patterns found: 8
Already allowed: 2
New suggestions: 6

### Green — Safe to Allow Globally (~/.claude/settings.json)

| # | Command Pattern | Times Approved | Suggested Rule |
|---|----------------|---------------|----------------|
| 1 | mix test | 23 | Bash(mix test:*) |
| 2 | mix format | 18 | Bash(mix format:*) |

### Yellow — Recommend Per-Project (.claude/settings.json)

| # | Command Pattern | Times Approved | Suggested Rule |
|---|----------------|---------------|----------------|
| 3 | mix ecto.migrate | 7 | Bash(mix ecto.migrate:*) |

### Red — Review Carefully Before Allowing

| # | Command Pattern | Times Approved | Suggested Rule | Risk |
|---|----------------|---------------|----------------|------|
| 4 | git push | 4 | Bash(git push:*) | Pushes to remote without review |

---
Apply all green rules? Apply specific rules? Or save for later?
```

### Step 6: Apply Rules (Interactive)

Options:
1. **All green** — apply all green rules to `~/.claude/settings.json`
2. **All green + yellow** — green to global, yellow to project settings
3. **Pick specific** — let engineer select by number
4. **None** — save suggestions for later review

For each selected scope, read the current settings file, merge new rules into the `permissions.allow` array (avoiding duplicates), and write back using the Edit tool.

### Step 7: Log the Audit

```
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Audited N sessions, found M patterns, applied X rules" >> ~/.claude/permissions-audit.log
```

Save the full suggestion set to `~/.claude/permissions-audit-last.json` for the `apply` argument.

## Apply

Re-read cached suggestions from `~/.claude/permissions-audit-last.json` and present them again (Step 5-6). If no cached suggestions exist, tell the engineer to run `scan` first.

## Log

Read and display the audit history from `~/.claude/permissions-audit.log`.

## Privacy

- Session transcripts are read locally by Claude Code — no data leaves the machine
- Only command patterns are extracted, not command output or file contents
- The audit log records pattern counts, not specific commands or their arguments

**Done when:** Report is printed with risk-classified suggestions and user has accepted or declined rules.
