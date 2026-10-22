import { MotionConfigContext } from "motion/react";
import { useContext, useSyncExternalStore } from "react";

export type DurationToken =
  | "--press"
  | "--sheet"
  | "--count-up"
  | "--celebrate"
  | "--shiver"
  | "--hop"
  | "--collapse"
  | "--fade"
  | "--undo";

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
 * The feel of the swipes (the home pager, the transaction rows, the toast). Durations are CSS
 * tokens (above); these are the rest: distances, speeds and springs. Tuned by hand on a 390 px
 * phone with real touch (Task 12c report); change them here, nowhere else.
 */
export const GESTURE = {
  /** px the finger moves before a gesture picks an axis (sideways, or the page's scroll). */
  axisSlop: 8,
  /** px/s: a release faster than this is a flick, and goes its way whatever the distance. */
  flickVelocity: 500,
  /** Past the first or last page, or toward a side with no action, content moves 0.3× the finger. */
  rubberBand: 0.3,
  /** px between two pages of the pager while they slide (more than the screen's side margin). */
  pagerGap: 32,
  /** pages/s: the most a release hands to the pager's spring, so a hard fling bounces only a bit. */
  pagerMaxVelocity: 4,
  /** A row runs its action when let go past this fraction of its width. */
  rowThreshold: 0.4,
  /** px: how much of an action a short swipe leaves open. */
  rowActionWidth: 88,
  /** A deleted row starts folding away once this much of it has left the screen. */
  rowGoneAt: 0.9,
  /** px: a toast dragged this far down or sideways is dismissed. */
  toastDismiss: 48,
} as const;

/** Springs, for Motion's `transition`. `restDelta` is in the animated value's own units. */
export const SPRINGS = {
  /** The tab pager settling on a page: stiff, a hint of bounce. Its value is in pages. */
  pager: { type: "spring", stiffness: 400, damping: 35, restDelta: 0.0005, restSpeed: 0.01 },
  /** A row snapping open, shut, or back after its action; in px. */
  row: { type: "spring", stiffness: 520, damping: 38, restDelta: 0.5 },
  /** A row flying off the screen when deleted (or back in after Deshacer); in px. */
  rowOut: { type: "spring", stiffness: 600, damping: 48, restDelta: 1 },
} as const;

const REDUCED_MOTION_QUERY = "(prefers-reduced-motion: reduce)";

type MatchMedia = (query: string) => {
  matches: boolean;
  addEventListener(type: "change", listener: () => void): void;
  removeEventListener(type: "change", listener: () => void): void;
};

/**
 * `prefers-reduced-motion` as an external store for `useSyncExternalStore`: the current setting,
 * and a subscription that fires whenever the person changes it while the page is open. Without
 * `matchMedia` (and on the server) it is false, so prerendered HTML and hydration keep motion on.
 * `getMatchMedia` is injectable for tests.
 */
export function reducedMotionStore(
  getMatchMedia: () => MatchMedia | undefined = () =>
    typeof window === "undefined" || typeof window.matchMedia !== "function"
      ? undefined
      : window.matchMedia.bind(window),
) {
  const query = () => getMatchMedia()?.(REDUCED_MOTION_QUERY);
  return {
    subscribe(onChange: () => void): () => void {
      const media = query();
      media?.addEventListener("change", onChange);
      return () => media?.removeEventListener("change", onChange);
    },
    getSnapshot: (): boolean => query()?.matches ?? false,
    getServerSnapshot: (): boolean => false,
  };
}

const reducedMotion = reducedMotionStore();

/**
 * Whether to keep motion to fades: the person's `prefers-reduced-motion`, live (it updates when
 * they switch it while the page is open), or a surrounding `<MotionConfig reducedMotion="always">`
 * (Storybook forces it to test these paths). Motion's own hooks can't be used: `useReducedMotion`
 * reads the setting once and never updates, and `useReducedMotionConfig`'s context defaults to
 * "never", which would ignore the OS setting whenever no MotionConfig is mounted.
 */
export function useReducedMotionPreference(): boolean {
  const prefersReduced = useSyncExternalStore(
    reducedMotion.subscribe,
    reducedMotion.getSnapshot,
    reducedMotion.getServerSnapshot,
  );
  const { reducedMotion: config } = useContext(MotionConfigContext);
  return config === "always" || prefersReduced;
}
