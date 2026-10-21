import type { CSSProperties } from "react";
import { useTranslations } from "use-intl";
import { cx } from "../ui/cx.ts";
import { useReducedMotionPreference } from "../ui/motion-tokens.ts";
import type { LukasMood } from "./mood.ts";

export type { LukasMood } from "./mood.ts";

/** A sprite sheet: a full grid of square frames in reading order, played as a seamless loop. */
export interface LukasSprite {
  /** Public URL of the transparent sheet. */
  src: string;
  columns: number;
  rows: number;
  /** Duration of one loop through every frame. */
  loopMs: number;
}

/** How one mood is drawn. Frames are 0-based indices in reading order. */
export interface LukasMoodArt {
  sprite: LukasSprite;
  /** Play the sheet's loop; otherwise show `frame`. */
  play: boolean;
  /** The frame shown when the sheet is not played. */
  frame: number;
  /** The frame shown under reduced motion. */
  stillFrame: number;
  /**
   * CSS treatment for moods without their own sheet: `shiver` adds a small side-to-side shake and
   * a sweat drop, `hop` a jump with squash and stretch plus sparkles.
   */
  treatment: "none" | "shiver" | "hop";
}

const WAVE: LukasSprite = { src: "/lukas/wave.webp", columns: 4, rows: 2, loopMs: 1200 };

/**
 * The art per mood. Only the happy wave exists as a sheet so far; worried and celebrating reuse
 * its first frame with a CSS treatment. When their sheets arrive, point `sprite` at them, set
 * `play: true` and `treatment: "none"`: callers don't change.
 */
export const LUKAS_ART: Record<LukasMood, LukasMoodArt> = {
  happy: { sprite: WAVE, play: true, frame: 0, stillFrame: 0, treatment: "none" },
  worried: { sprite: WAVE, play: false, frame: 0, stillFrame: 0, treatment: "shiver" },
  celebrating: { sprite: WAVE, play: false, frame: 0, stillFrame: 4, treatment: "hop" },
};

export interface LukasProps {
  mood: LukasMood;
  /** Width and height in px. */
  size?: number;
  /** Hide from assistive technology when something next to Lukas already says the same. */
  decorative?: boolean;
  /** Overrides the art for this mood (final art, the landing page, stories). */
  art?: LukasMoodArt;
}

/** `background-position` of a frame: with `background-size: cols·100% rows·100%`, a cell's
 * percentage is its column over (cols − 1), and its row over (rows − 1). */
function framePosition(sprite: LukasSprite, frame: number): string {
  const column = frame % sprite.columns;
  const row = Math.floor(frame / sprite.columns) % sprite.rows;
  const x = sprite.columns > 1 ? (column / (sprite.columns - 1)) * 100 : 0;
  const y = sprite.rows > 1 ? (row / (sprite.rows - 1)) * 100 : 0;
  return `${round(x)}% ${round(y)}%`;
}

function round(value: number): number {
  return Math.round(value * 1000) / 1000;
}

/**
 * Stepping the sheet: `lk-sprite-x` walks the columns of a row (steps(columns) over one row's
 * time) while `lk-sprite-y` moves down a row each time (steps(rows) over the whole loop), so the
 * frames play in reading order; for the 4×2 wave that's 8 steps over 1.2s. The end values reach
 * one cell past the last one, which `steps()` never shows.
 */
function playingVars(sprite: LukasSprite): Record<string, string | number> {
  const end = (n: number) => (n > 1 ? `${round((n / (n - 1)) * 100)}%` : "0%");
  return {
    "--lk-sprite-cols": sprite.columns,
    "--lk-sprite-rows": sprite.rows,
    "--lk-sprite-row-ms": `${round(sprite.loopMs / sprite.rows)}ms`,
    "--lk-sprite-loop-ms": `${sprite.loopMs}ms`,
    "--lk-sprite-x-end": end(sprite.columns),
    "--lk-sprite-y-end": end(sprite.rows),
  };
}

/** Where the sparkles sit around Lukas; each one's twinkle is staggered by a quarter of
 * `--celebrate` (see `.lk-lukas-sparkle` in app.css). */
const SPARKLES = [
  { left: "4%", top: "10%", tone: "is-gold" },
  { left: "82%", top: "4%", tone: "is-candy" },
  { left: "88%", top: "52%", tone: "is-gold" },
  { left: "0%", top: "58%", tone: "is-candy" },
] as const;

/**
 * Lukas, the gold coin, in 2D. Happy waves (the founder's 4×2 sprite sheet); worried shivers with
 * a sweat drop; celebrating hops among sparkles. Under reduced motion every mood is a still frame
 * (the treatment's drop or sparkles stay, unmoving). Named by its mood unless `decorative`.
 */
export function Lukas({ mood, size = 96, decorative = false, art }: LukasProps) {
  const t = useTranslations("mascot");
  const reduceMotion = useReducedMotionPreference();
  const { sprite, play, frame, stillFrame, treatment } = art ?? LUKAS_ART[mood];
  const moving = !reduceMotion;
  const playing = moving && play;

  const spriteStyle = {
    backgroundImage: `url("${sprite.src}")`,
    backgroundSize: `${sprite.columns * 100}% ${sprite.rows * 100}%`,
    backgroundPosition: framePosition(sprite, reduceMotion ? stillFrame : frame),
    ...(playing ? playingVars(sprite) : {}),
  } as CSSProperties;

  return (
    <span
      className={cx(
        "lk-lukas",
        `is-${mood}`,
        moving && treatment === "shiver" && "is-shiver",
        moving && treatment === "hop" && "is-hop",
      )}
      style={{ width: size, height: size }}
      {...(decorative ? { "aria-hidden": true } : { role: "img", "aria-label": t(mood) })}
    >
      <span className="lk-lukas-body">
        <span className={cx("lk-lukas-sprite", playing && "is-playing")} style={spriteStyle} />
        {treatment === "shiver" && (
          <svg className="lk-lukas-sweat" viewBox="0 0 20 28" aria-hidden="true">
            <path d="M10 2 C10 2 2 13 2 19 a8 8 0 0 0 16 0 C18 13 10 2 10 2 Z" />
          </svg>
        )}
      </span>
      {treatment === "hop" &&
        SPARKLES.map((s, index) => (
          <svg
            key={`${s.left}-${s.top}`}
            className={cx("lk-lukas-sparkle", s.tone)}
            style={{ left: s.left, top: s.top, "--lk-sparkle-index": index } as CSSProperties}
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <path d="M12 0 C13 8 16 11 24 12 C16 13 13 16 12 24 C11 16 8 13 0 12 C8 11 11 8 12 0 Z" />
          </svg>
        ))}
    </span>
  );
}
