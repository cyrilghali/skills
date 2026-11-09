# Install

Copy the folder into your skills directory (`~/.claude/skills/` for Claude Code).

Needs, on the machine that runs it:

- `gh`, authenticated with read access to the repository.
- `jq` and `bash`.
- `rg` (ripgrep), optional but strongly advised: transcripts run to gigabytes, and BSD grep takes minutes where ripgrep takes seconds.
- Claude Code session transcripts. Without them the breakdown still runs, and every "who decided" reads "unknown, no session found".

| Variable | Default | Role |
|---|---|---|
| `PR_BREAKDOWN_TRANSCRIPTS` | `$CLAUDE_CONFIG_DIR/projects`, else `~/.claude/projects` | Where session transcripts live |
| `PR_BREAKDOWN_MAX_CHARS` | `1500` | Longest message kept whole in a dump |
| `PR_BREAKDOWN_SQL` | unset | Optional read-only SQL command, called as `$PR_BREAKDOWN_SQL "<query>"`, used to count affected rows |

Export the optional variables in the file every non-interactive shell reads (`~/.zshenv` for zsh).

Smoke test:

```sh
scripts/sessions.sh list https://github.com/<owner>/<repo>/pull/<a PR you built with Claude Code>
scripts/sessions.sh dump <a session path marked built> | head -20
```

The first prints the building session first, marked `built`; the second prints `>>> OWNER:` and `ASSISTANT:` lines.

Run it at high reasoning effort: it is a verification job, and every claim it relays has to be checked against the code.
