# Install

Copy the folder into your skills directory (`~/.claude/skills/` for Claude
Code). Needs `python3` (3.9+) and `launchctl` (macOS only).

Symlink the script onto `PATH` so it runs as `routines`:

```sh
mkdir -p ~/.local/bin
ln -sf /path/to/skills/routine-watchdog/scripts/routine_watchdog.py ~/.local/bin/routines
```

Smoke test: `routines --self-test` prints `self-test passed`. Then
`routines` should print a table with one row per plist under
`~/Library/LaunchAgents`.

## Routine (launchd, macOS)

Daily, read-only. Write absolute paths (launchd does not expand `~`), save
under `~/Library/LaunchAgents/`, then `launchctl bootstrap gui/$(id -u) <plist>`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.example.routine-watchdog</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string><string>-lc</string>
    <string>d=$HOME/.local/share/routine-watchdog; mkdir -p $d; r=$d/latest.txt; /path/to/home/.local/bin/routines --problems >"$r" 2>&amp;1; grep -q '^all .* routines healthy$' "$r" || digest-add "Routine watchdog" "$(head -1 "$r")" "$r"</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key><string>/opt/homebrew/bin:/path/to/home/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
</dict>
</plist>
```

Set `PATH` explicitly: a non-interactive login shell (`-lc`) reads
`.zprofile` but not `.zshrc`, so a `PATH` built in `.zshrc` never reaches
launchd jobs — this exact gap is one of the things this skill's own check 4
looks for in *other* jobs' plists. It must reach `routines` and `digest-add`
(or your own notification command); check with
`env -i PATH=<that PATH> /bin/zsh -lc 'command -v routines digest-add'`.

`digest-add` is optional: if you don't have one, replace the last part of the
command with your own notification (`osascript -e 'display notification ...'`,
a Slack webhook, or just leaving the output in the log for a human to read).
The `grep` posts only when the output isn't exactly the "all N healthy" line
— this plist redirects both stdout and stderr into `$r`, so a script crash
(no healthy line at all) also triggers a post, which is the right behavior:
silence should mean healthy, not "the check didn't run". `$r` is a fixed
path (not a temp file removed right after) so `digest-add`'s report link
still resolves when the digest is opened later.
