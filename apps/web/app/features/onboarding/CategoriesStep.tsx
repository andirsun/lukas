import { type ReactNode, useId } from "react";
import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { CategoryChip } from "../../ui/CategoryChip.tsx";
import { StepFrame, type StepNavProps } from "./StepFrame.tsx";
import { SUGGESTED_CATEGORIES, type SuggestedCategory } from "./suggested-categories.ts";

export interface CategoriesStepProps extends StepNavProps {
  /** Keys of the chosen suggestions. */
  selected: ReadonlySet<string>;
  onToggle(key: string): void;
  busy?: boolean;
  error?: string | null;
}

/** True when the choice has at least one spending category (income alone has nothing to budget). */
export function hasExpense(selected: ReadonlySet<string>): boolean {
  return SUGGESTED_CATEGORIES.some((c) => c.kind === "expense" && selected.has(c.key));
}

/**
 * Step 2: the suggested categories as toggles, spending apart from income. Continue needs at least
 * one spending category; until then a line says so.
 */
export function CategoriesStep({
  selected,
  onToggle,
  busy = false,
  error,
  onBack,
  onNext,
}: CategoriesStepProps) {
  const t = useTranslations("onboarding");
  const { locale } = useLocale();
  const hintId = useId();
  const ready = hasExpense(selected);

  const group = (kind: SuggestedCategory["kind"], label: string) => (
    <ChipGroup label={label}>
      {SUGGESTED_CATEGORIES.filter((c) => c.kind === kind).map((c) => (
        <CategoryChip
          key={c.key}
          glyph={c.glyph}
          label={c.names[locale]}
          selected={selected.has(c.key)}
          onSelect={() => onToggle(c.key)}
        />
      ))}
    </ChipGroup>
  );

  return (
    <StepFrame
      step="categories"
      title={t("categories.title")}
      lead={t("categories.lead")}
      onBack={onBack}
      next={{
        label: busy ? t("saving") : t("continue"),
        onClick: onNext,
        disabled: !ready || busy,
        describedBy: ready ? undefined : hintId,
      }}
    >
      {group("expense", t("categories.expenses"))}
      {group("income", t("categories.income"))}
      {!ready && (
        <p id={hintId} className="text-[15px] text-ink-muted">
          {t("categories.need_expense")}
        </p>
      )}
      {error && (
        <p role="alert" className="text-[15px] text-over">
          {error}
        </p>
      )}
    </StepFrame>
  );
}

function ChipGroup({ label, children }: { label: string; children: ReactNode }) {
  const id = useId();
  return (
    <div role="group" aria-labelledby={id} className="flex flex-col gap-(--space-2)">
      <h2 id={id} className="font-display text-[18px] font-bold text-ink">
        {label}
      </h2>
      <div className="lk-chips">{children}</div>
    </div>
  );
}
