import { Composition } from "remotion";
import { DURATION, FPS } from "./beats";
import { Explainer } from "./Explainer";
import { LayoutProbe } from "./kit";
import { GrainTexture, PaperTexture } from "./look";

const WithProbe: React.FC = () => (
  <>
    <Explainer />
    <LayoutProbe />
  </>
);

export const RemotionRoot: React.FC = () => (
  <>
    <Composition id="Explainer" component={WithProbe} durationInFrames={DURATION} fps={FPS} width={1920} height={1080} />
    <Composition id="PaperTex" component={PaperTexture} durationInFrames={1} fps={FPS} width={1920} height={1080} />
    <Composition id="GrainTex" component={GrainTexture} durationInFrames={6} fps={FPS} width={1920} height={1080} />
  </>
);
