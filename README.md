# claude-skills

Claude Code skills, hooks, and statusline. Drop into `~/.claude/` and go.

## What's Inside

### Method skills

Skills that shape how work is written, reviewed and delegated. French and English mixed, as they were written.

| Skill | What it does |
|-------|-------------|
| [prose](skills/prose/) | The register for every text a human reads: a question heading that carries its stake, the answer first, one why, details in a table, no proof trail. Ships a gate hook that runs on every reply and document write. |
| [intent-pr](skills/intent-pr/) | A one-sentence PR body carrying the intent; the certification of what was checked goes to the author, in session. |
| [design-props](skills/design-props/) | Several credible architectures compared on the real code, with the pivotal fact verified, before a design decision. |
| [doc-pedagogique](skills/doc-pedagogique/) | An explanatory document for a newcomer: a running example, honest verdicts, decisions framed as questions. |
| [torture-test](skills/torture-test/) | An adversarial QA pass that attacks code and tests only where a named beneficiary gains. |
| [mutation-test](skills/mutation-test/) | Mutation testing of a branch by parallel agents, one mutant at a time, survivors reported as the assertion that would kill them. |
| [rewrite-commits](skills/rewrite-commits/) | Collapse a draft PR's iteration commits into one to three atomic commits. |

### Making things

| Skill | What it does |
|-------|-------------|
| [series-planner](skills/series-planner/) | A series of videos, lessons or pages planned from a goal, its audiences and a source: tiers from overview to deep dive, every fact placed in exactly one unit and none dropped for depth, and one brief per unit. |
| [video-script](skills/video-script/) | One video's narration written beat by beat from a brief or a bare topic: what the voice says, the few words on screen in each beat, and a fact check that ties every claim to a source. |
| [video-production](skills/video-production/) | A finished narration turned into a video: plans what moves in each beat, animates it in Remotion, voices it, checks the layout and renders an MP4. Its pen-and-ink look, voice and music are a default style you can swap. |

The three chain: series-planner writes one brief per video, video-script turns a brief into narration (`beats.json`), and video-production draws, voices and renders it. Each also works on its own.

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

Install one skill and get its updates with the [skills CLI](https://github.com/vercel-labs/skills):

```sh
npx skills add cyrilghali/skills --skill video-production
npx skills update        # later, to pull new versions
```

`explainer-video` is now `video-production`, and the old name is gone from this repo, so updates stop reaching it. If you installed it under the old name, run `npx skills remove explainer-video`, then add `video-production` as above.

Or copy a skill to `~/.claude/skills/`:

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
