import type { CategoryDto } from "@lukas/core";
import { type ReactNode, useId, useState } from "react";
import { Link } from "react-router";
import { useTranslations } from "use-intl";
import { useAllCategories, useMe } from "../../api/queries.ts";
import { formatMoney } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { categoryLook } from "../../ui/category-look.ts";
import { LukasBubble } from "../../ui/LukasBubble.tsx";
import { PageHeader } from "../../ui/PageHeader.tsx";
import { PressButton } from "../../ui/PressButton.tsx";
import { type DetailState, ManageFrame } from "./CategoryDetail.tsx";
import { useCategorySheets } from "./use-category-sheets.tsx";

/**
 * The categories page (`/app/categories`, spec §2.7): spending and income, each row leading to
 * its detail and with its own "Editar"; "Nueva categoría"; and the archived ones behind a toggle,
 * each with "Restaurar". Archiving is done from the edit sheet, after asking.
 */
export function CategoriesPage() {
  const t = useTranslations("categories");
  const tManage = useTranslations("manage");
  const me = useMe().data;
  if (!me) throw new Error("CategoriesPage renders inside AppShell, which waits for the profile");
  const categories = useAllCategories();
  const sheets = useCategorySheets();
  const [showArchived, setShowArchived] = useState(false);
  if (categories.error && !categories.data) throw categories.error;

  const all = categories.data;
  const active = all?.filter((c) => !c.archived) ?? [];
  const archived = all?.filter((c) => c.archived) ?? [];
  const row = (category: CategoryDto) => (
    <CategoryItem
      key={category.id}
      category={category}
      currency={me.currency}
      onEdit={() => sheets.startEdit(category)}
      onRestore={category.archived ? () => void sheets.restore(category) : undefined}
    />
  );

  return (
    <ManageFrame busy={!all}>
      <PageHeader back={{ to: "/app", label: tManage("back"), short: tManage("back_short") }} />
      <main className="flex flex-col gap-(--space-4)">
        <div className="flex flex-wrap items-center justify-between gap-(--space-2)">
          <h1 className="m-0 font-display text-[28px] font-bold text-ink">{t("title")}</h1>
          <PressButton onClick={sheets.startCreate}>
            <span aria-hidden="true">＋</span>
            {t("add")}
          </PressButton>
        </div>
        {all && active.length === 0 ? (
          <LukasBubble message={t("empty")} mood="happy" />
        ) : (
          <p className="m-0 text-[14px] font-bold text-ink-muted">{t("lead")}</p>
        )}
        {all && active.length > 0 && (
          <>
            <Group title={t("expenses")}>
              {active.filter((c) => c.kind === "expense").map(row)}
            </Group>
            <Group title={t("income")}>{active.filter((c) => c.kind === "income").map(row)}</Group>
          </>
        )}
        {all && (
          <div className="flex flex-col gap-(--space-2)">
            <PressButton
              variant="secondary"
              className="self-start"
              aria-pressed={showArchived}
              onClick={() => setShowArchived((shown) => !shown)}
            >
              <span aria-hidden="true">{showArchived ? "▾" : "▸"}</span>
              {t("show_archived")}
            </PressButton>
            {showArchived && (
              <Group title={t("archived_title")} empty={t("archived_none")}>
                {archived.map(row)}
              </Group>
            )}
          </div>
        )}
      </main>
      {sheets.sheets}
    </ManageFrame>
  );
}

function Group({
  title,
  empty,
  children,
}: {
  title: string;
  empty?: string;
  children: ReactNode[];
}) {
  const t = useTranslations("categories");
  const titleId = useId();
  return (
    <section aria-labelledby={titleId} className="flex flex-col gap-(--space-2)">
      <h2 id={titleId} className="lk-overline m-0">
        {title}
      </h2>
      {children.length > 0 ? (
        children
      ) : (
        <p className="m-0 text-[14px] font-bold text-ink-muted">{empty ?? t("none_of_kind")}</p>
      )}
    </section>
  );
}

/**
 * One category: its tile, name and this month's budget (or "Ingreso"); the row leads to its detail,
 * and its own buttons edit it or, when archived, bring it back.
 */
function CategoryItem({
  category,
  currency,
  onEdit,
  onRestore,
}: {
  category: CategoryDto;
  currency: string;
  onEdit(): void;
  onRestore?: (() => void) | undefined;
}) {
  const t = useTranslations("categories");
  const { locale } = useLocale();
  const id = useId();
  const look = categoryLook(category);
  const line =
    category.kind === "income"
      ? t("income_line")
      : category.currentBudget === null
        ? t("no_budget")
        : t("budget", { amount: formatMoney(category.currentBudget, currency, locale) });
  const state: DetailState = { from: "categories" };

  return (
    <div className="lk-rowcard lk-row">
      <Link
        to={`/app/categories/${category.id}`}
        state={state}
        className="lk-row-hit"
        aria-labelledby={`${id}-name ${id}-line`}
      />
      <span
        className="lk-tile"
        style={{ background: `color-mix(in srgb, ${look.tint} 45%, var(--surface-sunken))` }}
        aria-hidden="true"
      >
        {look.glyph}
      </span>
      <div className="lk-rowmain">
        <span id={`${id}-name`} className="truncate font-bold text-ink">
          {category.name}
        </span>
        <span id={`${id}-line`} className="lk-status">
          {line}
        </span>
      </div>
      <span className="lk-row-control flex gap-(--space-1)">
        {onRestore && (
          <PressButton
            variant="secondary"
            size="sm"
            aria-label={t("restore_named", { name: category.name })}
            onClick={onRestore}
          >
            {t("restore")}
          </PressButton>
        )}
        <PressButton
          variant="ghost"
          size="sm"
          aria-label={t("edit_named", { name: category.name })}
          onClick={onEdit}
        >
          <span aria-hidden="true">✎</span>
        </PressButton>
      </span>
    </div>
  );
}
