import {
  type CategoryDto,
  type Month,
  type MonthSummary,
  monthOf,
  type TransactionDto,
  todayIn,
} from "@lukas/core";
import { type ReactNode, useId, useState } from "react";
import { useLocation, useParams, useSearchParams } from "react-router";
import { useTranslations } from "use-intl";
import {
  useAllCategories,
  useCategoryTransactions,
  useMe,
  useReportByCategory,
  useSummary,
} from "../../api/queries.ts";
import { formatMoney, monthInSentence } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { BudgetBar } from "../../ui/BudgetBar.tsx";
import { categoryLook } from "../../ui/category-look.ts";
import { cx } from "../../ui/cx.ts";
import { MonthPicker } from "../../ui/MonthPicker.tsx";
import { PageHeader } from "../../ui/PageHeader.tsx";
import { PressButton } from "../../ui/PressButton.tsx";
import { PressLink } from "../../ui/PressLink.tsx";
import { useTransactionSheet } from "../add-transaction/TransactionSheetProvider.tsx";
import { useAppPath } from "../home/app-path.ts";
import { Day, type MorePages, ShowMore } from "../home/Home.tsx";
import { groupByDay } from "../home/home-model.ts";
import { SHOW_CATEGORIES } from "../home/home-storage.ts";
import { BudgetSheet } from "./BudgetSheet.tsx";
import { useCategorySheets } from "./use-category-sheets.tsx";

const MONTH_PATTERN = /^\d{4}-(0[1-9]|1[0-2])$/;

/** Where the detail was opened from: home's Categorías tab passes `{ from: "categories" }`. */
export interface DetailState {
  from?: "categories";
}

/** The width and gutters of the screens under the app shell that are not home. */
export function ManageFrame({ children, busy = false }: { children: ReactNode; busy?: boolean }) {
  return (
    <div
      className="mx-auto flex w-full max-w-[480px] flex-col gap-(--space-3) px-(--space-4) pt-(--space-3) lg:max-w-[720px] lg:px-(--space-6) lg:pt-(--space-5)"
      aria-busy={busy || undefined}
    >
      {children}
    </div>
  );
}

/** Back to where the detail came from: home's Categorías tab, or home as it was. */
function useBack() {
  const t = useTranslations("manage");
  const state = useLocation().state as DetailState | null;
  const appPath = useAppPath();
  return state?.from === "categories"
    ? {
        to: appPath(),
        state: SHOW_CATEGORIES,
        label: t("back_categories"),
        short: t("back_categories_short"),
      }
    : { to: appPath(), label: t("back"), short: t("back_short") };
}

/**
 * A category's detail (`/app/categories/:id`, spec §2.7): the month on screen (`?month=`, home's
 * month when opened from a category's row; never past the current one), the budget in force that
 * month with an edit that applies from it on, and its transactions that month (each opens the edit
 * sheet). "Editar" changes the name, emoji and tint, and archives it after asking; an archived one
 * says so and can be restored. Along with home's Categorías tab, this is where categories are
 * managed.
 */
export function CategoryDetail() {
  const me = useMe().data;
  if (!me) throw new Error("CategoryDetail renders inside AppShell, which waits for the profile");
  const { id = "" } = useParams();
  const [params, setParams] = useSearchParams();
  const back = useBack();
  const categories = useAllCategories();
  const today = todayIn(me.timezone);
  const current = monthOf(today);
  const asked = params.get("month") ?? "";
  const month: Month = MONTH_PATTERN.test(asked) && asked <= current ? asked : current;

  if (categories.error && !categories.data) throw categories.error;
  const category = categories.data?.find((c) => c.id === id);
  const picker = (
    <MonthPicker
      month={month}
      max={current}
      onChange={(next) => setParams({ month: next }, { replace: true })}
    />
  );

  if (!categories.data) {
    return (
      <ManageFrame busy>
        <PageHeader back={back} aside={picker} />
        <div className="lk-hero min-h-[140px]" />
      </ManageFrame>
    );
  }
  if (!category) {
    return (
      <ManageFrame>
        <PageHeader back={back} />
        <NotFound />
      </ManageFrame>
    );
  }
  return (
    <ManageFrame>
      <PageHeader back={back} aside={picker} />
      <DetailView
        key={category.id}
        category={category}
        month={month}
        today={today}
        currency={me.currency}
      />
    </ManageFrame>
  );
}

function NotFound() {
  const t = useTranslations("categories.detail");
  const appPath = useAppPath();
  return (
    <main className="lk-hero flex flex-col gap-(--space-2)">
      <h1 className="m-0 font-display text-[22px] font-bold text-ink">{t("not_found_title")}</h1>
      <p className="m-0 text-[14px] font-bold text-ink-muted">{t("not_found_lead")}</p>
      <PressLink to={appPath()} state={SHOW_CATEGORIES} className="self-start">
        {t("to_categories")}
      </PressLink>
    </main>
  );
}

interface DetailViewProps {
  category: CategoryDto;
  month: Month;
  today: string;
  currency: string;
}

function DetailView({ category, month, today, currency }: DetailViewProps) {
  const t = useTranslations("categories.detail");
  const tCategories = useTranslations("categories");
  const summary = useSummary(month);
  const transactions = useCategoryTransactions(month, category.id);
  const sheets = useCategorySheets();
  const [budgetSheet, setBudgetSheet] = useState<{ open: boolean; key: number }>({
    open: false,
    key: 0,
  });
  const look = categoryLook(category);
  const line = summary.data?.categories.find((c) => c.categoryId === category.id);
  const budget = line?.budget ?? null;

  if (summary.error && !summary.data) throw summary.error;
  if (transactions.error && !transactions.data) throw transactions.error;

  return (
    <main className="flex flex-col gap-(--space-3)">
      <div className="flex items-center gap-(--space-3)">
        <span
          className="lk-tile size-12! text-[24px]!"
          style={{ background: `color-mix(in srgb, ${look.tint} 45%, var(--surface-sunken))` }}
          aria-hidden="true"
        >
          {look.glyph}
        </span>
        <div className="flex min-w-0 flex-1 flex-col">
          <h1 className="m-0 truncate font-display text-[26px] leading-tight font-bold text-ink">
            {category.name}
          </h1>
          <p className="m-0 text-[13px] font-bold text-ink-muted">
            {category.kind === "expense" ? t("kind_expense") : t("kind_income")}
            {category.archived && ` · ${tCategories("archived_line")}`}
          </p>
        </div>
        <PressButton
          variant="secondary"
          size="sm"
          aria-label={t("edit")}
          onClick={() => sheets.startEdit(category)}
        >
          {t("edit_short")}
        </PressButton>
      </div>

      {category.archived && (
        <section className="lk-nudge" aria-label={tCategories("archived_line")}>
          <p className="m-0 min-w-0 flex-1 text-[14px] font-bold text-ink">{t("archived_note")}</p>
          <PressButton variant="secondary" size="sm" onClick={() => void sheets.restore(category)}>
            {tCategories("restore")}
          </PressButton>
        </section>
      )}

      {category.kind === "expense" ? (
        <BudgetCard
          summary={summary.data}
          line={line}
          month={month}
          currency={currency}
          archived={category.archived}
          onEdit={() => setBudgetSheet((s) => ({ open: true, key: s.key + 1 }))}
        />
      ) : (
        <IncomeCard categoryId={category.id} month={month} currency={currency} />
      )}

      <Transactions
        category={category}
        items={transactions.data}
        pages={transactions}
        month={month}
        today={today}
        currency={currency}
      />

      <BudgetSheet
        key={budgetSheet.key}
        open={budgetSheet.open}
        onClose={() => setBudgetSheet((s) => ({ ...s, open: false }))}
        category={category}
        month={month}
        budget={budget}
        currency={currency}
      />
      {sheets.sheets}
    </main>
  );
}

function BudgetCard({
  summary,
  line,
  month,
  currency,
  archived,
  onEdit,
}: {
  summary: MonthSummary | undefined;
  line: MonthSummary["categories"][number] | undefined;
  month: Month;
  currency: string;
  archived: boolean;
  onEdit(): void;
}) {
  const t = useTranslations("categories.detail");
  const tRow = useTranslations("category_row");
  const { locale } = useLocale();
  const titleId = useId();
  const money = (cents: number) => formatMoney(cents, currency, locale);
  const monthName = monthInSentence(month, locale);
  const budget = line?.budget ?? null;
  const spent = line?.spent ?? 0;
  const remaining = line?.remaining ?? null;
  const state = line?.state ?? "ok";
  const over = budget !== null && state === "over";

  return (
    <section aria-labelledby={titleId} className="lk-hero flex flex-col gap-(--space-2)">
      <h2 id={titleId} className="lk-hero-label m-0 text-[13px]">
        {t("budget_title")}
      </h2>
      {!summary ? (
        <div className="min-h-[72px]" aria-busy="true" />
      ) : budget === null ? (
        <>
          <p className="m-0 text-[15px] font-bold text-ink">
            {t("no_budget", { month: monthName })}
          </p>
          {spent !== 0 && (
            <p className="lk-hero-meta m-0">
              {t("spent", { month: monthName, amount: money(spent) })}
            </p>
          )}
        </>
      ) : (
        <>
          <p
            className={cx(
              "m-0 font-display text-[28px] font-bold",
              over ? "text-over" : "text-good",
            )}
          >
            {over
              ? tRow("over", { amount: money(Math.abs(remaining ?? budget - spent)) })
              : tRow("remaining", { amount: money(remaining ?? budget - spent) })}
          </p>
          <BudgetBar
            spent={spent}
            budget={budget}
            state={state}
            label={t("spent_of", { spent: money(spent), budget: money(budget) })}
          />
          <p className="lk-hero-meta m-0">
            {t("spent_of", { spent: money(spent), budget: money(budget) })}
          </p>
        </>
      )}
      {!archived && (
        <PressButton
          variant="secondary"
          className="self-start"
          onClick={onEdit}
          disabled={!summary}
        >
          {budget === null ? t("set_budget") : t("change_budget")}
        </PressButton>
      )}
    </section>
  );
}

/**
 * What came in to an income category that month: from the month's totals per income category
 * (every row of the month, not only the pages of the list fetched so far).
 */
function IncomeCard({
  categoryId,
  month,
  currency,
}: {
  categoryId: string;
  month: Month;
  currency: string;
}) {
  const t = useTranslations("categories.detail");
  const { locale } = useLocale();
  const report = useReportByCategory({ from: month, to: month, kind: "income" });
  if (report.error && !report.data) throw report.error;
  // While another month loads, the previous month's figure is not this one's.
  const answer = report.data?.range.from === month ? report.data : undefined;
  const total = answer?.items.find((i) => i.categoryId === categoryId)?.total ?? 0;
  return (
    <section className="lk-hero" aria-busy={!answer || undefined}>
      <p className="m-0 font-display text-[22px] font-bold text-good">
        {t("received", {
          month: monthInSentence(month, locale),
          amount: formatMoney(total, currency, locale),
        })}
      </p>
    </section>
  );
}

function Transactions({
  category,
  items,
  pages,
  month,
  today,
  currency,
}: {
  category: CategoryDto;
  items: TransactionDto[] | undefined;
  pages: MorePages;
  month: Month;
  today: string;
  currency: string;
}) {
  const t = useTranslations("categories.detail");
  const { locale } = useLocale();
  const { openAdd } = useTransactionSheet();
  const titleId = useId();
  const monthName = monthInSentence(month, locale);
  const byId = new Map([[category.id, category]]);

  return (
    <section aria-labelledby={titleId} className="flex flex-col gap-(--space-2)">
      <h2 id={titleId} className="m-0 font-display text-[20px] font-bold text-ink">
        {t("transactions_title", { month: monthName })}
      </h2>
      {!items ? (
        <div className="min-h-[120px]" aria-busy="true" />
      ) : items.length === 0 ? (
        <div className="flex flex-col items-start gap-(--space-3)">
          <p className="m-0 text-[14px] font-bold text-ink-muted">
            {t("empty", { name: category.name, month: monthName })}
          </p>
          {!category.archived && (
            <PressButton variant="secondary" onClick={() => openAdd(category.id)}>
              {category.kind === "income" ? t("add_income") : t("add_expense")}
            </PressButton>
          )}
        </div>
      ) : (
        <>
          {groupByDay(items, today).map((group) => (
            <Day key={group.date} group={group} byId={byId} currency={currency} />
          ))}
          <ShowMore pages={pages} />
        </>
      )}
    </section>
  );
}
