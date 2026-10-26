import React from "react";
import { Label, Voiceover } from "./kit";
import { Hatch } from "./look";
import { color, hand } from "./theme";

const box = (left: number, top: number, w: number, h: number): React.CSSProperties => ({ position: "absolute", left, top, width: w, height: h, border: `2px solid ${color.ink}` });
const crowd = "M 1300 300 L 1700 300 L 1700 520 L 1300 520 Z";

export const Explainer: React.FC = () => (
  <>
    <Voiceover />
    <div data-layout="shape" data-name="box" style={box(200, 200, 400, 300)} />
    <Label x={400} y={350} p={1} text="inside" />
    <Label x={400} y={200} p={1} text="crossing" />
    <Label x={1000} y={300} p={1} text="first" />
    <Label x={1040} y={300} p={1} text="second" />
    <div data-layout="shape" data-name="runaway" style={box(1800, 600, 300, 100)} />
    <div data-layout="shape" data-name="offcamera" style={box(2100, 600, 200, 100)} />
    <div data-layout="shape" data-name="rule" style={box(1200, 800, 400, 0)} />
    <Label x={1400} y={800} p={1} text="struck" />
    <Label x={2200} y={900} p={1} text="away" />
    <Label x={2230} y={900} p={1} text="beyond" />
    <Label x={400} y={350} p={1} opacity={0} text="hidden" />
    <div data-layout="icon" data-name="bell" style={box(700, 680, 60, 60)} />
    <Label x={730} y={720} p={1} text="ring" />
    <svg width={1920} height={1080} style={{ position: "absolute" }}>
      <Hatch id="crowd" d={crowd} box={[1300, 300, 400, 220]} stroke={color.ink} />
    </svg>
    <div data-layout="text" style={{ position: "absolute", left: 1460, top: 360, fontFamily: hand, fontSize: 38 }}>raw</div>
    <Label x={1500} y={480} p={1} text="backed" />
  </>
);
