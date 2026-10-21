import { createRoot, extend, type ReconcilerRoot, type RenderProps } from "@react-three/fiber";
import { Component, type ReactNode, useEffect, useInsertionEffect, useRef, useState } from "react";
import { DirectionalLight, Group, HemisphereLight, Mesh } from "three";

/**
 * Only the three.js classes the scene uses as JSX elements. R3F's `<Canvas>` registers the whole
 * `three` namespace (which keeps all of it in the bundle); a root of our own with this short list
 * lets the bundler drop the rest.
 */
extend({ DirectionalLight, Group, HemisphereLight, Mesh });

/** Hands errors from inside the 3D scene (a separate React root) back to the page's tree. */
class SceneBoundary extends Component<{ onError: (error: unknown) => void; children: ReactNode }> {
  override state = {};

  static getDerivedStateFromError() {
    return {};
  }

  override componentDidCatch(error: unknown) {
    this.props.onError(error);
  }

  override render() {
    return this.props.children;
  }
}

export type StageProps = Pick<
  RenderProps<HTMLCanvasElement>,
  "camera" | "dpr" | "frameloop" | "gl" | "onCreated"
> & { children: ReactNode };

/**
 * A lean stand-in for R3F's `<Canvas>`: a canvas that fills its parent, sized from the parent's
 * layout box (transforms ignored, so a scaled parent keeps a sharp canvas), with no pointer events
 * and only the catalogue above. Errors inside the scene (WebGL, a model that fails to load) are
 * rethrown here, for the nearest error boundary.
 */
export function Stage({ children, camera, dpr, frameloop, gl, onCreated }: StageProps) {
  const canvas = useRef<HTMLCanvasElement>(null);
  const root = useRef<ReconcilerRoot<HTMLCanvasElement> | null>(null);
  const [size, setSize] = useState({ width: 0, height: 0 });
  const [error, setError] = useState<unknown>(null);
  if (error) throw error;

  useEffect(() => {
    const parent = canvas.current?.parentElement;
    if (!parent) return;
    const observer = new ResizeObserver(() =>
      setSize({ width: parent.clientWidth, height: parent.clientHeight }),
    );
    observer.observe(parent);
    return () => observer.disconnect();
  }, []);

  // Released only on final removal (insertion effects survive StrictMode's effect replay).
  useInsertionEffect(
    () => () => {
      root.current?.unmount();
      root.current = null;
    },
    [],
  );

  useEffect(() => {
    const element = canvas.current;
    if (!element || size.width === 0 || size.height === 0) return;
    if (!root.current) root.current = createRoot(element);
    root.current
      .configure({
        camera,
        dpr,
        frameloop,
        gl,
        onCreated,
        events: undefined,
        size: { ...size, top: 0, left: 0 },
      })
      .catch(setError);
    try {
      root.current.render(<SceneBoundary onError={setError}>{children}</SceneBoundary>);
    } catch (failure) {
      setError(failure);
    }
  });

  return <canvas ref={canvas} style={{ display: "block", width: "100%", height: "100%" }} />;
}
