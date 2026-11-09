# Install

Requires `gh` (authenticated) and `jq`. The repository must have the Cubic GitHub app installed.

## Automatic babysit after a push

Add this entry under `hooks.PostToolUse` in `~/.claude/settings.json`. After any `gh pr create`, `gh stack push|submit` or `git push`, the agent is told to start babysit, which tags `@cubic-dev-ai` and waits for its review. A push that only touches prose files, or renames an `:atom` such as a feature flag everywhere it appears to a name that did not exist yet, gets a CI-only message instead; `evals/hook-cases.sh` shows each case.

```json
{
  "matcher": "Bash",
  "hooks": [
    { "type": "command", "command": "~/.claude/skills/babysit/hooks/auto-babysit.sh" }
  ]
}
```

Smoke test:

```sh
echo '{"tool_input":{"command":"gh pr create --draft"},"tool_response":{"stdout":"https://github.com/o/r/pull/1"}}' | ~/.claude/skills/babysit/hooks/auto-babysit.sh
```

It prints one JSON object with `additionalContext`. Any other command prints nothing.
