#!/bin/bash
set -e
mkdir -p remotion-starter && cd remotion-starter
cat > '.gitignore' <<'REMOTION_EOF'
node_modules
out
.DS_Store
REMOTION_EOF
cat > 'CLAUDE.md' <<'REMOTION_EOF'
# Remotion project guide for AI agents

Programmatic motion graphics with Remotion 4.0.504 (React + TypeScript).
All `remotion` and `@remotion/*` packages must stay on the exact same version, with no `^`.
Upgrade with `npx remotion upgrade`.

## Commands
- Install: `npm install`
- Open Studio (live preview): `npm run dev`
- New composition: `npm run new -- MyVideo` (creates `src/compositions/MyVideo/` and registers it in `src/Root.tsx`)
- Check a single frame: `npx remotion still Showreel out/check.png --frame=45`
- Render MP4: `npx remotion render <CompositionId> out/<name>.mp4` (the sample: `npm run render`)
- Useful render flags: `--scale=0.5` (quick draft), `--frames=0-60`, `--props='{"title":"Hi"}'`, `--crf=18`
- Type check: `npm run typecheck`

## Structure
- `src/config.ts`: width, height, fps, duration for every composition. Change formats here only.
- `src/theme.ts`: colors and font. Reuse these, do not hardcode new palettes per scene.
- `src/Root.tsx`: registers compositions. Keep the `[imports]` and `[compositions]` markers, the `new` script relies on them.
- `src/compositions/<Name>/index.tsx`: one folder per video.
- `src/components/`: reusable pieces (`AnimatedText`, `Shape`). Add new reusable pieces here.
- `src/lib/animation.ts`: `useSpringIn`, `useProgress`, `stagger`, easings, spring presets.
- `public/`: static assets, loaded with `staticFile("audio/track.mp3")`.

## Rules for animation
1. Drive everything from `useCurrentFrame()`. Never use CSS transitions, CSS animations, `setTimeout`, or `Math.random()` (renders run frames in parallel and must be deterministic).
2. Express time in seconds and convert: `secondsToFrames(2, fps)`. Read `fps`, `width`, `height`, `durationInFrames` from `useVideoConfig()`, never hardcode them.
3. Use `spring()` for natural motion and `interpolate()` with `extrapolateLeft/Right: "clamp"` for linear or eased motion.
4. Order scenes with `<Sequence from durationInFrames>` or `TransitionSeries`. Inside a Sequence, `useCurrentFrame()` starts at 0. Add `premountFor={fps}` to Sequences that load media.
5. Stagger groups with `stagger(index, step)`.

## Typography
Use `AnimatedText` for headlines (words rise from a mask). Load fonts with `@remotion/google-fonts/<FontName>` in `theme.ts`, or put local files in `public/fonts` and load with `@remotion/fonts`. Keep line length short and sizes large for video (headline 120+ px, supporting text 44+ px at 1080p).

## Graphics
Use `Shape` for circles, squares, and rings. For SVG paths, draw with `strokeDasharray` / `strokeDashoffset` driven by `useProgress`. Keep colors from `theme.colors`.

## Audio sync
- Place files in `public/audio/`, then `<Audio src={staticFile("audio/track.mp3")} />` inside the composition.
- Start audio late with `<Sequence from={N}><Audio .../></Sequence>`. Fade with `volume={(f) => interpolate(f, [0, fps], [0, 1], {extrapolateRight: "clamp"})}`.
- Sync visuals to beats by converting known beat times to frames (`secondsToFrames(t, fps)`) and starting springs on those frames.
- For music-reactive visuals, add `@remotion/media-utils` (same version as `remotion`) and use `useAudioData` + `visualizeAudio`.
- Set composition duration to the audio length with `calculateMetadata` and `getAudioDurationInSeconds` when needed.

## Workflow for a new video
1. `npm run new -- Name`, then edit `src/compositions/Name/index.tsx`.
2. Break it into scenes, one component each, and compose them with `TransitionSeries`.
3. Run `npm run dev` and scrub the timeline. Check key frames with `remotion still`.
4. Render with `npx remotion render Name out/Name.mp4` and confirm the file plays.
5. Run `npm run typecheck` before finishing.

Docs: https://www.remotion.dev/docs
REMOTION_EOF
cat > 'README.md' <<'REMOTION_EOF'
# Remotion starter

```
npm install
npm run dev        # open Remotion Studio
npm run render     # render the sample to out/Showreel.mp4
npm run new -- MyVideo   # create and register a new composition
```

Format (size, fps, duration) lives in `src/config.ts`. AI agent instructions are in `CLAUDE.md`.
REMOTION_EOF
mkdir -p 'out'
touch 'out/.gitkeep'
cat > 'package.json' <<'REMOTION_EOF'
{
  "name": "remotion-starter",
  "version": "1.0.0",
  "private": true,
  "description": "Programmatic motion graphics with Remotion, set up for AI coding agents",
  "scripts": {
    "dev": "remotion studio",
    "start": "remotion studio",
    "render": "remotion render Showreel out/Showreel.mp4",
    "still": "remotion still Showreel out/Showreel-thumb.png --frame=30",
    "new": "node scripts/new-composition.mjs",
    "typecheck": "tsc --noEmit",
    "upgrade": "remotion upgrade"
  },
  "dependencies": {
    "@remotion/cli": "4.0.504",
    "@remotion/google-fonts": "4.0.504",
    "@remotion/transitions": "4.0.504",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "remotion": "4.0.504"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "typescript": "^5.7.0"
  }
}
REMOTION_EOF
mkdir -p 'public/audio'
touch 'public/audio/.gitkeep'
mkdir -p 'public/fonts'
touch 'public/fonts/.gitkeep'
mkdir -p 'public/images'
touch 'public/images/.gitkeep'
cat > 'remotion.config.ts' <<'REMOTION_EOF'
import {Config} from "@remotion/cli/config";

Config.setVideoImageFormat("jpeg");
Config.setOverwriteOutput(true);
REMOTION_EOF
mkdir -p 'scripts'
cat > 'scripts/new-composition.mjs' <<'REMOTION_EOF'
import {existsSync, mkdirSync, readFileSync, writeFileSync} from "node:fs";

const name = process.argv[2];
if (!name || !/^[A-Z][A-Za-z0-9]*$/.test(name)) {
  console.error("Usage: npm run new -- MyVideo   (PascalCase name)");
  process.exit(1);
}

const dir = `src/compositions/${name}`;
if (existsSync(dir)) {
  console.error(`${dir} already exists.`);
  process.exit(1);
}
mkdirSync(dir, {recursive: true});

writeFileSync(
  `${dir}/index.tsx`,
  `import React from "react";
import {AbsoluteFill} from "remotion";
import {AnimatedText} from "../../components/AnimatedText";
import {theme} from "../../theme";

export const ${name}: React.FC = () => (
  <AbsoluteFill
    style={{backgroundColor: theme.colors.ink, justifyContent: "center", padding: 160}}
  >
    <AnimatedText text="${name}" fontSize={140} color={theme.colors.white} />
  </AbsoluteFill>
);
`,
);

let root = readFileSync("src/Root.tsx", "utf8");
root = root.replace(
  "// [imports]",
  `import {${name}} from "./compositions/${name}";\n// [imports]`,
);
root = root.replace(
  "{/* [compositions] */}",
  `<Composition
        id="${name}"
        component={${name}}
        durationInFrames={durationInFrames}
        fps={VIDEO.fps}
        width={VIDEO.width}
        height={VIDEO.height}
      />
      {/* [compositions] */}`,
);
writeFileSync("src/Root.tsx", root);

console.log(`Created ${dir} and registered it in src/Root.tsx`);
console.log(`Preview: npm run dev    Render: npx remotion render ${name} out/${name}.mp4`);
REMOTION_EOF
mkdir -p 'src'
cat > 'src/Root.tsx' <<'REMOTION_EOF'
import React from "react";
import {Composition} from "remotion";
import {VIDEO, durationInFrames} from "./config";
import {Showreel} from "./compositions/Showreel";
// [imports]

export const Root: React.FC = () => {
  return (
    <>
      <Composition
        id="Showreel"
        component={Showreel}
        durationInFrames={durationInFrames}
        fps={VIDEO.fps}
        width={VIDEO.width}
        height={VIDEO.height}
      />
      {/* [compositions] */}
    </>
  );
};
REMOTION_EOF
mkdir -p 'src/components'
cat > 'src/components/AnimatedText.tsx' <<'REMOTION_EOF'
import React from "react";
import {interpolate} from "remotion";
import {SPRING, stagger, useSpringIn} from "../lib/animation";
import {theme} from "../theme";

type AnimatedTextProps = {
  text: string;
  fontSize?: number;
  color?: string;
  weight?: 500 | 700;
  delay?: number;
  stepInFrames?: number;
  align?: "left" | "center";
  style?: React.CSSProperties;
};

const Word: React.FC<{word: string; delay: number}> = ({word, delay}) => {
  const progress = useSpringIn(delay, SPRING.smooth, 28);
  const y = interpolate(progress, [0, 1], [110, 0]);
  return (
    <span
      style={{
        display: "inline-block",
        overflow: "hidden",
        verticalAlign: "top",
        paddingBottom: "0.14em",
        marginRight: "0.26em",
      }}
    >
      <span style={{display: "inline-block", transform: `translateY(${y}%)`}}>
        {word}
      </span>
    </span>
  );
};

/** Words rise into place one after another from behind a mask. */
export const AnimatedText: React.FC<AnimatedTextProps> = ({
  text,
  fontSize = 120,
  color = theme.colors.white,
  weight = 700,
  delay = 0,
  stepInFrames = 4,
  align = "left",
  style,
}) => {
  return (
    <div
      style={{
        fontFamily: theme.fontFamily,
        fontSize,
        fontWeight: weight,
        color,
        lineHeight: 1.02,
        letterSpacing: "-0.02em",
        textAlign: align,
        ...style,
      }}
    >
      {text.split(" ").map((word, i) => (
        <Word key={i} word={word} delay={delay + stagger(i, stepInFrames)} />
      ))}
    </div>
  );
};
REMOTION_EOF
mkdir -p 'src/components'
cat > 'src/components/Shape.tsx' <<'REMOTION_EOF'
import React from "react";
import {useCurrentFrame, useVideoConfig} from "remotion";
import {SPRING, useSpringIn} from "../lib/animation";

type ShapeProps = {
  kind: "circle" | "square" | "ring";
  size: number;
  color: string;
  /** Center position in pixels. */
  x: number;
  y: number;
  delay?: number;
  spinDegPerSecond?: number;
  strokeWidth?: number;
};

/** A shape that springs in from zero scale and can spin. */
export const Shape: React.FC<ShapeProps> = ({
  kind,
  size,
  color,
  x,
  y,
  delay = 0,
  spinDegPerSecond = 0,
  strokeWidth = 6,
}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const scale = useSpringIn(delay, SPRING.snappy);
  const rotation = (spinDegPerSecond * frame) / fps;

  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width: size,
        height: size,
        boxSizing: "border-box",
        borderRadius: kind === "square" ? size * 0.08 : "50%",
        background: kind === "ring" ? "transparent" : color,
        border: kind === "ring" ? `${strokeWidth}px solid ${color}` : undefined,
        transform: `translate(-50%, -50%) scale(${scale}) rotate(${rotation}deg)`,
      }}
    />
  );
};
REMOTION_EOF
mkdir -p 'src/compositions/Showreel'
cat > 'src/compositions/Showreel/index.tsx' <<'REMOTION_EOF'
import React from "react";
import {AbsoluteFill, useVideoConfig} from "remotion";
import {linearTiming, springTiming, TransitionSeries} from "@remotion/transitions";
import {slide} from "@remotion/transitions/slide";
import {fade} from "@remotion/transitions/fade";
import {AnimatedText} from "../../components/AnimatedText";
import {Shape} from "../../components/Shape";
import {SPRING, stagger, useSpringIn} from "../../lib/animation";
import {theme} from "../../theme";

const {cobalt, lemon, ink, paper, white, signal} = theme.colors;

const Intro: React.FC = () => (
  <AbsoluteFill style={{backgroundColor: cobalt}}>
    <Shape kind="circle" size={560} color={lemon} x={1440} y={500} delay={6} />
    <Shape kind="ring" size={780} color={white} x={1440} y={500} delay={14} />
    <Shape kind="square" size={150} color={signal} x={1250} y={880} delay={22} spinDegPerSecond={40} />
    <div style={{position: "absolute", left: 140, top: 230, width: 1000}}>
      <AnimatedText text="Motion, composed in code." fontSize={150} />
    </div>
    <div style={{position: "absolute", left: 146, top: 780, width: 1000}}>
      <AnimatedText
        text="A Remotion starter ready for your next idea."
        fontSize={44}
        weight={500}
        delay={30}
        stepInFrames={2}
      />
    </div>
  </AbsoluteFill>
);

const Bar: React.FC<{index: number; width: number; color: string}> = ({index, width, color}) => {
  const progress = useSpringIn(24 + stagger(index, 6), SPRING.smooth, 36);
  return (
    <div
      style={{
        position: "absolute",
        left: 140,
        top: 560 + index * 110,
        height: 70,
        width: width * progress,
        borderRadius: 35,
        background: color,
      }}
    />
  );
};

const Timing: React.FC = () => (
  <AbsoluteFill style={{backgroundColor: lemon}}>
    <div style={{position: "absolute", left: 140, top: 150, width: 1500}}>
      <AnimatedText text="Type, shape and timing share one clock." fontSize={120} color={ink} />
    </div>
    <Bar index={0} width={1400} color={ink} />
    <Bar index={1} width={1000} color={cobalt} />
    <Bar index={2} width={1640} color={signal} />
  </AbsoluteFill>
);

const Outro: React.FC = () => (
  <AbsoluteFill style={{backgroundColor: paper}}>
    <Shape kind="circle" size={760} color={lemon} x={960} y={540} delay={0} />
    <Shape kind="ring" size={980} color={cobalt} x={960} y={540} delay={8} strokeWidth={8} />
    <AbsoluteFill style={{justifyContent: "center", alignItems: "center"}}>
      <div style={{width: 1700}}>
        <AnimatedText text="Ready to render." fontSize={170} color={ink} align="center" delay={10} />
      </div>
    </AbsoluteFill>
  </AbsoluteFill>
);

/** Three scenes that scale to whatever duration is set in src/config.ts. */
export const Showreel: React.FC = () => {
  const {fps, durationInFrames} = useVideoConfig();
  const t = Math.round(fps * 0.8);
  const scene = Math.ceil((durationInFrames + 2 * t) / 3);

  return (
    <TransitionSeries>
      <TransitionSeries.Sequence durationInFrames={scene}>
        <Intro />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition
        presentation={slide({direction: "from-right"})}
        timing={springTiming({config: {damping: 200}, durationInFrames: t})}
      />
      <TransitionSeries.Sequence durationInFrames={scene}>
        <Timing />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition
        presentation={fade()}
        timing={linearTiming({durationInFrames: t})}
      />
      <TransitionSeries.Sequence durationInFrames={scene}>
        <Outro />
      </TransitionSeries.Sequence>
    </TransitionSeries>
  );
};
REMOTION_EOF
mkdir -p 'src'
cat > 'src/config.ts' <<'REMOTION_EOF'
// One place to change the format of every composition.
// Edit these values and the Studio and renders follow.
export const VIDEO = {
  width: 1920,
  height: 1080,
  fps: 30,
  durationInSeconds: 12,
};

export const durationInFrames = Math.round(VIDEO.durationInSeconds * VIDEO.fps);
REMOTION_EOF
mkdir -p 'src'
cat > 'src/index.ts' <<'REMOTION_EOF'
import {registerRoot} from "remotion";
import {Root} from "./Root";

registerRoot(Root);
REMOTION_EOF
mkdir -p 'src/lib'
cat > 'src/lib/animation.ts' <<'REMOTION_EOF'
import {
  Easing,
  interpolate,
  spring,
  useCurrentFrame,
  useVideoConfig,
  SpringConfig,
} from "remotion";

export const easeOutExpo = Easing.bezier(0.16, 1, 0.3, 1);
export const easeInOut = Easing.bezier(0.65, 0, 0.35, 1);

export const SPRING: Record<string, Partial<SpringConfig>> = {
  snappy: {damping: 18, stiffness: 180, mass: 0.8},
  smooth: {damping: 200},
  bouncy: {damping: 10, stiffness: 120},
};

/** 0 -> 1 spring that starts after `delayInFrames`. */
export const useSpringIn = (
  delayInFrames = 0,
  config: Partial<SpringConfig> = SPRING.snappy,
  durationInFrames?: number,
) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return spring({frame: frame - delayInFrames, fps, config, durationInFrames});
};

/** 0 -> 1 eased progress between two frames, clamped. */
export const useProgress = (
  startFrame: number,
  endFrame: number,
  easing: (t: number) => number = easeOutExpo,
) => {
  const frame = useCurrentFrame();
  return interpolate(frame, [startFrame, endFrame], [0, 1], {
    easing,
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
};

export const secondsToFrames = (s: number, fps: number) => Math.round(s * fps);

/** Delay for the nth item in a staggered group. */
export const stagger = (index: number, stepInFrames = 4) => index * stepInFrames;
REMOTION_EOF
mkdir -p 'src'
cat > 'src/theme.ts' <<'REMOTION_EOF'
import {loadFont} from "@remotion/google-fonts/SpaceGrotesk";

// Loads from Google Fonts, so Studio and renders need internet the first time.
const {fontFamily} = loadFont("normal", {
  weights: ["500", "700"],
  subsets: ["latin"],
});

export const theme = {
  colors: {
    cobalt: "#2338FF",
    lemon: "#E9FF4F",
    ink: "#0E1330",
    paper: "#F7F7F2",
    white: "#FFFFFF",
    signal: "#FF5B2E",
  },
  fontFamily,
};
REMOTION_EOF
cat > 'tsconfig.json' <<'REMOTION_EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "esnext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noEmit": true,
    "lib": ["DOM", "ES2020"],
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src", "remotion.config.ts"],
  "exclude": ["node_modules", "out"]
}
REMOTION_EOF
echo 'Done. Now run: cd remotion-starter && npm install && npm run dev'
