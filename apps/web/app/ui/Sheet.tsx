import { AnimatePresence, motion, useDragControls } from "motion/react";
import {
  type KeyboardEvent,
  type PointerEvent,
  type ReactNode,
  useEffect,
  useId,
  useRef,
  useState,
} from "react";
import { createPortal } from "react-dom";
import { useTranslations } from "use-intl";
import { durationToken, useReducedMotionPreference } from "./motion-tokens.ts";
import { PressButton } from "./PressButton.tsx";
import { useToastHost } from "./Toast.tsx";

export interface SheetProps {
  open: boolean;
  onClose(): void;
  /** Names the dialog; shown in the sheet's header. */
  title: string;
  children?: ReactNode;
}

const FOCUSABLE =
  'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

/** Dragging the sheet down further than this (px), or flicking it faster (px/s), closes it. */
const CLOSE_OFFSET = 96;
const CLOSE_VELOCITY = 600;
/** iOS-like deceleration for the sheet's slide. */
const SHEET_EASE = [0.32, 0.72, 0, 1] as const;

function focusables(root: HTMLElement): HTMLElement[] {
  return [...root.querySelectorAll<HTMLElement>(FOCUSABLE)].filter(
    (element) => element.getClientRects().length > 0,
  );
}

/**
 * A bottom sheet (`lk-sheet`) over a dimmed backdrop: a modal dialog named by `title`. Opening
 * moves focus into it and Tab stays inside; Escape, the close button, the backdrop and dragging
 * the header down all call `onClose`. Focus returns to whatever had it before. Slides over
 * `--sheet`; under reduced motion it only fades. While open it hosts the toasts (`useToastHost`).
 */
export function Sheet({ open, onClose, title, children }: SheetProps) {
  const t = useTranslations("common");
  const reduceMotion = useReducedMotionPreference();
  const titleId = useId();
  const panel = useRef<HTMLDivElement>(null);
  const dragControls = useDragControls();
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

  const startDrag = (event: PointerEvent<HTMLDivElement>) => {
    if (event.target instanceof Element && event.target.closest("button")) return;
    dragControls.start(event);
  };

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
          <motion.div
            ref={panel}
            role="dialog"
            aria-modal="true"
            aria-labelledby={titleId}
            tabIndex={-1}
            onKeyDown={trapTab}
            className="lk-sheet relative max-h-[90dvh] w-full max-w-[480px] overflow-y-auto pb-[max(var(--space-4),env(safe-area-inset-bottom))] outline-none"
            initial={hidden}
            animate={shown}
            exit={hidden}
            transition={{ duration, ease: SHEET_EASE }}
            drag={reduceMotion ? false : "y"}
            dragListener={false}
            dragControls={dragControls}
            dragConstraints={{ top: 0, bottom: 0 }}
            dragElastic={{ top: 0, bottom: 0.7 }}
            onDragEnd={(_, info) => {
              if (info.offset.y > CLOSE_OFFSET || info.velocity.y > CLOSE_VELOCITY) onClose();
            }}
          >
            <div className="cursor-grab touch-none select-none" onPointerDown={startDrag}>
              <div className="lk-grab" aria-hidden="true" />
              <div className="flex items-center justify-between gap-(--space-2)">
                <h2 id={titleId} className="m-0 font-display text-[24px] leading-[1.15] font-bold">
                  {title}
                </h2>
                <PressButton variant="ghost" size="sm" onClick={onClose}>
                  {t("close")}
                </PressButton>
              </div>
            </div>
            {children}
            <div ref={setToastSlot} className="sticky bottom-0 z-10" />
          </motion.div>
        </div>
      )}
    </AnimatePresence>,
    document.body,
  );
}
