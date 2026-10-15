# Install

The skill works as instructions alone. The gate is optional: a hook that names the mechanical tells in a reply, and blocks a document write until they are gone.

## How do I install the skill?

Copy this folder to `~/.claude/skills/prose/` (every project) or `<repo>/.claude/skills/prose/` (one project).

## How do I turn on the gate?

The gate needs `bash`, `jq`, `awk` and `perl`. Make it executable:

```sh
chmod +x ~/.claude/skills/prose/hooks/prose-gate.sh
```

Merge these two entries into the `hooks` object of `~/.claude/settings.json`, with the path to wherever the folder lives:

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "~/.claude/skills/prose/hooks/prose-gate.sh stop", "timeout": 20 } ] }
    ],
    "PostToolUse": [
      { "matcher": "Write|Edit",
        "hooks": [ { "type": "command", "command": "~/.claude/skills/prose/hooks/prose-gate.sh doc", "timeout": 20 } ] }
    ]
  }
}
```

To lint text saved through another tool (a docs or issue-tracker MCP server), add its tool name to the matcher, such as `Write|Edit|mcp__docs__save_page`. The gate reads the call's `content`, `description` or `body` string.

Check that it fires:

```sh
printf 'Note that this is essentially fine \342\200\224 clearly.\n' > /tmp/gate-test.md
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/gate-test.md"}}' | ~/.claude/skills/prose/hooks/prose-gate.sh doc
```

A JSON object with a `reason` naming the tells means the gate works. No output means the text passed, or the file was skipped.

## What does the gate check?

| Mode | Fires on | Text linted |
| -- | -- | -- |
| `stop` | every reply | the last assistant message; findings come back as a system message and never block |
| `doc` | `Write` or `Edit` of a `.md` or `.html` file | the file on disk (a path that does not exist is skipped) |
| `doc` | any other tool in the matcher | its `content`, `description` and `body` strings |

The gate skips files under a `.claude/` folder, `CLAUDE.md`, `AGENTS.md`, `node_modules/` and `~/.config/`, which are configuration rather than prose. Inside a text, it skips fenced code, blockquotes, inline code and link targets. Tables are exempt from the sentence and paragraph limits, not from the em dash and emoji checks.

| Check | Threshold |
| -- | -- |
| emphasis and scaffolding words ("note that", "essentially", "clearly") | any |
| AI tells (delve, tapestry, "let's dive in", ...) | any |
| openers that flatter and closers that offer more ("great question", "let me know if") | any |
| sentence-start glue ("that said", "firstly", a dangling "this means") | any |
| hedge stacks and pair-ups ("may potentially", "not only X but also Y") | any |
| bullets in changelog voice ("Added X") | any |
| test counts in prose ("N tests pass") | any |
| exclamation marks | any |
| em dashes | any, tables and headings included |
| a label and a colon standing in for a sentence ("Result: ...", "Bottom line: ...") | any |
| status emoji | any, tables and headings included |
| generic headings (Overview, Summary, Context, ...) | any |
| sentence length | 40 words |
| paragraph length | 120 words |
| proof trail and session bookkeeping ("I verified", a date of discussion) | documents only |
| bold heading that is not a question | documents only |
| a quoted phrase inside a question heading | documents only |

The word lists are English. In another language, the length, em dash, emoji and heading-shape checks still apply. To discuss a flagged word without tripping the gate, put it in a code span or a blockquote.
