#!/bin/sh
# Usage: capture.sh <page.html | URL | video.mp4> <out-dir> <label>
# Pages: full-page captures in light and dark at 1440 px and 390 px wide. Video: one frame every 3 s.
# Prints the path of every PNG it writes.
set -eu
[ $# -ge 2 ] || { echo "usage: capture.sh <page.html|url|video> <out-dir> [label]" >&2; exit 2; }
src=$1 out=$2 label=${3:-shot}
mkdir -p "$out"
out=$(cd "$out" && pwd)

case "$src" in
  *.mp4|*.mov|*.webm)
    command -v ffmpeg >/dev/null || { echo "capture: ffmpeg not found; install it to capture video" >&2; exit 2; }
    ffmpeg -loglevel error -y -i "$src" -vf "fps=1/3,scale=960:-1" "$out/$label-frame-%03d.png"
    ls "$out/$label"-frame-*.png
    exit 0 ;;
esac

case "$src" in
  http://*|https://*|file://*) url=$src ;;
  *) [ -f "$src" ] || { echo "capture: no such file: $src" >&2; exit 2; }
     url="file://$(cd "$(dirname "$src")" && pwd)/$(basename "$src")" ;;
esac

chrome=${CHROME:-}
if [ -z "$chrome" ]; then
  for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome chromium chromium-browser; do
    if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then chrome=$c; break; fi
  done
fi
[ -n "$chrome" ] || { echo "capture: no Chrome found; set CHROME to its binary" >&2; exit 2; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# Inside an OS sandbox (ROAST_SANDBOXED set) Chrome cannot start its own sandbox and never exits
# after its work, so it runs in the background and is stopped once its output stops growing.
run_chrome() {  # $1: the file Chrome's output lands in; the rest are Chrome arguments
  result=$1; shift
  "$chrome" ${ROAST_SANDBOXED:+--no-sandbox} --headless=new --user-data-dir="$tmp/profile" --hide-scrollbars --allow-file-access-from-files \
    --virtual-time-budget=5000 "$@" >"$tmp/stdout" 2>/dev/null &
  pid=$! last=-1 i=0
  while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 120 ]; do
    size=0; [ -f "$result" ] && size=$(wc -c <"$result")
    if [ "$size" -gt 0 ] && [ "$size" -eq "$last" ]; then break; fi
    last=$size i=$((i + 1)); sleep 0.5
  done
  kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
}

# Headless Chrome will not open a window narrower than 500 px, so the page loads in an iframe of the exact width.
# The same iframe reports the full page height; a cross-origin page cannot, and falls back to 4000 px.
for width in 1440 390; do
  cat > "$tmp/measure.html" <<EOF
<body style="margin:0"><iframe id="f" src="$url" style="width:${width}px;height:900px;border:0"></iframe>
<script>f.onload=()=>{try{document.title=f.contentDocument.documentElement.scrollHeight}catch(e){document.title="none"}}</script></body>
EOF
  run_chrome "$tmp/stdout" --window-size=1500,1000 --dump-dom "file://$tmp/measure.html"
  height=$(sed -n 's/.*<title>\([0-9][0-9]*\)<\/title>.*/\1/p' "$tmp/stdout")
  if [ -z "$height" ]; then echo "capture: page height unknown at $width px (cross-origin?); using 4000 px" >&2; height=4000; fi
  [ "$height" -le 16000 ] || height=16000
  cat > "$tmp/shot.html" <<EOF
<body style="margin:0"><iframe src="$url" style="display:block;width:${width}px;height:${height}px;border:0"></iframe></body>
EOF
  window=$width; [ "$window" -ge 500 ] || window=500
  for theme in light dark; do
    if [ "$theme" = light ]; then scheme=1; else scheme=0; fi
    png="$out/$label-$theme-$width.png"
    rm -f "$png"
    run_chrome "$tmp/raw.png" --window-size="$window,$height" --blink-settings=preferredColorScheme=$scheme \
      --screenshot="$tmp/raw.png" "file://$tmp/shot.html"
    [ -s "$tmp/raw.png" ] || { echo "capture: Chrome wrote no screenshot for $theme at $width px" >&2; exit 1; }
    if [ "$window" -ne "$width" ] && command -v ffmpeg >/dev/null; then
      ffmpeg -loglevel error -y -i "$tmp/raw.png" -vf "crop=$width:ih:0:0" "$png"
    else
      mv "$tmp/raw.png" "$png"
    fi
    rm -f "$tmp/raw.png"
    echo "$png"
  done
done
