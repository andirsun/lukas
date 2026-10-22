import { useEffect, useState } from "react";
import { useReducedMotionPreference } from "../../ui/motion-tokens.ts";
import { whenLoadedAndIdle } from "../live-support.tsx";

/**
 * Whether this browser gets the 3D Lukas: WebGL works and the device has at least 4 GB of memory
 * (`navigator.deviceMemory`, where the browser reports it). Reduced motion is checked by the hook
 * below, since it can change while the page is open.
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

/**
 * True once the 3D Lukas should load: after the page has rendered and loaded, when the browser is
 * idle, and only without reduced motion, with WebGL and enough memory. Turns false again if the
 * person switches reduced motion on.
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
