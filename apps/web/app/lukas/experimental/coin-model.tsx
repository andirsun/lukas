import { useFrame } from "@react-three/fiber";
import { type RefObject, useEffect, useMemo, useRef } from "react";
import {
  BoxGeometry,
  CapsuleGeometry,
  CircleGeometry,
  CylinderGeometry,
  type Group,
  InstancedMesh,
  LatheGeometry,
  type Mesh,
  MeshBasicMaterial,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  Object3D,
  Shape,
  ShapeGeometry,
  SphereGeometry,
  TorusGeometry,
  Vector2,
} from "three";
import type { LukasPose } from "../use-scroll-pose.ts";
import { LUKAS_3D_PALETTE as C } from "./lukas3d-palette.ts";

/** Everything the coin can do: the scroll poses, flying between spots, and worried. */
export type CoinPose = LukasPose | "travel" | "worried";

/** What drives the model each frame; Lukas3D writes it, the model eases toward it. */
export interface CoinDrive {
  pose: CoinPose;
  /** Where the pupils look, -1..1 (right, up are positive). */
  lookX: number;
  lookY: number;
  /** 0 open … 1 closed. */
  blink: number;
  /** Seconds for one celebrating hop and arm pump (the `--celebrate` token). */
  celebrateSeconds: number;
  /** Arms and legs out: 0 tucked into the body (rolling in) … 1 out. */
  limbs: number;
}

/** Coin proportions, in model units (radius 1). */
const R = 1;
const HALF_DEPTH = 0.3;
const CORNER = 0.13;
const FACE_Z = HALF_DEPTH;
/** The face is a shallow dome inside the rim (so light rolls over it like on the concept). */
const FACE_RADIUS = 0.82;
const FACE_DOME = 0.05;
const FACE_SPHERE = (FACE_RADIUS ** 2 + FACE_DOME ** 2) / (2 * FACE_DOME);
/** Eyes, brows, cheeks and mouth sit on the dome, about this far in front of the coin's face. */
const FEATURE_Z = FACE_Z + FACE_DOME;
const RIDGES = 48;

/** A rounded, chubby coin body: a lathe around Y (turned to face the camera by its parent). */
function coinBodyGeometry(): LatheGeometry {
  const points: Vector2[] = [new Vector2(0, -HALF_DEPTH)];
  const arc = (cx: number, cy: number, from: number, to: number) => {
    for (let i = 0; i <= 8; i++) {
      const a = from + ((to - from) * i) / 8;
      points.push(new Vector2(cx + CORNER * Math.cos(a), cy + CORNER * Math.sin(a)));
    }
  };
  arc(R - CORNER, -HALF_DEPTH + CORNER, -Math.PI / 2, 0);
  arc(R - CORNER, HALF_DEPTH - CORNER, 0, Math.PI / 2);
  points.push(new Vector2(0, HALF_DEPTH));
  return new LatheGeometry(points, 96);
}

/** A four-point sparkle, like the 2D celebrating Lukas'. */
function sparkleGeometry(): ShapeGeometry {
  const s = new Shape();
  s.moveTo(0, 1);
  s.quadraticCurveTo(0.12, 0.12, 1, 0);
  s.quadraticCurveTo(0.12, -0.12, 0, -1);
  s.quadraticCurveTo(-0.12, -0.12, -1, 0);
  s.quadraticCurveTo(-0.12, 0.12, 0, 1);
  return new ShapeGeometry(s, 6);
}

function useAssets() {
  const assets = useMemo(() => {
    const gold = new MeshPhysicalMaterial({
      color: C.gold,
      metalness: 0.5,
      roughness: 0.3,
      clearcoat: 0.6,
      clearcoatRoughness: 0.25,
    });
    const goldEdge = new MeshStandardMaterial({
      color: C.goldEdge,
      metalness: 0.6,
      roughness: 0.32,
    });
    const goldFace = new MeshPhysicalMaterial({
      color: C.goldFace,
      metalness: 0.2,
      roughness: 0.4,
      clearcoat: 0.5,
      clearcoatRoughness: 0.3,
    });
    const limb = new MeshStandardMaterial({ color: C.limb, roughness: 0.55, metalness: 0 });
    const sneaker = new MeshStandardMaterial({ color: C.sneaker, roughness: 0.45 });
    const sole = new MeshStandardMaterial({ color: C.sole, roughness: 0.5 });
    const sclera = new MeshPhysicalMaterial({
      color: C.sclera,
      roughness: 0.15,
      clearcoat: 1,
      clearcoatRoughness: 0.05,
    });
    const iris = new MeshPhysicalMaterial({
      color: C.iris,
      roughness: 0.2,
      clearcoat: 1,
      clearcoatRoughness: 0.05,
    });
    const pupil = new MeshStandardMaterial({ color: C.pupil, roughness: 0.2 });
    const shine = new MeshBasicMaterial({ color: "#ffffff", toneMapped: false });
    const brow = new MeshStandardMaterial({ color: C.brow, roughness: 0.6 });
    const cheek = new MeshBasicMaterial({
      color: C.cheek,
      transparent: true,
      opacity: 0.78,
      depthWrite: false,
    });
    const mouth = new MeshStandardMaterial({ color: C.mouth, roughness: 0.6 });
    const tongue = new MeshStandardMaterial({ color: C.tongue, roughness: 0.5 });
    const teeth = new MeshStandardMaterial({ color: C.teeth, roughness: 0.4 });
    const sparkleGold = new MeshBasicMaterial({ color: C.sparkleGold, toneMapped: false });
    const sparkleMint = new MeshBasicMaterial({ color: C.sparkleMint, toneMapped: false });

    const geometries = {
      body: coinBodyGeometry(),
      ridge: new BoxGeometry(0.03, 2 * (HALF_DEPTH - CORNER) - 0.02, 0.045),
      rim: new TorusGeometry(0.84, 0.055, 14, 96),
      face: new SphereGeometry(
        FACE_SPHERE,
        96,
        12,
        0,
        Math.PI * 2,
        0,
        Math.asin(FACE_RADIUS / FACE_SPHERE),
      ).rotateX(Math.PI / 2),
      sphere: new SphereGeometry(1, 32, 20),
      limb: new CapsuleGeometry(0.095, 0.25, 6, 12),
      finger: new CapsuleGeometry(0.052, 0.07, 4, 10),
      thumb: new CapsuleGeometry(0.055, 0.05, 4, 10),
      arc: new TorusGeometry(0.12, 0.026, 8, 24, Math.PI),
      // An arc centered on the top of its circle, so tilting it pivots around the middle.
      brow: new TorusGeometry(0.13, 0.024, 8, 20, Math.PI * 0.55).rotateZ(Math.PI * 0.225),
      halfDisc: new CircleGeometry(1, 40, Math.PI, Math.PI),
      disc: new CircleGeometry(1, 32),
      teeth: new BoxGeometry(0.34, 0.055, 0.01),
      lace: new BoxGeometry(0.13, 0.02, 0.035),
      miniCoin: new CylinderGeometry(0.34, 0.34, 0.1, 40),
      miniRim: new TorusGeometry(0.28, 0.03, 8, 40),
      sparkle: sparkleGeometry(),
    };
    const materials = {
      gold,
      goldEdge,
      goldFace,
      limb,
      sneaker,
      sole,
      sclera,
      iris,
      pupil,
      shine,
      brow,
      cheek,
      mouth,
      tongue,
      teeth,
      sparkleGold,
      sparkleMint,
    };
    return { geometries, materials };
  }, []);

  useEffect(
    () => () => {
      for (const g of Object.values(assets.geometries)) g.dispose();
      for (const m of Object.values(assets.materials)) m.dispose();
    },
    [assets],
  );
  return assets;
}

/** The ridged edge: thin boxes around the side, in one draw call. */
function Ridges({ assets }: { assets: ReturnType<typeof useAssets> }) {
  const mesh = useMemo(() => {
    const m = new InstancedMesh(assets.geometries.ridge, assets.materials.goldEdge, RIDGES);
    const dummy = new Object3D();
    for (let i = 0; i < RIDGES; i++) {
      const angle = (i / RIDGES) * Math.PI * 2;
      dummy.position.set(Math.cos(angle) * (R - 0.008), 0, Math.sin(angle) * (R - 0.008));
      dummy.rotation.set(0, -angle, 0);
      dummy.updateMatrix();
      m.setMatrixAt(i, dummy.matrix);
    }
    m.instanceMatrix.needsUpdate = true;
    return m;
  }, [assets]);
  useEffect(() => () => mesh.dispose(), [mesh]);
  return <primitive object={mesh} />;
}

interface Expression {
  eyesOpen: boolean;
  mouth: "grin" | "smile" | "o";
  /** Brow tilt: positive raises the inner ends (worried). */
  browTilt: number;
  browLift: number;
}

const EXPRESSIONS: Record<CoinPose, Expression> = {
  wave: { eyesOpen: true, mouth: "grin", browTilt: 0, browLift: 0 },
  point: { eyesOpen: true, mouth: "grin", browTilt: 0, browLift: 0.02 },
  carry: { eyesOpen: true, mouth: "smile", browTilt: 0, browLift: 0.03 },
  celebrate: { eyesOpen: false, mouth: "grin", browTilt: 0, browLift: 0.05 },
  travel: { eyesOpen: true, mouth: "o", browTilt: 0, browLift: 0.06 },
  worried: { eyesOpen: true, mouth: "o", browTilt: 0.38, browLift: 0.02 },
};

/** Arm and leg targets. `raise` swings an arm out and up (0 = hanging), `fwd` brings it forward,
 * `reach` stretches it (rubber-hose arms). Legs: `kick` forward, `spread` outward. */
interface Limbs {
  left: { raise: number; fwd: number; reach: number };
  right: { raise: number; fwd: number; reach: number };
  legs: { leftKick: number; rightKick: number; spread: number };
}

function limbsFor(pose: CoinPose, t: number, celebrate: number): Limbs {
  const pump = Math.sin((t / celebrate) * Math.PI * 2);
  switch (pose) {
    case "wave":
      return {
        left: { raise: 2.5 + Math.sin(t * 8) * 0.3, fwd: 0.2, reach: 1.15 },
        right: { raise: 0.32, fwd: 0.1, reach: 1 },
        legs: { leftKick: 0, rightKick: 0, spread: 0.07 },
      };
    case "point":
      return {
        left: { raise: 1.25, fwd: 0.35, reach: 1.25 },
        right: { raise: 0.3, fwd: 0.1, reach: 1 },
        legs: { leftKick: 0, rightKick: 0, spread: 0.1 },
      };
    case "carry":
      return {
        left: { raise: 0.35, fwd: 0.1, reach: 1 },
        right: { raise: 2.55 + Math.sin(t * 2.4) * 0.06, fwd: 0.15, reach: 1.15 },
        legs: { leftKick: 0, rightKick: 0, spread: 0.08 },
      };
    case "celebrate":
      return {
        left: { raise: 2.3 + pump * 0.22, fwd: 0.15, reach: 1.15 },
        right: { raise: 2.3 - pump * 0.22, fwd: 0.15, reach: 1.15 },
        legs: { leftKick: 0.55 + pump * 0.2, rightKick: -0.35 - pump * 0.15, spread: 0.12 },
      };
    case "travel":
      return {
        left: { raise: 1.9, fwd: 0.1, reach: 1.1 },
        right: { raise: 1.9, fwd: 0.1, reach: 1.1 },
        legs: { leftKick: 0.45, rightKick: 0.25, spread: 0.12 },
      };
    case "worried":
      return {
        left: { raise: -0.55, fwd: 1.15, reach: 1 },
        right: { raise: -0.55, fwd: 1.15, reach: 1 },
        legs: { leftKick: 0, rightKick: 0, spread: 0.03 },
      };
  }
}

/** Frame-rate independent easing toward a target. */
function ease(current: number, target: number, rate: number, dt: number): number {
  return current + (target - current) * (1 - Math.exp(-rate * dt));
}

const ARM_LENGTH = 0.46;
/** Full length of the limb capsule (cylinder + both caps). */
const LIMB_LENGTH = 0.25 + 2 * 0.095;

/** How a glove hand is held. */
type HandShape = "open" | "fist" | "point" | "relaxed";

/** Curl per digit (0 straight … 1 curled): the three fingers from the thumb side out, then the
 * thumb. */
const HAND_CURLS: Record<HandShape, readonly [number, number, number, number]> = {
  open: [0, 0, 0, 0],
  fist: [1, 1, 1, 1],
  point: [0, 1, 1, 0.9],
  relaxed: [0.45, 0.55, 0.65, 0.35],
};

/** Which hand shape each pose uses (viewer's left hand, viewer's right hand). */
const HANDS: Record<CoinPose, readonly [HandShape, HandShape]> = {
  wave: ["open", "relaxed"],
  point: ["point", "relaxed"],
  carry: ["relaxed", "fist"],
  celebrate: ["fist", "fist"],
  travel: ["open", "open"],
  worried: ["fist", "fist"],
};

/**
 * Digit layout, hand-local (the arm hangs along -Y, the palm faces +Z): straight (`open`) and
 * curled into the palm (`curled`). `x` is mirrored per side, so the thumb is always on the side
 * toward the body. Three short fingers and a thumb, like the concept's cartoon gloves.
 */
const DIGITS = [
  { open: { x: -0.08, y: -0.235, z: 0, tilt: -0.28 }, curled: { x: -0.07, y: -0.13, z: 0.07 } },
  { open: { x: 0.005, y: -0.26, z: 0, tilt: 0.02 }, curled: { x: 0.005, y: -0.14, z: 0.075 } },
  { open: { x: 0.09, y: -0.225, z: 0, tilt: 0.32 }, curled: { x: 0.08, y: -0.125, z: 0.07 } },
] as const;
const THUMB = {
  open: { x: -0.155, y: -0.045, z: 0.04, tilt: -1.05 },
  curled: { x: -0.1, y: -0.1, z: 0.115, tilt: -0.35 },
} as const;

/** A cartoon glove: rounded palm, three short rounded fingers and a thumb, all in the limb
 * purple, easing between open, relaxed, pointing and fist. */
function Hand({
  side,
  index,
  assets,
  drive,
}: {
  side: -1 | 1;
  /** 0 for the viewer's left hand, 1 for the right. */
  index: 0 | 1;
  assets: ReturnType<typeof useAssets>;
  drive: RefObject<CoinDrive>;
}) {
  const { geometries: g, materials: m } = assets;
  const digits = useRef<(Mesh | null)[]>([]);
  const curls = useRef([0.5, 0.5, 0.5, 0.5]);

  useFrame((_, delta) => {
    const pose = drive.current?.pose ?? "wave";
    const target = HAND_CURLS[HANDS[pose][index]];
    const dt = Math.min(delta, 0.05);
    for (let i = 0; i < 4; i++) {
      const digit = digits.current[i];
      const c = ease(curls.current[i] ?? 0, target[i] ?? 0, 14, dt);
      curls.current[i] = c;
      if (!digit) continue;
      if (i < 3) {
        const layout = DIGITS[i as 0 | 1 | 2];
        digit.position.set(
          lerpN(layout.open.x, layout.curled.x, c) * side,
          lerpN(layout.open.y, layout.curled.y, c),
          lerpN(layout.open.z, layout.curled.z, c),
        );
        // Curling folds the finger toward the palm (+Z) and shortens what shows of it.
        digit.rotation.set(-1.45 * c, 0, layout.open.tilt * (1 - c) * side);
        // Open fingers are a bit longer; curled ones show only their knuckles.
        digit.scale.set(1, 1.25 - 0.55 * c, 1);
      } else {
        digit.position.set(
          lerpN(THUMB.open.x, THUMB.curled.x, c) * side,
          lerpN(THUMB.open.y, THUMB.curled.y, c),
          lerpN(THUMB.open.z, THUMB.curled.z, c),
        );
        digit.rotation.set(-0.5 * c, 0, lerpN(THUMB.open.tilt, THUMB.curled.tilt, c) * side);
      }
    }
  });

  return (
    <>
      <mesh geometry={g.sphere} material={m.limb} scale={[0.155, 0.15, 0.12]} />
      {[0, 1, 2].map((i) => (
        <mesh
          key={i}
          ref={(mesh) => {
            digits.current[i] = mesh;
          }}
          geometry={g.finger}
          material={m.limb}
        />
      ))}
      <mesh
        ref={(mesh) => {
          digits.current[3] = mesh;
        }}
        geometry={g.thumb}
        material={m.limb}
      />
    </>
  );
}

function lerpN(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

/** One arm: a shoulder pivot with a capsule and a glove hand (+ the mini coin it can hold up). */
function Arm({
  side,
  assets,
  drive,
  pivot,
  upper,
  hand,
  coin,
}: {
  side: -1 | 1;
  assets: ReturnType<typeof useAssets>;
  drive: RefObject<CoinDrive>;
  pivot: RefObject<Group | null>;
  upper: RefObject<Mesh | null>;
  hand: RefObject<Group | null>;
  coin?: RefObject<Group | null>;
}) {
  const { geometries: g, materials: m } = assets;
  return (
    <group ref={pivot} position={[side * 0.9, -0.06, -0.06]}>
      <mesh
        ref={upper}
        geometry={g.limb}
        material={m.limb}
        position={[0, -ARM_LENGTH / 2, 0]}
        scale={[1, ARM_LENGTH / LIMB_LENGTH, 1]}
      />
      <group ref={hand} position={[0, -ARM_LENGTH, 0]}>
        <Hand side={side} index={side === -1 ? 0 : 1} assets={assets} drive={drive} />
        {coin && (
          <group ref={coin} position={[0, -0.5, 0.05]} visible={false}>
            <mesh geometry={g.miniCoin} material={m.gold} rotation={[Math.PI / 2, 0, 0]} />
            <mesh geometry={g.miniRim} material={m.goldEdge} position={[0, 0, 0.052]} />
          </group>
        )}
      </group>
    </group>
  );
}

/** One leg with its pink sneaker. */
function Leg({
  side,
  assets,
  pivot,
}: {
  side: -1 | 1;
  assets: ReturnType<typeof useAssets>;
  pivot: RefObject<Group | null>;
}) {
  const { geometries: g, materials: m } = assets;
  return (
    <group ref={pivot} position={[side * 0.32, -0.84, -0.04]}>
      <mesh geometry={g.limb} material={m.limb} position={[0, -0.17, 0]} scale={[1, 0.75, 1]} />
      <group position={[side * 0.03, -0.42, 0.08]} rotation={[0, side * 0.22, 0]} scale={1.3}>
        {/* upper */}
        <mesh geometry={g.sphere} material={m.sneaker} scale={[0.17, 0.12, 0.25]} />
        {/* toe cap */}
        <mesh
          geometry={g.sphere}
          material={m.sole}
          position={[0, -0.015, 0.16]}
          scale={[0.13, 0.075, 0.1]}
        />
        {/* sole */}
        <mesh
          geometry={g.sphere}
          material={m.sole}
          position={[0, -0.075, 0.01]}
          scale={[0.18, 0.05, 0.27]}
        />
        {/* laces */}
        <mesh
          geometry={g.lace}
          material={m.sole}
          position={[0, 0.105, 0.02]}
          rotation={[0.3, 0, 0]}
        />
        <mesh
          geometry={g.lace}
          material={m.sole}
          position={[0, 0.085, 0.08]}
          rotation={[0.5, 0, 0]}
        />
        {/* collar */}
        <mesh
          geometry={g.sphere}
          material={m.sole}
          position={[0, 0.1, -0.08]}
          scale={[0.1, 0.035, 0.08]}
        />
      </group>
    </group>
  );
}

/** One eye: white, iris, pupil and two highlights; the iris group follows the look target. */
function Eye({
  x,
  assets,
  eye,
  iris,
}: {
  x: number;
  assets: ReturnType<typeof useAssets>;
  eye: RefObject<Group | null>;
  iris: RefObject<Group | null>;
}) {
  const { geometries: g, materials: m } = assets;
  return (
    <group ref={eye} position={[x, 0.13, FEATURE_Z + 0.03]}>
      <mesh geometry={g.sphere} material={m.sclera} scale={[0.19, 0.235, 0.07]} />
      <group ref={iris} position={[0, 0, 0.055]}>
        <mesh geometry={g.sphere} material={m.iris} scale={[0.13, 0.145, 0.03]} />
        <mesh
          geometry={g.sphere}
          material={m.pupil}
          position={[0, 0, 0.012]}
          scale={[0.075, 0.085, 0.025]}
        />
        <mesh
          geometry={g.sphere}
          material={m.shine}
          position={[-0.04, 0.05, 0.035]}
          scale={0.034}
        />
        <mesh
          geometry={g.sphere}
          material={m.shine}
          position={[0.04, -0.045, 0.033]}
          scale={0.016}
        />
      </group>
    </group>
  );
}

const SPARKLES = [
  { x: -1.45, y: 1.15, size: 0.17, phase: 0, mint: false },
  { x: 1.5, y: 1.0, size: 0.2, phase: 0.25, mint: false },
  { x: 1.55, y: -0.25, size: 0.12, phase: 0.5, mint: true },
  { x: -1.55, y: -0.05, size: 0.13, phase: 0.75, mint: true },
] as const;

/**
 * Lukas as a procedural 3D model, after the concept: a chubby gold coin with a rounded, ridged edge
 * and a raised rim around a lighter face; big glossy eyes with highlights, brows, rosy cheeks and
 * an open smile; dark purple rubber-hose arms and legs; pink sneakers with white soles and laces.
 * It eases its limbs and face toward `drive` every frame. Facing +Z, about 3.4 units tall.
 */
export function CoinModel({ drive }: { drive: RefObject<CoinDrive> }) {
  const assets = useAssets();
  const { geometries: g, materials: m } = assets;

  const leftArm = useRef<Group>(null);
  const rightArm = useRef<Group>(null);
  const leftUpper = useRef<Mesh>(null);
  const rightUpper = useRef<Mesh>(null);
  const leftHand = useRef<Group>(null);
  const rightHand = useRef<Group>(null);
  const miniCoin = useRef<Group>(null);
  const leftLeg = useRef<Group>(null);
  const rightLeg = useRef<Group>(null);
  const leftEye = useRef<Group>(null);
  const rightEye = useRef<Group>(null);
  const leftIris = useRef<Group>(null);
  const rightIris = useRef<Group>(null);
  const happyEyes = useRef<Group>(null);
  const leftBrow = useRef<Mesh>(null);
  const rightBrow = useRef<Mesh>(null);
  const grin = useRef<Group>(null);
  const smile = useRef<Mesh>(null);
  const oMouth = useRef<Mesh>(null);
  const sparkles = useRef<Group>(null);
  const time = useRef(0);

  useFrame((_, delta) => {
    const d = drive.current;
    if (!d) return;
    const dt = Math.min(delta, 0.05);
    time.current += dt;
    const t = time.current;
    const limbs = limbsFor(d.pose, t, d.celebrateSeconds);
    const expression = EXPRESSIONS[d.pose];

    const arm = (
      pivot: Group | null,
      upper: Mesh | null,
      hand: Group | null,
      side: -1 | 1,
      target: Limbs["left"],
    ) => {
      if (!pivot || !upper || !hand) return;
      pivot.rotation.z = ease(pivot.rotation.z, side * target.raise, 12, dt);
      pivot.rotation.x = ease(pivot.rotation.x, -target.fwd, 12, dt);
      const length = ease(-hand.position.y, ARM_LENGTH * target.reach, 12, dt);
      hand.position.y = -length;
      upper.position.y = -length / 2;
      upper.scale.y = length / LIMB_LENGTH;
    };
    arm(leftArm.current, leftUpper.current, leftHand.current, -1, limbs.left);
    arm(rightArm.current, rightUpper.current, rightHand.current, 1, limbs.right);

    if (leftLeg.current && rightLeg.current) {
      leftLeg.current.rotation.x = ease(leftLeg.current.rotation.x, -limbs.legs.leftKick, 10, dt);
      rightLeg.current.rotation.x = ease(
        rightLeg.current.rotation.x,
        -limbs.legs.rightKick,
        10,
        dt,
      );
      leftLeg.current.rotation.z = ease(leftLeg.current.rotation.z, -limbs.legs.spread, 10, dt);
      rightLeg.current.rotation.z = ease(rightLeg.current.rotation.z, limbs.legs.spread, 10, dt);
    }
    // Arms and legs pop out of the body during the entrance (scale from shoulder and hip).
    const limbScale = Math.max(0.001, d.limbs);
    for (const limb of [leftArm.current, rightArm.current, leftLeg.current, rightLeg.current]) {
      limb?.scale.setScalar(limbScale);
    }
    if (miniCoin.current) {
      miniCoin.current.visible = d.pose === "carry";
      miniCoin.current.rotation.y = Math.sin(t * 2) * 0.35;
    }

    // Eyes: open with tracking pupils and blinks, or closed happy arcs.
    const open = expression.eyesOpen;
    const lid = Math.max(0.06, 1 - d.blink);
    for (const eye of [leftEye.current, rightEye.current]) {
      if (!eye) continue;
      eye.visible = open;
      eye.scale.y = ease(eye.scale.y, lid, 40, dt);
    }
    for (const iris of [leftIris.current, rightIris.current]) {
      if (!iris) continue;
      iris.position.x = ease(iris.position.x, d.lookX * 0.055, 14, dt);
      iris.position.y = ease(iris.position.y, d.lookY * 0.075, 14, dt);
    }
    if (happyEyes.current) happyEyes.current.visible = !open;

    if (leftBrow.current && rightBrow.current) {
      // Positive tilt lifts the inner ends (toward the nose): worried, not cross.
      leftBrow.current.rotation.z = ease(leftBrow.current.rotation.z, expression.browTilt, 10, dt);
      rightBrow.current.rotation.z = ease(
        rightBrow.current.rotation.z,
        -expression.browTilt,
        10,
        dt,
      );
      const lift = 0.33 + expression.browLift;
      leftBrow.current.position.y = ease(leftBrow.current.position.y, lift, 10, dt);
      rightBrow.current.position.y = ease(rightBrow.current.position.y, lift, 10, dt);
    }
    if (grin.current) grin.current.visible = expression.mouth === "grin";
    if (smile.current) smile.current.visible = expression.mouth === "smile";
    if (oMouth.current) oMouth.current.visible = expression.mouth === "o";

    if (sparkles.current) {
      sparkles.current.visible = d.pose === "celebrate";
      sparkles.current.children.forEach((child, i) => {
        const phase = SPARKLES[i]?.phase ?? 0;
        const size = SPARKLES[i]?.size ?? 0.15;
        const twinkle = 0.55 + 0.45 * Math.sin((t / d.celebrateSeconds + phase) * Math.PI * 2);
        child.scale.setScalar(size * twinkle);
        child.rotation.z = Math.sin(t + phase * 6) * 0.2;
      });
    }
  });

  return (
    <group>
      {/* The coin: body, ridged edge, raised rim and face. */}
      <group rotation={[Math.PI / 2, 0, 0]}>
        <mesh geometry={g.body} material={m.gold} />
        <Ridges assets={assets} />
      </group>
      <mesh geometry={g.rim} material={m.gold} position={[0, 0, FACE_Z - 0.005]} />
      <mesh
        geometry={g.face}
        material={m.goldFace}
        position={[0, 0, FACE_Z + 0.004 + FACE_DOME - FACE_SPHERE]}
      />

      {/* Face */}
      <Eye x={-0.3} assets={assets} eye={leftEye} iris={leftIris} />
      <Eye x={0.3} assets={assets} eye={rightEye} iris={rightIris} />
      <group ref={happyEyes} visible={false} position={[0, 0.1, FEATURE_Z + 0.02]}>
        <mesh geometry={g.arc} material={m.iris} position={[-0.3, 0, 0]} scale={[1.05, 0.9, 1]} />
        <mesh geometry={g.arc} material={m.iris} position={[0.3, 0, 0]} scale={[1.05, 0.9, 1]} />
      </group>
      <mesh
        ref={leftBrow}
        geometry={g.brow}
        material={m.brow}
        position={[-0.32, 0.33, FEATURE_Z + 0.02]}
      />
      <mesh
        ref={rightBrow}
        geometry={g.brow}
        material={m.brow}
        position={[0.32, 0.33, FEATURE_Z + 0.02]}
      />
      <mesh
        geometry={g.disc}
        material={m.cheek}
        position={[-0.52, -0.13, FEATURE_Z + 0.014]}
        scale={[0.115, 0.095, 1]}
      />
      <mesh
        geometry={g.disc}
        material={m.cheek}
        position={[0.52, -0.13, FEATURE_Z + 0.014]}
        scale={[0.115, 0.095, 1]}
      />
      <group ref={grin} position={[0, -0.17, FEATURE_Z + 0.014]}>
        <mesh geometry={g.halfDisc} material={m.mouth} scale={[0.24, 0.23, 1]} />
        <mesh
          geometry={g.disc}
          material={m.tongue}
          position={[0, -0.16, 0.002]}
          scale={[0.13, 0.06, 1]}
        />
        <mesh geometry={g.teeth} material={m.teeth} position={[0, -0.022, 0.004]} />
      </group>
      <mesh
        ref={smile}
        geometry={g.arc}
        material={m.mouth}
        position={[0, -0.12, FEATURE_Z + 0.02]}
        rotation={[0, 0, Math.PI]}
        scale={[1.1, 0.8, 1]}
        visible={false}
      />
      <mesh
        ref={oMouth}
        geometry={g.disc}
        material={m.mouth}
        position={[0, -0.22, FEATURE_Z + 0.014]}
        scale={[0.075, 0.09, 1]}
        visible={false}
      />

      {/* Limbs */}
      <Arm
        side={-1}
        assets={assets}
        drive={drive}
        pivot={leftArm}
        upper={leftUpper}
        hand={leftHand}
      />
      <Arm
        side={1}
        assets={assets}
        drive={drive}
        pivot={rightArm}
        upper={rightUpper}
        hand={rightHand}
        coin={miniCoin}
      />
      <Leg side={-1} assets={assets} pivot={leftLeg} />
      <Leg side={1} assets={assets} pivot={rightLeg} />

      <group ref={sparkles} visible={false}>
        {SPARKLES.map((s) => (
          <mesh
            key={`${s.x}:${s.y}`}
            geometry={g.sparkle}
            material={s.mint ? m.sparkleMint : m.sparkleGold}
            position={[s.x, s.y, 0.3]}
            scale={s.size}
          />
        ))}
      </group>
    </group>
  );
}
