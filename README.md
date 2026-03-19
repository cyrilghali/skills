# claude-skills

Claude Code skills, hooks, and statusline. Drop into `~/.claude/` and go.

## What's Inside

### Skills

**[lint](skills/lint/)** — Lint agents and skills against official best practices. Auto-detects type, runs criteria checks, grades A-F, suggests fixes.

**[pr-comments](skills/pr-comments/)** — Fetch, classify, fact-check, and fix GitHub review comments on your open PRs. Ships with 2 companion agents ([orchestrator](agents/pr-comments.md) + [analyzer](agents/pr-comments-analyzer.md)).

```
/lint my-agent
/pr-comments                          # scan current repo
/pr-comments owner/repo#42            # specific PR
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

Copy skills to `~/.claude/skills/` and agents to `~/.claude/agents/`:

```sh
cp -r skills/lint ~/.claude/skills/
cp -r skills/pr-comments ~/.claude/skills/
cp agents/pr-comments*.md ~/.claude/agents/
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
