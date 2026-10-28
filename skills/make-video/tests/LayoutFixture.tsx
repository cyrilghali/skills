import React from "react";
import { Label, Note, type Sound } from "./kit";
import { Hatch } from "./look";
import { color, hand } from "./theme";

const box = (x: number, y: number, w: number, h: number) => ({ x, y, width: w, height: h, fill: "none", stroke: color.ink, strokeWidth: 2 });
const crowd = "M 1300 300 L 1700 300 L 1700 520 L 1300 520 Z";

export const sound: Sound = { cues: [] };

export const Explainer: React.FC = () => (
  <>
    <svg width={1920} height={1080}>
      <rect data-layout="shape" data-name="box" {...box(200, 200, 400, 300)} />
      <rect data-layout="shape" data-name="runaway" {...box(1800, 600, 300, 100)} />
      <rect data-layout="shape" data-name="offcamera" {...box(2100, 600, 200, 100)} />
      <line data-layout="shape" data-name="rule" x1={1200} y1={800} x2={1600} y2={800} stroke={color.ink} strokeWidth={2} />
      <rect data-layout="icon" data-name="bell" {...box(700, 680, 60, 60)} />
      <rect data-layout="shape" data-name="anchor" {...box(860, 290, 40, 20)} />
      <rect data-layout="shape" data-name="pad" {...box(1480, 570, 40, 20)} />
      <rect data-layout="shape" data-name="unseen" opacity={0} {...box(470, 790, 50, 20)} />
      <g opacity={0.5} data-layout="shape" data-name="far">
        <rect {...box(4400, 300, 200, 100)} />
      </g>
      <Hatch id="crowd" d={crowd} box={[1300, 300, 400, 220]} stroke={color.ink} />
      <text data-layout="text" x={1460} y={394} fontFamily={hand} fontSize={38} fill={color.ink}>
        raw
      </text>
    </svg>
    <Label x={400} y={350} p={1} text="inside" />
    <Label x={400} y={200} p={1} text="crossing" />
    <Label x={1000} y={300} p={1} text="first" />
    <Label x={1040} y={300} p={1} text="second" />
    <Label x={1400} y={800} p={1} text="struck" />
    <Label x={2200} y={900} p={1} text="away" />
    <Label x={2230} y={900} p={1} text="beyond" />
    <Label x={400} y={350} p={1} opacity={0} text="hidden" />
    <Label x={730} y={720} p={1} text="ring" />
    <Label x={1500} y={480} p={1} text="backed" />
    <Label x={1100} y={540} p={1} text="floating" />
    <Label x={400} y={800} p={1} text="ghost" />
    <Label x={400} y={600} p={1} text="near" />
    <Note t={1} id="only" phrase="layout" text="a note alone" />
    <Label x={250} y={100} p={1} text="unsaid words" />
    <Label x={540} y={100} p={1} text="later words" />
    <Label x={830} y={100} p={1} text="layout check" />
  </>
);
