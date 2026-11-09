---
name: handoff
description: >-
  Hands a self-contained side task (a fix, a PR, an investigation, a migration) to a
  fresh Claude session, in a new terminal tab (Herdr or tmux), a new Claude Desktop Code
  session, or a command to paste in any terminal, so the current conversation keeps its own job. Use when the user says "open a new tab
  for this", "new session for this", "new Desktop session", "hand this off", "spawn a
  session for the PR", "do this elsewhere and keep this convo on X", or when a side task
  surfaces mid-conversation that would take more than a few tool calls, does not need
  this conversation's live state, and the user has asked for the work rather than for an
  answer. A step of a plan this conversation is carrying out (such as the next PR
  of a stack) is not a side task: it runs as a subagent here.
metadata:
  category: agent
---

# Handing a side task to a fresh session

Move the task, not the conversation. The new session starts cold, so put everything it needs in one brief file, then go back to this conversation's own job the moment the new session is open.

The script picks the surface from where you run, first match wins:

| Surface | Chosen when | Result |
| -- | -- | -- |
| `herdr` | `HC_TERMINAL_ID` is set and `hc` is on PATH | a new unfocused tab in this session's Herdr space, session started by itself |
| `tmux` | `TMUX` is set | a new detached tmux window, session started by itself |
| `desktop` | macOS, no multiplexer above | a new Claude Desktop Code session; it sometimes waits in the composer for Enter |
| `print` | anything else (plain terminal, SSH, Linux) | the exact command to paste in a new terminal |

Pass `--surface herdr|tmux|desktop|print` to override. `--on <machine>` (herdr only) starts the session on another Herdr machine (`hc machine ls`) with `--cwd` a path there; the script copies the brief to the same path under that machine's home.

## Hand off only when all six conditions hold

Check each row. If one fails, do the work here, or answer and stop.

| Condition | Holds when |
| -- | -- |
| Work, not an answer | the user asked for a change, a PR, a fix, a study; a question gets an answer here |
| Side task | the task is not the job this conversation was opened for (a watch, a review, a design), nor a step of a plan this conversation is carrying out |
| Result not awaited | this conversation's next step does not wait on the result, check it, or edit the same files |
| Detachable | the new session needs no state that lives only here: no open transaction, no half-made decision, no file this session is still editing |
| Worth a session | more than a handful of tool calls, or a fork, a PR, a test run |
| Named owner | one person will review the result, and the brief can name what they must look at |

Four look-alikes stay here. Answer a question here. Finish a task on the files this session has open here. When the user has not yet decided on the task, ask one question. Run a step of a plan this conversation drives as a subagent here, and check it before the next step starts.

## Follow these steps

1. **Decide with the table.** Done when each of the six conditions has a yes, or the task stays here.
2. **Write the brief** in `${HANDOFF_DIR:-$HOME/.local/state/handoffs}/<slug>.md` from `BRIEF.md`. Apply the stranger test: a competent engineer with no access to this conversation finishes the task from the brief alone, without one question. Spell out every term coined in this conversation. Take every fact from a tool result; leave out a detail the conversation never established, and never fill it in from what seems likely. Done when the five headings of `BRIEF.md` are filled and the "Do not touch" line is explicit.
3. **Pick the model and effort from the task**, not from this session's own settings. Do this on every surface except Desktop: Desktop has no such setting and uses its own defaults, so skip this step there and tell the user in step 5. Use model aliases, so the choice follows new releases:

   | Task | `--model` | `--effort` |
   | -- | -- | -- |
   | Mechanical: a file copy, a scripted check, no code change | `sonnet` | `low` |
   | Execution: code change with tests, one PR, data gathering | `sonnet` or `opus` | `medium` |
   | Verification: review, audit, proving a fix or a skill works | `opus` | `high` |
   | Root cause unknown, design, or cross-PR decision | `opus` | `high` |

   Let effort follow the phase: low or medium to do the work, high to check it. Give a brief that mixes both the verification row. Done when both values are chosen and named in the report.
4. **Launch from the repo the task touches**, never the home directory. Give a task outside any repo its own folder.
   - Run `scripts/handoff.sh <brief> --cwd <repo> --title "<short title>" --model <alias> --effort <level>`. On Desktop, `--title`, `--model` and `--effort` are optional and ignored.
   - The script checks the brief's headings and the home-directory rule, launches on the surface, and prints a JSON line for this session to read (the `print` surface also prints the command to paste). Use `--dry-run` to print the launch without opening anything.
   - When several tabs launch into one repo, give each its own checkout first with `git worktree add <path> -b <branch>` and pass that path as `--cwd`. If the tabs must share one checkout, name in every brief the one session allowed to commit.
   - When the tool `mcp__ccd_session__start_session` is listed (this conversation runs inside Claude Desktop), launch with it instead of the script, with the same `/goal` prompt and the repo as folder. Then call `set_session_title` with the brief's title, and `set_session_model` and `set_session_effort` with the step 3 values when they accept the new session id. That session starts by itself, so step 5 needs no Enter note.
   - Done when the session id or the JSON line is printed.
5. **Report to the user in three lines.** The first line gives the tab title and its terminal id (herdr) or window (tmux) with its model and effort; on `print`, it says the command is ready and the user pastes it. On Desktop, it gives the new session's folder instead, and says "if the prompt still sits in the new session's composer, press Enter; it uses Desktop's current model and effort". The second line states the task. The third line says what the new session will need from them (a login, a secret, a decision).
   - When the launch waits on a question, write the same three lines: tab not yet opened and its title, the task, the question.
   - Done when the user can find the tab or session, knows to check whether it started, and knows what it will ask.
6. **Return to the job of this conversation.** Do not follow the handoff from here; the other session reports on its own.

## Keep one example in mind

A design conversation finds that a library upgrade is needed. The user says "do the upgrade in another tab". This session writes the brief: the version pin and its source, the failing test, "do not touch the lockfile of other packages". It launches the tab titled "Library upgrade" in the repo and reports: tab 4, one PR, the session will ask for a registry token. This conversation returns to the design.

## Message an agent that already runs in a terminal

When the user asks to tell a running agent something (Codex, another Claude), do not hand off and do not look for a script here.

1. Find it: `hc ls --json` in Herdr (agent, status, cwd, name per terminal), `tmux list-panes -a` in tmux.
2. Read what it does now: `hc read <terminal>`, or `tmux capture-pane -p -t <pane>`.
3. Send the message: `hc send <terminal> "<message>"`, or `tmux send-keys -t <pane> "<message>" Enter`. If a read then shows the message still sitting in the input box, send Enter again.

Sending text is not a restart: say "sent a message", never "restarted". Count the message as received only when the agent's own session log or a fresh read shows it.

## Keep these rules on every handoff

- Write one brief per task and open one tab per brief. A second task gets a second brief.
- Never let several tabs share one work tree without a named committer: the shared-worktree gate blocks their commits until a peer session commits (five blocks on 25/10/2026). Give each tab its own worktree, or name the one session that may commit.
- When this session pilots one task across several tabs, name the pilot's task file in every brief. Append each lesson the pilot learns (a thin data source, a failed approach) to the briefs of the tabs still running, as it comes in, so no tab repeats a mistake the pilot already found.
- Give every fact in the brief its source (a file and line, a query, an issue id), never a summary of a summary.
- Name what stays out of scope as firmly as what is in it. Keep data changes out unless the user said otherwise.
- Treat a contradiction met while writing the brief (an instruction that works against the stated goal, two sources that disagree) as a decision, not a detail. Put it to the user as one question before the launch, or as the first item under "Ask the user for", with both readings quoted. Never let the brief pick a side on its own.
- Keep the launch prompt short and point it at the brief; the brief carries the instructions. The default prompt is a `/goal` condition, so the new session keeps working until the Deliverable is proven, capped at 20 turns. Give a custom `--prompt` the same shape.
- Never poll the new tab from this session. If the user asks how it is going, they read that tab.
- Put a change after launch into the brief file, which the new session re-reads. Count a message sent to the tab as sent, not taken up, until that tab confirms it; never report it to the user as an accepted change before then.
