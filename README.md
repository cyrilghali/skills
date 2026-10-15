# claude-skills

Claude Code skills, hooks, and statusline. Drop into `~/.claude/` and go.

## What's Inside

### Method skills

Skills that shape how work is written, tested and reviewed. Each one is a self-contained folder with its own evals.

| Skill | What it does and when to reach for it | Install |
|-------|----------------------------------------|---------|
| [prose](skills/prose/) | Rewrites text a person will read so the answer comes first and every term is defined; reach for it when a doc, ticket or reply feels wordy, unclear or AI-sounding. | `npx skills add cyrilghali/skills/prose` |
| [newcomer-doc](skills/newcomer-doc/) | Writes a design doc or explainer that a reader new to the system can follow in one pass; reach for it when you must explain options or an architecture to people outside the code. | `npx skills add cyrilghali/skills/newcomer-doc` |
| [design-props](skills/design-props/) | Produces several competing design proposals checked against the real system and compares them; reach for it before a design decision with more than one credible answer. | `npx skills add cyrilghali/skills/design-props` |
| [intent-pr](skills/intent-pr/) | Writes a short pull request body about the gap the change fills and gives the author a risk check in the chat; reach for it when you open a PR and want the review to go faster. | `npx skills add cyrilghali/skills/intent-pr` |
| [rewrite-commits](skills/rewrite-commits/) | Collapses a branch's noisy iteration commits into one to three atomic commits; reach for it before you ask for review. | `npx skills add cyrilghali/skills/rewrite-commits` |
| [torture-test](skills/torture-test/) | Attacks code and its tests with hostile inputs, retries and interrupted state, then reports what broke and who would see it; reach for it before you ship risky logic. | `npx skills add cyrilghali/skills/torture-test` |
| [mutation-test](skills/mutation-test/) | Plants one small fault at a time in the code a branch added and reports each fault the tests miss; reach for it when you need to know whether the tests would catch a regression. | `npx skills add cyrilghali/skills/mutation-test` |

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

Install one skill with the `skills` CLI:

```sh
npx skills add cyrilghali/skills/prose
```

Or copy its folder to `~/.claude/skills/`:

```sh
cp -r skills/prose ~/.claude/skills/
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
