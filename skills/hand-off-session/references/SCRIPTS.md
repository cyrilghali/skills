# Hand off session: script behavior and rationale

Background on what the scripts do internally and why — read this if you need to explain a failure,
decide whether a step is safe to skip, or aren't sure a script did what you expected. The operative
steps themselves stay in SKILL.md; this file is supporting detail, not a step to follow.

## send.py — remote directory and transport

`scripts/send.py <archive> <target>` copies the archive into a fresh, private directory on the
remote created via `mktemp -d` — deliberately not the shared, world-writable `/tmp` directly, since
another local user on that host could otherwise pre-plant a file or symlink at a predictable path.
It prefers `rsync` and retries with `scp` whenever the first attempt fails for any reason (not just
when `rsync` is locally absent — it also covers the remote lacking `rsync`), and propagates the
final attempt's exit status so a failure (bad host, auth failure, no space) surfaces rather than
getting glossed over.

On success it prints `<target>:<remote-dir>/<archive-name>` — treat that path as opaque and pass it
through verbatim to whatever comes next (e.g. `unpack_remote.py`); don't assume it's under `/tmp`.

This assumes a Unix-like remote (it needs `mktemp`, `ssh`, and `rsync`/`scp`); if the target's OS is
unclear, ask rather than guessing.

## Why `--git-common-dir`, not `--show-toplevel`

In a linked worktree, `--show-toplevel` returns the *worktree* directory, so a session in
`~/code/myproject/.claude/worktrees/no-tier-2` would resolve the project as `no-tier-2` and then
fail to find it on the remote — where only `myproject` exists. `--git-common-dir` points at the main
checkout's git dir from either a worktree or a normal clone, so its parent is the project root in
both cases.

## resolve_project.py / record_project.py — the local cache

These two scripts maintain `~/.handoff/projects.tsv` — a local, tab-separated
`<target><TAB><project><TAB><remote-path>` cache — so repeat handoffs to the same project skip the
remote search. A cache hit is still verified against the remote (a cheap `test -d`) before being
trusted, so a renamed or removed remote project triggers a fresh search instead of silently pointing
at a stale path.

## Exit code convention

All five scripts in this skill share one contract: exit 64 means a usage error (bad arguments)
rather than a result, distinct from whatever result codes a given script defines (e.g.
`resolve_project.py`'s 0/1/2), so a usage error can never be mistaken for a valid result.
