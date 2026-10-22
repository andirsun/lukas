import type { Month } from "@lukas/core";
import { useCallback, useId, useState } from "react";
import { useTranslations } from "use-intl";
import { ApiProblem, problemMessage, type Translator } from "../../api/errors.ts";
import { useSetBudget } from "../../api/queries.ts";
import { formatMoney, lukasHint, monthInSentence } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { AmountField } from "../../ui/AmountField.tsx";
import { amountCents, keypadText } from "../../ui/keypad-input.ts";
import { PressButton } from "../../ui/PressButton.tsx";
import { Sheet } from "../../ui/Sheet.tsx";
import { useToast } from "../../ui/Toast.tsx";

export interface BudgetSheetProps {
  open: boolean;
  onClose(): void;
  category: { id: string; name: string };
  /** The month on screen: the budget applies from it on. */
  month: Month;
  /** The budget in force that month, in hundredths (the keypad starts from it). */
  budget: number | null;
  currency: string;
}

/**
 * A category's budget (`PUT /v1/categories/:id/budget`), from the month on screen on: the amount on
 * the shared keypad (a keyboard and a paste type too; pesos take no decimals, with the lukas
 * hint). A minus sign, typed or pasted, is refused and never sent: a budget is never negative.
 * Mount it with a new `key` each time it opens, so it starts from `budget`.
 */
export function BudgetSheet({
  open,
  onClose,
  category,
  month,
  budget,
  currency,
}: BudgetSheetProps) {
  const t = useTranslations("categories.budget_sheet");
  const tRoot = useTranslations() as unknown as Translator;
  const { locale } = useLocale();
  const toast = useToast();
  const setBudget = useSetBudget();
  const errorId = useId();
  const [raw, setRawState] = useState(() =>
    budget === null || budget === 0 ? "" : keypadText(budget, locale, currency),
  );
  const [error, setError] = useState<string | null>(null);

  const setRaw = useCallback((next: string) => {
    setRawState(next);
    setError(null);
  }, []);
  const onNegative = useCallback(() => setError(t("negative")), [t]);

  const save = async () => {
    if (setBudget.isPending) return;
    const amount = amountCents(raw, { locale, currency });
    if (amount <= 0) {
      setError(t("zero"));
      return;
    }
    try {
      await setBudget.mutateAsync({ id: category.id, amount, effectiveFrom: month });
    } catch (problem) {
      setError(
        problem instanceof ApiProblem ? problemMessage(problem, tRoot) : tRoot("errors.generic"),
      );
      return;
    }
    onClose();
    const money = formatMoney(amount, currency, locale);
    const hint = lukasHint(amount, currency, locale);
    toast.show({
      message: t("saved", { name: category.name, amount: hint ? `${money} (${hint})` : money }),
    });
  };

  return (
    <Sheet open={open} onClose={onClose} title={t("title", { name: category.name })}>
      <form
        noValidate
        className="flex flex-col gap-(--space-2) pt-(--space-2)"
        aria-describedby={error ? errorId : undefined}
        onSubmit={(event) => {
          event.preventDefault();
          void save();
        }}
      >
        <p className="m-0 text-center text-[14px] font-bold text-ink-muted">
          {t("from_month", { month: monthInSentence(month, locale) })}
        </p>
        <AmountField
          active={open}
          raw={raw}
          setRaw={setRaw}
          currency={currency}
          onNegative={onNegative}
          testId="budget-amount"
          invalid={error !== null}
        />
        {error && (
          <p id={errorId} role="alert" className="m-0 text-center text-[15px] font-bold text-over">
            {error}
          </p>
        )}
        <div className="lk-sheet-footer flex">
          <PressButton
            type="submit"
            className="flex-1"
            disabled={setBudget.isPending}
            aria-busy={setBudget.isPending}
          >
            {t("save")}
          </PressButton>
        </div>
      </form>
    </Sheet>
  );
}
