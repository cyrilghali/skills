#!/usr/bin/env bash
# Checks a skill folder's frontmatter, size and home-path leaks. Usage: validate.sh <skill-folder>
set -u
dir="${1:-.}"
skill="$dir/SKILL.md"
errors=0
fail() { echo "FAIL: $*"; errors=$((errors + 1)); }

[ -f "$skill" ] || { echo "FAIL: no SKILL.md in $dir"; exit 1; }
[ "$(head -1 "$skill")" = "---" ] || fail "frontmatter must open with --- on line 1"

front=$(awk 'NR==1 && $0=="---" {inside=1; next} inside && $0=="---" {exit} inside' "$skill")
field() {
  printf '%s\n' "$front" | awk -v key="$1" '
    $0 ~ "^" key ":" { sub("^" key ":[ ]*", ""); if ($0 ~ /^[>|][-+]?$/) { block=1; next } print; exit }
    block && /^[ \t]/ { sub(/^[ \t]+/, ""); printf "%s ", $0; next }
    block { exit }'
}

name=$(field name | tr -d "\"'")
desc=$(field description)

[ -n "$name" ] || fail "missing name"
[[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ && ${#name} -le 64 ]] || fail "name '$name' must be lowercase words joined by single hyphens, at most 64 characters"
[[ "$name" =~ claude|anthropic ]] && fail "name must not contain 'claude' or 'anthropic'"
[ "$name" = "$(basename "$(cd "$dir" && pwd -P)")" ] || fail "name '$name' differs from the folder name"

[ -n "$desc" ] || fail "missing description"
[ "${#desc}" -le 1024 ] || fail "description is ${#desc} characters; the limit is 1024"
[[ "$desc" == *"<"* || "$desc" == *">"* ]] && fail "description must not contain < or >"

categories=$(printf '%s\n' "$front" | grep -c '^  category:')
[ "$categories" -eq 1 ] || fail "frontmatter holds $categories metadata.category lines; it needs exactly one"

lines=$(wc -l < "$skill" | tr -d ' ')
[ "$lines" -le 100 ] || fail "SKILL.md has $lines lines; split reference into a sibling file below 100"

leaks=$(cd "$dir" && /usr/bin/grep -rnIF -e '~/' -e '/Users/' -e '/home/' . --exclude=INSTALL.md --exclude=validate.sh --exclude-dir=.git)
[ -z "$leaks" ] || fail "home paths found:"$'\n'"$leaks"

[ "$errors" -eq 0 ] && echo "OK: $name (${#desc}-character description, $lines lines)"
exit $((errors > 0))
