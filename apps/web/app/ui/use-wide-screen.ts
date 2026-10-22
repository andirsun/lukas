import { useSyncExternalStore } from "react";

/** The app's wide layout (sidebar, lists side by side): 64rem and up, as the CSS's `lg:`. */
const WIDE_QUERY = "(min-width: 64rem)";

function media(): MediaQueryList | undefined {
  return typeof window === "undefined" || typeof window.matchMedia !== "function"
    ? undefined
    : window.matchMedia(WIDE_QUERY);
}

function subscribe(onChange: () => void): () => void {
  const list = media();
  list?.addEventListener("change", onChange);
  return () => list?.removeEventListener("change", onChange);
}

/** Whether the screen is wide (live, as the window is resized). False without `matchMedia`. */
export function useWideScreen(): boolean {
  return useSyncExternalStore(
    subscribe,
    () => media()?.matches ?? false,
    () => false,
  );
}
