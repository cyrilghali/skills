# Install

Needs the `claude` CLI, `jq`, and a Linear MCP server that the CLI is already signed in to (a headless `claude -p` reuses that sign-in).

## Environment

| Variable | Default | Meaning |
|---|---|---|
| `LPH_LINEAR_MCP` | `linear` | Name of the Linear MCP server, as `claude mcp list` prints it |
| `LPH_NOTIFY` | unset (prints the report path to the log) | Command run as `$LPH_NOTIFY <title> <one line> <report path>` when a pass has something to say |
| `LPH_STATE_DIR` | `$HOME/.local/share/linear-project-hygiene` | Reports and `routine.log` |

## Schedule (macOS launchd)

One job per pass. Each calls `scripts/routine.sh daily` or `scripts/routine.sh weekly` from the installed skill folder, with the variables above under `EnvironmentVariables`. A laptop sleeps through fixed times, so call the script from several weekday slots behind a once-per-period guard (any wrapper that runs a command at most once per day or week and retries a failed run at the next slot).

```
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<label>.plist
launchctl kickstart -k gui/$(id -u)/<label>     # force one run now
```

## Smoke test

`scripts/routine.sh daily`, then read the last block of `routine.log`: it ends with `nothing to report` or a `report:` path.
