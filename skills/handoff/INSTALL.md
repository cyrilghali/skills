# Install

Copy the folder into `~/.claude/skills/handoff/` and make the script executable:

```sh
chmod +x ~/.claude/skills/handoff/scripts/handoff.sh
```

## Dependencies

| Tool | Why | Check |
| -- | -- | -- |
| `claude` CLI on PATH | every surface starts `claude --model .. --effort .. '<prompt>'` | `command -v claude` |
| `python3` | encodes the Desktop link and prints the JSON line | `command -v python3` |
| Herdr `hc` CLI (optional) | the `herdr` surface runs `hc run` in the caller's terminal | `echo $HC_TERMINAL_ID; command -v hc` |
| `herdr-app` (optional) | places the tab in the caller's space and titles it; without it the tab opens with no space label | `command -v herdr-app` |
| `tmux` (optional) | the `tmux` surface runs `tmux new-window -d` | `command -v tmux` |
| Claude Desktop, macOS `open` (optional) | the `desktop` surface opens a `claude://code/new` link; the prompt is typed, not sent | `./scripts/handoff.sh <brief> --cwd <repo> --dry-run` on a Mac with no multiplexer prints the link |

With none of the optional tools the script prints the command to paste in a new terminal.

Briefs go to `$HANDOFF_DIR`, default `~/.local/state/handoffs/`; create it once:

```sh
mkdir -p ~/.local/state/handoffs
```

## Smoke test

```sh
./scripts/handoff.sh <brief> --cwd <repo> --surface print --title smoke --model haiku --effort low --dry-run
bash evals/check_surface.sh
```

The first prints a `claude ...` command. The second checks every surface choice and override without opening anything.
