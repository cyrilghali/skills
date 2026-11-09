# Install

Drop the folder into your skills directory, then link the recorder onto PATH under the name every skill's record sentence uses:

```sh
ln -s "$PWD/scripts/record.sh" ~/.local/bin/skill-record
```

Both scripts need only bash, python3 and git, and `gh` when a PR number should be recorded.

## SKILL_TELEMETRY_DIR is optional

Where `runs.jsonl` and the `sessions.tsv` cache live. Unset, the scripts use `~/.local/share/skill-telemetry` and create it on first use. Set it only to move the log elsewhere, in the shell file every non-interactive shell reads (`~/.zshenv` for zsh), never in the skill:

```sh
export SKILL_TELEMETRY_DIR="$HOME/telemetry"
```

## Smoke test

Run from the skill folder, with a scratch folder so no test row lands in the real log:

```sh
SKILL_TELEMETRY_DIR=$(mktemp -d) sh -c 'scripts/record.sh smoke a=1 b=2/3 && scripts/report.sh smoke'
```

The report prints one block `smoke: 1 run in 30d, last <today>` with rows `a`, `b` and `b_of`, then a compliance line.
