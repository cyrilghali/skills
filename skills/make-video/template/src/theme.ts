/** Font families; scripts/setup.sh downloads their files and the render loads only those. */
export const hand = "Gaegu";
export const mono = "JetBrains Mono";

export const color = {
  paper: "#efe5cf",
  paperDeep: "#e2d4b6",
  paperShade: "#c9b48f",
  ink: "#2b241c",
  inkSoft: "#2b241c99",
  inkFaint: "#2b241c33",
  earth: "#4b3a29",
  blue: "#1f6d9e",
  amber: "#dc9a24",
  green: "#1f8a66",
  rust: "#c95a26",
};

/** The hues an actor can be lit in; each has a hatch pattern `url(#hatch-<hue>)` from InkDefs. */
export const HUES = ["blue", "amber", "green", "rust"] as const;
export type Hue = (typeof HUES)[number];
