---
name: session-watchdog
description: Finds Claude sessions started from a handoff brief that went idle before finishing it, classes each open handoff as working, waiting on the user, finished but brief not closed, or stalled, and nudges only the stalled ones with one short message pointing back at the brief's Deliverable. Reads Herdr terminals and Claude transcripts, Desktop sessions included, and flags briefs no session ever opened; never closes tabs, kills sessions or renames briefs. Use when asked to "run the session watchdog", "which handoff sessions stalled", "nudge stalled sessions", "check on my handoff tabs", or as the scheduled watchdog routine.
metadata:
  category: operate
---

# Nudging stalled handoff sessions

A handoff brief is a `<slug>.md` file in the handoff folder; a `.done.md` or `.superseded.md` suffix marks it closed. Each open brief ran in one Claude session, in a Herdr tab or a Claude Desktop Code session. Find the sessions that stopped short, nudge each Herdr one once, and report the Desktop ones.

Let `scripts/watchdog.py` do the deterministic part. It matches each local Claude terminal in Herdr (`hc ls --json`; the brief path is in the terminal's launch command from `hc get`), and its transcript, and each recent Desktop transcript (from any project folder, since Desktop works in a per-session worktree), to the brief named in the session's first prompt. It measures idle time from the transcript's modification time. It classes the session from Herdr's terminal status (none for Desktop) and the last paragraph of its final message:

| Class | Meaning | Action |
| -- | -- | -- |
| working | Herdr reports working, or it announced work under the grace period (20 min) | none |
| waiting | a question, a permission prompt, or a request for the user's decision | none; list it for the user |
| finished | final report delivered, brief still unsuffixed | none; list it so the user closes the brief |
| stalled | idle past the grace period after announcing work | Herdr: nudge once. Desktop: report (the script cannot type into it) |
| not-started | an open brief past the grace period (and under a week old) that no session opened, likely because Enter was never pressed in the new Desktop session | report; tell the user to open the session and press Enter |

## Run the watchdog

1. **List the open handoffs.** Run `scripts/watchdog.py list`. In a scheduled run add `--notify`: it raises one macOS notification per stalled Desktop session and per not-started brief. Done when every open handoff appears with its tab, idle time, class and the tail of its last message.
2. **Confirm each stalled and finished row** by reading its tail, because the script reads only the last paragraph. A tail that reports the brief's deliverable as done is finished, and a tail that asks the user anything is waiting, whatever the script said. A finished row whose tail says a watch or a background task will wake it is working. A stalled row that promised a wake-up stays stalled: it is already past the grace period, so the wake-up has not come. Done when each stalled and finished row is confirmed or reclassed, with one line saying why.
3. **Read the nudge** each confirmed row would receive. The listing prints it under the row, or prints why the script refuses it (the session was already nudged and has written nothing since). Done when each confirmed row has its message or its refusal.
4. **Send the nudges.** For Herdr rows, when a person is present, show them the rows and each message word for word, and send after their yes; a scheduled run sends directly. Send with `scripts/watchdog.py nudge <id> --send`, where the id is the row's session, tab or terminal id (the script types it with `hc send`); the script re-checks the class and the refusal before sending. A Desktop row cannot go through the script. When this skill runs inside a Desktop session and `mcp__ccd_session_mgmt__send_message` is listed, send the row's nudge text to that session with it, under the same show-then-yes rule. Otherwise report the row and stop. Done when each Herdr send printed `sent to terminal` and each Desktop row was messaged or reported.
5. **Report to the user.** Give a table of every open handoff (class, tab, idle time, brief), then the nudges sent, then the finished briefs the user should close. Done when the report names every row from step 1.

A Herdr terminal on another machine (`nas/t1`) is not watched, because its transcripts are not on this one.

## Send one nudge and change nothing else

- Send only the script's single message as the nudge; it points at the brief's Deliverable and asks the session to say what blocks it.
- Send one nudge per silence: the script records the last assistant message it nudged and refuses a repeat until new output appears.
- Leave closing tabs, killing sessions, renaming briefs and any git or PR action to the user.

## Configure through the environment

Set these variables to change the defaults: `HANDOFF_DIR` (`$HOME/.local/state/handoffs`), `CLAUDE_PROJECTS_DIR` (`$HOME/.claude/projects`), `WATCHDOG_STATE` (the nudge log), `WATCHDOG_IDLE_MIN` (20), `HC_BIN` (`hc`). A variable set in the environment is deliberate, so run the script with the environment exactly as given. `scripts/watchdog.py selftest` checks the classes and the nudge guards on fixtures. `INSTALL.md` covers the schedule.
