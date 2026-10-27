import { Audio } from "@remotion/media";
import React, { useEffect } from "react";
import { AbsoluteFill, interpolate, Sequence, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { at, BEATS, DURATION, FPS, saying, word } from "./beats";
import { Paper } from "./look";
import { color, hand, mono } from "./theme";

/** Warm paper; render it first. */
export const Background: React.FC = () => <Paper />;

/** Plays each beat's narration clip at the beat's start. */
export const Voiceover: React.FC = () => (
  <>
    {Object.values(BEATS).map((b) => (
      <Sequence key={b.id} from={Math.round(b.start * FPS)}>
        <Audio src={staticFile(b.file)} />
      </Sequence>
    ))}
  </>
);

const speaking = (t: number) =>
  Math.max(0, ...Object.values(BEATS).map((b) => interpolate(t, [b.start - 0.3, b.start, b.end, b.end + 0.4], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })));

/** The ambient music bed: fades in and out, and dips under the voice. */
export const Music: React.FC<{ level?: number }> = ({ level = 0.22 }) => (
  <Audio
    src={staticFile("sound/music.wav")}
    loop
    loopVolumeCurveBehavior="extend"
    volume={(f) => {
      const t = f / FPS;
      const edges = interpolate(f, [0, 2 * FPS, DURATION - 2 * FPS, DURATION], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
      return level * edges * (1 - 0.45 * speaking(t));
    }}
  />
);

/** A short sound on cue, `delay` seconds into beat `beat`: tick (a point lights), whoosh (the camera moves), swell (a reveal builds), chime (the answer). */
export const Cue: React.FC<{ beat: string; delay?: number; sound: "tick" | "whoosh" | "swell" | "chime"; volume?: number }> = ({ beat, delay = 0, sound, volume = 0.5 }) => {
  if (!BEATS[beat]) throw new Error(`Unknown beat "${beat}"`);
  return (
    <Sequence from={Math.round((BEATS[beat].start + delay) * FPS)}>
      <Audio src={staticFile(`sound/${sound}.wav`)} volume={volume} />
    </Sequence>
  );
};

// Paper behind every label, feathered at the edge, so words stay readable on hatching or a crowd.
const backing: React.CSSProperties = {
  background: `${color.paper}eb`,
  boxShadow: `0 0 10px 6px ${color.paper}eb`,
  borderRadius: 12,
  padding: "0 10px",
};

/** Text typed on as `p` goes 0 to 1; the untyped rest is laid out but transparent, so the words never shift. */
const Typed: React.FC<{ text: string; p: number }> = ({ text, p }) => {
  const n = Math.ceil(text.length * Math.min(1, Math.max(0, p)));
  return (
    <>
      {text.slice(0, n)}
      <span style={{ opacity: 0 }}>{text.slice(n)}</span>
    </>
  );
};

/** A short lowercase hand-lettered label centred on (x, y), typed on as `p` goes 0 to 1. */
export const Label: React.FC<{ x: number; y: number; p: number; text: string; opacity?: number; size?: number; c?: string; weight?: number }> = ({
  x,
  y,
  p,
  text,
  opacity = 1,
  size = 38,
  c = color.ink,
  weight = 400,
}) => (
  <div
    data-layout="text"
    data-backed
    style={{
      position: "absolute",
      left: x,
      top: y,
      transform: "translate(-50%, -50%)",
      opacity: p > 0 ? opacity : 0,
      fontFamily: hand,
      fontSize: size,
      fontWeight: weight,
      color: c,
      whiteSpace: "nowrap",
      letterSpacing: 0.5,
      ...backing,
    }}
  >
    <Typed text={text} p={p} />
  </div>
);

/**
 * The beat's note, bottom left: typed on as the voice says `phrase` in beat `id`,
 * gone when beat `until` starts (by default the next beat).
 */
export const Note: React.FC<{ t: number; id: string; phrase: string; text: string; until?: string }> = ({ t, id, phrase, text, until }) => {
  const ids = Object.keys(BEATS);
  const next = until ?? ids[ids.indexOf(id) + 1];
  const p = at(t, id, word(id, phrase) - 0.1, Math.min(1.2, 0.05 * text.length));
  const out = next ? at(t, next, -0.3, 0.4) : 0;
  return (
    <div
      data-layout="text"
      data-backed
      style={{ position: "absolute", left: 124, top: 968, transform: "translateY(-50%)", opacity: p > 0 ? 1 - out : 0, fontFamily: hand, fontSize: 46, color: color.ink, whiteSpace: "nowrap", letterSpacing: 0.5, ...backing }}
    >
      <Typed text={text} p={p} />
    </div>
  );
};

/** A monospace chip centred on (x, y) for code names, `path:line` references and values. */
export const Tag: React.FC<{ x: number; y: number; opacity: number; c?: string; children: React.ReactNode }> = ({ x, y, opacity, c = color.ink, children }) => (
  <div
    data-layout="text"
    data-backed
    style={{
      position: "absolute",
      left: x,
      top: y,
      transform: "translate(-50%, -50%)",
      opacity,
      fontFamily: mono,
      fontSize: 28,
      color: c,
      padding: "6px 14px",
      borderRadius: 8,
      background: color.paper,
      border: `1.5px solid ${color.inkSoft}`,
      whiteSpace: "nowrap",
    }}
  >
    {children}
  </div>
);

type Box = { x0: number; y0: number; x1: number; y1: number };

const effectiveOpacity = (el: Element): number => {
  let o = 1;
  for (let e: Element | null = el; e; e = e.parentElement) o *= Number(getComputedStyle(e).opacity);
  return o;
};

const textBox = (el: Element): Box => {
  const range = document.createRange();
  range.selectNodeContents(el);
  const r = range.getBoundingClientRect();
  return { x0: r.left, y0: r.top, x1: r.right, y1: r.bottom };
};

// A browser box ignores clip paths, so hatching's long clipped strokes would swell an SVG group's box;
// measure a group by its unclipped geometry instead.
const drawnRect = (el: Element): DOMRect => {
  if (!(el instanceof SVGGElement)) return el.getBoundingClientRect();
  const parts = Array.from(el.querySelectorAll("path, circle, ellipse, rect, line, polyline, polygon, text")).filter(
    (p) => {
      const clipped = p.parentElement?.closest("[clip-path]");
      return !p.closest("clipPath, defs") && !(clipped && el.contains(clipped));
    },
  );
  if (parts.length === 0) return el.getBoundingClientRect();
  const rs = parts.map((p) => p.getBoundingClientRect());
  const x0 = Math.min(...rs.map((r) => r.left));
  const y0 = Math.min(...rs.map((r) => r.top));
  return new DOMRect(x0, y0, Math.max(...rs.map((r) => r.right)) - x0, Math.max(...rs.map((r) => r.bottom)) - y0);
};

const shapeBox = (el: Element): Box => {
  const r = drawnRect(el);
  const half = 3; // A straight line has a zero-height box; give it a stroke's thickness.
  return {
    x0: r.width < 2 * half ? r.left - half : r.left,
    x1: r.width < 2 * half ? r.right + half : r.right,
    y0: r.height < 2 * half ? r.top - half : r.top,
    y1: r.height < 2 * half ? r.bottom + half : r.bottom,
  };
};

// Sample the text box against an SVG shape's real fill: the share of points inside, or undefined for a non-SVG or flat shape.
const fillShare = (s: Element, b: Box): number | undefined => {
  if (!(s instanceof SVGGeometryElement)) return undefined;
  const ctm = s.getScreenCTM();
  const r = s.getBBox();
  if (!ctm || r.width < 6 || r.height < 6) return undefined;
  const toShape = ctm.inverse();
  let hits = 0;
  let total = 0;
  for (let i = 0; i <= 12; i++)
    for (let j = 0; j <= 4; j++) {
      const p = new DOMPoint(b.x0 + ((b.x1 - b.x0) * i) / 12, b.y0 + ((b.y1 - b.y0) * j) / 4).matrixTransform(toShape);
      total++;
      if (s.isPointInFill(p) || s.isPointInStroke(p)) hits++;
    }
  return hits / total;
};

const overlaps = (a: Box, b: Box, eps = 2) => Math.min(a.x1, b.x1) - Math.max(a.x0, b.x0) > eps && Math.min(a.y1, b.y1) - Math.max(a.y0, b.y0) > eps;
const inside = (a: Box, b: Box) => a.x0 >= b.x0 && a.y0 >= b.y0 && a.x1 <= b.x1 && a.y1 <= b.y1;
const quote = (el: Element) => JSON.stringify((el.textContent ?? "").trim().slice(0, 30));

/**
 * What the camera frame shows: text that crosses a shape's edge, overlaps other text or an icon,
 * or sits on texture without a paper backing, and anything cut by the frame edge.
 * Anything wholly outside the frame is off camera and skipped.
 */
export const layoutProblems = (width: number, height: number): string[] => {
  // Anything a viewer can still make out counts; only near-invisible elements are skipped.
  const shown = (el: Element) => effectiveOpacity(el) > 0.02;
  const frame: Box = { x0: 0, y0: 0, x1: width, y1: height };
  const onCamera = (el: Element) => overlaps(shapeBox(el), frame, 0);
  const marked = (kind: string) => Array.from(document.querySelectorAll(`[data-layout="${kind}"]`)).filter(shown);
  const texts = marked("text").filter((el) => overlaps(textBox(el), frame, 0));
  const shapes = marked("shape").filter(onCamera);
  const icons = marked("icon").filter(onCamera);
  const textures = marked("texture").filter(onCamera);
  const off = (b: Box) => b.x0 < -2 || b.y0 < -2 || b.x1 > width + 2 || b.y1 > height + 2;
  const name = (el: Element) => (el as HTMLElement).dataset.name ?? el.tagName.toLowerCase();
  const problems: string[] = [];
  for (const s of [...shapes, ...icons]) if (off(shapeBox(s))) problems.push(`shape "${name(s)}" leaves the frame`);
  texts.forEach((t, i) => {
    const tb = textBox(t);
    if (off(tb)) problems.push(`${quote(t)} leaves the frame`);
    for (const o of texts.slice(i + 1)) if (overlaps(tb, textBox(o))) problems.push(`${quote(t)} overlaps ${quote(o)}`);
    for (const s of shapes) {
      if (s.contains(t) || t.contains(s)) continue;
      const sb = shapeBox(s);
      if (!overlaps(tb, sb)) continue;
      const share = fillShare(s, tb);
      if (share === undefined ? !inside(tb, sb) && !inside(sb, tb) : share > 0 && share < 1) problems.push(`${quote(t)} crosses the edge of shape "${name(s)}"`);
    }
    for (const c of icons) if (overlaps(tb, shapeBox(c))) problems.push(`${quote(t)} overlaps icon "${name(c)}"`);
    if (!(t as HTMLElement).dataset.backed)
      for (const x of textures) {
        if (!overlaps(tb, shapeBox(x))) continue;
        const share = fillShare(x, tb);
        if (share === undefined || share > 0) problems.push(`${quote(t)} sits on texture "${name(x)}" without a paper backing`);
      }
  });
  return [...new Set(problems)];
};

const CHECK_FRAMES = new Map<number, number>([
  ...Object.values(BEATS).map((b, i): [number, number] => [Math.round(b.end * FPS), i + 1]),
  [DURATION - 1, Object.keys(BEATS).length],
]);

/**
 * At the end of each beat, logs BEAT: <seconds> and one LAYOUT: line per problem from
 * layoutProblems. Every 0.1 s, logs SHOWN: for each visible text with the words being spoken.
 * scripts/render.sh collects all three.
 */
export const LayoutProbe: React.FC = () => {
  const frame = useCurrentFrame();
  const { width, height } = useVideoConfig();
  useEffect(() => {
    if (frame % Math.round(FPS / 10) === 0)
      for (const el of Array.from(document.querySelectorAll('[data-layout="text"]')))
        if (effectiveOpacity(el) > 0.5 && overlaps(textBox(el), { x0: 0, y0: 0, x1: width, y1: height }, 0)) console.log(`SHOWN: ${(frame / FPS).toFixed(1)}s ${quote(el)} as the voice says "${saying(frame / FPS)}"`);
    const beat = CHECK_FRAMES.get(frame);
    if (beat === undefined) return;
    console.log(`BEAT: ${(frame / FPS).toFixed(2)}`);
    for (const p of layoutProblems(width, height)) console.log(`LAYOUT: beat ${beat} (${(frame / FPS).toFixed(1)}s): ${p}`);
  }, [frame, width, height]);
  return null;
};
