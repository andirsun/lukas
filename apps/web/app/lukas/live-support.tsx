import { Component, type ReactNode, useEffect, useState } from "react";
import { useReducedMotionPreference } from "../ui/motion-tokens.ts";

/** Runs `callback` once the page has loaded and the browser is idle (or after a short wait). */
export function whenLoadedAndIdle(callback: () => void): () => void {
  let cancelled = false;
  let idle = 0;
  let timer = 0;
  const idleThen = () => {
    if (cancelled) return;
    if ("requestIdleCallback" in window) {
      idle = window.requestIdleCallback(callback, { timeout: 2500 });
    } else {
      timer = globalThis.setTimeout(callback, 400) as unknown as number;
    }
  };
  if (document.readyState === "complete") idleThen();
  else window.addEventListener("load", idleThen, { once: true });
  return () => {
    cancelled = true;
    window.removeEventListener("load", idleThen);
    if (idle) window.cancelIdleCallback(idle);
    if (timer) globalThis.clearTimeout(timer);
  };
}

/**
 * True once the live Lukas (the one that moves over the page) should mount: after the page (and
 * so the prerendered hero) has rendered and loaded, when the browser is idle, and only without
 * reduced motion. Turns false again if the person switches reduced motion on, so the still,
 * prerendered Lukas comes back.
 */
export function useLiveLukasReady(): boolean {
  const reduceMotion = useReducedMotionPreference();
  const [ready, setReady] = useState(false);
  useEffect(() => {
    if (reduceMotion) return;
    return whenLoadedAndIdle(() => setReady(true));
  }, [reduceMotion]);
  return ready && !reduceMotion;
}

/** Renders nothing if the live Lukas fails: the prerendered one stays. */
export class LiveLukasBoundary extends Component<{ children: ReactNode }, { failed: boolean }> {
  override state = { failed: false };

  static getDerivedStateFromError() {
    return { failed: true };
  }

  override componentDidCatch(error: unknown) {
    // Not an app error: the page keeps the prerendered Lukas. Keep a trace for debugging.
    console.warn("The live Lukas is off:", error);
  }

  override render() {
    return this.state.failed ? null : this.props.children;
  }
}
