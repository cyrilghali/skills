# Install

The skill works as instructions alone. The gate is optional and adds a hook that blocks a reply or a document write until the mechanical tells are gone.

## The skill

Copy this folder to `~/.claude/skills/prose/` (every project) or `<repo>/.claude/skills/prose/` (one project). Nothing else is needed.

## The gate

Needs `jq`, `awk` and a shell. Make it executable:

```sh
chmod +x ~/.claude/skills/prose/hooks/prose-gate.sh
```

Merge these two entries into the `hooks` object of `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "~/.claude/skills/prose/hooks/prose-gate.sh stop", "timeout": 20 } ] }
    ],
    "PostToolUse": [
      { "matcher": "Write|Edit|mcp__linear-server__save_document|mcp__linear-server__save_issue",
        "hooks": [ { "type": "command", "command": "~/.claude/skills/prose/hooks/prose-gate.sh doc", "timeout": 20 } ] }
    ]
  }
}
```

Check it fires:

```sh
printf 'Note that this is essentially fine — clearly.\n' > /tmp/gate-test.md
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/gate-test.md"}}' | ~/.claude/skills/prose/hooks/prose-gate.sh doc
```

A JSON object with a `reason` naming the tells means the gate works. No output means the text passed (or the file was skipped, see below).

## What the gate does

| Mode | Fires on | Text linted |
| -- | -- | -- |
| `stop` | every reply | the last assistant message, at most two attempts per session |
| `doc` | `Write` or `Edit` of a `.md` file | the file on disk (a path that does not exist is skipped) |
| `doc` | a Linear save (`save_document`, `save_issue`) | the content, description and patch strings of the call |

Skipped on purpose: files under `~/.claude/`, `.claude/`, `memory/`, `CLAUDE.md`, `node_modules/`. Inside a text: fenced code, blockquotes, inline code and link targets are not linted; tables are exempt from the sentence and paragraph limits but not from the em dash check.

| Check | Threshold |
| -- | -- |
| emphasis and scaffolding words (French and English) | any |
| AI tells (delve, leverage, seamless, "it is worth noting", ...) | any |
| openers that flatter and closers that offer more ("great question", "let me know if") | any |
| sentence-start glue ("that said", "firstly", a dangling "this ensures") | any |
| hedge stacks and pair-ups ("may potentially", "not only X but also Y") | any |
| bullets in changelog voice ("Added X") | any |
| test counts in prose ("412 tests pass") | any |
| exclamation marks | any |
| em dashes | any, tables and headings included |
| a label and a colon standing in for a sentence ("Résultat : ...", "Bottom line: ...") | any |
| status emoji | any, tables and headings included |
| generic headings (Overview, Summary, Contexte, ...) | any |
| sentence length | 40 words |
| paragraph length | 120 words |
| proof trail and session bookkeeping ("j'ai vérifié", "I verified", "décidé le", ...) | documents only |
| bold heading that is not a question | documents only |
| a quoted phrase inside a question heading | documents only |

To discuss a forbidden word without tripping the gate, put it in a code span or a blockquote.
