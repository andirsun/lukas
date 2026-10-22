import { useCallback, useSyncExternalStore } from "react";

/** The app's wide layout (sidebar, lists side by side): 64rem and up, as the CSS's `lg:`. */
const WIDE_QUERY = "(min-width: 64rem)";

/**
 * A short screen, as the add sheet's CSS has it (an Android phone under Chrome's bars is about
 * 760 px): the sheet tightens so all of it fits.
 */
export const SHORT_QUERY = "(max-height: 799.98px)";

function media(query: string): MediaQueryList | undefined {
  return typeof window === "undefined" || typeof window.matchMedia !== "function"
    ? undefined
    : window.matchMedia(query);
}

/** Whether `query` matches (live, as the window is resized). False without `matchMedia`. */
export function useMediaQuery(query: string): boolean {
  const subscribe = useCallback(
    (onChange: () => void) => {
      const list = media(query);
      list?.addEventListener("change", onChange);
      return () => list?.removeEventListener("change", onChange);
    },
    [query],
  );
  return useSyncExternalStore(
    subscribe,
    () => media(query)?.matches ?? false,
    () => false,
  );
}

/** Whether the screen is wide (live, as the window is resized). False without `matchMedia`. */
export function useWideScreen(): boolean {
  return useMediaQuery(WIDE_QUERY);
}
