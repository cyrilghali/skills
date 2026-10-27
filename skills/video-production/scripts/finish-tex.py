"""Usage: finish-tex.py <project-dir> <fps> <width> <height> <out-dir>
Bakes what look.tsx's Paper and Finish lay over a flat render into one multiply frame per grain step:
paper.png divided by the flat paper colour, times the vignette, times the grain. Writes one PNG per frame
of a loop of fps/2 frames (the grain changes 12 times a second and cycles through six frames)."""
import re, sys
from pathlib import Path
import numpy as np
from PIL import Image

project, fps, w, h, out = Path(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), Path(sys.argv[5])
theme = (project / "src/theme.ts").read_text()
hexc = lambda k: np.array([int(c, 16) for c in re.findall(r'\b' + k + r': "#(..)(..)(..)"', theme)[0]]) / 255
paper, shade = hexc("paper"), hexc("paperShade")
tex = project / "public/tex"
W, H = 1920, 1080

base = np.asarray(Image.open(tex / "paper.png").convert("RGB"), float) / 255 / paper  # paper.png only darkens the flat colour
yy, xx = np.mgrid[0:H, 0:W] + 0.5
r = np.hypot((xx - 0.5 * W) / (0.8 * W), (yy - 0.48 * H) / (0.75 * H))  # radial-gradient(ellipse 80% 75% at 50% 48%, ...)
a = 0.8 * np.clip((r - 0.58) / (1.35 - 0.58), 0, 1)[..., None]           # transparent 58% -> paperShade 135%, opacity 0.8
base *= 1 - a * (1 - shade)
out.mkdir(parents=True, exist_ok=True)
grains = []
for s in range(6):
    g = np.asarray(Image.open(tex / f"grain-{s}.png").convert("RGBA"), float) / 255
    ga = 0.22 * g[..., 3:]
    f = np.clip(base * (1 - ga * (1 - g[..., :3])), 0, 1)
    grains.append(Image.fromarray((f * 255 + 0.5).astype(np.uint8)).resize((w, h), Image.LANCZOS))
for j in range(fps // 2):
    grains[(j * 12 // fps) % 6].save(out / f"f{j:03d}.png")
print(out)
