import { animate, motion, useMotionValue, useTransform } from "motion/react";
import {
  createContext,
  type MouseEvent,
  type PointerEvent,
  type ReactNode,
  useCallback,
  useContext,
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import { useTranslations } from "use-intl";
import { feedback } from "../feedback/feedback.ts";
import { cx } from "./cx.ts";
import {
  armedSide,
  gestureOwner,
  lockAxis,
  rowOffset,
  rowRelease,
  SWIPE_ROW_ATTRIBUTE,
  velocityTracker,
} from "./gesture.ts";
import { durationToken, GESTURE, SPRINGS, useReducedMotionPreference } from "./motion-tokens.ts";

export interface SwipeRowProps {
  children: ReactNode;
  /** Swipe left: Borrar. The row slides out and folds away first, then this runs. */
  onDelete?: (() => void) | undefined;
  /** Swipe right: Editar, or Pagado on a pending row. Runs as the row springs back. */
  right?: { kind: "edit" | "paid"; run(): void } | undefined;
  /** Slides in on mount (a row brought back by Deshacer). */
  enter?: boolean | undefined;
}

/** The id of the row's swipe hint, for the row's own button to point `aria-describedby` at. */
const SwipeHintContext = createContext<string | undefined>(undefined);

/** Inside a SwipeRow: the id of the text saying what its swipes do. */
export function useSwipeHint(): string | undefined {
  return useContext(SwipeHintContext);
}

/** Only one row is open at a time: opening one closes this one. */
let closeOpenRow: (() => void) | null = null;

type Side = "left" | "right";

interface Drag {
  pointerId: number;
  x: number;
  y: number;
  start: number;
  width: number;
  axis: "x" | "y" | null;
  tracker: ReturnType<typeof velocityTracker>;
}

/**
 * A row with swipe shortcuts (spec §2.6, founder request 2026-10-22): left reveals a red Borrar,
 * right reveals Editar (Pagado on a pending row). The row follows the finger; let go past 40 % of
 * its width (or flicked) the action runs, a shorter swipe leaves it open (tap it to run it, tap
 * anywhere else or scroll to close). A haptic tick marks the threshold each way. Only one row is
 * open at a time.
 *
 * Swipes are shortcuts only: tapping the row edits (and the edit sheet deletes), the pending badge
 * pays. The row's button describes them (`useSwipeHint`), and closed actions are out of the tab
 * order and hidden from assistive technology. Which gestures are the row's (and not the home
 * pager's) is decided by `gestureOwner` in gesture.ts.
 */
export function SwipeRow({ children, onDelete, right, enter = false }: SwipeRowProps) {
  const t = useTranslations("swipe");
  const reduceMotion = useReducedMotionPreference();
  const root = useRef<HTMLDivElement>(null);
  const x = useMotionValue(0);
  const [open, setOpen] = useState<Side | null>(null);
  const [armed, setArmed] = useState<Side | null>(null);
  const [gone, setGone] = useState(false);
  const drag = useRef<Drag | null>(null);
  const dragged = useRef(false);
  const hintId = useId();
  const left = onDelete !== undefined;
  const hasRight = right !== undefined;

  // Each side shows only while the row is moved its way, so nothing peeks at the corners at rest.
  const leftShown = useTransform(x, (v) => (v < -0.5 ? 1 : 0));
  const rightShown = useTransform(x, (v) => (v > 0.5 ? 1 : 0));

  /**
   * Whether the actions are in the page at all: only while the row is moved, open or on its way
   * back. At rest they are gone, so their words never mix with the row's (search, tests, readers).
   */
  const [revealed, setRevealed] = useState(false);

  const springTo = useCallback(
    (to: number, velocity = 0) => {
      const controls = animate(
        x,
        to,
        reduceMotion ? { duration: 0 } : { ...SPRINGS.row, velocity },
      );
      if (to === 0) {
        controls.then(() => {
          if (x.get() === 0) setRevealed(false);
        });
      }
      return controls;
    },
    [x, reduceMotion],
  );

  const close = useCallback(() => {
    setOpen(null);
    setArmed(null);
    springTo(0);
    if (closeOpenRow === close) closeOpenRow = null;
  }, [springTo]);

  const opened = (side: Side, velocity: number) => {
    if (closeOpenRow && closeOpenRow !== close) closeOpenRow();
    closeOpenRow = close;
    setOpen(side);
    springTo(side === "left" ? -GESTURE.rowActionWidth : GESTURE.rowActionWidth, velocity);
  };

  // Open: a tap anywhere else, or a scroll, closes it.
  useEffect(() => {
    if (!open) return;
    const onDown = (event: globalThis.PointerEvent) => {
      if (root.current && event.target instanceof Node && root.current.contains(event.target)) {
        return;
      }
      close();
    };
    const onScroll = () => close();
    document.addEventListener("pointerdown", onDown, true);
    window.addEventListener("scroll", onScroll, { capture: true, passive: true });
    return () => {
      document.removeEventListener("pointerdown", onDown, true);
      window.removeEventListener("scroll", onScroll, true);
    };
  }, [open, close]);

  useEffect(
    () => () => {
      if (closeOpenRow === close) closeOpenRow = null;
    },
    [close],
  );

  // Brought back by Deshacer: it unfolds and slides in from where it left.
  useLayoutEffect(() => {
    const element = root.current;
    if (!enter || !element) return;
    const height = element.offsetHeight;
    const collapse = durationToken("--collapse");
    if (reduceMotion) {
      animate(element, { opacity: [0, 1] }, { duration: durationToken("--fade") });
      return;
    }
    x.set(-element.offsetWidth);
    animate(element, { height: [0, height], opacity: [0, 1] }, { duration: collapse }).then(() => {
      element.style.height = "";
    });
    animate(x, 0, { ...SPRINGS.rowOut, delay: collapse * 0.5 });
  }, []);

  /** Deletes: the row leaves to the left, folds away (the rows under it slide up), then goes. */
  const remove = async (velocity = 0) => {
    const element = root.current;
    if (!element || !onDelete || gone) return;
    setGone(true);
    if (closeOpenRow === close) closeOpenRow = null;
    const gap = Number.parseFloat(getComputedStyle(element.parentElement ?? element).rowGap) || 0;
    if (reduceMotion) {
      await animate(element, { opacity: 0 }, { duration: durationToken("--fade") });
    } else {
      // Off it goes; the fold starts as it leaves the screen, not after the spring's tail.
      const width = element.offsetWidth;
      await new Promise<void>((resolve) => {
        const stop = x.on("change", (value) => {
          if (value <= -width * GESTURE.rowGoneAt) done();
        });
        function done() {
          stop();
          resolve();
        }
        animate(x, -width, { ...SPRINGS.rowOut, velocity }).then(done);
      });
    }
    await animate(
      element,
      { height: [element.offsetHeight, 0], marginBottom: [0, -gap], opacity: 0 },
      { duration: reduceMotion ? 0 : durationToken("--collapse"), ease: "easeOut" },
    );
    onDelete();
  };

  const runRight = (velocity = 0) => {
    if (!right) return;
    setOpen(null);
    springTo(0, velocity);
    if (closeOpenRow === close) closeOpenRow = null;
    right.run();
  };

  const onPointerDown = (event: PointerEvent<HTMLDivElement>) => {
    // Any new press starts clean: a touch drag is never followed by a click to swallow.
    dragged.current = false;
    if (event.pointerType === "mouse" || gone || !event.isPrimary) return;
    if (gestureOwner(event.target) !== "row") return;
    // A new drag mid-spring carries on from where the row is.
    x.stop();
    const tracker = velocityTracker();
    tracker.add(event.timeStamp, event.clientX);
    drag.current = {
      pointerId: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      start: x.get(),
      width: event.currentTarget.offsetWidth,
      axis: null,
      tracker,
    };
    dragged.current = false;
  };

  const onPointerMove = (event: PointerEvent<HTMLDivElement>) => {
    const current = drag.current;
    if (!current || event.pointerId !== current.pointerId) return;
    const dx = event.clientX - current.x;
    const dy = event.clientY - current.y;
    if (current.axis === null) {
      current.axis = lockAxis(dx, dy, GESTURE.axisSlop);
      if (current.axis === "y") {
        // A scroll: the browser's.
        drag.current = null;
        return;
      }
      if (current.axis === null) return;
      dragged.current = true;
      setRevealed(true);
      if (closeOpenRow && closeOpenRow !== close) closeOpenRow();
      try {
        event.currentTarget.setPointerCapture(event.pointerId);
      } catch {
        // Synthetic pointers (tests) cannot be captured; moves still arrive here.
      }
    }
    current.tracker.add(event.timeStamp, event.clientX);
    const offset = rowOffset({
      start: current.start,
      dx,
      width: current.width,
      factor: GESTURE.rubberBand,
      left,
      right: hasRight,
    });
    x.set(offset);
    const nowArmed = armedSide(offset, current.width, GESTURE.rowThreshold);
    const usable = nowArmed === "left" ? left : nowArmed === "right" ? hasRight : true;
    const next = usable ? nowArmed : null;
    if (next !== armed) {
      setArmed(next);
      feedback("swipeThreshold");
    }
  };

  const release = (event: PointerEvent<HTMLDivElement>, cancelled: boolean) => {
    const current = drag.current;
    if (!current || event.pointerId !== current.pointerId) return;
    drag.current = null;
    if (current.axis !== "x") return;
    // The click a drag may produce comes before any timer: forget the drag after it.
    setTimeout(() => {
      dragged.current = false;
    }, 0);
    const vx = cancelled ? 0 : current.tracker.velocity(event.timeStamp);
    const outcome = rowRelease({
      offset: x.get(),
      vx,
      width: current.width,
      threshold: GESTURE.rowThreshold,
      flick: GESTURE.flickVelocity,
      openWidth: GESTURE.rowActionWidth,
      left,
      right: hasRight,
    });
    setArmed(null);
    if (outcome === "commit-left") void remove(vx);
    else if (outcome === "commit-right") runRight(vx);
    else if (outcome === "open-left" || outcome === "open-right") {
      opened(outcome === "open-left" ? "left" : "right", vx);
    } else close();
  };

  // A drag (or a tap on an open row, which closes it) is never also a tap on the row.
  const onClickCapture = (event: MouseEvent<HTMLDivElement>) => {
    const onAction =
      event.target instanceof Element && event.target.closest(".lk-swipe-action") !== null;
    if (dragged.current || (open && !onAction)) {
      event.preventDefault();
      event.stopPropagation();
      dragged.current = false;
      if (open && !onAction) close();
    }
  };

  const action = (side: Side) => {
    const shown = open === side;
    const label = side === "left" ? t("delete") : right?.kind === "paid" ? t("paid") : t("edit");
    return (
      <motion.div
        aria-hidden={shown ? undefined : true}
        inert={!shown}
        className={cx(
          "lk-swipe-side",
          side === "left" ? "is-left" : right?.kind === "paid" ? "is-right is-paid" : "is-right",
          armed === side && "is-armed",
        )}
        style={{ opacity: side === "left" ? leftShown : rightShown }}
      >
        <button
          type="button"
          tabIndex={shown ? 0 : -1}
          className="lk-swipe-action"
          onClick={() => (side === "left" ? void remove() : runRight())}
        >
          <span aria-hidden="true" className="lk-swipe-glyph">
            {side === "left" ? "🗑" : right?.kind === "paid" ? "✓" : "✎"}
          </span>
          {label}
        </button>
      </motion.div>
    );
  };

  return (
    <div
      ref={root}
      {...{ [SWIPE_ROW_ATTRIBUTE]: "" }}
      className="lk-swipe"
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={(event) => release(event, false)}
      onPointerCancel={(event) => release(event, true)}
      onClickCapture={onClickCapture}
    >
      {revealed && left && action("left")}
      {revealed && hasRight && action("right")}
      <motion.div className="lk-swipe-face" style={{ x }}>
        <SwipeHintContext.Provider value={left || hasRight ? hintId : undefined}>
          {children}
        </SwipeHintContext.Provider>
      </motion.div>
      {(left || hasRight) && (
        <span id={hintId} hidden>
          {right?.kind === "paid" ? t("hint_pending") : t("hint")}
        </span>
      )}
    </div>
  );
}
