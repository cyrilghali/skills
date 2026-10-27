#!/usr/bin/env bash
# Usage: finish.sh <project-dir> <scale>  ->  prints the folder of one-second finish frames for that scale.
# Bakes the paper and six grain frames into public/tex once, then the paper, vignette and grain into one multiply
# frame per grain step (finish-tex.py). Both depend only on look.tsx and theme.ts, so they are shared between
# projects through a cache.
set -euo pipefail
project=$(cd "${1:?usage: finish.sh <project-dir> <scale>}" && pwd)
scale=${2:?usage: finish.sh <project-dir> <scale>}
here=$(cd "$(dirname "$0")" && pwd)
cd "$project"
cache="${EXPLAINER_CACHE:-$HOME/.cache/make-video}/$(cat src/look.tsx src/theme.ts "$here/finish-tex.py" | shasum | cut -c1-16)"
textures() { for f in paper grain-0 grain-1 grain-2 grain-3 grain-4 grain-5; do [ -s "$1/$f.png" ] || return 1; done; }
if ! textures public/tex; then
  if ! textures "$cache"; then
    if ! { node "$here/render.mjs" "$project" textures "$cache.tmp.$$" >&2 && mkdir -p "$cache" && mv "$cache.tmp.$$"/*.png "$cache/" && rmdir "$cache.tmp.$$"; }; then
      echo "baking the paper texture failed" >&2; exit 1
    fi
  fi
  mkdir -p public/tex && cp "$cache"/*.png public/tex/
fi
fps=$(grep -o '"fps": *[0-9]*' src/timeline.json | grep -o '[0-9]*$' || echo 30)
width=$(awk -v s="$scale" 'BEGIN { printf "%d", 1920 * s + 0.5 }')
height=$(awk -v s="$scale" 'BEGIN { printf "%d", 1080 * s + 0.5 }')
fin="$cache/finish-${width}x${height}@$fps"
if [ ! -d "$fin" ]; then
  if ! { uv run -q --python 3.12 --with numpy --with pillow python "$here/finish-tex.py" "$project" "$fps" "$width" "$height" "$fin.tmp.$$" >/dev/null && mv "$fin.tmp.$$" "$fin"; }; then
    echo "baking the finish frames failed" >&2; exit 1
  fi
fi
echo "$fin"
