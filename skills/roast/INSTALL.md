# Install

1. Copy the `roast/` folder into your skills folder (for Claude Code, `~/.claude/skills/`).
2. Put your category files in an `excellence/` folder beside the skills folder (`~/.claude/excellence/`), or anywhere else and export `ROAST_DIR=<that folder>` in the shell file every non-interactive shell reads (`~/.zshenv` for zsh). `CATEGORY.md` shows the shape of a file.
3. Recommended: install the critic agent, so the read-only rule is enforced by a hook instead of asked. For Claude Code, save this as `~/.claude/agents/roast-critic.md`:

   ```markdown
   ---
   name: roast-critic
   description: The fresh, blind critic for one round of the roast skill. Reads and observes only. Use only when the roast skill starts a round or its final score-only critic.
   model: opus
   effort: high
   hooks:
     PreToolUse:
       - matcher: "Bash|Write|Edit|MultiEdit|NotebookEdit"
         hooks:
           - type: command
             command: "~/.claude/skills/roast/hooks/readonly-guard.sh"
   ---

   You are a critic. You score an output you did not write against the bar you are handed, with evidence for every check. Change nothing outside your scratch folder.
   ```

   `hooks/readonly-guard.sh` needs `python3`. On macOS it rewrites every critic command to run inside `sandbox-exec`, which allows file writes only under temp folders, a `.roast/` run folder and tool caches, whatever program makes them. It also parses each command and denies what a file sandbox cannot see: pushes, gh writes, POST-style requests, sends, publishes, container runs, and network or account switches. It never approves a command, so the host's own permission check still judges what the parser misses, such as a request sent from inside a script. Setuid programs such as `ps` cannot run in the sandbox. Without `sandbox-exec` (Linux), only the parsed checks and the path check on the Write and Edit tools apply.
4. Recommended: install the bar-setter agent, so the bar comes from a fresh reader and not from the author. Save as `~/.claude/agents/bar-setter.md`:

   ```markdown
   ---
   name: bar-setter
   description: "Sets the bar for a piece of work before it is drafted (who reads it, what they must do after it, observable situational checks, the author's likely biases as checks, and what the excellent version looks like). Never sees a draft. Use when the roast skill starts, or before any deliverable is drafted."
   model: opus
   effort: high
   ---

   You define what excellent means for one piece of work you will not see. Follow the prompt you are handed and return only the bar in its format. When in doubt, choose the stricter check.
   ```
5. Optional dependencies for `scripts/capture.sh`: Google Chrome or Chromium for pages (set `CHROME` if it is not found), and `ffmpeg` for video frames.

Smoke test:

```sh
sh ~/.claude/skills/roast/scripts/capture.sh https://example.com /tmp/roast-smoke before
```

It prints four PNG paths.
