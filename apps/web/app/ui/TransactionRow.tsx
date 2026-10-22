import { useId } from "react";
import { useTranslations } from "use-intl";
import { formatMoney } from "../i18n/format.ts";
import { useLocale } from "../i18n/IntlProvider.tsx";
import { cx } from "./cx.ts";
import { PendingBadge } from "./PendingBadge.tsx";
import { useSwipeHint } from "./SwipeRow.tsx";

export interface TransactionRowProps {
  /** The transaction's name; blank shows the category name instead. */
  name: string;
  categoryName: string;
  /** The category's emoji. */
  glyph: string;
  /** Signed cents: expenses negative, income positive. */
  amount: number;
  /** ISO 4217 code, e.g. `EUR`. */
  currency: string;
  status: "paid" | "pending";
  /** Opens the edit sheet. */
  onOpen(): void;
  /** Marks a pending transaction paid. Without it a pending row shows a plain label. */
  onPay?(): Promise<void>;
  /**
   * Paid from this row just now: the badge stays (showing "✓ Pagado") although `status` is
   * already `paid`, so the change is seen and announced where it happened.
   */
  paidHere?: boolean;
}

/**
 * One transaction: glyph, name (or its category), category, and the amount (a real minus sign
 * for expenses; `+` in `good` for income). The card opens the editor through one button; a
 * pending row carries its own PendingBadge button, which sits above that hit area.
 */
export function TransactionRow({
  name,
  categoryName,
  glyph,
  amount,
  currency,
  status,
  onOpen,
  onPay,
  paidHere = false,
}: TransactionRowProps) {
  const t = useTranslations("common");
  const { locale } = useLocale();
  const id = useId();
  // Inside a SwipeRow, the row's button also says what its swipes do.
  const swipeHint = useSwipeHint();
  const title = name.trim() || categoryName;
  const income = amount > 0;

  return (
    <div className="lk-rowcard lk-row">
      <button
        type="button"
        className="lk-row-hit"
        aria-labelledby={`${id}-name ${id}-amount ${id}-category`}
        aria-describedby={swipeHint}
        onClick={onOpen}
      />
      <span className="lk-tile" aria-hidden="true">
        {glyph}
      </span>
      <div className="lk-rowmain">
        <div className="lk-rowtop">
          <span id={`${id}-name`} className="truncate">
            {title}
          </span>
          <span id={`${id}-amount`} className={cx("lk-amount", income && "text-good")}>
            {formatMoney(amount, currency, locale, { sign: income ? "always" : "auto" })}
          </span>
        </div>
        <div className="lk-status flex flex-wrap items-center gap-x-(--space-2)">
          <span id={`${id}-category`}>{categoryName}</span>
          {(status === "pending" || (paidHere && onPay)) &&
            (onPay ? (
              <span className="lk-row-control -my-(--space-3)">
                <PendingBadge onPay={onPay} paid={status === "paid"} />
              </span>
            ) : (
              <span className="lk-badge cursor-default">{t("pending")}</span>
            ))}
        </div>
      </div>
    </div>
  );
}
