import React, { useId } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { at, BEATS, word } from "./beats";
import { useMeasure } from "./frame";
import { color, hand, mono } from "./theme";

export { Easing, interpolate, random, useCurrentFrame } from "./frame";

const W = 1920;
const H = 1080;

/** The flat paper colour under the scene; render it first. The render lays the paper texture on afterwards. */
export const Background: React.FC = () => <rect width={W} height={H} fill={color.paper} />;

export type Cue = { beat: string; delay?: number; sound: "tick" | "whoosh" | "swell" | "chime"; volume?: number };
/** What the video plays besides the narration: the music bed's level and the cues keyed to beats. A cue is a tick (a point lights), a whoosh (the camera moves), a swell (a reveal builds) or a chime (the answer). */
export type Sound = { music?: number; cues: Cue[] };

// Line boxes from the fonts' hhea metrics, as a browser lays out one line: Gaegu has ascent 0.76,
// descent 0.24 and a 0.25 line gap split above and below; JetBrains Mono has ascent 1.02 and descent 0.3.
const HAND = { line: 1.25, baseline: 0.885 };
const MONO = { line: 1.32, baseline: 1.02 };
const PAPER_ALPHA = 0xeb / 255;

/** The text typed on as `p` goes 0 to 1; the untyped rest is kept but transparent, so the line keeps its width. */
const typed = (text: string, p: number) => {
  const n = Math.ceil(text.length * Math.min(1, Math.max(0, p)));
  return (
    <>
      {text.slice(0, n)}
      <tspan fillOpacity={0}>{text.slice(n)}</tspan>
    </>
  );
};

/** A one-line <text> with its left edge at x0 and its width measured by the renderer. */
const line = (measure: (svgText: string) => number, props: React.SVGProps<SVGTextElement>, children: React.ReactNode) => {
  const el = <text {...props}>{children}</text>;
  return { el, width: measure(renderToStaticMarkup(el)) };
};

/** Paper behind a label, feathered at the edge like a blurred shadow, so words stay readable on hatching or a crowd. */
const Backing: React.FC<{ x0: number; y0: number; w: number; h: number }> = ({ x0, y0, w, h }) => {
  const id = useId();
  const blur = `feather${id}`;
  const outside = `outside${id}`;
  const r = 12;
  const box = `M ${x0 + r} ${y0} H ${x0 + w - r} A ${r} ${r} 0 0 1 ${x0 + w} ${y0 + r} V ${y0 + h - r} A ${r} ${r} 0 0 1 ${x0 + w - r} ${y0 + h} H ${x0 + r} A ${r} ${r} 0 0 1 ${x0} ${y0 + h - r} V ${y0 + r} A ${r} ${r} 0 0 1 ${x0 + r} ${y0} Z`;
  return (
    <>
      <filter id={blur} x="-50%" y="-100%" width="200%" height="300%">
        <feGaussianBlur stdDeviation={5} />
      </filter>
      <clipPath id={outside}>
        <path clipRule="evenodd" d={`M -50 -50 H ${W + 50} V ${H + 50} H -50 Z ${box}`} />
      </clipPath>
      <g clipPath={`url(#${outside})`}>
        <rect x={x0 - 6} y={y0 - 6} width={w + 12} height={h + 12} rx={r + 6} fill={color.paper} fillOpacity={PAPER_ALPHA} filter={`url(#${blur})`} />
      </g>
      <rect x={x0} y={y0} width={w} height={h} rx={r} fill={color.paper} fillOpacity={PAPER_ALPHA} />
    </>
  );
};

/** Hand-lettered text on its own paper backing; (x, y) is the left edge or the centre of the box, by `anchor`. */
const Backed: React.FC<{ x: number; y: number; anchor: "left" | "middle"; p: number; opacity: number; text: string; size: number; c: string; weight: number; role?: "note" }> = ({
  x,
  y,
  anchor,
  p,
  opacity,
  text,
  size,
  c,
  weight,
  role,
}) => {
  const measure = useMeasure();
  if (p <= 0 || opacity <= 0) return null;
  const font = { fontFamily: hand, fontSize: size, fontWeight: weight, letterSpacing: 0.5, fill: c };
  const { width } = line(measure, font, text);
  const w = width + 20;
  const h = size * HAND.line;
  const x0 = anchor === "left" ? x : x - w / 2;
  const y0 = y - h / 2;
  return (
    <g data-layout="text" data-backed data-role={role} opacity={opacity}>
      <Backing x0={x0} y0={y0} w={w} h={h} />
      <text x={x0 + 10} y={y0 + size * HAND.baseline} {...font}>
        {typed(text, p)}
      </text>
    </g>
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
}) => <Backed x={x} y={y} anchor="middle" p={p} opacity={opacity} text={text} size={size} c={c} weight={weight} />;

/**
 * The beat's note, bottom left: typed on as the voice says `phrase` in beat `id`,
 * gone when beat `until` starts (by default the next beat).
 */
export const Note: React.FC<{ t: number; id: string; phrase: string; text: string; until?: string }> = ({ t, id, phrase, text, until }) => {
  const ids = Object.keys(BEATS);
  const next = until ?? ids[ids.indexOf(id) + 1];
  const p = at(t, id, word(id, phrase) - 0.1, Math.min(1.2, 0.05 * text.length));
  const out = next ? at(t, next, -0.3, 0.4) : 0;
  return <Backed x={124} y={968} anchor="left" p={p} opacity={1 - out} text={text} size={46} c={color.ink} weight={400} role="note" />;
};

/** A monospace chip centred on (x, y) for code names, `path:line` references and values. */
export const Tag: React.FC<{ x: number; y: number; opacity: number; c?: string; children: React.ReactNode }> = ({ x, y, opacity, c = color.ink, children }) => {
  const measure = useMeasure();
  if (opacity <= 0) return null;
  const size = 28;
  const border = 1.5;
  const font = { fontFamily: mono, fontSize: size, fill: c };
  const { width } = line(measure, font, children);
  const w = width + 28 + 2 * border;
  const h = size * MONO.line + 12 + 2 * border;
  const x0 = x - w / 2;
  const y0 = y - h / 2;
  return (
    <g data-layout="text" data-backed opacity={opacity}>
      <rect x={x0 + border / 2} y={y0 + border / 2} width={w - border} height={h - border} rx={8 - border / 2} fill={color.paper} stroke={color.inkSoft} strokeWidth={border} />
      <text x={x0 + border + 14} y={y0 + border + 6 + size * MONO.baseline} {...font}>
        {children}
      </text>
    </g>
  );
};
