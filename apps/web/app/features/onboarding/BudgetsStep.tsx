import { useId, useLayoutEffect, useRef } from "react";
import { useTranslations } from "use-intl";
import { formatMoney, type Locale, lukasHint } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { cx } from "../../ui/cx.ts";
import { budgetExample, formatBudgetTyping, parseBudgetInput } from "./budget-input.ts";
import { StepError, StepFrame, type StepNavProps, useStepActions } from "./StepFrame.tsx";

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
  /** Where prefilled amounts came from ("Basado en lo que gastaste en tus últimos 3 meses"). */
  prefillBasis?: string | null;
  error?: string | null;
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
  hintShownElsewhere = false,
}: {
  cents: number;
  currency: string;
  className?: string;
  id?: string;
  /** The hint already shows beside the field: here it is only read out, not shown twice. */
  hintShownElsewhere?: boolean;
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
          <span
            className={hintShownElsewhere ? "sr-only" : "text-[0.8em] font-bold text-ink-muted"}
          >
            ({hint})
          </span>
        </>
      )}
    </span>
  );
}

/**
 * The last step: an amount per chosen spending category, typed in the locale's way (`300.000`,
 * `120,50`), with what it comes to under the field and, for COP, the lukas hint. The running total
 * is "what you can spend per month". An empty field means no budget; a field that is not an amount
 * says so and holds SIGUIENTE back (SALTAR still finishes, without budgets).
 */
export function BudgetsStep({
  categories,
  drafts,
  onChange,
  currency,
  prefillBasis,
  error,
  ...nav
}: BudgetsStepProps) {
  const t = useTranslations("onboarding");
  const { locale } = useLocale();
  const actions = useStepActions(nav);
  const invalid = categories.some((c) => readDraft(drafts[c.id], locale) === "invalid");
  const total = draftsTotal(categories, drafts, locale);

  return (
    <StepFrame
      step="budgets"
      title={t("budgets.title")}
      lead={t("budgets.lead")}
      onBack={nav.onBack}
      skip={actions.skip}
      next={{ ...actions.next, disabled: actions.next.disabled || invalid }}
      summary={<BudgetsTotal total={total} currency={currency} />}
    >
      {prefillBasis && <p className="text-[15px] text-ink-muted">{prefillBasis}</p>}
      <BudgetsList
        categories={categories}
        drafts={drafts}
        onChange={onChange}
        currency={currency}
      />
      {error && <StepError>{error}</StepError>}
    </StepFrame>
  );
}

/** "Lo que puedes gastar al mes": the running total, read out as it changes. */
export function BudgetsTotal({ total, currency }: { total: number; currency: string }) {
  const t = useTranslations("onboarding");
  return (
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
  );
}

/** One budget field per spending category (shared by the step and the app's import page). */
export function BudgetsList({
  categories,
  drafts,
  onChange,
  currency,
}: Pick<BudgetsStepProps, "categories" | "drafts" | "onChange" | "currency">) {
  const t = useTranslations("onboarding");
  return (
    <>
      {categories.length === 0 && <p className="text-ink-muted">{t("budgets.empty")}</p>}
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
    </>
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
  const hint = typeof value === "number" ? lukasHint(value, currency, locale) : null;
  const input = useRef<HTMLInputElement>(null);
  /** Where the cursor goes once the formatted text is in the field. */
  const caret = useRef<number | null>(null);

  // Grouped as typed ("300000" → "300.000"), the cursor staying after the same digit.
  useLayoutEffect(() => {
    const at = caret.current;
    caret.current = null;
    if (at !== null && input.current && document.activeElement === input.current) {
      input.current.setSelectionRange(at, at);
    }
  }, [text]);

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
            ref={input}
            value={text}
            onChange={(event) => {
              const typed = event.target.value;
              const next = formatBudgetTyping(typed, event.target.selectionStart ?? typed.length, {
                locale,
                currency,
              });
              caret.current = next.caret;
              onChange(next.text);
            }}
            className="lk-num min-h-9 min-w-0 flex-1 border-0 bg-transparent p-0 font-text text-[16px] text-ink outline-none"
          />
          {hint && (
            <span aria-hidden="true" className="flex-none text-[14px] font-bold text-ink-muted">
              ({hint})
            </span>
          )}
        </div>
        <p id={amountId} className="text-[15px] text-ink">
          {typeof value === "number" ? (
            <AmountWithHint cents={value} currency={currency} hintShownElsewhere />
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
