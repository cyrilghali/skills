#!/usr/bin/env bash
# Runs scripts/new-flags.py over three daily reports in a row and asserts what counts as new.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
cat >"$t/day1.md" <<'EOF'
HEADLINE: 0 repairs, 3 flags across 2 projects
## Alpha
Needs a person:
- Milestone "Frontend start" is past its 2026-09-25 target and holds no ticket.
- ENG-1 (started) has no milestone and no parent.
## Beta
Repaired:
- ENG-9 milestone: none → Launch
Needs a person:
- Milestone "Frontend start" is past its 2026-10-07 target and holds no ticket.
EOF
sed -e 's/is past its \(.*\) target and holds no ticket/: target \1, holds no ticket/' -e 's/ENG-1 (started)/ENG-1 (In Progress)/' "$t/day1.md" >"$t/day2.md"
sed 's/2026-09-25 target/2026-10-20 target/' "$t/day1.md" >"$t/day3.md"
seen="$t/seen.tsv"
run() { python3 "$here/scripts/new-flags.py" "$t/$1.md" "$seen" "$2"; }

[ "$(run day1 2026-10-12)" = "3 0 -" ]
[ "$(grep -c '(new)$' "$t/day1.md")" = 3 ]
[ "$(run day2 2026-10-13)" = "0 3 2026-10-12" ]   # rewording and status names are not new; same milestone name in two projects stays two items
! grep -q '(new)' "$t/day2.md"
[ "$(run day3 2026-10-14)" = "1 2 2026-10-12" ]   # a moved date is new information
grep -q 'Milestone "Frontend start" is past its 2026-10-20 target and holds no ticket. (new)$' "$t/day3.md"
! grep -q 'ENG-9.*(new)' "$t/day3.md"             # repairs are never marked
printf 'HEADLINE: x\n## Alpha\nNeeds a person:\n- ENG-1 (backlog) has no milestone and no parent.\n' >"$t/day4.md"
[ "$(run day4 2026-10-15)" = "0 1 2026-10-12" ]   # dropped flags leave the seen file
[ "$(wc -l <"$seen" | tr -d ' ')" = 1 ]
echo "new-flags: all checks passed"
