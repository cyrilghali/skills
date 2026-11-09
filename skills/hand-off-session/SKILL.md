---
name: hand-off-session
description: >-
  Compacts the current conversation into a handoff document a fresh agent can pick the
  work up from, optionally bundling everything it depends on into a self-contained
  archive and shipping that to another machine. Use when the user asks for a handoff,
  a session summary to carry forward, a context dump for the next session, or wants
  the current work moved to another machine or agent. Invoke only on an explicit
  request — never load it on your own initiative, since it summarises rather than
  advances the work in progress.
compatibility: Packing and sending need a Unix-like local and remote host with tar, ssh, and rsync or scp.
disable-model-invocation: true
metadata:
  category: agent
---

# Hand off session

> **`$SKILL_DIR` in the commands below is notation, not a variable that is already set.** It stands
> for this skill's own directory — the absolute path printed when the skill is loaded, or the
> directory holding this `SKILL.md`. Export it once (`SKILL_DIR=<that path>`) before running any of
> them.

**Explicit invocation only.** Some agents honour the `disable-model-invocation` frontmatter above; where that key is ignored, this paragraph is the rule — do not load this skill because a handoff sounds relevant, only because the user asked for one.

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Include a "suggested skills" section in the document, naming the skills the next agent should invoke. Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs) — reference them by path or URL instead, that keeps the handoff short and avoids drift from the source of truth. Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

## Before writing the document

If work is mid-flight, make it durable first: finish the current atomic step or back out of it cleanly, then commit uncommitted edits — a `wip:` commit is fine — so nothing depends on this session staying alive. Note in the commit body if the tree is left broken. Don't take an irreversible action, such as a push, a PR, or a merge, just to produce a handoff; only do that if one was already in flight before the handoff was requested.

For each piece of work the document reports as done, say plainly whether it was verified against the real thing (tests run, the feature exercised) or only implemented and asserted. The next agent should treat the document as authoritative for what happened, but still re-verify anything marked unverified rather than trusting a self-report it didn't watch happen.

## Arguments

| Argument | Meaning |
|---|---|
| `--output=chat\|file\|pack` | Where the handoff goes. Default `chat`. |
| `--send=<target>` | After building a pack, copy it to `<target>` (an ssh destination). Requires `--output=pack`. |
| `--move` | Unpack the sent archive into the matching project on the target. Requires `--send`. |
| *anything else* | Prose describing what the next session will focus on. Tailor the document to it. |

## Output modes

- `chat` (default) — output the document directly in the chat response. It's meant to be read or copied right away, not hunted for on disk.
- `file` — save the document to a single markdown file in the temporary directory of the user's OS (not the current workspace), named meaningfully with today's date, e.g. `handoff-<topic>-YYYY-MM-DD.md`. Dependencies stay referenced by path/URL, same as `chat`.
- `pack` — bundle the handoff document together with copies of everything it depends on into one self-contained `.tar.gz`, so the result is still usable after moving to a machine that has no access to the original paths or URLs (a fresh clone, a different laptop, a different session).

## Building a pack

1. Create a staging directory in the OS temp dir, e.g. `handoff-<topic>-YYYY-MM-DD/`.
2. Identify what the handoff depends on, and for each one decide whether it can be bundled or must stay a live reference: the current conversation transcript, if one is accessible on disk (bundle it); plan documents relevant to the handed-off work (bundle them); temporary/scratch files created during the session that the next agent would need, e.g. anything under the session's scratchpad directory (bundle them); other local files the handoff depends on such as PRDs, ADRs, notes (bundle only what's referenced, not the whole repo); remote dependencies such as a GitHub issue/PR, a Linear ticket, a Notion doc (fetch their current content and bundle it as a snapshot file — markdown or JSON — when feasible; that's what makes the pack usable without network/credential access on the other end; if a snapshot isn't feasible, it stays a URL reference). Copy each bundled item into the staging directory, preserving enough relative structure to stay unambiguous.
3. Write `handoff.md` directly into the staging directory: reference bundled items by their relative path inside the pack, and unbundled ones by URL with a note that it's a live reference, not a copy. There's no separate "write it plainly, then rewrite the links" pass — you already know each dependency's fate from step 2, so write the real path the first time.
4. Archive and clean up with `"$SKILL_DIR/scripts/pack.py" <staging-dir>` — it tars the staging directory into the OS temp dir as `<staging-dir-name>.tar.gz`, removes the staging directory, and prints the archive path. Prefer it over re-deriving the tar/cleanup by hand.
5. Tell the user the resulting archive path.

## Sending a pack

Pass `--send=<target>` (e.g. `--send=user@host`) to copy the finished archive to the remote machine after building it. This only makes sense for `--output=pack` — a bare markdown file (`file`) or chat output (`chat`) isn't something you `rsync`/`scp` anywhere. If `--send` is passed with `file`/`chat`, or with no `--output` (which defaults to `chat`), stop and tell the user `--send` requires `--output=pack` rather than silently ignoring it or guessing they meant something else.

Run `"$SKILL_DIR/scripts/send.py" <archive> <target>`. Tell the user both the local archive path and the remote path it prints. See [references/SCRIPTS.md](references/SCRIPTS.md) for what it does internally (private remote dir, rsync/scp fallback) if you need to explain a failure.

## Moving a pack

Pass `--move` together with `--send=<target>` to go one step further: instead of leaving the archive sitting in its private remote temp directory, unpack it directly into the identical project on that machine (same project name as the current one, e.g. being in `sherpas-api` locally and running `--output=pack --send=nas --move` unpacks into `sherpas-api` on `nas`). `--move` only makes sense together with `--send` (which in turn requires `--output=pack`) — if `--move` is passed without `--send`, stop and tell the user rather than guessing which target they meant.

Resolving *where* to unpack doesn't depend on the pack itself, so do it first — before spending effort building the pack, so a failure here doesn't waste that work:

1. Get the local project name:
   ```bash
   root="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" \
     && project="$(basename "$(dirname "$root")")" \
     || project="$(basename "$PWD")"
   ```
   Use `--git-common-dir`, not `--show-toplevel` — see [references/SCRIPTS.md](references/SCRIPTS.md) for why worktrees break the latter. The `||` branch covers not being in a repo at all.
2. Resolve it on the remote with `"$SKILL_DIR/scripts/resolve_project.py" <target> <project>`:
   - Exit 0: the remote path is printed — proceed.
   - Exit 1: no matching project directory exists on `<target>` — **stop and fail**. This is a hard requirement, not a fallback situation: tell the user the project isn't there and let them decide what to do (create it, pick a different target, drop `--move`).
   - Exit 2: multiple candidates were printed (one per line) — ask the user which one is correct, then cache their choice with `"$SKILL_DIR/scripts/record_project.py" <target> <project> <chosen-path>`.
   - Exit 64: a usage error (bad arguments) rather than a result — see [references/SCRIPTS.md](references/SCRIPTS.md) for the shared convention across all five scripts.
3. Build and send the pack as usual (Building a pack, Sending a pack above). Keep the exact remote archive path `send.py` printed — you'll need it verbatim in the next step.
4. Unpack it with `"$SKILL_DIR/scripts/unpack_remote.py" <target> <remote-archive-path-from-send.py> <remote-project-path>` — this also removes the remote archive once extraction succeeds.
5. Tell the user the final remote path it printed (`<target>:<remote-project-path>/<archive-name>/`) instead of the private-temp-dir one from step 3.

`resolve_project.py`/`record_project.py` cache results in `~/.handoff/projects.tsv` so repeat handoffs skip the remote search — see [references/SCRIPTS.md](references/SCRIPTS.md) for the cache format and verification behavior.

## Sources

The pre-handoff durability step and the verified-vs-claimed distinction adapt ideas from poteto's `pstack` (MIT, Lauren Tan).

Originally from github.com/Ephasme/agent-skills (forked 25/09/2026; no longer tracked upstream).
