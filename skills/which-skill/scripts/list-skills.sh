#!/usr/bin/env bash
# Prints one line per installed skill: name<TAB>auto|manual<TAB>description<TAB>folder<TAB>category
# Scans the folders in $SKILL_DIRS (colon-separated) or the usual Claude Code and
# Codex locations, then the skills of every enabled Claude Code plugin under
# $CLAUDE_PLUGINS (named plugin:skill); follows symlinks and keeps the first
# folder seen for each name.
# Category: metadata.category in SKILL.md, else categories.tsv beside this folder
# (skills whose files an update would overwrite), else plugin, else uncategorized.
set -euo pipefail

lookup="$(cd "$(dirname "$0")/.." && pwd)/categories.tsv"
plugins="${CLAUDE_PLUGINS:-$HOME/.claude/plugins}"
settings="$(dirname "$plugins")/settings.json"

default_dirs="$HOME/.agents/skills:$HOME/.claude/skills:$HOME/.codex/skills:$PWD/.agents/skills:$PWD/.claude/skills"
IFS=':' read -r -a dirs <<< "${SKILL_DIRS:-$default_dirs}"

# One "folder<TAB>plugin-name" line per skill folder to scan; plugin-name is empty outside plugins.
skill_folders() {
  for dir in "${dirs[@]}"; do
    [ -d "$dir" ] || continue
    for skill in "$dir"/*/; do printf '%s\t\n' "${skill%/}"; done
  done
  [ -d "$plugins" ] || return 0
  {
    [ -f "$plugins/installed_plugins.json" ] && sed -n 's/.*"installPath": *"\([^"]*\)".*/\1/p' "$plugins/installed_plugins.json"
    for root in "$plugins"/synced/*/*/; do echo "${root%/}"; done
  } | while read -r root; do
    manifest="$root/.claude-plugin/plugin.json"
    [ -f "$manifest" ] || continue
    name="$(sed -n 's/^ *"name": *"\([^"]*\)".*/\1/p' "$manifest" | head -1)"
    [ -f "$settings" ] && grep -q "\"$name@[^\"]*\": *false" "$settings" && continue
    for skill in "$root"/skills/*/; do printf '%s\t%s\n' "${skill%/}" "$name"; done
  done
}

skill_folders | while IFS=$'\t' read -r skill plugin; do
  file="$skill/SKILL.md"
  [ -f "$file" ] || continue
  real="$(cd -P "$skill" && pwd)"
  awk -v folder="$skill" -v real="$real" -v lookup="$lookup" -v plugin="$plugin" '
    BEGIN { while ((getline row < lookup) > 0) { split(row, f, "\t"); if (f[2] != "") known[f[1]] = f[2] } }
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { done = 1 }
    done { exit }
    /^name:/ { sub(/^name:[ \t]*/, ""); gsub(/"/, ""); name = $0; collecting = 0; next }
    /^metadata:/ { in_meta = 1; collecting = 0; next }
    /^[A-Za-z_-]+:/ { in_meta = 0 }
    /^category:/ || (in_meta && /^[ \t]+category:/) {
      sub(/^[ \t]*category:[ \t]*/, ""); sub(/[ \t]*#.*$/, ""); gsub(/["\x27]/, ""); category = $0; next
    }
    /^disable-model-invocation:[ \t]*true/ { manual = 1; collecting = 0; next }
    /^description:/ {
      sub(/^description:[ \t]*/, ""); gsub(/^["\x27]|["\x27]$/, "")
      desc = ($0 ~ /^[>|][-+]?$/) ? "" : $0; collecting = 1; next
    }
    collecting && /^[ \t]+/ { line = $0; sub(/^[ \t]+/, "", line); desc = desc (desc ? " " : "") line; next }
    /^[A-Za-z_-]+:/ { collecting = 0 }
    END {
      if (name == "") { n = split(folder, parts, "/"); name = parts[n] }
      if (plugin != "" && name !~ /:/) name = plugin ":" name
      gsub(/\t/, " ", desc)
      if (category == "") category = (name in known) ? known[name] : (plugin != "" || real ~ /\/plugins\/|-plugin\// || name ~ /:/) ? "plugin" : "uncategorized"
      printf "%s\t%s\t%s\t%s\t%s\n", name, (manual ? "manual" : "auto"), desc, folder, category
    }
  ' "$file"
done | awk -F'\t' '!seen[$1]++' | sort -f
