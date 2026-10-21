import { useId } from "react";
import { useTranslations } from "use-intl";
import { formatMoney, type Locale, lukasHint } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { cx } from "../../ui/cx.ts";
import { budgetExample, parseBudgetInput } from "./budget-input.ts";
import { StepFrame, type StepNavProps } from "./StepFrame.tsx";

export interface BudgetCategory {
  id: string;
  name: string;
  glyph: string;
  tint: string;
}

export interface BudgetsStepProps extends StepNavProps {
  /** The chosen spending categories. */
  categories: BudgetCategory[];
  /** What is typed per category id; empty or missing means no budget. */
  drafts: Readonly<Record<string, string>>;
  onChange(id: string, text: string): void;
  currency: string;
  /** The amounts came from an import's recent months: say so. */
  prefilled?: boolean;
}

/** A draft read as hundredths: null when empty, `"invalid"` when it is not an amount. */
export function readDraft(text: string | undefined, locale: Locale): number | null | "invalid" {
  try {
    return parseBudgetInput(text ?? "", locale);
  } catch {
    return "invalid";
  }
}

/** The total of the valid drafts, in hundredths. */
export function draftsTotal(
  categories: { id: string }[],
  drafts: Readonly<Record<string, string>>,
  locale: Locale,
): number {
  return categories.reduce((sum, c) => {
    const value = readDraft(drafts[c.id], locale);
    return typeof value === "number" ? sum + value : sum;
  }, 0);
}

/** An amount with the COP lukas hint after it, small and muted (spec §2.6c). */
export function AmountWithHint({
  cents,
  currency,
  className,
  id,
}: {
  cents: number;
  currency: string;
  className?: string;
  id?: string;
}) {
  const { locale } = useLocale();
  const hint = lukasHint(cents, currency, locale);
  return (
    <span id={id} className={className}>
      <span data-budget-amount className="lk-num">
        {formatMoney(cents, currency, locale)}
      </span>
      {hint && (
        <>
          {" "}
          <span className="text-[0.8em] font-bold text-ink-muted">({hint})</span>
        </>
      )}
    </span>
  );
}

/**
 * Step 3: an amount per chosen spending category, typed in the locale's way (`300.000`, `120,50`),
 * with what it comes to under the field and, for COP, the lukas hint. The running total is "what
 * you can spend per month". An empty field means no budget; a field that is not an amount says so
 * and holds Continue back.
 */
export function BudgetsStep({
  categories,
  drafts,
  onChange,
  currency,
  prefilled = false,
  onBack,
  onNext,
}: BudgetsStepProps) {
  const t = useTranslations("onboarding");
  const { locale } = useLocale();
  const invalid = categories.some((c) => readDraft(drafts[c.id], locale) === "invalid");
  const total = draftsTotal(categories, drafts, locale);

  return (
    <StepFrame
      step="budgets"
      title={t("budgets.title")}
      lead={t("budgets.lead")}
      onBack={onBack}
      next={{ label: t("continue"), onClick: onNext, disabled: invalid }}
      summary={
        <div
          role="status"
          className="flex flex-wrap items-baseline justify-between gap-x-(--space-3) border-t-2 border-stroke pt-(--space-3)"
        >
          <span className="text-[15px] text-ink-muted">{t("budgets.total_label")}</span>
          <AmountWithHint
            cents={total}
            currency={currency}
            className="font-display text-[24px] font-bold text-good"
          />
        </div>
      }
    >
      {prefilled && <p className="text-[15px] text-ink-muted">{t("prefill_basis")}</p>}
      <ul className="flex flex-col gap-(--space-2)">
        {categories.map((category) => (
          <BudgetRow
            key={category.id}
            category={category}
            text={drafts[category.id] ?? ""}
            onChange={(text) => onChange(category.id, text)}
            currency={currency}
          />
        ))}
      </ul>
    </StepFrame>
  );
}

function BudgetRow({
  category,
  text,
  onChange,
  currency,
}: {
  category: BudgetCategory;
  text: string;
  onChange(text: string): void;
  currency: string;
}) {
  const t = useTranslations("onboarding");
  const { locale } = useLocale();
  const amountId = useId();
  const errorId = useId();
  const value = readDraft(text, locale);
  const invalid = value === "invalid";

  return (
    <li className="lk-rowcard items-start">
      <span
        className="lk-tile mt-(--space-1)"
        style={{ background: `color-mix(in srgb, ${category.tint} 45%, var(--surface-sunken))` }}
        aria-hidden="true"
      >
        {category.glyph}
      </span>
      <div className="flex min-w-0 flex-1 flex-col gap-(--space-1)">
        <span className="truncate font-display text-[17px] font-bold text-ink">
          {category.name}
        </span>
        <div className={cx("lk-input min-h-11", invalid && "border-over")}>
          <input
            type="text"
            inputMode="decimal"
            autoComplete="off"
            enterKeyHint="next"
            aria-label={t("budgets.amount_label", { category: category.name })}
            aria-invalid={invalid || undefined}
            aria-describedby={invalid ? `${amountId} ${errorId}` : amountId}
            value={text}
            onChange={(event) => onChange(event.target.value)}
            className="lk-num min-h-9 min-w-0 flex-1 border-0 bg-transparent p-0 font-text text-[16px] text-ink outline-none"
          />
        </div>
        <p id={amountId} className="text-[15px] text-ink">
          {typeof value === "number" ? (
            <AmountWithHint cents={value} currency={currency} />
          ) : (
            <span className="text-ink-muted">{t("budgets.none")}</span>
          )}
        </p>
        {invalid && (
          <p id={errorId} className="text-[15px] text-over">
            {t("budgets.invalid", { example: budgetExample(currency, locale) })}
          </p>
        )}
      </div>
    </li>
  );
}
