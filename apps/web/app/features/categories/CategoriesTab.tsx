import type { CategoryDto, CategoryKind, MonthSummary } from "@lukas/core";
import { useState } from "react";
import { useNavigate } from "react-router";
import { useTranslations } from "use-intl";
import { CategoryRow } from "../../ui/CategoryRow.tsx";
import { categoryLook } from "../../ui/category-look.ts";
import { PressButton } from "../../ui/PressButton.tsx";
import { SegmentedControl } from "../../ui/SegmentedControl.tsx";
import { useAppPath } from "../home/app-path.ts";
import type { DetailState } from "./CategoryDetail.tsx";
import { useCategorySheets } from "./use-category-sheets.tsx";

export interface CategoriesTabProps {
  /** The month on screen; its lines carry each spending category's budget and spend. */
  summary: MonthSummary | undefined;
  /** Every category, archived ones too. */
  categories: CategoryDto[] | undefined;
  currency: string;
  month: string;
}

/** What a spending category with no line in the summary (just created) shows: nothing yet. */
const NO_LINE = { budget: null, spent: 0, remaining: null, state: "ok" } as const;

/**
 * Home's Categorías tab: where categories are managed (founder decision 2026-10-24; there is no
 * separate page). A Gastos | Ingresos switch; one row per category of that kind, opening its
 * detail (a spending category with its month's budget bar, an income one with "Ingreso"); "Nueva
 * categoría"; and the archived ones of that kind folded at the end, each with "Restaurar". Renaming,
 * the icon and colour, and archiving are in the detail.
 */
export function CategoriesTab({ summary, categories, currency, month }: CategoriesTabProps) {
  const t = useTranslations("categories");
  const tHome = useTranslations("home");
  const navigate = useNavigate();
  const appPath = useAppPath();
  const sheets = useCategorySheets();
  const [kind, setKind] = useState<CategoryKind>("expense");
  const [showArchived, setShowArchived] = useState(false);
  if (!summary || !categories) return <div className="min-h-[120px]" aria-busy="true" />;

  const lines = new Map(summary.categories.map((line) => [line.categoryId, line]));
  const ofKind = categories
    .filter((c) => c.kind === kind)
    .sort((a, b) => a.sortOrder - b.sortOrder);
  const active = ofKind.filter((c) => !c.archived);
  const archived = ofKind.filter((c) => c.archived);
  // Its detail, in the month on screen, and back to this tab from it.
  const open = (category: CategoryDto) => {
    const state: DetailState = { from: "categories" };
    navigate(appPath(`/categories/${category.id}?month=${month}`), { state });
  };

  return (
    <>
      <div className="flex flex-wrap items-center gap-(--space-2)">
        <div className="min-w-[200px] flex-1">
          <SegmentedControl<CategoryKind>
            label={t("kind_label")}
            value={kind}
            options={[
              { value: "expense", label: t("expenses") },
              { value: "income", label: t("income") },
            ]}
            onChange={setKind}
          />
        </div>
        <PressButton size="sm" onClick={sheets.startCreate}>
          <span aria-hidden="true">＋</span>
          {t("add")}
        </PressButton>
      </div>
      {active.length === 0 ? (
        <p className="m-0 text-[14px] font-bold text-ink-muted">
          {kind === "expense" ? tHome("no_expense_categories") : t("none_of_kind")}
        </p>
      ) : (
        active.map((category) => {
          const look = categoryLook(category);
          const line = lines.get(category.id) ?? NO_LINE;
          return (
            <CategoryRow
              key={category.id}
              name={category.name}
              glyph={look.glyph}
              tint={look.tint}
              budget={line.budget}
              spent={line.spent}
              remaining={line.remaining}
              state={line.state}
              currency={currency}
              {...(kind === "income" ? { line: t("income_line") } : {})}
              onOpen={() => open(category)}
            />
          );
        })
      )}
      {archived.length > 0 && (
        <div className="flex flex-col gap-(--space-2)">
          <PressButton
            variant="secondary"
            className="self-start"
            aria-expanded={showArchived}
            onClick={() => setShowArchived((shown) => !shown)}
          >
            <span aria-hidden="true">{showArchived ? "▾" : "▸"}</span>
            {t("archived_fold", { count: archived.length })}
          </PressButton>
          {showArchived && (
            <section aria-label={t("archived_title")} className="flex flex-col gap-(--space-2)">
              {archived.map((category) => {
                const look = categoryLook(category);
                return (
                  <CategoryRow
                    key={category.id}
                    name={category.name}
                    glyph={look.glyph}
                    tint={look.tint}
                    budget={null}
                    spent={0}
                    remaining={null}
                    state="ok"
                    currency={currency}
                    line={t("archived_line")}
                    onOpen={() => open(category)}
                    control={
                      <PressButton
                        variant="secondary"
                        size="sm"
                        aria-label={t("restore_named", { name: category.name })}
                        onClick={() => void sheets.restore(category)}
                      >
                        {t("restore")}
                      </PressButton>
                    }
                  />
                );
              })}
            </section>
          )}
        </div>
      )}
      {sheets.sheets}
    </>
  );
}
