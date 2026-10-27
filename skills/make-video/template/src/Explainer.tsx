import React from "react";
import { at, BEATS, FPS, move, word } from "./beats";
import { Background, Cue, Label, Music, Note, Tag, useCurrentFrame, Voiceover } from "./kit";
import { boilSeed, camera, Counter, dim, Finish, Guide, Hatch, InkDefs } from "./look";
import { color } from "./theme";

const R = 300;
const SUN = 70;
const circle = (x: number, y: number, r: number) => `M ${x - r} ${y} a ${r} ${r} 0 1 1 ${2 * r} 0 a ${r} ${r} 0 1 1 ${-2 * r} 0 Z`;

export const Explainer: React.FC = () => {
  const frame = useCurrentFrame();
  const t = frame / FPS;

  const cam = camera([
    [1, { x: 0, y: -R, s: 3 }],
    [move(t, "orbit", 0.2, 1.8), { x: 0, y: 0, s: 1 }],
  ]);
  // Ink lines keep about the same weight on screen as the camera zooms.
  const sw = (px: number) => px / Math.pow(cam.s, 0.6);

  const planetIn = at(t, "intro", word("intro", "planet") - 0.4, 0.8);
  const sunIn = at(t, "orbit", word("orbit", "the sun") - 0.2, 0.9);
  const draw = at(t, "orbit", word("orbit", "circle") - 0.3, 1.4);
  const travel = move(t, "year", word("year", "full turn") - 0.2, BEATS.year.seconds);
  const angle = -Math.PI / 2 + travel * 2 * Math.PI;
  const planet = { x: R * Math.cos(angle), y: R * Math.sin(angle) };
  const planetLit = planetIn;
  const sunLit = sunIn;

  const planetLbl = cam.screen(planet.x, planet.y - 26);
  const sunLbl = cam.screen(0, SUN + 72);

  return (
    <>
      <Background />
      <Voiceover />
      <Music />
      <Cue beat="intro" delay={word("intro", "planet")} sound="tick" />
      <Cue beat="orbit" delay={0.2} sound="whoosh" />
      <Cue beat="orbit" delay={word("orbit", "the sun") - 0.4} sound="swell" />
      <Cue beat="year" delay={BEATS.year.seconds + 0.3} sound="chime" />

      <svg width={1920} height={1080} style={{ position: "absolute" }}>
        <InkDefs seed={boilSeed(frame)} />
        <g filter="url(#ink)">
          <g transform={cam.view}>
            <path d={circle(0, 0, R)} fill="none" stroke={color.ink} strokeWidth={sw(2)} strokeDasharray="6 7" opacity={draw} />

            <g opacity={sunIn} data-layout="shape" data-name="sun">
              {Array.from({ length: 12 }, (_, i) => {
                const a = (i * Math.PI) / 6;
                return <path key={i} d={`M ${Math.cos(a) * (SUN + 14)} ${Math.sin(a) * (SUN + 14)} L ${Math.cos(a) * (SUN + 34)} ${Math.sin(a) * (SUN + 34)}`} stroke={color.ink} strokeWidth={sw(2.2)} strokeLinecap="round" />;
              })}
              <path d={circle(0, 0, SUN)} fill={color.paper} />
              <Hatch id="sun" d={circle(0, 0, SUN)} box={[-SUN, -SUN, 2 * SUN, 2 * SUN]} stroke={sunLit > 0.5 ? color.amber : color.inkSoft} gap={6} cross opacity={dim(sunLit)} />
              <path d={circle(0, 0, SUN)} fill="none" stroke={color.ink} strokeWidth={sw(2.6)} />
            </g>

            <g opacity={planetIn} data-layout="shape" data-name="planet">
              <path d={circle(planet.x, planet.y, 14)} fill={color.paper} />
              <Hatch id="planet" d={circle(planet.x, planet.y, 14)} box={[planet.x - 14, planet.y - 14, 28, 28]} stroke={color.blue} gap={3} width={0.9} opacity={dim(planetLit)} />
              <path d={circle(planet.x, planet.y, 14)} fill="none" stroke={color.ink} strokeWidth={sw(2)} />
            </g>

            <Guide x={-520} y={260} r={34} tint={color.green} lit={0} look={Math.sign(planet.x + 520) || 1} blink={t % 3.7 < 0.12 ? 1 : 0} opacity={at(t, "intro", 0, 0.6)} />
          </g>
        </g>
      </svg>

      <Label x={planetLbl.x} y={planetLbl.y - 20} p={planetIn} opacity={1 - at(t, "orbit", -0.2, 0.4)} text="a planet" />
      <Label x={sunLbl.x} y={sunLbl.y} p={at(t, "orbit", word("orbit", "the sun"), 0.5)} opacity={1 - at(t, "year", -0.2, 0.4)} text="the sun" />
      <Tag x={sunLbl.x} y={sunLbl.y} opacity={at(t, "year", 0.2, 0.6)}>
        day <Counter value={365} p={travel} />
      </Tag>

      <Note t={t} id="orbit" phrase="circle" text="bent into a circle" />
      <Note t={t} id="year" phrase="full turn" text="one turn, one year" />

      <Finish />
    </>
  );
};
