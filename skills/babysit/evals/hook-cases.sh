#!/usr/bin/env bash
# Runs hooks/auto-babysit.sh against fixture pushes in a throwaway repo and checks which
# message each one gets. Usage: evals/hook-cases.sh [bash-binary]. Exit 1 on any mismatch.
set -euo pipefail

hook="$(cd "$(dirname "$0")/.." && pwd)/hooks/auto-babysit.sh"
shell=${1:-bash}
repo=$(mktemp -d)
trap 'rm -rf "$repo"' EXIT
cd "$repo"
git init -q && git config user.email t@t && git config user.name t

mkdir -p lib test
cat >lib/score.ex <<'EOF'
defmodule Score do
  @timeout 30
  def lateral?(ws), do: FunWithFlags.enabled?(:acme_score_lateral, for: ws) and ws.count > 1
end
EOF
echo "def fast?(ws), do: FunWithFlags.enabled?(:acme_score_fast, for: ws)" >lib/fast.ex
cat >test/score_test.exs <<'EOF'
@tag flag: :acme_score_lateral
test "lateral", do: assert Score.lateral?(ws())
EOF
echo "Scores lateral movement." >README.md
git add . && git commit -qm base
base=$(git rev-parse HEAD)

# case name, sed edits applied from base (file:expression pairs)
commit_case() {
  git checkout -q "$base"
  while (($#)); do sed -i.bak "$2" "$1" && rm "$1.bak"; shift 2; done
  git commit -qam case && git rev-parse HEAD
}

run() { # command, output
  jq -n --arg c "$1" --arg e "$2" '{tool_input:{command:$c}, tool_response:{stdout:"", stderr:$e}}' |
    "$shell" "$hook" | jq -r '.hookSpecificOutput.additionalContext // empty' |
    { read -r first || true; case "$first" in *trivial*) echo ci-only ;; "") echo silent ;; *) echo full ;; esac; }
}

pushed() { printf 'To github.com:o/r.git\n   %s..%s  b -> b\n' "${base:0:10}" "${1:0:10}"; }

fail=0
check() { # name, expected, actual
  if [ "$2" = "$3" ]; then echo "pass  $1: $3"; else echo "FAIL  $1: expected $2, got $3"; fail=1; fi
}

rename=$(commit_case lib/score.ex 's/acme_score_lateral/acme_score_lateral_exists/' \
  test/score_test.exs 's/acme_score_lateral/acme_score_lateral_exists/')
check "flag rename in lib and test tag" ci-only "$(run 'git push' "$(pushed "$rename")")"

merge=$(commit_case lib/score.ex 's/acme_score_lateral/acme_score_fast/')
check "flag folded into a name the old tree already uses" full "$(run 'git push' "$(pushed "$merge")")"

wording=$(commit_case README.md 's/Scores lateral movement./Scores lateral movement across drives./')
check "wording-only change" ci-only "$(run 'git push origin b' "$(pushed "$wording")")"

logic=$(commit_case lib/score.ex 's/count > 1/count >= 1/')
check "lib logic change (operator)" full "$(run 'git push' "$(pushed "$logic")")"

const=$(commit_case lib/score.ex 's/@timeout 30/@timeout 60/')
check "lib constant change" full "$(run 'git push' "$(pushed "$const")")"

boolean=$(commit_case lib/score.ex 's/ and ws/ or ws/')
var=$(commit_case lib/score.ex 's/def lateral?(ws)/def lateral?(ws_input_row)/;s/for: ws)/for: ws_input_row)/;s/and ws.count/and ws_input_row.count/')
check "variable rename" full "$(run 'git push' "$(pushed "$var")")"

boolean=$(commit_case lib/score.ex 's/ and ws/ or ws/')
check "keyword swap" full "$(run 'git push' "$(pushed "$boolean")")"

git checkout -q "$base"
echo 'test "none", do: refute Score.lateral?(empty())' >>test/score_test.exs
testchange=$(git commit -qam t && git rev-parse HEAD)
check "test change" full "$(run 'git push' "$(pushed "$testchange")")"

check "forced push onto rename" ci-only \
  "$(run 'git push --force-with-lease' "$(printf 'To github.com:o/r.git\n + %s...%s b -> b (forced update)' "${base:0:10}" "${rename:0:10}")")"
check "new branch push" full "$(run 'git push -u origin b' ' * [new branch]      b -> b')"
check "range unknown to this repo" full "$(run 'git push' '   abcdef1..1234567  b -> b')"
check "failed push" silent "$(run 'git push' ' ! [rejected]        b -> b (fetch first)')"
check "PR creation" full "$(run 'gh pr create --draft' 'https://github.com/o/r/pull/7')"
check "gh stack submit" full "$(run 'gh stack submit' 'https://github.com/o/r/pull/8')"

exit "$fail"
