#!/usr/bin/env bash
# Usage: new.sh <project-dir>  ->  copies the template there and installs it.
set -euo pipefail
dir=${1:?usage: new.sh <project-dir>}
here=$(cd "$(dirname "$0")/.." && pwd)
if [ -e "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then echo "$dir is not empty" >&2; exit 2; fi
mkdir -p "$dir"
cp -R "$here/template/." "$dir/"
cd "$dir"
pnpm install --silent >/dev/null 2>&1 || pnpm install
echo "project: $(pwd)"
