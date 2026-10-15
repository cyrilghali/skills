# Installing rewrite-commits

```bash
npx skills add cyrilghali/skills/rewrite-commits
```

## What it needs

| Tool | Needed for | Install |
|---|---|---|
| `git` | every rewrite | your package manager |
| `gh`, logged in | reading the PR's base, draft state, reviews and body | https://cli.github.com, then `gh auth login` |
| `gh stack` extension | rewriting a stack of PRs | `gh extension install github/gh-stack` (public, MIT, https://github.com/github/gh-stack) |
| `jq` | `scripts/stack.sh` | your package manager |

A single branch needs only `git` and `gh`. Without the `gh stack` extension, `gh stack view --json` fails and every branch is treated as a single branch.

## Smoke test

From the installed skill folder:

```bash
scripts/stack.sh
```

It prints its four commands (`snapshot`, `replay`, `check`, `restore`) and exits with status 2.
