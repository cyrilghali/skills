# Install

Drop the folder where your agent loads skills:

- Codex: `~/.agents/skills/which-skill`
- Claude Code: `~/.claude/skills/which-skill` (a symlink to the Codex copy works)

Edit `SHORTLIST.md` to list the skill names you want to remember.
The scan reads `$SKILL_DIRS` (colon-separated folders) when set, else the usual Claude Code and Codex skill folders. It then adds the skills of every enabled Claude Code plugin under `$CLAUDE_PLUGINS` (default `~/.claude/plugins`), named `plugin:skill`.

Smoke test: `./scripts/list-skills.sh | head` prints `name<TAB>auto|manual<TAB>description<TAB>folder<TAB>category` lines.

Categories come from `metadata.category` in each skill's frontmatter; list skills you installed from someone else's repository in `categories.tsv` instead, since an update would overwrite their `SKILL.md`.
