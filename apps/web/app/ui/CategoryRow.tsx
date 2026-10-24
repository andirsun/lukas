import { type ReactNode, useId } from "react";
import { useTranslations } from "use-intl";
import { formatMoney } from "../i18n/format.ts";
import { useLocale } from "../i18n/IntlProvider.tsx";
import { BudgetBar } from "./BudgetBar.tsx";
import { cx } from "./cx.ts";

export interface CategoryRowProps {
  name: string;
  /** A short muted word after the name, e.g. "archivada". Part of the row's name. */
  note?: string;
  /** Emoji shown in the tile. */
  glyph: string;
  /** The category's color; the tile mixes it into the sunken surface so it reads in both themes. */
  tint: string;
  /** Cents budgeted this month, or `null` without a budget. */
  budget: number | null;
  /** Cents spent this month. */
  spent: number;
  /** Cents left (negative when over), or `null` without a budget. */
  remaining: number | null;
  /** From the month summary; never recomputed here. */
  state: "ok" | "near" | "over";
  /** ISO 4217 code, e.g. `EUR`. */
  currency: string;
  /** Opens the category detail. */
  onOpen(): void;
  /**
   * A plain line instead of the budget's status, bar and figures: an income category ("Ingreso")
   * or an archived one ("Archivada"). The budget figures are then ignored.
   */
  line?: string | undefined;
  /** A button of its own at the row's end (an archived category's "Restaurar"). */
  control?: ReactNode;
}

/**
 * One category in the budget list: tinted glyph tile, name and budget, the status in words
 * (`Quedan 46,33 €` / `Te pasaste 14,12 €` / `Sin presupuesto`) and a small bar. Status is never
 * color alone. The whole card opens the detail through one button named by the name and status.
 */
export function CategoryRow({
  name,
  note,
  glyph,
  tint,
  budget,
  spent,
  remaining,
  state,
  currency,
  onOpen,
  line,
  control,
}: CategoryRowProps) {
  const t = useTranslations("category_row");
  const { locale } = useLocale();
  const id = useId();
  const money = (cents: number) => formatMoney(cents, currency, locale);

  const budgeted = line === undefined ? budget : null;
  const hasBudget = budgeted !== null;
  const status =
    line !== undefined
      ? line
      : budgeted === null
        ? t("no_budget")
        : state === "over"
          ? t("over", { amount: money(Math.abs(remaining ?? budgeted - spent)) })
          : t("remaining", { amount: money(remaining ?? budgeted - spent) });

  return (
    <div className="lk-rowcard lk-row">
      <button
        type="button"
        className="lk-row-hit"
        aria-labelledby={`${id}-name ${id}-status`}
        onClick={onOpen}
      />
      <span
        className="lk-tile"
        style={{ background: `color-mix(in srgb, ${tint} 45%, var(--surface-sunken))` }}
        aria-hidden="true"
      >
        {glyph}
      </span>
      <div className="lk-rowmain">
        <div className="lk-rowtop">
          <span id={`${id}-name`} className="truncate">
            {name}
            {note && " "}
            {note && <span className="font-bold text-ink-muted">· {note}</span>}
          </span>
          {budgeted !== null && <span className="lk-num">{money(budgeted)}</span>}
        </div>
        <div className="lk-status flex flex-wrap gap-x-(--space-2)">
          <span
            id={`${id}-status`}
            className={cx(
              "lk-status",
              hasBudget && state === "near" && "is-near",
              hasBudget && state === "over" && "is-over",
            )}
          >
            {status}
          </span>
          {!hasBudget && line === undefined && spent !== 0 && (
            <span>{t("spent", { amount: money(spent) })}</span>
          )}
        </div>
        {budgeted !== null && (
          <BudgetBar
            spent={spent}
            budget={budgeted}
            state={state}
            size="sm"
            label={t("meter", { name, status })}
          />
        )}
      </div>
      {control && <span className="lk-row-control">{control}</span>}
    </div>
  );
}
