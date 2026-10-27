import React from "react";
import { FPS, mix } from "./beats";
import { random } from "./frame";
import { color, HUES } from "./theme";

const W = 1920;
const H = 1080;

/** A seed that changes `hz` times a second, so ink lines boil like a hand-drawn film. */
export const boilSeed = (frame: number, hz = 6) => Math.floor((frame / FPS) * hz) % 12;

/** Base tone, slow mottling, fibres and fine tooth. scripts/render.sh bakes it once into public/tex/paper.png. */
export const PaperTexture: React.FC = () => (
  <svg width={W} height={H}>
    <rect width={W} height={H} fill={color.paper} />
    <filter id="paper-mottle" x={0} y={0} width={W} height={H} filterUnits="userSpaceOnUse">
      <feTurbulence type="fractalNoise" baseFrequency="0.0022 0.0035" numOctaves={4} seed={3} />
      <feColorMatrix type="matrix" values="0 0 0 0 0.78  0 0 0 0 0.69  0 0 0 0 0.52  0 0 0 1.1 -0.38" />
    </filter>
    <rect width={W} height={H} filter="url(#paper-mottle)" opacity={0.55} />
    <filter id="paper-tooth" x={0} y={0} width={W} height={H} filterUnits="userSpaceOnUse">
      <feTurbulence type="fractalNoise" baseFrequency="0.75" numOctaves={2} seed={9} />
      <feColorMatrix type="matrix" values="0 0 0 0 0.35  0 0 0 0 0.28  0 0 0 0 0.2  0 0 0 0.9 -0.32" />
    </filter>
    <rect width={W} height={H} filter="url(#paper-tooth)" opacity={0.5} />
    {Array.from({ length: 260 }, (_, i) => {
      const x = random(`fx${i}`) * W;
      const y = random(`fy${i}`) * H;
      const a = random(`fa${i}`) * Math.PI;
      const l = 6 + random(`fl${i}`) * 22;
      const bend = (random(`fb${i}`) - 0.5) * 8;
      return (
        <path
          key={i}
          d={`M ${x} ${y} q ${(Math.cos(a) * l) / 2 + bend} ${(Math.sin(a) * l) / 2 - bend} ${Math.cos(a) * l} ${Math.sin(a) * l}`}
          stroke={color.paperShade}
          strokeWidth={0.8}
          fill="none"
          opacity={0.35}
        />
      );
    })}
  </svg>
);

/**
 * Warm edge darkening and moving grain over everything; render it last. It draws nothing here:
 * scripts/render.sh multiplies the paper, the vignette and the grain over every frame in ffmpeg.
 */
export const Finish: React.FC = () => null;

/** One transparent grain frame per seed; scripts/render.sh bakes six of them into public/tex/. */
export const GrainTexture: React.FC<{ seed: number }> = ({ seed }) => (
  <svg width={W} height={H}>
    <filter id="grain" x={0} y={0} width={W} height={H} filterUnits="userSpaceOnUse">
      <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves={1} seed={seed} />
      <feColorMatrix type="matrix" values="0 0 0 0 0.3  0 0 0 0 0.25  0 0 0 0 0.2  0 0 0 0.8 -0.25" />
    </filter>
    <rect width={W} height={H} filter="url(#grain)" />
  </svg>
);

/**
 * The ink wobble filter, a hatch pattern per hue, crowd fills and an open arrowhead.
 * Put it first in the full-frame <svg>, and apply filter="url(#ink)" on an untransformed <g>
 * so the wobble stays the same size in pixels whatever the camera zoom.
 */
export const InkDefs: React.FC<{ seed: number }> = ({ seed }) => (
  <defs>
    <filter id="ink" x={0} y={0} width={W} height={H} filterUnits="userSpaceOnUse">
      <feTurbulence type="fractalNoise" baseFrequency="0.03" numOctaves={2} seed={seed} result="n" />
      <feDisplacementMap in="SourceGraphic" in2="n" scale={3.2} xChannelSelector="R" yChannelSelector="G" />
    </filter>
    {(["ink", ...HUES] as const).map((k) => (
      <pattern key={k} id={`hatch-${k}`} patternUnits="userSpaceOnUse" width={5} height={5} patternTransform="rotate(38)">
        <line x1={0} y1={0} x2={0} y2={5} stroke={color[k]} strokeWidth={1.3} />
      </pattern>
    ))}
    <pattern id="pat-dots" patternUnits="userSpaceOnUse" width={4} height={4}>
      <circle cx={2} cy={2} r={0.9} fill={color.ink} />
    </pattern>
    <pattern id="pat-rows" patternUnits="userSpaceOnUse" width={4} height={3.4}>
      <line x1={0} y1={1} x2={4} y2={1} stroke={color.ink} strokeWidth={0.8} />
    </pattern>
    <pattern id="pat-cross" patternUnits="userSpaceOnUse" width={4} height={4} patternTransform="rotate(45)">
      <path d="M 0 2 L 4 2 M 2 0 L 2 4" stroke={color.ink} strokeWidth={0.6} />
    </pattern>
    <marker id="arrow" viewBox="0 0 10 10" refX="7" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M 0 1 L 9 5 L 0 9" fill="none" stroke={color.ink} strokeWidth={1.4} />
    </marker>
  </defs>
);

/** Cuts a segment to the box [x0, y0, x1, y1] (Liang-Barsky); null when it misses the box. */
const clipToBox =
  ([bx0, by0, bx1, by1]: number[]) =>
  (x1: number, y1: number, x2: number, y2: number): number[] | null => {
    let t0 = 0;
    let t1 = 1;
    const dx = x2 - x1;
    const dy = y2 - y1;
    for (const [p, q] of [[-dx, x1 - bx0], [dx, bx1 - x1], [-dy, y1 - by0], [dy, by1 - y1]]) {
      if (p === 0) {
        if (q < 0) return null;
        continue;
      }
      const r = q / p;
      if (p < 0) {
        if (r > t1) return null;
        t0 = Math.max(t0, r);
      } else {
        if (r < t0) return null;
        t1 = Math.min(t1, r);
      }
    }
    return [x1 + t0 * dx, y1 + t0 * dy, x1 + t1 * dx, y1 + t1 * dy];
  };

/**
 * Pen hatching inside the closed path `d`: parallel strokes with a little jitter in spacing,
 * length and angle. `box` is [x, y, w, h] around the path; `cross` adds a second, darker pass;
 * `p` (0 to 1) draws the strokes on in order. `id` must be unique in the frame.
 */
export const Hatch: React.FC<{
  id: string;
  d: string;
  box: [number, number, number, number];
  stroke: string;
  gap?: number;
  angle?: number;
  width?: number;
  cross?: boolean;
  opacity?: number;
  p?: number;
}> = ({ id, d, box, stroke, gap = 5, angle = 38, width = 1.1, cross = false, opacity = 1, p = 1 }) => {
  const [x, y, w, h] = box;
  const cx = x + w / 2;
  const cy = y + h / 2;
  const r = Math.hypot(w, h) / 2 + 4;
  // A stroke cut to the box draws the same picture inside the clip, and keeps each layer resvg allocates small.
  const trim = clipToBox([x - 3, y - 3, x + w + 3, y + h + 3]);
  const lines = (a: number, tag: string) => {
    const ux = Math.cos((a * Math.PI) / 180);
    const uy = Math.sin((a * Math.PI) / 180);
    const n = Math.ceil((2 * r) / gap);
    return Array.from({ length: Math.ceil(n * p) }, (_, i) => {
      const off = -r + i * gap + (random(`${id}${tag}o${i}`) - 0.5) * gap * 0.45;
      const a0 = -r * (0.9 + random(`${id}${tag}a${i}`) * 0.15);
      const a1 = r * (0.9 + random(`${id}${tag}b${i}`) * 0.15);
      const tilt = (random(`${id}${tag}t${i}`) - 0.5) * 0.05;
      const px = cx - uy * off;
      const py = cy + ux * off;
      const seg = trim(px + ux * a0, py + uy * a0 + a0 * tilt, px + ux * a1, py + uy * a1 + a1 * tilt);
      if (!seg) return null;
      return (
        <line
          key={`${tag}${i}`}
          x1={seg[0]}
          y1={seg[1]}
          x2={seg[2]}
          y2={seg[3]}
          stroke={stroke}
          strokeWidth={width * (0.75 + random(`${id}${tag}w${i}`) * 0.5)}
          strokeLinecap="round"
        />
      );
    });
  };
  return (
    <g opacity={opacity}>
      <clipPath id={`clip-${id}`}>
        <path d={d} />
      </clipPath>
      <g clipPath={`url(#clip-${id})`}>
        {lines(angle, "a")}
        {cross && lines(angle - 76, "b")}
      </g>
      <path d={d} fill="none" stroke="none" data-layout="texture" data-name={id} />
    </g>
  );
};

/** How strongly an actor shows: full when lit, a soft pencil grey at rest. */
export const dim = (lit: number) => 0.3 + 0.7 * lit;

/** A small person: round head, bell shoulders, feet at (0, 0). */
export const personPath = (h: number) => {
  const w = h * 0.78;
  const hr = h * 0.2;
  const hy = -h + hr;
  return `M ${-w / 2} 0 C ${-w / 2} ${-h * 0.62} ${w / 2} ${-h * 0.62} ${w / 2} 0 Z M ${hr} ${hy} a ${hr} ${hr} 0 1 1 ${-2 * hr} 0 a ${hr} ${hr} 0 1 1 ${2 * hr} 0 Z`;
};

/** A sheet of paper with a folded corner, its top-left at (0, 0). */
export const filePath = (w: number, h: number) => {
  const f = Math.min(w, h) * 0.3;
  return `M 0 0 L ${w - f} 0 L ${w} ${f} L ${w} ${h} L 0 ${h} Z`;
};

/** A house, its base centred on (0, 0). */
export const housePath = (w: number) => {
  const h = w * 0.7;
  return `M ${-w / 2} 0 L ${-w / 2} ${-h} L 0 ${-h - w * 0.45} L ${w / 2} ${-h} L ${w / 2} 0 Z`;
};

/**
 * The guide: a small round creature in ink that stands in for the narrator.
 * `look` turns the eyes (-1 left, 1 right); `blink` (0 to 1) closes them;
 * `ping` (0 to 1, looping) sends rings out while `pingOn` is above 0.
 */
export const Guide: React.FC<{ x: number; y: number; r: number; tint: string; lit: number; look?: number; ping?: number; pingOn?: number; blink?: number; opacity?: number }> = ({
  x,
  y,
  r,
  tint,
  lit,
  look = 1,
  ping = 0,
  pingOn = 0,
  blink = 0,
  opacity = 1,
}) => {
  const body = `M ${-r} 0 a ${r} ${r} 0 1 1 ${2 * r} 0 a ${r} ${r} 0 1 1 ${-2 * r} 0 Z`;
  return (
    <g transform={`translate(${x} ${y})`} opacity={opacity} data-layout="shape" data-name="guide">
      {pingOn > 0.01 &&
        [0, 0.33, 0.66].map((o) => {
          const q = (ping + o) % 1;
          return (
            <path
              key={o}
              d={`M ${r * (1.4 + q * 3)} ${-r * (1.2 + q * 2.4)} A ${r * (1.9 + q * 3.8)} ${r * (1.9 + q * 3.8)} 0 0 1 ${r * (1.4 + q * 3)} ${r * (1.2 + q * 2.4)}`}
              fill="none"
              stroke={color.ink}
              strokeWidth={r * 0.09}
              strokeDasharray={`${r * 0.35} ${r * 0.22}`}
              opacity={pingOn * (1 - q)}
            />
          );
        })}
      <path d={body} fill={color.paper} />
      <Hatch id="guide-body" d={body} box={[-r, -r, 2 * r, 2 * r]} stroke={tint} gap={r * 0.16} width={r * 0.06} opacity={lit} />
      <path d={body} fill="none" stroke={color.ink} strokeWidth={r * 0.1} />
      <path d={`M ${-r * 0.3} ${r * 0.4} q ${r * 0.3} ${r * 0.22} ${r * 0.6} 0`} fill="none" stroke={color.ink} strokeWidth={r * 0.08} strokeLinecap="round" />
      {[-0.32, 0.22].map((ex) => (
        <ellipse key={ex} cx={r * (ex + 0.18 * look)} cy={-r * 0.12} rx={r * 0.09} ry={r * 0.2 * (1 - blink * 0.9)} fill={color.ink} />
      ))}
    </g>
  );
};

/** A number that counts toward `value`; `p` (0 to 1) is how far it has counted. Put it inside a <Tag> or a <text>. */
export const Counter: React.FC<{ value: number; p: number; decimals?: number }> = ({ value, p, decimals = 0 }) => (
  <>{(value * p).toLocaleString("en-US", { minimumFractionDigits: decimals, maximumFractionDigits: decimals })}</>
);

export type Pose = { x: number; y: number; rot: number };

/** An SVG transform that carries a shape drawn around (0, 0) from pose `a` to pose `b` in one rigid piece. */
export const pose = (p: number, a: Pose, b: Pose) => `translate(${mix(p, a.x, b.x)} ${mix(p, a.y, b.y)}) rotate(${mix(p, a.rot, b.rot)})`;

type Shot = { x?: number; y?: number; s?: number };
export type Cam = { x: number; y: number; s: number; screen: (x: number, y: number) => { x: number; y: number }; view: string };

/**
 * A camera that moves through shots in order: camera([[move(t, "zoom"), { x: 300, s: 1.8 }], [move(t, "back"), { s: 1 }]]).
 * `view` is the SVG transform for the world group; screen(x, y) maps a world point (origin at the frame center) to pixels.
 */
export const camera = (shots: [number, Shot][]): Cam => {
  let x = 0;
  let y = 0;
  let s = 1;
  for (const [p, shot] of shots) {
    if (shot.x !== undefined) x = mix(p, x, shot.x);
    if (shot.y !== undefined) y = mix(p, y, shot.y);
    // Zoom in log space, so a 3x push feels as even as a 3x pull.
    if (shot.s !== undefined) s = Math.exp(mix(p, Math.log(s), Math.log(shot.s)));
  }
  return { x, y, s, screen: (px, py) => ({ x: W / 2 + (px - x) * s, y: H / 2 + (py - y) * s }), view: `translate(${W / 2} ${H / 2}) scale(${s}) translate(${-x} ${-y})` };
};
