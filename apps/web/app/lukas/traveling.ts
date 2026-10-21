/**
 * Pure helpers for the traveling 2.5D Lukas on the landing page (see `TravelingLukas.tsx`): which
 * mood a spot asks for, the tilt toward the pointer, how he gets from one spot to the next without
 * ever crossing text, and the rolling entrance. No DOM here, so all of it is unit tested.
 */
import { entrancePhase, rollAt } from "./entrance.ts";
import type { LukasMood } from "./mood.ts";
import type { LukasPose } from "./use-scroll-pose.ts";

const MOODS: readonly LukasMood[] = ["happy", "worried", "celebrating"];

/** The mood a pose implies when its spot doesn't say (`data-lukas-mood`). */
const POSE_MOOD: Record<LukasPose, LukasMood> = {
  wave: "happy",
  point: "happy",
  carry: "happy",
  celebrate: "celebrating",
};

/**
 * Lukas' mood on a spot: its `data-lukas-mood` when that is a mood, else the one its
 * `data-lukas-pose` implies (celebrate → celebrating, anything else → happy).
 */
export function spotMood(pose: string | undefined, mood: string | undefined): LukasMood {
  if (mood && (MOODS as readonly string[]).includes(mood)) return mood as LukasMood;
  return POSE_MOOD[pose as LukasPose] ?? "happy";
}

/** The most he turns toward the pointer, either way, around either axis. */
export const MAX_TILT_DEG = 12;

/** The pointer reaches the full tilt this far from him, as a fraction of the viewport. */
const TILT_REACH = 0.45;

function clamp(value: number, min = -1, max = 1): number {
  return Math.min(max, Math.max(min, Number.isFinite(value) ? value : 0));
}

/**
 * How much he turns toward the pointer, in degrees, for CSS `rotateX()`/`rotateY()`: a pointer to
 * his right turns him right (positive `rotateY`), one below him tips his face down (negative
 * `rotateX`). Proportional to the distance up to 45% of the viewport, then clamped to ±12°.
 */
export function tiltToward(
  pointer: { x: number; y: number },
  center: { x: number; y: number },
  viewport: { width: number; height: number },
): { rotateX: number; rotateY: number } {
  if (viewport.width <= 0 || viewport.height <= 0) return { rotateX: 0, rotateY: 0 };
  const dx = clamp((pointer.x - center.x) / (viewport.width * TILT_REACH));
  const dy = clamp((pointer.y - center.y) / (viewport.height * TILT_REACH));
  // `|| 0` turns a -0 into 0.
  return { rotateX: -dy * MAX_TILT_DEG || 0, rotateY: dx * MAX_TILT_DEG || 0 };
}

/** Through the last part of a section (scroll `y`, see `useScrollPose`), he moves to the next spot. */
export const TRAVEL_FROM = 0.7;

export interface TravelFrame {
  /** Which spot he stands on: the section's own, or the next one. */
  at: "current" | "next";
  opacity: number;
  /** `rotateY()` in degrees: like a coin turned edge-on (±90°) as he leaves and arrives. */
  turn: number;
  /** Between spots: no hops, no pointer. */
  moving: boolean;
}

function smoothstep(x: number): number {
  const t = clamp(x, 0, 1);
  return t * t * (3 - 2 * t);
}

/**
 * Where he is for a section's scroll `y` (0 to 1). He never flies across the page (he would pass
 * over text): through the end of the section he turns edge-on like a coin and fades out on his
 * spot, swaps spots while invisible, and turns back face-on as he fades in on the next one. The
 * spots themselves sit in free space beside the headings, so he never covers text.
 */
export function travelFrame(y: number, hasNext: boolean): TravelFrame {
  const p = hasNext ? clamp((y - TRAVEL_FROM) / (1 - TRAVEL_FROM), 0, 1) : 0;
  if (p <= 0) return { at: "current", opacity: 1, turn: 0, moving: false };
  if (p >= 1) return { at: "next", opacity: 1, turn: 0, moving: false };
  if (p < 0.5) {
    const out = smoothstep(p / 0.5);
    return { at: "current", opacity: 1 - out, turn: out * 90, moving: true };
  }
  const back = smoothstep((p - 0.5) / 0.5);
  return { at: "next", opacity: back, turn: -(1 - back) * 90 || 0, moving: true };
}

/**
 * Where the coin is in a frame of the sprite sheets (fractions of the frame): its face's center
 * and radius, and how far it sits above his soles. Measured on the founder's sheets.
 */
export const COIN = { x: 0.52, y: 0.42, radius: 0.31, drop: 0.2 } as const;

export interface EntranceFrame {
  phase: ReturnType<typeof entrancePhase>["phase"];
  /** Horizontal offset from his spot, px. */
  x: number;
  /** How far the tucked coin sits below its standing height, as a fraction of his size. */
  drop: number;
  /** CSS `rotate()` in degrees, around the coin's center. */
  rotate: number;
  /** 0: tucked (only the coin shows), 1: arms and legs out. */
  reveal: number;
  scale: number;
  /** Show a still frame (rolling, settling, unfolding); the wave sheet plays once false. */
  still: boolean;
}

/** Ease-out-back: overshoots a little, then settles (a springy pop). */
function popOut(p: number): number {
  const c = 1.9;
  return 1 + (c + 1) * (p - 1) ** 3 + c * (p - 1) ** 2;
}

const RAD_TO_DEG = 180 / Math.PI;

/**
 * The once-per-session entrance at `elapsedMs`, for a Lukas `size` px wide coming from `from`
 * (1: the right, -1: the left). The sheet has no "limbs tucked" frame, so he is tucked by showing
 * only the coin (a circle around its face, `reveal` 0), dropped to the ground. He rolls one
 * circumference without sliding (`rollAt`), settles with a small bounce, unfolds (the circle
 * grows past the frame while he rises onto his feet, with a springy pop), and waves.
 */
export function entranceFrame(elapsedMs: number, size: number, from: 1 | -1): EntranceFrame {
  const { phase, progress } = entrancePhase(elapsedMs);
  const standing = { phase, x: 0, drop: 0, rotate: 0, reveal: 1, scale: 1, still: false };
  if (phase === "roll") {
    const radius = COIN.radius * size;
    const { offset, angle } = rollAt(progress, 2 * Math.PI * radius, radius);
    return {
      phase,
      x: from * offset,
      drop: COIN.drop,
      // Rolling toward his spot: counter-clockwise from the right, clockwise from the left.
      rotate: -from * angle * RAD_TO_DEG || 0,
      reveal: 0,
      scale: 1,
      still: true,
    };
  }
  if (phase === "settle") {
    const fade = 1 - progress;
    return {
      phase,
      x: 0,
      drop: COIN.drop - Math.sin(progress * Math.PI) * 0.06 * fade,
      rotate: -from * Math.sin(progress * Math.PI * 3) * 9 * fade || 0,
      reveal: 0,
      scale: 1,
      still: true,
    };
  }
  if (phase === "unfold") {
    const pop = popOut(progress);
    return {
      phase,
      x: 0,
      drop: COIN.drop * Math.max(0, 1 - pop),
      rotate: 0,
      reveal: clamp(pop, 0, 1),
      scale: 0.92 + 0.08 * pop,
      still: true,
    };
  }
  return standing;
}
