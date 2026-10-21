import { MotionConfigContext, useReducedMotion } from "motion/react";
import { useContext } from "react";

export type DurationToken = "--press" | "--sheet" | "--count-up" | "--celebrate" | "--shiver";

/**
 * Reads a duration token (`--sheet: 260ms`) from the stylesheet, in seconds, for Motion. The
 * tokens stay the single source of timing; without a document (prerender) it is 0.
 */
export function durationToken(name: DurationToken): number {
  if (typeof document === "undefined") return 0;
  const raw = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  const value = Number.parseFloat(raw);
  if (!Number.isFinite(value)) return 0;
  return raw.endsWith("ms") ? value / 1000 : value;
}

/**
 * Whether to keep motion to fades: the person's `prefers-reduced-motion`, or a surrounding
 * `<MotionConfig reducedMotion="always">` (Storybook forces it to test these paths). Motion's own
 * `useReducedMotionConfig` can't be used: its context defaults to "never", which would ignore the
 * OS setting whenever no MotionConfig is mounted.
 */
export function useReducedMotionPreference(): boolean {
  const prefersReduced = useReducedMotion() ?? false;
  const { reducedMotion } = useContext(MotionConfigContext);
  return reducedMotion === "always" || prefersReduced;
}
