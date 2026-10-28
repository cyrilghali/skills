"""Print one STYLE: line per departure from DESIGN.md that code can see in the scene files."""

import re
import sys
from pathlib import Path

KIT = {"theme.ts", "look.tsx", "kit.tsx", "beats.ts", "frame.ts"}
CHECKS = [
    (re.compile(r"#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(|[\"'](white|black)[\"']"), "a literal color; use color.* from theme.ts so the palette holds"),
    (re.compile(r"fontFamily:\s*[\"']"), "a literal font; use hand or mono from theme.ts"),
    (re.compile(r"\buseState\b|\bsetTimeout\b|\btransition:"), "time outside t; every animation must be a function of t"),
]
REQUIRED = [
    ("<Background", "no <Background />, so the frame has no paper"),
    ("<Finish", "no <Finish /> last, so the frame has no grain or vignette"),
    ("url(#ink)", "no filter=\"url(#ink)\" on the drawing, so its lines are machine-straight"),
    ("<Voiceover", "no <Voiceover />, so the narration is silent"),
    ("<Music", "no <Music />, so there is no music bed"),
    ("<Cue", "no <Cue />, so nothing on screen makes a sound"),
    ("camera(", "camera() is never used, so the camera never moves"),
    ("word(", "no move is cued with word(), so motion runs ahead of or behind the voice"),
]


def lint(project):
    problems = []
    files = [p for p in sorted((project / "src").glob("*.tsx")) if p.name not in KIT]
    text = ""
    for path in files:
        source = path.read_text()
        text += source
        for n, line in enumerate(source.splitlines(), 1):
            if line.strip().startswith("//"):
                continue
            for pattern, why in CHECKS:
                if pattern.search(line):
                    problems.append(f"{path.name}:{n}: {why}")
        for m in re.finditer(r"<(?:Label|Note)\b[^>]*?\btext=\"([^\"]*)\"", source):
            words = m.group(1)
            n = source[: m.start()].count("\n") + 1
            if words != words.lower():
                problems.append(f"{path.name}:{n}: label \"{words}\" has capitals; hand-lettered labels are lowercase, code names go in a <Tag>")
            if len(words.split()) > 6:
                problems.append(f"{path.name}:{n}: label \"{words}\" runs past six words; keep the words the voice says, the voice carries the rest")
        for m in re.finditer(r"<Tag\b[^>]*>([\s\S]*?)</Tag>", source):
            words = re.sub(r"<[^>]*>|\{[^}]*\}", " ", m.group(1))
            if len(re.findall(r"[A-Za-z]{2,}", words)) >= 3:
                n = source[: m.start()].count("\n") + 1
                problems.append(f"{path.name}:{n}: a sentence in a Tag; Tag is the monospace chip for values, so words go in a hand-lettered <Label>")
    for needle, why in REQUIRED:
        if needle not in text:
            problems.append(why)
    return problems


if __name__ == "__main__":
    for p in lint(Path(sys.argv[1] if len(sys.argv) > 1 else ".")):
        print(f"STYLE: {p}")
