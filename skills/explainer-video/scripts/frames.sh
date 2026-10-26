#!/usr/bin/env bash
# Usage: frames.sh <video.mp4>  ->  prints one contact-sheet PNG, one tile per narrated beat,
# taken as the beat ends (when the most is on screen). Tiles read left to right.
# Without the .beats.txt file render.sh writes beside the video, takes one tile every 3 seconds.
set -euo pipefail
video=${1:?usage: frames.sh <video.mp4>}
beats="${video%.mp4}.beats.txt"
if [ -s "$beats" ]; then
  times=$(awk '{ t = $1 - 0.1; print (t < 0 ? 0 : t) }' "$beats")
else
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video")
  times=$(awk -v d="$dur" 'BEGIN { for (t = 1; t < d; t += 3) print t }')
fi
tmp=$(mktemp -d)
i=0
for t in $times; do
  i=$((i + 1))
  ffmpeg -v error -y -ss "$t" -i "$video" -frames:v 1 -vf "scale=960:-1:flags=lanczos" "$tmp/$(printf %03d $i).png"
done
[ "$i" -gt 0 ] || { echo "no frames extracted" >&2; exit 1; }
rows=$(( (i + 1) / 2 ))
out="${video%.mp4}-frames.png"
ffmpeg -v error -y -framerate 1 -i "$tmp/%03d.png" -vf "tile=2x${rows}:padding=8:color=gray" -frames:v 1 "$out"
rm -rf "$tmp"
echo "$out"
