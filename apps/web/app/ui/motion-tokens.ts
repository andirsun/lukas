import { MotionConfigContext } from "motion/react";
import { useContext, useSyncExternalStore } from "react";

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
