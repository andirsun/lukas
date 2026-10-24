import { animate, type MotionValue, motion, useMotionValue, useTransform } from "motion/react";
import {
  Children,
  type CSSProperties,
  type MouseEvent,
  type PointerEvent,
  type ReactNode,
  useEffect,
  useRef,
  useState,
} from "react";
import { feedback } from "../feedback/feedback.ts";
import { gestureOwner, pagerTarget, rubberBand } from "./gesture.ts";
import { durationToken, GESTURE, SPRINGS, useReducedMotionPreference } from "./motion-tokens.ts";
import { useAxisDrag } from "./use-axis-drag.ts";

export interface PagerOptions {
  /** The page shown (and remembered by the caller). */
  index: number;
  count: number;
  onIndexChange(index: number): void;
  /** Off (wide screens, where the pages sit side by side): no gestures. */
  enabled?: boolean;
}

export interface Pager {
  /**
   * Where the track is, in pages (0 = the first page, 0.5 = halfway to the second). It follows
   * the finger while dragging and springs to `index` after; the tabs' thumb follows it.
   */
  position: MotionValue<number>;
  /** Spread on the element whose sideways drags turn the pages (it may hold more than the track). */
  surface: {
    onPointerDown(event: PointerEvent<HTMLElement>): void;
    onPointerMove(event: PointerEvent<HTMLElement>): void;
    onPointerUp(event: PointerEvent<HTMLElement>): void;
    onPointerCancel(event: PointerEvent<HTMLElement>): void;
    onClickCapture(event: MouseEvent<HTMLElement>): void;
    style: CSSProperties;
  };
  index: number;
  /** Nothing is moving: the pages that are not shown are hidden (and out of reach). */
  settled: boolean;
  /** The track, measured for the drag's width (one page). */
  frame: React.RefObject<HTMLDivElement | null>;
  /** The page elements, for the reduced-motion cross-fade. */
  pages: React.RefObject<(HTMLDivElement | null)[]>;
}

/**
 * Pages that follow the finger (home's Movimientos ⇄ Categorías, spec §2.5): the content tracks
 * a sideways drag 1:1, resists past the first and last page (0.3×), and on release springs to the
 * nearer page, or one page on in a flick's direction. A drag picks its axis after a few pixels:
 * mostly down is the page's scroll, untouched. A drag that starts on a swipeable row is the row's
 * (`gestureOwner`). A light vibration marks each page change; a tap on the tabs slides the same
 * way. A new drag mid-spring carries on from where the track is. Under reduced motion nothing
 * follows the finger: on release the page switches with a short cross-fade.
 */
export function usePager({ index, count, onIndexChange, enabled = true }: PagerOptions): Pager {
  const reduceMotion = useReducedMotionPreference();
  const position = useMotionValue(index);
  const [settled, setSettled] = useState(true);
  const frame = useRef<HTMLDivElement>(null);
  const pages = useRef<(HTMLDivElement | null)[]>([]);
  /** The velocity (pages/s) a release hands to the spring that follows its page change. */
  const handoff = useRef(0);
  const shown = useRef(index);

  const settle = (target: number, velocity: number) => {
    setSettled(false);
    if (reduceMotion) {
      position.set(target);
      const page = pages.current[target];
      if (page && target !== shown.current) {
        animate(page, { opacity: [0, 1] }, { duration: durationToken("--fade") });
      }
      shown.current = target;
      setSettled(true);
      return;
    }
    shown.current = target;
    animate(position, target, { ...SPRINGS.pager, velocity }).then(() => {
      if (position.get() === target) setSettled(true);
    });
  };

  // The page changed (a release, a tap on the tabs, the keyboard): slide there, with a tick.
  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    feedback("pageChange");
    const velocity = handoff.current;
    handoff.current = 0;
    settle(index, velocity);
  }, [index]);

  /** The drag under way: where the track was (in pages, maybe mid-spring) and one page's px. */
  const from = useRef({ position: 0, width: 1 });
  const gesture = useAxisDrag(
    { accept: (target) => gestureOwner(target) === "pager", enabled },
    {
      onStart() {
        const page = frame.current?.offsetWidth ?? 0;
        if (page === 0) return false;
        // A touch catches the track where it is (mid-spring too); onSettle or a release moves on.
        position.stop();
        // One page further along is a page and the gap between two.
        from.current = { position: position.get(), width: page + GESTURE.pagerGap };
        return true;
      },
      onLock() {
        setSettled(false);
        return true;
      },
      onMove(dx) {
        if (reduceMotion) return;
        const { position: start, width } = from.current;
        position.set(rubberBand(start - dx / width, 0, count - 1, GESTURE.rubberBand));
      },
      onRelease(dx, vx, cancelled) {
        const { position: start, width } = from.current;
        const base = Math.round(start);
        const target = cancelled
          ? index
          : pagerTarget({
              index: base,
              // Measured from the page it started nearest to, so a catch mid-spring counts right.
              dx: dx + (start - base) * -width,
              vx,
              width,
              count,
              flick: GESTURE.flickVelocity,
            });
        const max = GESTURE.pagerMaxVelocity;
        const velocity = Math.max(-max, Math.min(max, -vx / width));
        if (target !== index) {
          handoff.current = velocity;
          onIndexChange(target);
        } else {
          settle(index, velocity);
        }
      },
      // A tap, a scroll or a cancel caught the track: it goes on to the page shown.
      onSettle() {
        if (position.get() !== index) settle(index, 0);
      },
    },
  );

  return {
    position,
    index,
    settled,
    frame,
    pages,
    surface: {
      onPointerDown: gesture.onPointerDown,
      onPointerMove: gesture.onPointerMove,
      onPointerUp: gesture.onPointerUp,
      onPointerCancel: gesture.onPointerCancel,
      onClickCapture: (event) => void gesture.swallowClick(event),
      // Vertical scrolling and zoom stay the browser's; sideways drags are ours.
      style: enabled ? { touchAction: "pan-y pinch-zoom" } : {},
    },
  };
}

/**
 * The pages of a `usePager`, side by side on a track that moves with `position`. The shown page is
 * in the flow (the pager takes its height); the others sit beside it, hidden once nothing moves.
 */
export function PagerTrack({ pager, children }: { pager: Pager; children: ReactNode }) {
  const gap = GESTURE.pagerGap;
  const x = useTransform(pager.position, (p) => `calc(${-p * 100}% - ${p * gap}px)`);
  const pages = Children.toArray(children);
  return (
    <div className="lk-pager">
      <motion.div ref={pager.frame} data-pager-track="" className="lk-pager-track" style={{ x }}>
        {pages.map((page, i) => {
          const shown = i === pager.index;
          const hidden = !shown && pager.settled;
          return (
            <div
              key={i}
              ref={(node) => {
                pager.pages.current[i] = node;
              }}
              className="lk-pager-page"
              inert={hidden}
              style={{
                position: shown ? "relative" : "absolute",
                left: `calc(${i * 100}% + ${i * gap}px)`,
                visibility: hidden ? "hidden" : undefined,
              }}
            >
              {page}
            </div>
          );
        })}
      </motion.div>
    </div>
  );
}
