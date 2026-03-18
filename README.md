# claude-skills

Claude Code skills, hooks, and statusline. Drop into `~/.claude/` and go.

## What's Inside

### Skills

| Skill | What it does |
|-------|-------------|
| **[lint](skills/lint/)** | Lint agents and skills against best practices. Grades A-F, suggests fixes. |
| **[babysit-pr](skills/babysit-pr/)** | Monitor open PRs, surface blockers, auto-rebase stale branches, fix review comments. |
| **[handover](skills/handover/)** | Generate a structured handover doc from current git state for the next engineer/session. |
| **[permissions-audit](skills/permissions-audit/)** | Scan session transcripts for repeated approvals, suggest allowlist rules by risk level. |
| **[session-analyzer](skills/session-analyzer/)** | Analyze past sessions for skill gaps, repeated failures, workflow friction. |
| **[pm-review](skills/pm-review/)** | Review Linear issues in batch for completeness, consistency, scope creep. |
| **[linear-plan-review](skills/linear-plan-review/)** | Transform an implementation plan into a 3-part digest (Product/Tech Specs + DAG). |
| **[linear-orchestration](skills/linear-orchestration/)** | Convert a plan into Linear tickets with blocking dependencies. |

```
/lint my-agent
/babysit-pr quiet
/permissions-audit scan
```

### Plugins

**[docs](plugins/docs/)** — Documentation authoring workflow with 9 skills:

| Skill | What it does |
|-------|-------------|
| `/docs:strategy` | Analyze codebase, prioritize what to document |
| `/docs:outline` | Plan a page (type, audience, sections, sources) |
| `/docs:write` | Write a page following a style guide |
| `/docs:review` | Score a page against a 15-item checklist, auto-fix |
| `/docs:rewrite` | Bring an existing page into compliance |
| `/docs:audit` | Score an entire directory, produce gap report |
| `/docs:fill-gaps` | Generate stub outlines for undocumented features |
| `/docs:verify` | Cross-reference docs against source code |
| `/docs:compound` | Capture a lesson into the style guide |

Requires a `docs/style-guide.md` in your project. The skills reference it for rules, skeletons, and checklists.

### Hooks

**[shellcheck-post-edit.sh](hooks/shellcheck-post-edit.sh)** — Runs shellcheck on `.sh` files after every Write/Edit. Advisory only (exit 0).

**[tmux-pane-name.sh](hooks/tmux-pane-name.sh)** — Sets a random fun name on the tmux pane ("The Claudetroopers", "Opus Division", etc.).

### Statusline

**[statusline.sh](statusline.sh)** — Rich 3-line statusline showing:
- Model, directory, branch, worktree
- Context usage bar (color-coded), lines added/removed, duration
- Token counts, session cost, off-peak 2x indicator

## Install

### Skills

Copy any skill to `~/.claude/skills/`:

```sh
# All skills
cp -r skills/* ~/.claude/skills/

# Or pick one
cp -r skills/babysit-pr ~/.claude/skills/
```

### Docs Plugin

**Option A — Local directory:**

Add to `settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "cyrilghali-skills": {
      "source": {
        "source": "directory",
        "path": "/path/to/claude-skills/plugins/docs"
      }
    }
  },
  "enabledPlugins": {
    "docs@cyrilghali-skills": true
  }
}
```

**Option B — From GitHub** (once published as a marketplace):

```json
{
  "extraKnownMarketplaces": {
    "cyrilghali-skills": {
      "source": {
        "source": "github",
        "repo": "cyrilghali/claude-skills"
      }
    }
  },
  "enabledPlugins": {
    "docs@cyrilghali-skills": true
  }
}
```

### Hooks

Copy to `~/.claude/hooks/` and add to `settings.json`:

```sh
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/shellcheck-post-edit.sh"
          }
        ]
      }
    ]
  }
}
```

### Statusline

```sh
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## License

MIT
