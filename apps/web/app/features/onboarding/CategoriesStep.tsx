import type { CategoryKind } from "@lukas/core";
import { type ReactNode, useId, useState } from "react";
import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { CategoryChip } from "../../ui/CategoryChip.tsx";
import { PressButton } from "../../ui/PressButton.tsx";
import { AddCategorySheet, type NewCategory } from "./AddCategorySheet.tsx";
import { StepError, StepFrame, type StepNavProps, useStepActions } from "./StepFrame.tsx";
import { SUGGESTED_CATEGORIES } from "./suggested-categories.ts";

/** A category the person made themselves (or an import brought), shown next to the suggestions. */
export interface CustomCategory {
  id: string;
  name: string;
  glyph: string;
  kind: CategoryKind;
}

export interface CategoriesStepProps extends StepNavProps {
  /** Suggestion keys and custom category ids that are chosen. */
  selected: ReadonlySet<string>;
  onToggle(keyOrId: string): void;
  custom: CustomCategory[];
  onCreate(category: NewCategory): Promise<void>;
  errorText(problem: unknown): string;
  error?: string | null;
}

/**
 * The categories: the suggestions come pre-selected (SIGUIENTE works with no input, tapping one
 * deselects it), the person's own ones beside them, spending apart from income, and
 * "＋ Agregar categoría" to make a new one.
 */
export function CategoriesStep({
  selected,
  onToggle,
  custom,
  onCreate,
  errorText,
  error,
  ...nav
}: CategoriesStepProps) {
  const t = useTranslations("onboarding");
  const { locale } = useLocale();
  const { skip, next } = useStepActions(nav);
  const [adding, setAdding] = useState(false);

  const group = (kind: CategoryKind, label: string) => (
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
      {custom
        .filter((c) => c.kind === kind)
        .map((c) => (
          <CategoryChip
            key={c.id}
            glyph={c.glyph}
            label={c.name}
            selected={selected.has(c.id)}
            onSelect={() => onToggle(c.id)}
          />
        ))}
    </ChipGroup>
  );

  return (
    <StepFrame
      step="categories"
      title={t("categories.title")}
      lead={t("categories.lead")}
      onBack={nav.onBack}
      skip={skip}
      next={next}
    >
      {group("expense", t("categories.expenses"))}
      {group("income", t("categories.income"))}
      <PressButton variant="secondary" className="w-full" onClick={() => setAdding(true)}>
        <span aria-hidden="true">＋</span>
        {t("categories.add")}
      </PressButton>
      {error && <StepError>{error}</StepError>}
      <AddCategorySheet
        open={adding}
        onClose={() => setAdding(false)}
        onSave={onCreate}
        errorText={errorText}
      />
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
