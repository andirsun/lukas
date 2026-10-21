import { useGLTF } from "@react-three/drei";
import { useMemo } from "react";

/**
 * A GLB of Lukas in place of the procedural coin (its own lazy chunk: the GLTF loader only ships
 * when a model is given). No Draco or Meshopt decoders: nothing is fetched from third parties.
 */
export default function GltfModel({ url }: { url: string }) {
  const { scene } = useGLTF(url, false, false);
  const model = useMemo(() => scene.clone(true), [scene]);
  return <primitive object={model} />;
}
