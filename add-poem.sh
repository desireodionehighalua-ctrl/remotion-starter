#!/bin/bash
set -e
if [ -d remotion-starter ] && [ ! -d src ]; then cd remotion-starter; fi
if [ ! -d src ]; then echo "Run this from your remotion-starter project folder."; exit 1; fi
mkdir -p 'src'
cat > 'src/Root.tsx' <<'POEM_EOF'
import React from "react";
import {Composition} from "remotion";
import {VIDEO, durationInFrames} from "./config";
import {Showreel} from "./compositions/Showreel";
import {DandelionPoem, POEM_FRAMES} from "./compositions/DandelionPoem";
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
      <Composition
        id="DandelionPoem"
        component={DandelionPoem}
        durationInFrames={POEM_FRAMES}
        fps={VIDEO.fps}
        width={VIDEO.width}
        height={VIDEO.height}
      />
      {/* [compositions] */}
    </>
  );
};
POEM_EOF
mkdir -p 'src/compositions/DandelionPoem'
cat > 'src/compositions/DandelionPoem/PoemLines.tsx' <<'POEM_EOF'
import React from "react";
import {interpolate, Sequence, useCurrentFrame, useVideoConfig} from "remotion";
import {AnimatedText} from "../../components/AnimatedText";
import {poemFont} from "./style";

const Line: React.FC<{text: string; color: string; duration: number}> = ({text, color, duration}) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [duration - 12, duration], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <div
      style={{
        position: "absolute",
        left: 170,
        right: 170,
        top: 80,
        height: 300,
        display: "flex",
        justifyContent: "center",
        alignItems: "flex-start",
        opacity,
      }}
    >
      <AnimatedText
        text={text}
        fontSize={62}
        weight={500}
        color={color}
        align="center"
        stepInFrames={2}
        style={{fontFamily: poemFont, letterSpacing: "0em", lineHeight: 1.15}}
      />
    </div>
  );
};

/** Shows one poem line at a time near the top of the frame. */
export const PoemLines: React.FC<{lines: string[]; color: string}> = ({lines, color}) => {
  const {fps} = useVideoConfig();
  const first = Math.round(1.2 * fps);
  const each = Math.round(2.8 * fps);
  return (
    <>
      {lines.map((text, i) => (
        <Sequence key={i} from={first + i * each} durationInFrames={each} layout="none">
          <Line text={text} color={color} duration={each} />
        </Sequence>
      ))}
    </>
  );
};
POEM_EOF
mkdir -p 'src/compositions/DandelionPoem/art'
cat > 'src/compositions/DandelionPoem/art/Dandelion.tsx' <<'POEM_EOF'
import React from "react";
import {useCurrentFrame} from "remotion";

export type DandelionSpec = {x: number; base: number; h: number};

// Kept away from the center so the figure has room.
export const DANDELIONS: DandelionSpec[] = [
  {x: 90, base: 975, h: 250},
  {x: 250, base: 1010, h: 340},
  {x: 420, base: 960, h: 210},
  {x: 560, base: 1015, h: 300},
  {x: 1290, base: 965, h: 280},
  {x: 1460, base: 1012, h: 360},
  {x: 1630, base: 962, h: 230},
  {x: 1800, base: 1008, h: 320},
];

export type Palette = {
  skyTop: string;
  skyBottom: string;
  hillFar: string;
  hillNear: string;
  ground: string;
  puff: string;
  stem: string;
  text: string;
};

const SPOKES = 18;

const Dandelion: React.FC<
  DandelionSpec & {index: number; released: number; puff: string; stem: string}
> = ({x, base, h, index, released, puff, stem}) => {
  const frame = useCurrentFrame();
  const sway = Math.sin(frame / 45 + index * 1.7) * 14;
  const tipX = x + sway;
  const tipY = base - h;

  return (
    <g>
      <path
        d={`M ${x} ${base} Q ${x + sway * 0.2} ${base - h * 0.5} ${tipX} ${tipY}`}
        stroke={stem}
        strokeWidth={5}
        fill="none"
        strokeLinecap="round"
      />
      {Array.from({length: SPOKES}, (_, i) => {
        if (i / SPOKES < released) return null;
        const a = (i / SPOKES) * Math.PI * 2;
        const ex = tipX + Math.cos(a) * 34;
        const ey = tipY + Math.sin(a) * 34;
        return (
          <g key={i}>
            <line x1={tipX} y1={tipY} x2={ex} y2={ey} stroke={puff} strokeWidth={2} />
            <circle cx={ex} cy={ey} r={5} fill={puff} opacity={0.9} />
          </g>
        );
      })}
      <circle cx={tipX} cy={tipY} r={7} fill={stem} />
    </g>
  );
};

/** Sky, hills, ground and the row of dandelions. Goes inside an <svg viewBox="0 0 1920 1080">. */
export const Field: React.FC<{id: string; palette: Palette; released: number}> = ({
  id,
  palette,
  released,
}) => (
  <>
    <defs>
      <linearGradient id={`${id}-sky`} x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor={palette.skyTop} />
        <stop offset="1" stopColor={palette.skyBottom} />
      </linearGradient>
    </defs>
    <rect width={1920} height={1080} fill={`url(#${id}-sky)`} />
    <path
      d="M0 760 C 260 680 520 720 800 700 C 1100 680 1500 740 1920 690 L1920 1080 L0 1080 Z"
      fill={palette.hillFar}
    />
    <path
      d="M0 850 C 300 800 700 860 1000 830 C 1300 800 1600 860 1920 820 L1920 1080 L0 1080 Z"
      fill={palette.hillNear}
    />
    <rect x={0} y={930} width={1920} height={150} fill={palette.ground} />
    {DANDELIONS.map((d, i) => (
      <Dandelion key={i} {...d} index={i} released={released} puff={palette.puff} stem={palette.stem} />
    ))}
  </>
);
POEM_EOF
mkdir -p 'src/compositions/DandelionPoem/art'
cat > 'src/compositions/DandelionPoem/art/Motion.tsx' <<'POEM_EOF'
import React from "react";
import {useCurrentFrame} from "remotion";

/** Deterministic pseudo-random number in [0, 1). Never use Math.random in Remotion. */
export const rand = (n: number) => {
  const s = Math.sin(n * 127.1 + 311.7) * 43758.5453;
  return s - Math.floor(s);
};

type SeedProps = {
  x0: number;
  y0: number;
  start: number;
  dur: number;
  driftX: number;
  driftY: number;
  wobble: number;
  size: number;
  color: string;
  phase: number;
};

/** One dandelion seed floating away from a starting point. */
export const Seed: React.FC<SeedProps> = ({x0, y0, start, dur, driftX, driftY, wobble, size, color, phase}) => {
  const frame = useCurrentFrame();
  const t = (frame - start) / dur;
  if (t <= 0 || t >= 1) return null;

  const x = x0 + driftX * t + Math.sin(t * 7 + phase) * wobble;
  const y = y0 + driftY * t + Math.cos(t * 5 + phase) * wobble * 0.6;
  const opacity = Math.min(1, t * 8, (1 - t) * 3);
  const rotation = Math.sin(t * 4 + phase) * 30;

  return (
    <g transform={`translate(${x} ${y}) rotate(${rotation})`} opacity={opacity}>
      <line x1={0} y1={0} x2={0} y2={-size} stroke={color} strokeWidth={2.5} strokeLinecap="round" />
      {[-60, -30, 0, 30, 60].map((a) => (
        <line
          key={a}
          x1={0}
          y1={-size}
          x2={Math.sin((a * Math.PI) / 180) * size * 0.55}
          y2={-size - Math.cos((a * Math.PI) / 180) * size * 0.55}
          stroke={color}
          strokeWidth={1.6}
          strokeLinecap="round"
        />
      ))}
      <circle cx={0} cy={0} r={3} fill={color} />
    </g>
  );
};

type BurstProps = {
  x: number;
  y: number;
  start: number;
  count: number;
  /** Frames over which the seeds leave one after another. */
  span: number;
  driftX: number;
  driftY: number;
  color: string;
  size?: number;
  dur?: number;
  seed?: number;
};

/** A group of seeds released from one spot. */
export const SeedBurst: React.FC<BurstProps> = ({
  x,
  y,
  start,
  count,
  span,
  driftX,
  driftY,
  color,
  size = 26,
  dur = 150,
  seed = 0,
}) => (
  <>
    {Array.from({length: count}, (_, i) => {
      const r1 = rand(seed + i * 3 + 1);
      const r2 = rand(seed + i * 3 + 2);
      const r3 = rand(seed + i * 3 + 3);
      return (
        <Seed
          key={i}
          x0={x + (r1 - 0.5) * 30}
          y0={y + (r2 - 0.5) * 30}
          start={start + Math.round(r3 * span)}
          dur={dur}
          driftX={driftX * (0.6 + r1 * 0.8)}
          driftY={driftY * (0.6 + r2 * 0.8)}
          wobble={30 + r3 * 50}
          size={size}
          color={color}
          phase={r2 * 6}
        />
      );
    })}
  </>
);

type StreakProps = {
  x0: number;
  y0: number;
  /** 0 = left to right, 180 = right to left, 90 = top to bottom, -90 = bottom to top. */
  angle?: number;
  travel: number;
  start: number;
  dur: number;
  color: string;
  width?: number;
  length?: number;
};

/** A curved wind line that sweeps across the frame. */
export const WindStreak: React.FC<StreakProps> = ({
  x0,
  y0,
  angle = 0,
  travel,
  start,
  dur,
  color,
  width = 4,
  length = 280,
}) => {
  const frame = useCurrentFrame();
  const p = (frame - start) / dur;
  if (p <= 0 || p >= 1) return null;

  const head = travel * p;
  return (
    <g transform={`translate(${x0} ${y0}) rotate(${angle})`} opacity={Math.sin(p * Math.PI) * 0.55}>
      <path
        d={`M ${head - length} 0 q ${length / 2} -34 ${length} 0`}
        stroke={color}
        strokeWidth={width}
        fill="none"
        strokeLinecap="round"
      />
    </g>
  );
};
POEM_EOF
mkdir -p 'src/compositions/DandelionPoem/art'
cat > 'src/compositions/DandelionPoem/art/Person.tsx' <<'POEM_EOF'
import React from "react";
import {useCurrentFrame} from "remotion";
import {figure} from "../style";

export type PersonProps = {
  /** Position of the feet, in pixels. */
  x: number;
  y: number;
  scale?: number;
  /** Degrees each arm is lifted outward from hanging down (90 = straight out). */
  armLeft?: number;
  armRight?: number;
  /** Degrees the head tilts (positive = clockwise). */
  headTilt?: number;
  /** Pixels the head drops. */
  headDrop?: number;
  /** Degrees the upper body leans (negative = left). */
  lean?: number;
  /** -1 sad, 0 neutral, 1 hopeful. */
  mood?: number;
};

const Arm: React.FC<{side: 1 | -1; angle: number}> = ({side, angle}) => {
  const px = side * 70;
  const py = -385;
  return (
    <g transform={`rotate(${-side * angle} ${px} ${py})`}>
      <line x1={px} y1={py} x2={px} y2={py + 200} stroke={figure.skin} strokeWidth={26} strokeLinecap="round" />
      <line x1={px} y1={py} x2={px} y2={py + 120} stroke={figure.coat} strokeWidth={36} strokeLinecap="round" />
    </g>
  );
};

/** A flat, front-facing figure. Origin is at the feet; it grows upward. */
export const Person: React.FC<PersonProps> = ({
  x,
  y,
  scale = 1,
  armLeft = 8,
  armRight = 8,
  headTilt = 0,
  headDrop = 0,
  lean = 0,
  mood = 0,
}) => {
  const frame = useCurrentFrame();
  const blink = frame % 110 < 5 ? 0.1 : 1;
  const breathe = Math.sin(frame / 18) * 3;

  return (
    <g transform={`translate(${x} ${y}) scale(${scale})`}>
      <line x1={-24} y1={-200} x2={-28} y2={-14} stroke={figure.pants} strokeWidth={40} strokeLinecap="round" />
      <line x1={24} y1={-200} x2={28} y2={-14} stroke={figure.pants} strokeWidth={40} strokeLinecap="round" />
      <ellipse cx={-34} cy={-4} rx={36} ry={14} fill={figure.shoes} />
      <ellipse cx={34} cy={-4} rx={36} ry={14} fill={figure.shoes} />
      <g transform={`rotate(${lean} 0 -200)`}>
        <path
          d="M -72 -405 L 72 -405 L 96 -190 L -96 -190 Z"
          fill={figure.coat}
          stroke={figure.coat}
          strokeWidth={26}
          strokeLinejoin="round"
        />
        <Arm side={-1} angle={armLeft} />
        <Arm side={1} angle={armRight} />
        <rect x={-16} y={-436} width={32} height={46} fill={figure.skin} />
        <g transform={`translate(0 ${headDrop + breathe * 0.3}) rotate(${headTilt} 0 -430)`}>
          <circle cx={0} cy={-478} r={54} fill={figure.skin} />
          <ellipse cx={0} cy={-512} rx={60} ry={36} fill={figure.hair} />
          <ellipse cx={-19} cy={-470} rx={5} ry={6 * blink} fill={figure.hair} />
          <ellipse cx={19} cy={-470} rx={5} ry={6 * blink} fill={figure.hair} />
          <path
            d={`M -16 -446 Q 0 ${-446 + mood * 16} 16 -446`}
            stroke="#3B1F14"
            strokeWidth={4}
            fill="none"
            strokeLinecap="round"
          />
        </g>
      </g>
    </g>
  );
};
POEM_EOF
mkdir -p 'src/compositions/DandelionPoem'
cat > 'src/compositions/DandelionPoem/index.tsx' <<'POEM_EOF'
import React from "react";
import {useVideoConfig} from "remotion";
import {linearTiming, TransitionSeries} from "@remotion/transitions";
import {fade} from "@remotion/transitions/fade";
import {VIDEO} from "../../config";
import {Scene1, Scene2, Scene3, Scene4} from "./scenes";

// Change the length of the poem video here.
export const POEM_SECONDS = 48;
export const POEM_FRAMES = Math.round(POEM_SECONDS * VIDEO.fps);

/** "Dandelions": four stanzas, four scenes, soft fades between them. */
export const DandelionPoem: React.FC = () => {
  const {fps, durationInFrames} = useVideoConfig();
  const t = Math.round(fps * 0.9);
  const scene = Math.ceil((durationInFrames + 3 * t) / 4);
  const fadeTiming = linearTiming({durationInFrames: t});

  return (
    <TransitionSeries>
      <TransitionSeries.Sequence durationInFrames={scene}>
        <Scene1 />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={fade()} timing={fadeTiming} />
      <TransitionSeries.Sequence durationInFrames={scene}>
        <Scene2 />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={fade()} timing={fadeTiming} />
      <TransitionSeries.Sequence durationInFrames={scene}>
        <Scene3 />
      </TransitionSeries.Sequence>
      <TransitionSeries.Transition presentation={fade()} timing={fadeTiming} />
      <TransitionSeries.Sequence durationInFrames={scene}>
        <Scene4 />
      </TransitionSeries.Sequence>
    </TransitionSeries>
  );
};
POEM_EOF
mkdir -p 'src/compositions/DandelionPoem'
cat > 'src/compositions/DandelionPoem/scenes.tsx' <<'POEM_EOF'
import React from "react";
import {AbsoluteFill, interpolate, useCurrentFrame} from "remotion";
import {easeInOut, useProgress} from "../../lib/animation";
import {DANDELIONS, Field, Palette} from "./art/Dandelion";
import {SeedBurst, WindStreak} from "./art/Motion";
import {Person} from "./art/Person";
import {PoemLines} from "./PoemLines";

const lerp = (a: number, b: number, t: number) => a + (b - a) * t;
const clamp01 = {extrapolateLeft: "clamp", extrapolateRight: "clamp"} as const;

// Where the figure stands.
const PX = 900;
const PY = 985;

const heads = DANDELIONS.map((d) => ({x: d.x, y: d.base - d.h}));

const dusk: Palette = {
  skyTop: "#2C3550", skyBottom: "#9A94AE", hillFar: "#4A5470", hillNear: "#3A4560",
  ground: "#2B3449", puff: "#ECEAF4", stem: "#6F7C8F", text: "#FFFFFF",
};
const warm: Palette = {
  skyTop: "#F2B27A", skyBottom: "#FCE6C8", hillFar: "#E7A774", hillNear: "#D98F5F",
  ground: "#B8714B", puff: "#FFF7E8", stem: "#8C5A3A", text: "#3A2418",
};
const stormy: Palette = {
  skyTop: "#1F3A44", skyBottom: "#6C9A9B", hillFar: "#35605F", hillNear: "#2B4F50",
  ground: "#1F3B3E", puff: "#E6F2F0", stem: "#9BBDB8", text: "#FFFFFF",
};
const golden: Palette = {
  skyTop: "#F5BC45", skyBottom: "#FFF0C4", hillFar: "#EBB04B", hillNear: "#DB9A33",
  ground: "#B97B22", puff: "#FFFFFF", stem: "#7A5214", text: "#3A2410",
};

const Canvas: React.FC<{children: React.ReactNode}> = ({children}) => (
  <svg viewBox="0 0 1920 1080" width="100%" height="100%" style={{position: "absolute", left: 0, top: 0}}>
    {children}
  </svg>
);

const LINES_1 = [
  "Like Dandelions in the field",
  "I've watched the seeds of my hopes and dreams",
  "Dance, glide, and disappear into disbelief's air",
  "And left me in unfortunate despair",
];
const LINES_2 = [
  "But in my heart's empty space,",
  "I see clear pictures being painted by grace",
  "The thorns of regret start to sting my soul",
  "But these new pictures rather make me whole",
];
const LINES_3 = [
  "For like Dandelions in the field,",
  "The breath of men's disapproval would make every hope dance on the air of disbelief",
  "But the hopes of the Righteous will persevere",
  "For they are God birthed and fully in His care",
];
const LINES_4 = [
  "Though protesting winds will blow against me",
  "From the West, North, South, and East",
  "But as the Dandelions in the field",
  "These new Hopes will dance, glide, and be caught in the beauty of whom I'm made to be.",
];

/** Stanza 1: seeds drift away and the figure's shoulders drop. */
export const Scene1: React.FC = () => {
  const droop = useProgress(30, 170, easeInOut);
  const released = useProgress(60, 330, easeInOut);
  return (
    <AbsoluteFill>
      <Canvas>
        <Field id="s1" palette={dusk} released={released * 0.8} />
        <Person
          x={PX}
          y={PY}
          armLeft={lerp(6, 16, droop)}
          armRight={lerp(6, 16, droop)}
          headTilt={lerp(0, 14, droop)}
          headDrop={lerp(0, 16, droop)}
          mood={-1}
        />
        <SeedBurst x={PX - 80} y={PY - 190} start={70} count={7} span={200} driftX={700} driftY={-220} color={dusk.puff} seed={1} />
        <SeedBurst x={PX + 80} y={PY - 190} start={90} count={7} span={200} driftX={700} driftY={-220} color={dusk.puff} seed={40} />
        {heads.map((h, i) => (
          <SeedBurst key={i} x={h.x} y={h.y} start={100 + i * 25} count={3} span={120} driftX={600} driftY={-260} color={dusk.puff} seed={i * 10} />
        ))}
      </Canvas>
      <PoemLines lines={LINES_1} color={dusk.text} />
    </AbsoluteFill>
  );
};

const STROKES = [
  {d: "M 500 760 C 560 640 700 660 760 540", c: "#F2994A", w: 22, s: 70},
  {d: "M 540 560 C 620 520 700 470 790 500", c: "#F9C74F", w: 16, s: 100},
  {d: "M 1040 540 C 1130 480 1230 520 1300 620", c: "#E9724C", w: 20, s: 130},
  {d: "M 1000 760 C 1080 680 1200 700 1280 780", c: "#FFD166", w: 18, s: 160},
  {d: "M 760 400 C 860 340 960 340 1060 400", c: "#F4A261", w: 14, s: 190},
];

/** Stanza 2: thorns sting, then painted light fills the heart. */
export const Scene2: React.FC = () => {
  const frame = useCurrentFrame();
  const lift = useProgress(20, 150, easeInOut);
  const glow = useProgress(60, 260, easeInOut);
  const thorns = interpolate(frame, [0, 20, 100, 170], [0, 0.9, 0.9, 0], clamp01);
  const shake = Math.sin(frame * 1.7) * 2 * thorns;
  return (
    <AbsoluteFill>
      <Canvas>
        <defs>
          <radialGradient id="s2-glow">
            <stop offset="0" stopColor="#FFE29A" stopOpacity="0.95" />
            <stop offset="1" stopColor="#FFE29A" stopOpacity="0" />
          </radialGradient>
        </defs>
        <Field id="s2" palette={warm} released={0} />
        <Person
          x={PX}
          y={PY}
          armLeft={lerp(16, 50, lift)}
          armRight={lerp(16, 50, lift)}
          headTilt={lerp(14, 0, lift)}
          headDrop={lerp(16, 0, lift)}
          mood={lerp(-1, 1, lift)}
        />
        <circle cx={PX} cy={PY - 300} r={lerp(20, 300, glow)} fill="url(#s2-glow)" opacity={0.75} />
        {STROKES.map((s, i) => (
          <path
            key={i}
            d={s.d}
            pathLength={1}
            strokeDasharray={1}
            strokeDashoffset={interpolate(frame, [s.s, s.s + 70], [1, 0], clamp01)}
            stroke={s.c}
            strokeWidth={s.w}
            fill="none"
            strokeLinecap="round"
          />
        ))}
        <g transform={`translate(${shake} 0)`} opacity={thorns}>
          <path
            d="M 800 700 l 16 -30 l 16 30 l 16 -30 l 16 30 l 16 -30 l 16 30"
            stroke="#4A1F2A"
            strokeWidth={5}
            fill="none"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </g>
        <SeedBurst x={PX} y={PY - 200} start={150} count={6} span={150} driftX={100} driftY={-350} color={warm.puff} seed={77} />
      </Canvas>
      <PoemLines lines={LINES_2} color={warm.text} />
    </AbsoluteFill>
  );
};

/** Stanza 3: strong wind, but the figure stands firm under a falling light. */
export const Scene3: React.FC = () => {
  const frame = useCurrentFrame();
  const light = useProgress(120, 300, easeInOut);
  const smile = useProgress(180, 330, easeInOut);
  return (
    <AbsoluteFill>
      <Canvas>
        <defs>
          <linearGradient id="s3-light" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#FFFFFF" stopOpacity="0.9" />
            <stop offset="1" stopColor="#FFFFFF" stopOpacity="0" />
          </linearGradient>
        </defs>
        <Field id="s3" palette={stormy} released={0.3} />
        <polygon points="760,0 1040,0 1230,985 570,985" fill="url(#s3-light)" opacity={light * 0.45} />
        <Person
          x={PX}
          y={PY}
          lean={-6 + Math.sin(frame / 10) * 1.2}
          armLeft={lerp(20, 35, smile)}
          armRight={lerp(20, 35, smile)}
          headTilt={lerp(0, -4, smile)}
          mood={lerp(0, 1, smile)}
        />
        {Array.from({length: 16}, (_, i) => (
          <WindStreak
            key={i}
            x0={-400}
            y0={260 + ((i * 137) % 640)}
            start={6 + i * 21}
            dur={70 + (i % 3) * 15}
            travel={2700}
            length={380}
            color="#DDF3F0"
            width={4}
          />
        ))}
        {heads.map((h, i) => (
          <SeedBurst key={i} x={h.x} y={h.y} start={20 + i * 30} count={5} span={160} driftX={1100} driftY={-150} dur={110} color={stormy.puff} seed={i * 7 + 3} />
        ))}
      </Canvas>
      <PoemLines lines={LINES_3} color={stormy.text} />
    </AbsoluteFill>
  );
};

/** Stanza 4: winds from every side, arms open, seeds caught in golden light. */
export const Scene4: React.FC = () => {
  const open = useProgress(30, 170, easeInOut);
  const glow = useProgress(20, 200, easeInOut);
  return (
    <AbsoluteFill>
      <Canvas>
        <defs>
          <radialGradient id="s4-glow">
            <stop offset="0" stopColor="#FFFFFF" stopOpacity="0.9" />
            <stop offset="1" stopColor="#FFFFFF" stopOpacity="0" />
          </radialGradient>
        </defs>
        <Field id="s4" palette={golden} released={0.2} />
        <circle cx={PX} cy={PY - 300} r={lerp(100, 560, glow)} fill="url(#s4-glow)" opacity={0.7} />
        <Person
          x={PX}
          y={PY}
          armLeft={lerp(18, 128, open)}
          armRight={lerp(18, 128, open)}
          headTilt={lerp(0, -6, open)}
          headDrop={lerp(0, -6, open)}
          mood={1}
        />
        {[0, 1, 2, 3].map((i) => (
          <React.Fragment key={i}>
            <WindStreak x0={-400} y0={380 + i * 140} angle={0} travel={1500} start={10 + i * 40} dur={110} length={300} color="#C77F0A" width={5} />
            <WindStreak x0={2320} y0={430 + i * 140} angle={180} travel={1500} start={30 + i * 40} dur={110} length={300} color="#C77F0A" width={5} />
            <WindStreak x0={760 + i * 130} y0={-300} angle={90} travel={1300} start={30 + i * 40} dur={110} length={300} color="#C77F0A" width={5} />
            <WindStreak x0={760 + i * 130} y0={1380} angle={-90} travel={1300} start={50 + i * 40} dur={110} length={300} color="#C77F0A" width={5} />
          </React.Fragment>
        ))}
        <SeedBurst x={200} y={720} start={20} count={8} span={200} driftX={650} driftY={-260} color="#FFFDF4" seed={5} />
        <SeedBurst x={1720} y={700} start={40} count={8} span={200} driftX={-650} driftY={-260} color="#FFFDF4" seed={15} />
        {heads.map((h, i) => (
          <SeedBurst
            key={i}
            x={h.x}
            y={h.y}
            start={40 + i * 20}
            count={3}
            span={120}
            driftX={h.x < PX ? 300 : -300}
            driftY={-300}
            color="#FFFDF4"
            seed={i * 11 + 2}
          />
        ))}
      </Canvas>
      <PoemLines lines={LINES_4} color={golden.text} />
    </AbsoluteFill>
  );
};
POEM_EOF
mkdir -p 'src/compositions/DandelionPoem'
cat > 'src/compositions/DandelionPoem/style.ts' <<'POEM_EOF'
import {loadFont} from "@remotion/google-fonts/Lora";

// Poem typeface. Loads from Google Fonts (needs internet the first time).
const {fontFamily} = loadFont("normal", {weights: ["500"], subsets: ["latin"]});
export const poemFont = fontFamily;

// Character colors. Change `skin`, `hair`, `coat` to restyle the figure.
export const figure = {
  skin: "#8A5A3C",
  hair: "#1E1411",
  coat: "#B5446E",
  pants: "#2B2A44",
  shoes: "#1A1A2E",
};
POEM_EOF
echo 'Added the DandelionPoem composition. Now run: npm run dev'
