"""Usage: mix.py <project-dir>  ->  writes <project>/out/mix.wav from <project>/out/audio.json.
Places each beat's voice clip at its beat start and each cue at its time, and lays the music bed under them:
looped, faded in and out over 2 s, and dipped by 45% while a beat speaks (the curve kit.tsx describes)."""
import json, sys
from pathlib import Path
import numpy as np
import soundfile as sf
import soxr

RATE = 48000
project = Path(sys.argv[1])
plan = json.loads((project / "out/audio.json").read_text())
n = round(plan["duration"] * RATE)
t = np.arange(n) / RATE
out = np.zeros(n)


def clip(name):
    data, rate = sf.read(project / "public" / name, always_2d=True)
    return soxr.resample(data.mean(axis=1), rate, RATE) if rate != RATE else data.mean(axis=1)


def place(sound, start, volume=1.0):
    i = round(start * RATE)
    if i >= n:
        return
    s = sound[max(0, -i) : n - i]
    out[max(0, i) : max(0, i) + len(s)] += volume * s


for v in plan["voice"]:
    place(clip(v["file"]), v["start"])
for c in plan["cues"]:
    place(clip(c["file"]), c["start"], c["volume"])
if plan.get("music") is not None:
    bed = clip("sound/music.wav")
    bed = np.tile(bed, n // len(bed) + 1)[:n]
    d = plan["duration"]
    edges = np.interp(t, [0, 2, d - 2, d], [0, 1, 1, 0])
    speaking = np.zeros(n)
    for v in plan["voice"]:
        speaking = np.maximum(speaking, np.interp(t, [v["start"] - 0.3, v["start"], v["end"], v["end"] + 0.4], [0, 1, 1, 0]))
    out += plan["music"] * edges * (1 - 0.45 * speaking) * bed
sf.write(project / "out/mix.wav", np.clip(out, -1, 1), RATE, subtype="PCM_16")
print(project / "out/mix.wav")
