import { AnimatePresence, animate, motion, useMotionValue } from "motion/react";
import { type KeyboardEvent, type ReactNode, useEffect, useId, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { useTranslations } from "use-intl";
import { feedback } from "../feedback/feedback.ts";
import { cx } from "./cx.ts";
import { rubberBand } from "./gesture.ts";
import { durationToken, GESTURE, SPRINGS, useReducedMotionPreference } from "./motion-tokens.ts";
import { PressButton } from "./PressButton.tsx";
import { useToastHost } from "./Toast.tsx";
import { useAxisDrag } from "./use-axis-drag.ts";

export interface SheetProps {
  open: boolean;
  onClose(): void;
  /** Names the dialog; shown in the sheet's header. */
  title: string;
  children?: ReactNode;
  /**
   * Pinned under the content, always in view (the add sheet's keypad and Guardar): the content
   * scrolls between the header and it. Without it the whole sheet scrolls.
   */
  footer?: ReactNode;
}

const FOCUSABLE =
  'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

/** iOS-like deceleration for the sheet's slide. */
const SHEET_EASE = [0.32, 0.72, 0, 1] as const;

/**
 * Whether a touch at `target` may drag the sheet down: not while it is inside an area scrolled
 * away from its top (that area scrolls back first, as on iOS), the sheet itself included.
 */
function atTop(target: EventTarget | null, panel: HTMLElement): boolean {
  let element = target instanceof Element ? target : null;
  while (element && panel.contains(element)) {
    if (element.scrollTop > 0 && element.scrollHeight > element.clientHeight) return false;
    if (element === panel) break;
    element = element.parentElement;
  }
  return true;
}

/** Whether an area under `target` (the sheet included) has more to scroll down to. */
function canScrollDown(target: EventTarget | null, panel: HTMLElement): boolean {
  let element = target instanceof Element ? target : null;
  while (element && panel.contains(element)) {
    if (element.scrollHeight - element.clientHeight - element.scrollTop > 1) {
      const overflow = getComputedStyle(element).overflowY;
      if (overflow === "auto" || overflow === "scroll") return true;
    }
    if (element === panel) break;
    element = element.parentElement;
  }
  return false;
}

function focusables(root: HTMLElement): HTMLElement[] {
  return [...root.querySelectorAll<HTMLElement>(FOCUSABLE)].filter(
    (element) => element.getClientRects().length > 0,
  );
}

/**
 * A bottom sheet (`lk-sheet`) over a dimmed backdrop: a modal dialog named by `title`. Opening
 * moves focus into it and Tab stays inside; Escape, the close button, the backdrop and dragging
 * it down from anywhere all call `onClose` (the same path as Cerrar). The drag follows the finger
 * (resisting upward); let go past `GESTURE.sheetCloseAt` of its height, or flicked down, it
 * closes, otherwise it springs back. Taps stay taps, sideways swipes stay sideways, an inner area
 * scrolled away from its top scrolls back first, and a key a drag starts on never types. Focus returns to whatever had it before. Slides over
 * `--sheet`; under reduced motion it only fades. While open it hosts the toasts (`useToastHost`).
 */
export function Sheet({ open, onClose, title, children, footer }: SheetProps) {
  const t = useTranslations("common");
  const reduceMotion = useReducedMotionPreference();
  const titleId = useId();
  const panel = useRef<HTMLDivElement>(null);
  /** How far the sheet is dragged down from where it rests, in px. */
  const dragY = useMotionValue(0);
  /** Where the drag started (for the scroll guard) and the sheet's height; null: no drag. */
  const dragFrom = useRef<{ x: number; y: number; offset: number; height: number } | null>(null);
  const armed = useRef(false);
  /** What the touch started on. */
  const target = useRef<EventTarget | null>(null);
  const [mounted, setMounted] = useState(false);
  const onCloseRef = useRef(onClose);
  onCloseRef.current = onClose;
  const setToastHost = useToastHost();
  const [toastSlot, setToastSlot] = useState<HTMLDivElement | null>(null);

  // While open, toasts render inside the dialog (announced, and reachable in its focus trap).
  useEffect(() => {
    if (!open || !toastSlot || !setToastHost) return;
    setToastHost(toastSlot);
    return () => setToastHost(null);
  }, [open, toastSlot, setToastHost]);

  useEffect(() => setMounted(true), []);

  useEffect(() => {
    if (!open || !mounted) return;
    // A sheet closed by a drag opens again where it rests.
    dragY.set(0);
    const opener = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    const { overflow } = document.body.style;
    document.body.style.overflow = "hidden";
    panel.current?.focus();
    const onKey = (event: globalThis.KeyboardEvent) => {
      if (event.key !== "Escape") return;
      event.preventDefault();
      onCloseRef.current();
    };
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = overflow;
      opener?.focus();
    };
  }, [open, mounted]);

  const trapTab = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key !== "Tab" || !panel.current) return;
    const items = focusables(panel.current);
    const first = items[0];
    const last = items.at(-1);
    if (!first || !last) {
      event.preventDefault();
      return;
    }
    const active = document.activeElement;
    if (event.shiftKey && (active === first || active === panel.current)) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && active === last) {
      event.preventDefault();
      first.focus();
    }
  };

  const springBack = () => {
    dragFrom.current = null;
    if (dragY.get() !== 0) {
      animate(dragY, 0, reduceMotion ? { duration: 0 } : SPRINGS.sheetBack);
    }
  };
  const gesture = useAxisDrag(
    {
      axis: "y",
      accept: (target) => panel.current !== null && atTop(target, panel.current),
      // The mouse drags by the grab bar and the title only (it selects text elsewhere).
      mouse: (target) => target instanceof Element && target.closest("[data-sheet-grab]") !== null,
    },
    {
      onStart(event) {
        // A touch catches a sheet springing back where it is.
        dragY.stop();
        dragFrom.current = {
          x: event.clientX,
          y: event.clientY,
          offset: dragY.get(),
          height: panel.current?.offsetHeight ?? 1,
        };
        armed.current = false;
        target.current = event.target;
        return true;
      },
      // Upward, where the content under the finger can scroll, it scrolls: the sheet stays.
      onLock(delta) {
        if (delta < 0 && panel.current && canScrollDown(target.current, panel.current)) {
          dragFrom.current = null;
          return false;
        }
        return true;
      },
      onMove(delta) {
        const from = dragFrom.current;
        if (!from) return;
        const offset = rubberBand(
          from.offset + delta,
          0,
          Number.POSITIVE_INFINITY,
          GESTURE.rubberBand,
        );
        if (!reduceMotion) dragY.set(offset);
        const past = offset >= from.height * GESTURE.sheetCloseAt;
        if (past !== armed.current) {
          armed.current = past;
          feedback("swipeThreshold");
        }
      },
      onRelease(delta, velocity, cancelled) {
        const from = dragFrom.current;
        dragFrom.current = null;
        if (!from) return;
        const offset = from.offset + delta;
        const closing =
          !cancelled &&
          (offset >= from.height * GESTURE.sheetCloseAt ||
            (velocity >= GESTURE.flickVelocity && offset > 0));
        if (closing) onCloseRef.current();
        else springBack();
      },
      onSettle: springBack,
    },
  );

  // While the touch may still become a drag down (and once it is one), the browser must not take
  // it for a scroll of the sheet: its pointer events would stop. Sideways moves stay native.
  useEffect(() => {
    const element = panel.current;
    if (!open || !mounted || !element) return;
    const onTouchMove = (event: TouchEvent) => {
      const from = dragFrom.current;
      const touch = event.touches[0];
      if (!from || !touch || !event.cancelable) return;
      if (gesture.locked()) {
        event.preventDefault();
        return;
      }
      if (!gesture.active()) return;
      const dx = touch.clientX - from.x;
      const dy = touch.clientY - from.y;
      if (dy > 0 && dy >= Math.abs(dx)) event.preventDefault();
    };
    element.addEventListener("touchmove", onTouchMove, { passive: false });
    return () => element.removeEventListener("touchmove", onTouchMove);
  }, [open, mounted]);

  if (!mounted) return null;

  const duration = durationToken("--sheet");
  const hidden = reduceMotion ? { opacity: 0 } : { y: "100%" };
  const shown = reduceMotion ? { opacity: 1 } : { y: 0 };

  return createPortal(
    <AnimatePresence>
      {open && (
        <div key="sheet" className="fixed inset-0 z-40 flex items-end justify-center">
          <motion.div
            data-sheet-backdrop=""
            aria-hidden="true"
            className="absolute inset-0 bg-(--scrim)"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration }}
            onClick={onClose}
          />
          {/* Carries the drag; the dialog inside carries the slide in and out. */}
          <motion.div
            data-sheet-drag=""
            className="relative flex w-full max-w-[480px] justify-center"
            style={{ y: dragY }}
          >
            <motion.div
              ref={panel}
              role="dialog"
              aria-modal="true"
              aria-labelledby={titleId}
              tabIndex={-1}
              onKeyDown={trapTab}
              className={cx(
                "lk-sheet relative max-h-[90dvh] w-full max-w-[480px] pb-[max(var(--space-4),env(safe-area-inset-bottom))] outline-none",
                footer ? "has-footer" : "overflow-y-auto",
              )}
              initial={hidden}
              animate={shown}
              exit={hidden}
              transition={{ duration, ease: SHEET_EASE }}
              onPointerDown={gesture.onPointerDown}
              onPointerMove={gesture.onPointerMove}
              onPointerUp={gesture.onPointerUp}
              onPointerCancel={gesture.onPointerCancel}
              // A drag that started on a key (or a chip) never also presses it.
              onClickCapture={(event) => void gesture.swallowClick(event)}
            >
              <div data-sheet-grab="" className="cursor-grab touch-none select-none">
                <div className="lk-grab" aria-hidden="true" />
                <div className="flex items-center justify-between gap-(--space-2)">
                  <h2
                    id={titleId}
                    className="m-0 font-display text-[24px] leading-[1.15] font-bold"
                  >
                    {title}
                  </h2>
                  <PressButton variant="ghost" size="sm" onClick={onClose}>
                    {t("close")}
                  </PressButton>
                </div>
              </div>
              {footer ? (
                <>
                  <div className="lk-sheet-body">
                    {children}
                    <div ref={setToastSlot} className="sticky bottom-0 z-10" />
                  </div>
                  {footer}
                </>
              ) : (
                <>
                  {children}
                  <div ref={setToastSlot} className="sticky bottom-0 z-10" />
                </>
              )}
            </motion.div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>,
    document.body,
  );
}
