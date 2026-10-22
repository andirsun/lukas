import { useFrame, useThree } from "@react-three/fiber";
import {
  lazy,
  type RefObject,
  Suspense,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { type Group, NeutralToneMapping, PMREMGenerator } from "three";
import { RoomEnvironment } from "three/examples/jsm/environments/RoomEnvironment.js";
import { durationToken } from "../../ui/motion-tokens.ts";
import { entrancePhase, markEntranceSeen, rollAt, shouldPlayEntrance } from "../entrance.ts";
import type { LukasMood } from "../mood.ts";
import { type LukasSpot, useScrollPose } from "../use-scroll-pose.ts";
import { type CoinDrive, CoinModel, type CoinPose } from "./coin-model.tsx";
import { LUKAS_3D_PALETTE as C } from "./lukas3d-palette.ts";
import { Stage } from "./stage.tsx";
import "./lukas3d.css";

/** Loaded only when a GLB replaces the procedural model (it brings the GLTF loader along). */
const GltfModel = lazy(() => import("./gltf-model.tsx"));

export interface Lukas3DProps {
  mood?: LukasMood;
  /** A GLB of Lukas to show instead of the procedural coin (same framing: ~3.4 units tall). */
  modelUrl?: string;
}

/** Up to ±12° of body turn toward the pointer, around a slight three-quarter view (the concept
 * shows the coin's edge on the left). */
const MAX_TURN = (12 * Math.PI) / 180;
const BASE_YAW = 0.55;
/** Through the last part of a section (scroll `y`), Lukas travels to the next section's spot. */
const TRAVEL_FROM = 0.7;
/** A pointer older than this stops steering on touch screens; then the device tilt can. */
const TOUCH_LOOK_MS = 4000;

/** The framing: Lukas, arms up, fills the square canvas like the 2D sprite fills its frame. */
const CAMERA = { position: [0, 0.1, 6.6] as [number, number, number], fov: 30, near: 1, far: 20 };
/** Scene units across the canvas (its height = width) at the coin: px per unit = size / this. */
const VISIBLE_UNITS = 2 * CAMERA.position[2] * Math.tan(((CAMERA.fov / 2) * Math.PI) / 180);
/** While rolling in, the coin rides lower: his bottom edge where his soles will be. */
const ROLL_DROP = -0.45;
const DPR: [number, number] = [1, 2];
const GL = {
  alpha: true,
  antialias: true,
  powerPreference: "low-power" as const,
  toneMapping: NeutralToneMapping,
};

const MOOD_POSE: Record<LukasMood, CoinPose> = {
  happy: "wave",
  celebrating: "celebrate",
  worried: "worried",
};

/** The once-per-session entrance, as the render loop plays it. */
interface Entrance {
  state: "playing" | "skipped" | "done" | "none";
  elapsedMs: number;
  frames: number;
  /** He rolls in from this side of his spot: 1 right, -1 left. */
  from: 1 | -1;
  onDone: () => void;
}

/** Ease-out-back: overshoots a little, then settles (a springy pop). */
function popOut(p: number): number {
  const c = 1.9;
  return 1 + (c + 1) * (p - 1) ** 3 + c * (p - 1) ** 2;
}

/** Input and travel state shared between the page listeners and the render loop. */
interface Motion {
  pointer: { x: number; y: number; at: number; touch: boolean } | null;
  tilt: { x: number; y: number } | null;
  /** 0 on a spot … 1 on the next one. */
  travel: number;
  jumps: number;
  spins: number;
}

function clamp(value: number, min = -1, max = 1): number {
  return Math.min(max, Math.max(min, value));
}

function smoothstep(from: number, to: number, value: number): number {
  const x = clamp((value - from) / (to - from), 0, 1);
  return x * x * (3 - 2 * x);
}

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

/** A procedural studio for reflections, so the gold reads as metal without loading an HDR. */
function StudioLight() {
  const { gl, scene } = useThree();
  useEffect(() => {
    const generator = new PMREMGenerator(gl);
    const room = new RoomEnvironment();
    const texture = generator.fromScene(room, 0.04).texture;
    scene.environment = texture;
    scene.environmentIntensity = 0.55;
    room.dispose();
    generator.dispose();
    return () => {
      scene.environment = null;
      texture.dispose();
    };
  }, [gl, scene]);
  return (
    <>
      <hemisphereLight args={[C.sky, C.ground, 0.7]} />
      <directionalLight position={[-3, 4, 5]} intensity={1.7} color={C.keyLight} />
      <directionalLight position={[4, 2.5, -4]} intensity={3.4} color={C.rimLight} />
      <directionalLight position={[-4, -1, -3]} intensity={1.6} color={C.rimLight} />
    </>
  );
}

/**
 * Moves the whole character: idle bob, the turn toward the pointer (or touch, or tilt), the spin
 * while traveling, jumps on hover and springy spins on tap, the celebrating hop; and decides where
 * the eyes look and when they blink.
 */
function Rig({
  drive,
  motion,
  layer,
  stage,
  entrance,
  modelUrl,
}: {
  drive: RefObject<CoinDrive>;
  motion: RefObject<Motion>;
  layer: RefObject<HTMLDivElement | null>;
  stage: RefObject<HTMLDivElement | null>;
  entrance: RefObject<Entrance>;
  modelUrl?: string;
}) {
  const root = useRef<Group>(null);
  const s = useRef({
    t: 0,
    wall: 0,
    yaw: BASE_YAW,
    pitch: 0,
    spin: 0,
    spinVelocity: 0,
    spinTarget: 0,
    jump: 0,
    jumpVelocity: 0,
    squash: 0,
    squashVelocity: 0,
    jumps: 0,
    spins: 0,
    nextBlink: 1.5,
    blinkStart: -1,
  });

  useFrame((_, delta) => {
    const d = drive.current;
    const m = motion.current;
    const group = root.current;
    const box = layer.current?.getBoundingClientRect();
    if (!d || !m || !group || !box) return;
    const st = s.current;
    const dt = Math.min(delta, 0.05);
    st.t += dt;
    const t = st.t;

    // The entrance: roll in on his edge, settle, pop the limbs out; then the usual life below.
    const e = entrance.current;
    if (e?.state === "playing") {
      // The clock starts once frames flow (the first ones wait on shader compilation), and a
      // stalled frame advances it by at most 0.1 s, so the roll is never skipped.
      e.frames += 1;
      if (e.frames > 2) e.elapsedMs += Math.min(delta, 0.1) * 1000;
      const { phase, progress } = entrancePhase(e.elapsedMs);
      if (phase === "done") {
        e.state = "done";
        e.onDone();
      } else if (phase !== "wave") {
        d.lookX = 0;
        d.lookY = 0.1;
        d.blink = 0;
        group.scale.set(1, 1, 1);
        if (phase === "roll") {
          const size = layer.current?.offsetWidth ?? 0;
          const radius = size / VISIBLE_UNITS;
          const { offset, angle } = rollAt(progress, 2 * Math.PI * radius, radius);
          if (stage.current) stage.current.style.transform = `translateX(${e.from * offset}px)`;
          d.limbs = 0;
          group.position.y = ROLL_DROP;
          group.rotation.set(0, 0, e.from * angle);
        } else if (phase === "settle") {
          if (stage.current) stage.current.style.transform = "";
          d.limbs = 0;
          const fade = 1 - progress;
          group.position.y = ROLL_DROP + Math.sin(progress * Math.PI) * 0.12 * fade;
          group.rotation.set(0, 0, Math.sin(progress * Math.PI * 3) * 0.16 * fade * e.from);
        } else {
          const pop = popOut(progress);
          d.limbs = pop;
          group.position.y = ROLL_DROP * (1 - pop);
          st.yaw = BASE_YAW * (1 - (1 - progress) ** 3);
          group.rotation.set(0, st.yaw, 0);
        }
        return;
      }
      d.limbs = 1;
    }

    // Where to look: the pointer (always with a mouse; for a while after a touch), else the tilt,
    // else an idle glance around.
    let lookX = Math.sin(t * 0.45) * 0.35;
    let lookY = -0.15 + Math.sin(t * 0.3) * 0.1;
    const pointer = m.pointer;
    const pointerFresh =
      pointer && (!pointer.touch || performance.now() - pointer.at < TOUCH_LOOK_MS);
    if (pointer && pointerFresh) {
      const cx = box.left + box.width / 2;
      const cy = box.top + box.height * 0.42;
      lookX = clamp((pointer.x - cx) / (window.innerWidth * 0.45));
      lookY = clamp((pointer.y - cy) / (window.innerHeight * 0.45));
    } else if (m.tilt) {
      lookX = m.tilt.x;
      lookY = m.tilt.y;
    }
    d.lookX = lookX;
    d.lookY = -lookY;

    // Blink every 2–5.5 s, sometimes twice. On wall-clock time, so a blink stays a blink (150 ms)
    // even when frames are slow.
    st.wall += Math.min(delta, 0.25);
    const w = st.wall;
    if (st.blinkStart < 0 && w >= st.nextBlink) st.blinkStart = w;
    if (st.blinkStart >= 0) {
      const phase = (w - st.blinkStart) / 0.15;
      d.blink = phase < 1 ? Math.sin(phase * Math.PI) : 0;
      if (phase >= 1) {
        st.blinkStart = -1;
        st.nextBlink = w + (Math.random() < 0.2 ? 0.12 : 2 + Math.random() * 3.5);
      }
    }

    // Hover → jump; tap → springy spin (with a small hop).
    if (m.jumps !== st.jumps) {
      st.jumps = m.jumps;
      if (st.jump <= 0.001) st.jumpVelocity = 3.4;
    }
    if (m.spins !== st.spins) {
      st.spins = m.spins;
      st.spinTarget += Math.PI * 2;
      if (st.jump <= 0.001) st.jumpVelocity = 2.4;
    }
    if (st.jump > 0 || st.jumpVelocity > 0) {
      st.jumpVelocity -= 18 * dt;
      st.jump += st.jumpVelocity * dt;
      if (st.jump <= 0) {
        st.jump = 0;
        st.jumpVelocity = 0;
        st.squashVelocity = -2.6;
      }
    }
    st.squashVelocity += (-160 * st.squash - 12 * st.squashVelocity) * dt;
    st.squash += st.squashVelocity * dt;
    st.spinVelocity += (90 * (st.spinTarget - st.spin) - 11 * st.spinVelocity) * dt;
    st.spin += st.spinVelocity * dt;

    const celebrating = d.pose === "celebrate";
    const hop = celebrating
      ? Math.abs(Math.sin((t / d.celebrateSeconds) * Math.PI * 2)) * 0.2
      : Math.sin(t * 2.2) * 0.035;
    const travel = m.travel;
    st.yaw += (BASE_YAW + lookX * MAX_TURN - st.yaw) * (1 - Math.exp(-6 * dt));
    st.pitch += (lookY * MAX_TURN * 0.6 - st.pitch) * (1 - Math.exp(-6 * dt));

    group.position.y = hop + st.jump;
    group.rotation.set(
      st.pitch,
      st.yaw + st.spin + travel * Math.PI * 2,
      Math.sin(t * 1.2) * 0.03 + Math.sin(travel * Math.PI) * 0.25,
    );
    const squash = clamp(st.squash, -0.2, 0.2);
    group.scale.set(1 - squash * 0.5, 1 + squash, 1 - squash * 0.5);
  });

  return (
    <group position={[-0.06, -0.1, 0]}>
      <group ref={root}>
        {modelUrl ? (
          <Suspense fallback={null}>
            <GltfModel url={modelUrl} />
          </Suspense>
        ) : (
          <CoinModel drive={drive} />
        )}
      </group>
    </group>
  );
}

/** sessionStorage, or undefined where reading it throws (blocked storage). */
function sessionStore(): Storage | undefined {
  try {
    return window.sessionStorage;
  } catch {
    return undefined;
  }
}

/** The hero spot says where he rolls in from (`data-lukas-enter-from`, default right). */
function entranceSide(): 1 | -1 {
  const hero = document.querySelector<HTMLElement>("[data-lukas-spot]");
  return hero?.dataset.lukasEnterFrom === "left" ? -1 : 1;
}

interface SpotBox {
  x: number;
  y: number;
  size: number;
}

/**
 * Lukas in 3D (three.js through React Three Fiber): the procedural coin, or a GLB at `modelUrl`.
 * He bobs, blinks, follows the pointer with his eyes and up to ±12° of body turn (the last touch on
 * touch screens, or the device tilt where the browser allows it without asking), jumps on hover
 * and spins on tap.
 *
 * On a page with Lukas spots (`[data-lukas-spot]`, see `useScrollPose`) he travels with the
 * scroll: he stands on the current section's spot in its pose and, through the end of the
 * section, flies to the next one (spinning like a tossed coin); the layer never takes clicks but
 * his body. Without spots he fills his parent and takes the pose of `mood`.
 *
 * Rendering pauses while he is off screen or the tab is hidden. Callers decide whether to show him
 * at all (reduced motion, WebGL, memory: see `useLukas3DReady`); `<html data-lukas3d="live">` is
 * set once his first frame is on screen, so the 2D Lukas in the spots can step aside.
 */
export function Lukas3D({ mood = "happy", modelUrl }: Lukas3DProps) {
  const layer = useRef<HTMLDivElement>(null);
  const hit = useRef<HTMLDivElement>(null);
  const drive = useRef<CoinDrive>({
    pose: MOOD_POSE[mood],
    lookX: 0,
    lookY: 0,
    blink: 0,
    celebrateSeconds: 1.2,
    limbs: 1,
  });
  const stage = useRef<HTMLDivElement>(null);
  const motion = useRef<Motion>({ pointer: null, tilt: null, travel: 0, jumps: 0, spins: 0 });
  const [inView, setInView] = useState(true);
  const [pageVisible, setPageVisible] = useState(true);

  const place = useCallback(
    ({ spots, index, y }: { spots: LukasSpot[]; index: number; y: number }) => {
      const element = layer.current;
      const parent = element?.offsetParent;
      const current = spots[index];
      if (!element || !parent || !current) return;
      const base = parent.getBoundingClientRect();
      const boxOf = (spot: LukasSpot): SpotBox => {
        const b = spot.element.getBoundingClientRect();
        return {
          x: b.left - base.left + b.width / 2,
          y: b.top - base.top + b.height / 2,
          size: Math.min(b.width, b.height),
        };
      };
      const boxes = spots.map(boxOf);
      const layerSize = Math.max(...boxes.map((b) => b.size));
      const size = `${layerSize}px`;
      if (element.style.width !== size) {
        element.style.width = size;
        element.style.height = size;
      }
      const from = boxes[index] as SpotBox;
      const nextSpot = spots[index + 1];
      const to = boxes[index + 1] ?? from;
      const travel = nextSpot ? smoothstep(TRAVEL_FROM, 1, y) : 0;
      const arc = Math.sin(travel * Math.PI) * Math.max(from.size, to.size) * 0.45;
      const x = lerp(from.x, to.x, travel);
      const top = lerp(from.y, to.y, travel) - arc;
      const scale = lerp(from.size, to.size, travel) / layerSize;
      element.style.transform = `translate3d(${x - layerSize / 2}px, ${top - layerSize / 2}px, 0) scale(${scale})`;

      motion.current.travel = travel;
      const d = drive.current;
      d.pose =
        travel > 0.08 && travel < 0.92
          ? "travel"
          : travel >= 0.92 && nextSpot
            ? nextSpot.pose
            : current.pose;
      // Only his body takes clicks, and only while he stands on a spot.
      if (hit.current) hit.current.style.pointerEvents = travel === 0 ? "" : "none";
    },
    [],
  );
  const scroll = useScrollPose(place);
  // Decided on the first render (this component only renders in the browser), so the canvas is
  // never sized to the whole page for a frame.
  const [traveling] = useState(() => document.querySelector("[data-lukas-spot]") !== null);

  // The entrance plays on the landing once per session, if the hero (the first spot) is in view.
  const [entranceState, setEntranceState] = useState<Entrance["state"]>(() => {
    const hero = document.querySelector<HTMLElement>("[data-lukas-spot]");
    if (!hero) return "none";
    const box = hero.getBoundingClientRect();
    const heroInView = box.bottom > box.height * 0.25 && box.top < window.innerHeight;
    return shouldPlayEntrance(sessionStore(), heroInView) ? "playing" : "skipped";
  });
  const entrance = useRef<Entrance>({
    state: entranceState,
    elapsedMs: 0,
    frames: 0,
    from: entranceSide(),
    onDone: () => setEntranceState("done"),
  });
  useEffect(() => {
    if (entrance.current.state === "playing") markEntranceSeen(sessionStore());
  }, []);

  useEffect(() => {
    if (!traveling) drive.current.pose = MOOD_POSE[mood];
  }, [mood, traveling]);

  useEffect(() => {
    drive.current.celebrateSeconds = durationToken("--celebrate") || 1.2;
    const onPointer = (event: PointerEvent) => {
      motion.current.pointer = {
        x: event.clientX,
        y: event.clientY,
        at: performance.now(),
        touch: event.pointerType !== "mouse",
      };
    };
    // Device tilt steers on phones, but only where it needs no permission prompt (not iOS).
    const onTilt = (event: DeviceOrientationEvent) => {
      if (event.gamma === null || event.beta === null) return;
      motion.current.tilt = { x: clamp(event.gamma / 30), y: clamp((event.beta - 45) / 30) };
    };
    const orientation = globalThis.DeviceOrientationEvent as
      | (typeof DeviceOrientationEvent & { requestPermission?: unknown })
      | undefined;
    const tiltAllowed =
      orientation !== undefined && typeof orientation.requestPermission !== "function";
    const onVisibility = () => setPageVisible(!document.hidden);
    window.addEventListener("pointermove", onPointer, { passive: true });
    window.addEventListener("pointerdown", onPointer, { passive: true });
    if (tiltAllowed) window.addEventListener("deviceorientation", onTilt, { passive: true });
    document.addEventListener("visibilitychange", onVisibility);
    return () => {
      window.removeEventListener("pointermove", onPointer);
      window.removeEventListener("pointerdown", onPointer);
      window.removeEventListener("deviceorientation", onTilt);
      document.removeEventListener("visibilitychange", onVisibility);
    };
  }, []);

  useEffect(() => {
    const element = layer.current;
    if (!element) return;
    const observer = new IntersectionObserver(
      (entries) => setInView(entries.some((entry) => entry.isIntersecting)),
      { rootMargin: "64px" },
    );
    observer.observe(element);
    return () => observer.disconnect();
  }, []);

  useEffect(() => () => document.documentElement.removeAttribute("data-lukas3d"), []);

  // Off screen or in a hidden tab, nothing is drawn (battery).
  const rendering = inView && pageVisible;

  const scene = useMemo(
    () => (
      <>
        <StudioLight />
        <Rig
          drive={drive}
          motion={motion}
          layer={layer}
          stage={stage}
          entrance={entrance}
          modelUrl={modelUrl}
        />
      </>
    ),
    [modelUrl],
  );

  const onCreated = useCallback(() => {
    // The first frame is drawn on the next animation frame: then the 2D Lukas can step aside.
    requestAnimationFrame(() =>
      requestAnimationFrame(() => document.documentElement.setAttribute("data-lukas3d", "live")),
    );
  }, []);

  return (
    <div
      ref={layer}
      className={traveling ? "lk-lukas3d is-traveling" : "lk-lukas3d"}
      data-lukas3d-layer=""
      data-pose={traveling ? (scroll?.pose ?? "wave") : MOOD_POSE[mood]}
      data-rendering={rendering ? "running" : "paused"}
      data-entrance={entranceState}
      aria-hidden="true"
    >
      <div ref={stage} className="lk-lukas3d-stage">
        <Stage
          frameloop={rendering ? "always" : "never"}
          dpr={DPR}
          camera={CAMERA}
          gl={GL}
          onCreated={onCreated}
        >
          {scene}
        </Stage>
        <div
          ref={hit}
          className="lk-lukas3d-hit"
          onPointerEnter={(event) => {
            if (event.pointerType === "mouse") motion.current.jumps += 1;
          }}
          onPointerDown={() => {
            motion.current.spins += 1;
          }}
        />
      </div>
    </div>
  );
}

export default Lukas3D;
