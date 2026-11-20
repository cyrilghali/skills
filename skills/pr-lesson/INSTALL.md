# Install

The scripts need `python3` (standard library only), `git`, `gh` (signed in) and `jq`.

## The store

Pick one folder for the lessons, for example `~/.local/share/pr-lessons`. Pass it as `--home` to every script. It holds `areas/` (one map per area), `records/` (one record per lesson), `rows/` (one rendered row per lesson) and `work/` (drafts).

## Optional: a list of areas

When the product already has a written list of its areas (one file per feature, a docs folder), export its folder so every lesson files itself under the same ids:

```sh
export PR_LESSON_AREAS=/path/to/the/folder   # in the file every non-interactive shell reads, .zshenv for zsh
```

Without it, the skill names areas itself from the code.

## Optional: the lessons page

`template/index.html` is a page for claude.ai that lists the rows and shows a lesson when one is opened. Publish it once as an Artifact with the capabilities `{"db": {"rules": [{"path": "lessons", "read": "view", "write": "admin"}, {"path": "status", "read": "view", "write": "admin"}]}, "user": {}}`. Then write each file of `rows/` into the collection `lessons`, with the row's `slug` as the document id. A document `status/<YYYY-MM-DD>` with `{"day": "<YYYY-MM-DD>"}` tells the page that the program that writes lessons ran that day; the page warns when the last one is two working days old. Its optional `waiting` list, `[{"pr", "repo", "title", "author", "opened"}]`, names the pull requests whose lesson is not written yet; the page lists them under the lessons.

Without the page, `scripts/render.py … --preview <file.html>` writes one standalone page per lesson.

## Smoke test

```sh
scripts/check-record.py --help && scripts/render.py --help && scripts/prepare.sh
```

The first two print their usage; the third prints its usage line and exits 2.
