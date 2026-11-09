# skills

Claude Code skills, hooks, and statusline. Drop into `~/.claude/` and go.

## What's Inside

37 skills, the same ones I run every day. Each folder is self-contained: `SKILL.md`, the reference files it points at, scripts, and evals. Skills marked *manual* start only when you call them by name.

### Plan

| Skill | What it does |
|-------|-------------|
| [grill-me](skills/grill-me/) | Interviews you about a plan, one question at a time, until every branch of the decision tree is settled. |
| [design-props](skills/design-props/) | Several credible architectures compared on the real code, with the pivotal fact verified, before a design decision. |
| [codebase-design](skills/codebase-design/) | Shared vocabulary for deep modules: find deepening opportunities and design an interface twice. |
| [plan-series](skills/plan-series/) | Plans a series of videos, lessons or pages from a source: which units, for whom, in what order, one brief per unit. |

### Build and understand

| Skill | What it does |
|-------|-------------|
| [investigate-first](skills/investigate-first/) | Diagnoses an unclear failure or explains a subsystem with ranked hypotheses before any edit. |
| [trace](skills/trace/) | Follows one user action front to back, hop by hop, each step tied to a file and line. |
| [deep-research](skills/deep-research/) | Splits a question into sub-questions, searches wide, and answers with every claim linked to two sources. |

### Check

| Skill | What it does |
|-------|-------------|
| [roast](skills/roast/) | Scores a finished output against a written definition of excellent; a fresh critic each round until nothing new turns up. |
| [mutation-test](skills/mutation-test/) | Plants small bugs in a branch's new code and reports each one no test catches, with the assertion that would. |
| [torture-test](skills/torture-test/) | An adversarial QA pass that attacks code and tests only where a named beneficiary gains. |
| [comment-review](skills/comment-review/) | Reviews every added or changed comment for accuracy, value and rot, plus comments the change made false. |
| [crap-check](skills/crap-check/) | CRAP score (complexity against coverage) for every function a branch changed, with the cheapest fix. |
| [dry-check](skills/dry-check/) | Near-duplicate code pairs involving lines a branch added, with the shared helper that removes them. |
| [scan-code-quality](skills/scan-code-quality/) | A severity-ranked structural review of a codebase, each finding verified by a separate checker. |

### Ship

| Skill | What it does |
|-------|-------------|
| [intent-pr](skills/intent-pr/) | A one- or two-sentence PR body on the product gap; the risk certification goes to the author, in session. |
| [pr-breakdown](skills/pr-breakdown/) | An ownership briefing for a PR a model wrote, so its owner can defend every decision. |
| [stacked-prs](skills/stacked-prs/) | Plans, sizes, creates and maintains stacked PRs with `gh stack`. |
| [babysit](skills/babysit/) | Walks a PR or stack through Cubic review and CI, fixing only the findings that hold up. |
| [rewrite-commits](skills/rewrite-commits/) | *Manual.* Collapses a draft PR's iteration commits into one to three atomic commits. |

### Write

| Skill | What it does |
|-------|-------------|
| [prose](skills/prose/) | The register for every text a human reads: a question heading, the answer first, one why, no proof trail. Ships a gate hook. |
| [deslop-en](skills/deslop-en/) | Removes AI writing patterns from English prose. |
| [readme](skills/readme/) | Writes a project README as a front page: the question it answers, real output, then install. |
| [doc-pedagogique](skills/doc-pedagogique/) | A teaching technical document in French: a running example, compared options, honest verdicts. |
| [ascii-graph](skills/ascii-graph/) | Draws graphs, trees, pipelines and state machines as box-drawing art for the terminal. |
| [write-video-script](skills/write-video-script/) | One video's narration, beat by beat, with the words on screen and a fact check. |
| [make-video](skills/make-video/) | Turns a finished narration into a rendered explainer video: drawn, animated, voiced. |

The three video skills chain: plan-series writes one brief per video, write-video-script turns a brief into narration (`beats.json`), and make-video draws, voices and renders it. Each also works on its own.

### Agents and sessions

| Skill | What it does |
|-------|-------------|
| [handoff](skills/handoff/) | Hands a self-contained side task to a fresh Claude session in a new tab (Herdr, tmux or Claude Desktop). |
| [hand-off-session](skills/hand-off-session/) | *Manual.* Compacts the session into a brief, optionally packed and sent to another machine. |
| [which-skill](skills/which-skill/) | Finds the installed skill that fits a task. |
| [write-a-skill](skills/write-a-skill/) | Builds or changes a skill with evals written first, as a shareable folder. |
| [writing-great-skills](skills/writing-great-skills/) | *Manual.* Reference vocabulary and principles for writing skills. |
| [skill-telemetry](skills/skill-telemetry/) | *Manual.* One JSON line per skill run, read back as medians and trends. |
| [cyril-mode](skills/cyril-mode/) | *Manual.* Makes an agent work the way I do, in a harness where my rule files are absent. |

### Routines

| Skill | What it does |
|-------|-------------|
| [routine-watchdog](skills/routine-watchdog/) | Daily, model-free health check of macOS launchd routines. |
| [session-watchdog](skills/session-watchdog/) | Finds handoff sessions that went idle before finishing, and nudges only the stalled ones. |
| [linear-project-hygiene](skills/linear-project-hygiene/) | Repairs drift in the Linear projects you lead and drafts a weekly pulse. |
| [complexity-trend](skills/complexity-trend/) | *Manual.* Weekly, model-free reading of an Elixir codebase's complexity trend. |

### Credits

[codebase-design](skills/codebase-design/), [grill-me](skills/grill-me/), [write-a-skill](skills/write-a-skill/) and [writing-great-skills](skills/writing-great-skills/) started from [mattpocock/skills](https://github.com/mattpocock/skills), MIT License, Copyright (c) 2026 Matt Pocock. [deslop-en](skills/deslop-en/) lists the sources it draws on in its frontmatter.

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
npx skills add cyrilghali/skills --skill make-video
npx skills update        # later, to pull new versions
```

The video skills were renamed after what they do: `explainer-video` (later `video-production`) is now `make-video`, `series-planner` is now `plan-series`, and `video-script` is now `write-video-script`. The old names are gone from this repo, so updates stop reaching them. If you installed one under an old name, run `npx skills remove <old name>`, then add the new name as above.

Or copy a skill to `~/.claude/skills/`:

```sh
cp -r skills/prose ~/.claude/skills/
```

Some eval folders hold a `private/` subfolder on my machine for cases tied to private code. It is gitignored, so those skills ship with fewer eval cases here.

### Docs Plugin

**Option A — Local directory:**

Add to `settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "cyrilghali-skills": {
      "source": {
        "source": "directory",
        "path": "/path/to/skills/plugins/docs"
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
        "repo": "cyrilghali/skills"
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
