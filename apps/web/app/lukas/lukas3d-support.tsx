import { Component, type ReactNode, useEffect, useState } from "react";
import { useReducedMotionPreference } from "../ui/motion-tokens.ts";

/**
 * Whether this browser gets the 3D Lukas: WebGL works and the device has at least 4 GB of memory
 * (`navigator.deviceMemory`, where the browser reports it). Reduced motion is checked by the hook
 * below, since it can change while the page is open. This module is tiny on purpose: it ships with
 * the page, three.js only with the lazy `Lukas3D` chunk.
 */
export function canRender3D(): boolean {
  if (typeof window === "undefined") return false;
  const memory = (navigator as Navigator & { deviceMemory?: number }).deviceMemory;
  if (typeof memory === "number" && memory < 4) return false;
  try {
    const canvas = document.createElement("canvas");
    const gl = canvas.getContext("webgl2") ?? canvas.getContext("webgl");
    if (!gl) return false;
    gl.getExtension("WEBGL_lose_context")?.loseContext();
    return true;
  } catch {
    return false;
  }
}

/** Runs `callback` once the page has loaded and the browser is idle (or after a short wait). */
function whenLoadedAndIdle(callback: () => void): () => void {
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
 * True once the 3D Lukas should load: after the page (and so the hero) has rendered and loaded,
 * when the browser is idle, and only without reduced motion, with WebGL and enough memory. Turns
 * false again if the person switches reduced motion on, so the still 2D Lukas comes back.
 */
export function useLukas3DReady(): boolean {
  const reduceMotion = useReducedMotionPreference();
  const [ready, setReady] = useState(false);
  useEffect(() => {
    if (reduceMotion || !canRender3D()) return;
    return whenLoadedAndIdle(() => setReady(true));
  }, [reduceMotion]);
  return ready && !reduceMotion;
}

/** Renders nothing if the 3D Lukas fails (a lost context, a failed chunk): the 2D one stays. */
export class Lukas3DBoundary extends Component<{ children: ReactNode }, { failed: boolean }> {
  override state = { failed: false };

  static getDerivedStateFromError() {
    return { failed: true };
  }

  override componentDidCatch(error: unknown) {
    // Not an app error: the page keeps the 2D Lukas. Keep a trace for debugging.
    console.warn("Lukas 3D is off:", error);
  }

  override render() {
    return this.state.failed ? null : this.props.children;
  }
}
