#!/usr/bin/env bash
# Usage: still.sh <project-dir> <frame> <out.png>  ->  renders one full-size frame, paper and grain included,
# and prints that frame's LAYOUT: lines to stderr. Uses the voice timing of the last render.sh run.
set -euo pipefail
project=$(cd "${1:?usage: still.sh <project-dir> <frame> <out.png>}" && pwd)
frame=${2:?usage: still.sh <project-dir> <frame> <out.png>}
out=${3:?usage: still.sh <project-dir> <frame> <out.png>}
here=$(cd "$(dirname "$0")" && pwd)
fin=$("$here/finish.sh" "$project" 1)
node "$here/render.mjs" "$project" still "$frame" 1 "$fin" "$out"
echo "$out"
