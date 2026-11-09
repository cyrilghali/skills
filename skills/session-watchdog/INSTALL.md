# Install

Needs Python 3 (stdlib only), the Herdr `hc` CLI on PATH (the scheduled job needs its directory in the plist `PATH`), and the `claude` CLI.

1. Copy the folder to `~/.claude/skills/session-watchdog` and check it: `~/.claude/skills/session-watchdog/scripts/watchdog.py selftest` prints `selftest ok`.
2. Adjust the binary paths in `launchd/session-watchdog.plist.template` if `claude` or `hc` live elsewhere (`command -v claude hc`).
3. Render the schedule (four runs a day, 09:30, 12:30, 15:30 and 18:30) and lint it:

   ```sh
   sed "s#__HOME__#$HOME#g" launchd/session-watchdog.plist.template > ~/Library/LaunchAgents/local.session-watchdog.plist
   plutil -lint ~/Library/LaunchAgents/local.session-watchdog.plist
   ```

4. Load it when you want the routine live: `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.session-watchdog.plist`. Unload with `launchctl bootout gui/$(id -u)/local.session-watchdog`. Runs log to `~/Library/Logs/session-watchdog.log`.

The job runs in `dontAsk` permission mode, so it can run the watchdog script and read files but nothing else. The scheduled run sends nudges without asking. Run the skill by hand at least once first, and check its classes against your open tabs.

Desktop sessions need no hook: the script reads their transcripts (`entrypoint` `claude-desktop`). Without Herdr running, the Herdr part is skipped. Add `--notify` to the routine's `list` call to get a macOS notification for stalled Desktop sessions and not-started briefs.
