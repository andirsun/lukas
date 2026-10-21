import { AnimatePresence, motion, useReducedMotion } from "motion/react";
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
import { durationToken } from "./motion-tokens.ts";

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

/** How long a toast stays, unless the pointer or focus is on it. */
const TOAST_MS = 5000;

const ToastContext = createContext<ToastApi | null>(null);

/**
 * Hosts one toast at a time at the bottom of the screen; a new one replaces the current one.
 * Toasts leave after 5 seconds (paused while hovered or focused) or when an action is taken.
 * Info toasts live in a polite `status` region, errors in an `alert` region.
 */
export function ToastProvider({ children }: { children: ReactNode }) {
  const [toast, setToast] = useState<(ToastOptions & { id: number }) | null>(null);
  const [paused, setPaused] = useState(false);
  const [mounted, setMounted] = useState(false);
  const nextId = useRef(0);
  const reduceMotion = useReducedMotion() ?? false;

  useEffect(() => setMounted(true), []);

  const show = useCallback((options: ToastOptions) => {
    nextId.current += 1;
    setToast({ ...options, id: nextId.current });
  }, []);
  const dismiss = useCallback(() => {
    setToast(null);
    setPaused(false);
  }, []);

  useEffect(() => {
    if (!toast || paused) return;
    const timer = setTimeout(dismiss, TOAST_MS);
    return () => clearTimeout(timer);
  }, [toast, paused, dismiss]);

  const api = useMemo(() => ({ show }), [show]);

  const render = (tone: "info" | "error") => {
    const current = toast && (toast.tone ?? "info") === tone ? toast : null;
    const offset = reduceMotion ? {} : { y: 16 };
    return (
      <AnimatePresence mode="wait">
        {current && (
          <motion.div
            key={current.id}
            className={cx(
              "lk-toast pointer-events-auto",
              current.tone === "error" && "border-2 border-over",
            )}
            initial={{ opacity: 0, ...offset }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, ...offset }}
            transition={{ duration: durationToken("--sheet") }}
            onPointerEnter={() => setPaused(true)}
            onPointerLeave={() => setPaused(false)}
            onFocus={() => setPaused(true)}
            onBlur={() => setPaused(false)}
          >
            <span className="min-w-0 flex-1">{current.message}</span>
            {current.actions?.length ? (
              <span className="lk-toast-actions">
                {current.actions.map((action) => (
                  <button
                    key={action.label}
                    type="button"
                    className="min-h-11 px-(--space-1)"
                    onClick={() => {
                      action.onClick();
                      dismiss();
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
      {children}
      {mounted &&
        createPortal(
          <div className="pointer-events-none fixed inset-x-0 bottom-0 z-50 flex flex-col items-center px-(--space-4) pb-[max(var(--space-4),env(safe-area-inset-bottom))]">
            <div role="status" className="w-full max-w-[480px]">
              {render("info")}
            </div>
            <div role="alert" className="w-full max-w-[480px]">
              {render("error")}
            </div>
          </div>,
          document.body,
        )}
    </ToastContext.Provider>
  );
}

export function useToast(): ToastApi {
  const value = useContext(ToastContext);
  if (!value) throw new Error("useToast must be used inside <ToastProvider>");
  return value;
}
