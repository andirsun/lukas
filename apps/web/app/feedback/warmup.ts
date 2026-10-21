import { useEffect } from "react";
import { LUKAS_ART } from "../lukas/Lukas.tsx";
import { installSoundUnlock } from "./feedback.ts";

/** Used when the browser has no `requestIdleCallback` (Safari): a moment after the first paint. */
const IDLE_FALLBACK_MS = 2000;

/**
 * Fetches an image into the HTTP cache once the browser is idle, so it is ready the first time it
 * is shown. Returns a function that cancels it if it has not run yet.
 */
export function prefetchImageWhenIdle(src: string): () => void {
  if (typeof window === "undefined" || typeof Image === "undefined") return () => {};
  const load = () => {
    new Image().src = src;
  };
  if (typeof window.requestIdleCallback === "function") {
    const handle = window.requestIdleCallback(load);
    return () => window.cancelIdleCallback?.(handle);
  }
  const timer = setTimeout(load, IDLE_FALLBACK_MS);
  return () => clearTimeout(timer);
}

/**
 * Prepares the feedback module for the app's screens, once, from the app layout (never the
 * landing): the sounds are unlocked on the first tap or key press, and the celebrating Lukitas'
 * sprite sheet (386 KB) is prefetched when idle, so the first celebration is not a late pop-in.
 */
export function useFeedbackWarmup(): void {
  useEffect(() => {
    const removeUnlock = installSoundUnlock();
    const cancelPrefetch = prefetchImageWhenIdle(LUKAS_ART.celebrating.sprite.src);
    return () => {
      removeUnlock();
      cancelPrefetch();
    };
  }, []);
}
