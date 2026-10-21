import { useCallback, useEffect, useRef, useState } from "react";
import { cx } from "../ui/cx.ts";
import { markEntranceSeen, shouldPlayEntrance } from "./entrance.ts";
import { LUKAS_ART, Lukas, type LukasMoodArt } from "./Lukas.tsx";
import type { LukasMood } from "./mood.ts";
import { COIN, entranceFrame, spotMood, tiltToward, travelFrame } from "./traveling.ts";
import { type LukasSpot, useScrollPose } from "./use-scroll-pose.ts";
import "./traveling-lukas.css";

/** The entrance's still frame: the first frame of the wave sheet, not playing. */
const TUCKED_ART: LukasMoodArt = { ...LUKAS_ART.happy, play: false, frame: 0 };
/** Mood layers, in a fixed order so React keeps each one's node (and its loaded sheet). */
const MOOD_ORDER: readonly LukasMood[] = ["happy", "worried", "celebrating"];
/** The attribute on `<html>` that makes the prerendered Lukas in the spots step aside. */
const LIVE_ATTRIBUTE = "data-lukas-live";

type EntranceState = "playing" | "skipped" | "done";

/** sessionStorage, or undefined where reading it throws (blocked storage). */
function sessionStore(): Storage | undefined {
  try {
    return window.sessionStorage;
  } catch {
    return undefined;
  }
}

function moodOf(spot: HTMLElement | null | undefined): LukasMood {
  return spotMood(spot?.dataset.lukasPose, spot?.dataset.lukasMood);
}

/** The first spot (the hero) says where he rolls in from (`data-lukas-enter-from`, default right). */
function entranceSide(): 1 | -1 {
  return firstSpot()?.dataset.lukasEnterFrom === "left" ? -1 : 1;
}

function initialEntrance(): EntranceState {
  const hero = firstSpot();
  if (!hero) return "skipped";
  const box = hero.getBoundingClientRect();
  const heroInView = box.bottom > box.height * 0.25 && box.top < window.innerHeight;
  return shouldPlayEntrance(sessionStore(), heroInView) ? "playing" : "skipped";
}

/** The clip that tucks his arms and legs away: a circle around the coin, grown by `reveal`. */
function tuckClip(reveal: number): string {
  if (reveal >= 1) return "";
  const radius = COIN.radius * 100 + (80 - COIN.radius * 100) * Math.max(0, reveal);
  return `circle(${radius.toFixed(2)}% at ${COIN.x * 100}% ${COIN.y * 100}%)`;
}

/**
 * Lukas living on the landing page, in 2.5D: the founder's sprite sheets with CSS depth on top.
 * One sprite in an overlay (absolutely positioned in the page, `aria-hidden`, out of the layout)
 * that stands on the page's Lukas spots (`[data-lukas-spot]`, see `useScrollPose`), in each
 * spot's mood (`data-lukas-mood`, else from `data-lukas-pose`; moods cross-fade). Between spots
 * he turns edge-on like a coin and fades out, then turns back in on the next spot: he never
 * crosses the page, so he never covers text (`travelFrame`).
 *
 * Depth: a soft ground shadow that shrinks as he rises, an idle bob, a hop with squash and
 * stretch on hover or tap (only his body takes the pointer), and, with a fine pointer, a tilt of
 * up to ±12° toward it. Once per session, with the hero in view, he rolls in from the side away
 * from the text, settles, unfolds and waves (`entranceFrame`).
 *
 * Client-only, and mounted after the page's spots are in the DOM: the landing mounts him once the
 * page has loaded and is idle, and only without reduced motion. The prerendered Lukas in the spots
 * steps aside while he is live.
 */
export function TravelingLukas() {
  const layer = useRef<HTMLDivElement>(null);
  const turn = useRef<HTMLDivElement>(null);
  const roller = useRef<HTMLDivElement>(null);
  const body = useRef<HTMLDivElement>(null);
  const tilt = useRef<HTMLDivElement>(null);
  const [mood, setMood] = useState<LukasMood>(() => moodOf(firstSpot()));
  const [mounted, setMounted] = useState<ReadonlySet<LukasMood>>(() => new Set([mood]));
  const [spotId, setSpotId] = useState(() => firstSpot()?.dataset.lukasSpot ?? "");
  const [entrance, setEntrance] = useState<EntranceState>(initialEntrance);
  const [tucked, setTucked] = useState(entrance === "playing");
  const [hopping, setHopping] = useState(false);
  const moving = useRef(false);
  const size = useRef(0);
  // The mood his spot asks for; he shows it once its sheet has loaded (never a blank frame).
  const wanted = useRef(mood);
  const sheets = useRef({ ready: new Set<LukasMood>(), loading: new Set<LukasMood>() });

  /** Loads a mood's sheet once; then mounts its layer and, if his spot wants it, shows it. */
  const load = useCallback((m: LukasMood) => {
    const { ready, loading } = sheets.current;
    if (ready.has(m) || loading.has(m)) return;
    loading.add(m);
    const image = new Image();
    image.src = LUKAS_ART[m].sprite.src;
    const done = () => {
      loading.delete(m);
      ready.add(m);
      setMounted((previous) => (previous.has(m) ? previous : new Set([...previous, m])));
      if (wanted.current === m) setMood(m);
    };
    image.decode().then(done, done);
  }, []);

  const place = useCallback(
    ({ spots, index, y }: { spots: LukasSpot[]; index: number; y: number }) => {
      const element = layer.current;
      const parent = element?.offsetParent;
      const current = spots[index];
      if (!element || !parent || !current) return;
      const base = parent.getBoundingClientRect();
      const boxOf = (spot: LukasSpot) => {
        const b = spot.element.getBoundingClientRect();
        return {
          x: b.left - base.left + b.width / 2,
          y: b.top - base.top + b.height / 2,
          size: Math.min(b.width, b.height),
        };
      };
      // One layer, sized for the biggest spot and scaled down on the others: no relayout.
      const layerSize = Math.max(...spots.map((spot) => boxOf(spot).size));
      if (layerSize !== size.current) {
        size.current = layerSize;
        element.style.width = `${layerSize}px`;
        element.style.height = `${layerSize}px`;
      }
      const next = spots[index + 1];
      const frame = travelFrame(y, next !== undefined);
      const spot = frame.at === "next" && next ? next : current;
      const box = boxOf(spot);
      element.style.transform = `translate3d(${box.x - layerSize / 2}px, ${box.y - layerSize / 2}px, 0) scale(${box.size / layerSize})`;
      if (turn.current) {
        turn.current.style.opacity = frame.opacity === 1 ? "" : frame.opacity.toFixed(3);
        turn.current.style.transform =
          frame.turn === 0 ? "" : `rotateY(${frame.turn.toFixed(2)}deg)`;
      }
      if (moving.current !== frame.moving) {
        moving.current = frame.moving;
        element.toggleAttribute("data-moving", frame.moving);
      }
      setSpotId(spot.id);
      const target = moodOf(spot.element);
      wanted.current = target;
      load(target);
      // Until the spot's sheet has loaded (an anchor jump on a slow link), he keeps his mood.
      if (sheets.current.ready.has(target)) setMood(target);
    },
    [load],
  );
  useScrollPose(place);

  // Every spot's sheet starts loading as soon as he is live (the page has loaded and is idle), so
  // a jump straight to a section (the header's "how it works" link) finds it ready or in flight.
  useEffect(() => {
    for (const spot of document.querySelectorAll<HTMLElement>("[data-lukas-spot]")) {
      load(moodOf(spot));
    }
  }, [load]);

  // He is live: the prerendered Lukas in the spots steps aside (and comes back when he unmounts).
  useEffect(() => {
    const frame = requestAnimationFrame(() =>
      document.documentElement.setAttribute(LIVE_ATTRIBUTE, "live"),
    );
    return () => {
      cancelAnimationFrame(frame);
      document.documentElement.removeAttribute(LIVE_ATTRIBUTE);
    };
  }, []);

  // The entrance: roll in, settle, unfold, wave; driven per frame from the pure `entranceFrame`.
  useEffect(() => {
    if (entrance !== "playing") return;
    markEntranceSeen(sessionStore());
    const from = entranceSide();
    let start = 0;
    let frame = 0;
    const step = (now: number) => {
      if (!start) start = now;
      const f = entranceFrame(now - start, size.current, from);
      const element = roller.current;
      const coin = body.current;
      if (element && coin) {
        element.style.transform = f.x === 0 ? "" : `translateX(${f.x.toFixed(1)}px)`;
        const drop = f.drop * size.current;
        coin.style.transform =
          f.reveal >= 1 && f.scale === 1
            ? ""
            : `translateY(${drop.toFixed(1)}px) rotate(${f.rotate.toFixed(2)}deg) scale(${f.scale.toFixed(3)})`;
        coin.style.clipPath = tuckClip(f.reveal);
      }
      if (!f.still) setTucked(false);
      if (f.phase === "done") {
        setEntrance("done");
        return;
      }
      frame = requestAnimationFrame(step);
    };
    frame = requestAnimationFrame(step);
    return () => cancelAnimationFrame(frame);
  }, [entrance]);

  // With a fine pointer (desktop), he turns toward it, up to ±12°.
  useEffect(() => {
    const fine = window.matchMedia("(pointer: fine)");
    let frame = 0;
    let pointer: { x: number; y: number } | null = null;
    const apply = () => {
      frame = 0;
      const element = tilt.current;
      const box = layer.current?.getBoundingClientRect();
      if (!element || !box) return;
      if (!pointer || !fine.matches) {
        element.style.transform = "";
        return;
      }
      const { rotateX, rotateY } = tiltToward(
        pointer,
        { x: box.left + box.width / 2, y: box.top + box.height * 0.45 },
        { width: window.innerWidth, height: window.innerHeight },
      );
      element.style.transform = `rotateX(${rotateX.toFixed(2)}deg) rotateY(${rotateY.toFixed(2)}deg)`;
    };
    const onMove = (event: PointerEvent) => {
      if (event.pointerType !== "mouse" && event.pointerType !== "pen") return;
      pointer = { x: event.clientX, y: event.clientY };
      if (!frame) frame = requestAnimationFrame(apply);
    };
    const onLeave = () => {
      pointer = null;
      if (!frame) frame = requestAnimationFrame(apply);
    };
    window.addEventListener("pointermove", onMove, { passive: true });
    document.documentElement.addEventListener("pointerleave", onLeave);
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener("pointermove", onMove);
      document.documentElement.removeEventListener("pointerleave", onLeave);
    };
  }, []);

  const hop = () => {
    if (moving.current || entrance === "playing" || hopping) return;
    setHopping(true);
  };

  return (
    <div
      ref={layer}
      className="lk-traveler"
      data-lukas-traveler=""
      data-spot={spotId}
      data-mood={mood}
      data-entrance={entrance}
      aria-hidden="true"
    >
      <div ref={turn} className="lk-traveler-turn">
        <div ref={roller} className="lk-traveler-roller">
          <div className={cx("lk-traveler-shadow", hopping && "is-hopping")} />
          <div ref={tilt} className="lk-traveler-tilt">
            <div className="lk-traveler-bob">
              <div
                className={cx("lk-traveler-hop", hopping && "is-hopping")}
                onAnimationEnd={(event) => {
                  if (event.target === event.currentTarget) setHopping(false);
                }}
              >
                <div ref={body} className="lk-traveler-body">
                  {MOOD_ORDER.filter((m) => mounted.has(m)).map((m) => (
                    <div
                      key={m}
                      className={cx("lk-traveler-mood", m === mood && "is-active")}
                      data-mood={m}
                    >
                      <Lukas
                        mood={m}
                        size="100%"
                        decorative
                        art={m === "happy" && tucked ? TUCKED_ART : undefined}
                      />
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
          <div
            className="lk-traveler-hit"
            onPointerEnter={(event) => {
              if (event.pointerType === "mouse") hop();
            }}
            onPointerDown={hop}
          />
        </div>
      </div>
    </div>
  );
}

/** The first spot in page order (the hero): where he starts, before the first scroll update. */
function firstSpot(): HTMLElement | null {
  return document.querySelector<HTMLElement>("[data-lukas-spot]");
}
