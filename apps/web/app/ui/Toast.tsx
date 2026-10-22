import { AnimatePresence, motion } from "motion/react";
import {
  createContext,
  type ReactNode,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { createPortal } from "react-dom";
import { cx } from "./cx.ts";
import { durationToken, GESTURE, useReducedMotionPreference } from "./motion-tokens.ts";

export interface ToastAction {
  /** A verb in sentence case: `Deshacer`, `Ponerle nombre`. */
  label: string;
  onClick(): void;
}

export interface ToastOptions {
  /** What changed, with the amount: `Supermercado · −6,08 €`. */
  message: ReactNode;
  actions?: ToastAction[];
  /** `error` is announced assertively and outlined in `over`. */
  tone?: "info" | "error";
}

interface ToastApi {
  show(toast: ToastOptions): void;
}

/** How long a toast without actions stays, unless the pointer or focus is on it. */
const TOAST_MS = 5000;
/** A toast with an action (Deshacer): the `--undo` token (8 s), read when it shows. */
const UNDO_FALLBACK_MS = 8000;

/** How long `toast` stays: `--undo` with actions, 5 s without; a test's override wins. */
function lifetime(toast: ToastOptions, override: number | undefined): number {
  if (override !== undefined) return override;
  if (!toast.actions?.length) return TOAST_MS;
  return Math.round(durationToken("--undo") * 1000) || UNDO_FALLBACK_MS;
}

type Leave = { x?: number; y?: number } | null;

const ToastContext = createContext<ToastApi | null>(null);

/** Lets a modal (the Sheet) host the toasts while it is open: see `useToastHost`. */
const ToastHostContext = createContext<((host: HTMLElement | null) => void) | null>(null);

/**
 * Hosts one toast at a time at the bottom of the screen; a new one replaces the current one (so
 * only the latest action can be undone). A toast with an action (Deshacer) stays 8 seconds (the
 * `--undo` token), one without 5; a thin bar shows the time left. The countdown stops while the
 * toast is hovered, touched or focused, and resumes where it was. Toasts also leave when an action
 * is taken, or when swiped down or sideways. Info toasts live in a polite `status` region, errors
 * in an `alert` region.
 *
 * While a modal sheet is open, a toast shows inside it (`useToastHost`): outside an
 * `aria-modal` dialog it would be hidden from assistive technology and out of the dialog's focus
 * trap. The (empty) regions stay on the page otherwise, and the toast moves back when it closes.
 */
export function ToastProvider({
  children,
  dismissAfterMs,
}: {
  children: ReactNode;
  /** Shortened only by tests (for every toast). */
  dismissAfterMs?: number;
}) {
  const [toast, setToast] = useState<(ToastOptions & { id: number; ms: number }) | null>(null);
  const [paused, setPaused] = useState(false);
  const [leave, setLeave] = useState<Leave>(null);
  /** The time left of a toast's countdown (by its id), kept across pauses. */
  const remaining = useRef({ id: 0, ms: 0 });
  const [mounted, setMounted] = useState(false);
  const [host, setHost] = useState<HTMLElement | null>(null);
  const nextId = useRef(0);
  const reduceMotion = useReducedMotionPreference();

  useEffect(() => setMounted(true), []);

  const show = useCallback(
    (options: ToastOptions) => {
      nextId.current += 1;
      const ms = lifetime(options, dismissAfterMs);
      remaining.current = { id: nextId.current, ms };
      setLeave(null);
      setToast({ ...options, id: nextId.current, ms });
      // The replaced toast may never get its pointer-leave or blur; the new one starts unpaused.
      setPaused(false);
    },
    [dismissAfterMs],
  );
  const dismiss = useCallback(() => {
    setToast(null);
    setPaused(false);
  }, []);

  // Counts down what is left; a pause keeps the rest for when it resumes.
  useEffect(() => {
    if (!toast || paused) return;
    const started = Date.now();
    const timer = setTimeout(dismiss, remaining.current.ms);
    return () => {
      clearTimeout(timer);
      const left = remaining.current;
      if (left.id === toast.id) left.ms = Math.max(0, left.ms - (Date.now() - started));
    };
  }, [toast, paused, dismiss]);

  const api = useMemo(() => ({ show }), [show]);
  // Inside an open modal only while there is a toast: empty regions stay out of the dialog.
  const inSheet = host !== null && toast !== null;

  const render = (tone: "info" | "error") => {
    const current = toast && (toast.tone ?? "info") === tone ? toast : null;
    const offset = reduceMotion ? {} : { y: 16 };
    // Swiped away: it leaves the way it was thrown (a fade only, under reduced motion).
    const away = (to: Leave) => ({
      opacity: 0,
      ...(reduceMotion ? {} : to ? { x: to.x ?? 0, y: to.y ?? 0 } : offset),
    });
    return (
      <AnimatePresence mode="wait" custom={leave}>
        {current && (
          <motion.div
            key={current.id}
            className={cx(
              "lk-toast pointer-events-auto",
              current.tone === "error" && "border-2 border-over",
            )}
            custom={leave}
            variants={{ gone: away }}
            initial={{ opacity: 0, ...offset }}
            animate={{ opacity: 1, x: 0, y: 0 }}
            exit="gone"
            transition={{ duration: durationToken("--sheet") }}
            drag
            dragSnapToOrigin
            dragElastic={{ top: 0.1, bottom: 0.8, left: 0.8, right: 0.8 }}
            dragConstraints={{ top: 0, bottom: 0, left: 0, right: 0 }}
            onDragEnd={(_, info) => {
              const far = GESTURE.toastDismiss;
              const fast = GESTURE.flickVelocity;
              const down = info.offset.y > far || info.velocity.y > fast;
              const side =
                Math.abs(info.offset.x) > far || Math.abs(info.velocity.x) > fast
                  ? Math.sign(info.offset.x || info.velocity.x)
                  : 0;
              if (!down && side === 0) return;
              setLeave(side !== 0 ? { x: side * 360 } : { y: 120 });
              dismiss();
            }}
            onPointerEnter={() => setPaused(true)}
            onPointerLeave={() => setPaused(false)}
            onPointerDown={() => setPaused(true)}
            onPointerUp={(event) => {
              if (event.pointerType !== "mouse") setPaused(false);
            }}
            onFocus={() => setPaused(true)}
            onBlur={() => setPaused(false)}
          >
            <span
              aria-hidden="true"
              className="lk-toast-progress"
              style={{
                animationDuration: `${current.ms}ms`,
                animationPlayState: paused ? "paused" : "running",
              }}
            />
            <span className="min-w-0 flex-1">{current.message}</span>
            {current.actions?.length ? (
              <span className="lk-toast-actions">
                {current.actions.map((action) => (
                  <button
                    key={action.label}
                    type="button"
                    className="min-h-11 px-(--space-1)"
                    onClick={() => {
                      // Dismiss first: an action may show a follow-up toast, which must win.
                      dismiss();
                      action.onClick();
                    }}
                  >
                    {action.label}
                  </button>
                ))}
              </span>
            ) : null}
          </motion.div>
        )}
      </AnimatePresence>
    );
  };

  return (
    <ToastContext.Provider value={api}>
      <ToastHostContext.Provider value={setHost}>{children}</ToastHostContext.Provider>
      {mounted &&
        createPortal(
          <div
            className={cx(
              "pointer-events-none flex flex-col items-center",
              inSheet
                ? "pt-(--space-2)"
                : "fixed inset-x-0 bottom-0 z-50 px-(--space-4) pb-[calc(max(var(--space-4),env(safe-area-inset-bottom))+var(--toast-lift,0px))]",
            )}
          >
            {/* Lukitas celebrates clear of the toasts (Celebration.tsx). */}
            <div role="status" data-celebration-avoid="" className="w-full max-w-[480px]">
              {render("info")}
            </div>
            <div role="alert" data-celebration-avoid="" className="w-full max-w-[480px]">
              {render("error")}
            </div>
          </div>,
          inSheet ? host : document.body,
        )}
    </ToastContext.Provider>
  );
}

export function useToast(): ToastApi {
  const value = useContext(ToastContext);
  if (!value) throw new Error("useToast must be used inside <ToastProvider>");
  return value;
}

/**
 * For a modal: returns a setter to call with the element the toasts should render in while the
 * modal is open (and with null when it closes). Null outside a `ToastProvider`.
 */
export function useToastHost(): ((host: HTMLElement | null) => void) | null {
  return useContext(ToastHostContext);
}
