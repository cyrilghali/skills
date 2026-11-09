#!/usr/bin/env bash
# Runs linear-review-link.sh against a stubbed gh. Exit 1 on any mismatch.
set -euo pipefail

script="$(cd "$(dirname "$0")" && pwd)/linear-review-link.sh"
stub=$(mktemp -d)
trap 'rm -rf "$stub"' EXIT

cat >"$stub/gh" <<'STUB'
#!/usr/bin/env bash
case "$*" in
  "repo view"*) echo acme/app ;;
  "api repos/acme/app/issues/7/comments"*)
    printf '<!-- linear-linkback -->\n<a href="https://linear.app/acme/issue/ENG-1/x">ENG-1</a>\n<!-- linear-review-link -->\n<a href="https://linear.app/acme/review/fix-the-thing-abc123def456">Review in Linear</a>\n' ;;
  "api repos/other/lib/issues/7/comments"*)
    printf '<!-- linear-linkback -->\n<a href="https://linear.app/acme/issue/ENG-1/x">ENG-1</a>\n' ;;
  *) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
STUB
chmod +x "$stub/gh"
export PATH="$stub:$PATH"

fail=0
check() { # label, expected, actual
  [[ "$2" == "$3" ]] && echo "ok   $1" || { echo "FAIL $1: expected '$2', got '$3'"; fail=1; }
}

expected="linear://acme/review/fix-the-thing-abc123def456"
check "number uses the current repo" "$expected" "$("$script" 7)"
check "URL names its own repo" "$expected" "$("$script" https://github.com/acme/app/pull/7)"

set +e
"$script" https://github.com/other/lib/pull/7 >/dev/null 2>&1
check "no review comment exits 1" 1 "$?"
"$script" nonsense >/dev/null 2>&1
check "bad argument exits 64" 64 "$?"
exit "$fail"
