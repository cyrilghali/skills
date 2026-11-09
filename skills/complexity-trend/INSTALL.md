# Install

Copy the folder into your skills directory (`~/.claude/skills/` for Claude Code).

Needs, on the machine that runs it:

- `python3` (3.9 or later), `git`, and the Elixir toolchain the measured repo builds with.
- The repo using Credo (`mix credo` available).
- `gh`, authenticated with read access to the repo, for the merged pull request
  count. Without it the trend still prints and says the count is unavailable.

Environment:

| Variable | Required | Default |
|---|---|---|
| `COMPLEXITY_REPO` | yes, to measure | none: a local clone with an `origin` remote |
| `COMPLEXITY_CHECKOUT` | no | `~/.local/share/complexity-trend/checkout` (a detached worktree the script creates and owns) |
| `COMPLEXITY_HISTORY` | no | `~/.local/share/complexity-trend/history.tsv` |

Smoke test: `scripts/complexity_trend.py --self-test` prints `self-test passed`.
Then run it once with `COMPLEXITY_REPO` set and check that the history gained a
row for today.

## Routine (launchd, macOS)

Weekly, model-free. Write absolute paths (launchd does not expand `~`), save
under `~/Library/LaunchAgents/`, then `launchctl bootstrap gui/$(id -u) <plist>`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>complexity-trend</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string><string>-lc</string>
    <string>/path/to/skills/complexity-trend/scripts/complexity_trend.py >> "$HOME/.local/share/complexity-trend/routine.log" 2>&amp;1</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>COMPLEXITY_REPO</key><string>/path/to/clone</string>
  </dict>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key><integer>1</integer>
    <key>Hour</key><integer>8</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
</dict>
</plist>
```

The login shell (`-lc`) puts the Elixir toolchain and `gh` on `PATH`. Create
`~/.local/share/complexity-trend/` before the first run so the log has a home.
