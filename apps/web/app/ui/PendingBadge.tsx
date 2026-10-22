import { useEffect, useRef, useState } from "react";
import { useTranslations } from "use-intl";
import { cx } from "./cx.ts";

export interface PendingBadgeProps {
  /**
   * Marks the transaction paid. Resolving turns the badge into "✓ Pagado"; rejecting puts it
   * back to "Pendiente" (the caller reports the error, e.g. with a toast).
   */
  onPay(): Promise<void>;
  /** Already paid elsewhere (a swipe on the row): shows "✓ Pagado" and is inert. */
  paid?: boolean;
}

type Status = "idle" | "paying" | "paid";

/**
 * "Pendiente" on a scheduled, unpaid transaction, and the button that pays it. The visible pill
 * keeps the design's size; the button around it is a 44px target. While paying it is busy and
 * once paid it is inert, so a transaction is never paid twice from here.
 */
export function PendingBadge({ onPay, paid: paidElsewhere = false }: PendingBadgeProps) {
  const t = useTranslations("common");
  const [status, setStatus] = useState<Status>("idle");
  const mounted = useRef(false);

  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);

  const pay = async () => {
    if (status !== "idle" || paidElsewhere) return;
    setStatus("paying");
    try {
      await onPay();
      if (mounted.current) setStatus("paid");
    } catch {
      if (mounted.current) setStatus("idle");
    }
  };

  const paid = status === "paid" || paidElsewhere;
  return (
    <span aria-live="polite" className="inline-flex">
      <button
        type="button"
        onClick={pay}
        aria-label={paid ? undefined : t("pending_pay_label")}
        aria-disabled={status === "idle" && !paid ? undefined : true}
        aria-busy={status === "paying" ? true : undefined}
        className={cx(
          "group inline-flex min-h-11 min-w-11 items-center justify-center",
          "border-0 bg-transparent p-0 font-text outline-none",
          paid ? "cursor-default" : "cursor-pointer",
        )}
      >
        <span
          className={cx(
            "lk-badge",
            "group-focus-visible:outline-3 group-focus-visible:outline-focus group-focus-visible:outline-offset-2",
            paid
              ? "is-paid"
              : "shadow-[0_2px_0_var(--surface-edge)] transition-[translate,box-shadow] duration-(--press) group-active:translate-y-0.5 group-active:shadow-none",
          )}
        >
          {paid ? (
            <>
              <span aria-hidden="true">✓</span>
              {t("paid")}
            </>
          ) : (
            t("pending")
          )}
        </span>
      </button>
    </span>
  );
}
