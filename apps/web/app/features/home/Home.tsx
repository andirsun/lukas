import {
  type CategoryDto,
  type Month,
  type MonthSummary,
  monthOf,
  type TransactionDto,
  todayIn,
} from "@lukas/core";
import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useId, useMemo, useState } from "react";
import { useNavigate } from "react-router";
import { useTranslations } from "use-intl";
import { useApi, useApiMode } from "../../api/ApiProvider.tsx";
import { ApiProblem, problemMessage, type Translator } from "../../api/errors.ts";
import {
  queryKeys,
  useAllCategories,
  useMe,
  useSummary,
  useTransactions,
} from "../../api/queries.ts";
import { formatDay, formatMoney, formatMonth } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { moodFor } from "../../lukas/mood.ts";
import { BudgetBar } from "../../ui/BudgetBar.tsx";
import { CategoryRow } from "../../ui/CategoryRow.tsx";
import { categoryLook } from "../../ui/category-look.ts";
import { cx } from "../../ui/cx.ts";
import { LukasBubble } from "../../ui/LukasBubble.tsx";
import { Money } from "../../ui/Money.tsx";
import { type Pager, PagerTrack, usePager } from "../../ui/Pager.tsx";
import { PressButton } from "../../ui/PressButton.tsx";
import { PressLink } from "../../ui/PressLink.tsx";
import { SegmentedControl } from "../../ui/SegmentedControl.tsx";
import { SwipeRow } from "../../ui/SwipeRow.tsx";
import { useToast } from "../../ui/Toast.tsx";
import { TransactionRow } from "../../ui/TransactionRow.tsx";
import { useWideScreen } from "../../ui/use-wide-screen.ts";
import { useTransactionSheet } from "../add-transaction/TransactionSheetProvider.tsx";
import { createSuggestions, useHasTransactions } from "../onboarding/onboarding-api.ts";
import { SUGGESTED_CATEGORIES } from "../onboarding/suggested-categories.ts";
import { useAppPath } from "./app-path.ts";
import { HomeHeader } from "./HomeHeader.tsx";
import { type DayGroup, groupByDay, homeLukasLine, overallState } from "./home-model.ts";
import { type HomeView, useDismissed, useHomeView } from "./home-storage.ts";
import type { SignOutRequest } from "./use-sign-out.ts";

/** How long Lukitas celebrates after a save or a payment. */
const CELEBRATE_MS = 2500;
/** The phone's pages, in order: Movimientos first (founder decision 2026-10-22). */
const VIEWS: readonly HomeView[] = ["transactions", "budgets"];

/**
 * Home (`/app`, spec §2.5): the month (the person's current one by default, earlier ones
 * browsable), Lukitas with a line about it, what is left (or, without budgets, what was spent),
 * and two lists: Movimientos (by day: today on top, the upcoming pending ones next, then the past)
 * and Presupuestos (one row per spending category, opening its detail). On phones they are two
 * pages that follow the finger (a sideways drag anywhere on the screen but a row, which has its
 * own swipes; `gestureOwner` decides), or the segmented control above them; Movimientos first and
 * by default, the choice remembered on the device. On wide screens they sit side by side,
 * Movimientos first. Around them, gentle cards for an account that skipped the setup.
 */
export interface HomeProps {
  /** Ends the session (stories pass a stand-in); Better Auth's by default. */
  signOut?: SignOutRequest;
}

export function Home({ signOut }: HomeProps = {}) {
  const me = useMe().data;
  if (!me) throw new Error("Home renders inside AppShell, which waits for the profile");
  const today = todayIn(me.timezone);
  const current = monthOf(today);
  const [month, setMonth] = useState<Month>(current);
  return (
    <MonthView
      key={me.id}
      userId={me.id}
      currency={me.currency}
      today={today}
      current={current}
      month={month}
      onMonth={setMonth}
      signOut={signOut}
    />
  );
}

interface MonthViewProps {
  userId: string;
  currency: string;
  today: string;
  current: Month;
  month: Month;
  onMonth(month: Month): void;
  signOut?: SignOutRequest | undefined;
}

function MonthView({ userId, currency, today, current, month, onMonth, signOut }: MonthViewProps) {
  const t = useTranslations("home");
  const { locale } = useLocale();
  const summary = useSummary(month);
  const transactions = useTransactions(month);
  // Archived ones too: older transactions (and a month's summary) can still be in them.
  const categories = useAllCategories();
  const [view, setView] = useHomeView();
  const wide = useWideScreen();
  const pager = usePager({
    index: VIEWS.indexOf(view),
    count: VIEWS.length,
    onIndexChange: (index) => setView(VIEWS[index] ?? "transactions"),
    enabled: !wide,
  });

  if (summary.error && !summary.data) throw summary.error;
  if (transactions.error && !transactions.data) throw transactions.error;
  if (categories.error && !categories.data) throw categories.error;

  const active = categories.data?.filter((c) => !c.archived);
  const money = (cents: number) => formatMoney(cents, currency, locale);
  const monthName = formatMonth(month, locale);

  return (
    <div className="mx-auto flex w-full max-w-[480px] flex-col gap-(--space-3) px-(--space-4) pt-(--space-3) lg:max-w-[1040px] lg:px-(--space-6) lg:pt-(--space-5)">
      <HomeHeader month={month} onMonth={onMonth} max={current} signOut={signOut} />
      <main className="flex flex-col gap-(--space-3)" {...pager.surface}>
        {summary.data && categories.data && transactions.data ? (
          <>
            <Lukitas
              summary={summary.data}
              categories={categories.data}
              items={transactions.data}
              today={today}
              current={current}
              money={money}
            />
            <Hero
              summary={summary.data}
              currency={currency}
              past={month < current}
              monthName={monthName}
            />
          </>
        ) : (
          <div className="lk-hero min-h-[140px]" aria-busy="true" />
        )}
        {active && active.length === 0 ? (
          <NoCategories />
        ) : (
          <>
            {active && summary.data && (
              <Nudges userId={userId} categories={active} summary={summary.data} />
            )}
            <Lists
              view={view}
              onView={setView}
              pager={wide ? null : pager}
              summary={summary.data}
              categories={categories.data}
              items={transactions.data}
              pages={transactions}
              today={today}
              currency={currency}
              month={month}
              monthName={monthName}
            />
          </>
        )}
      </main>
    </div>
  );
}

// -- Lukitas ---------------------------------------------------------------------------------------

function Lukitas({
  summary,
  categories,
  items,
  today,
  current,
  money,
}: {
  summary: MonthSummary;
  categories: CategoryDto[];
  items: TransactionDto[];
  today: string;
  current: Month;
  money(cents: number): string;
}) {
  const tRoot = useTranslations();
  const { lastEvent } = useTransactionSheet();
  const event = lastEvent && lastEvent.month === summary.month ? lastEvent : null;
  const names = useMemo(() => new Map(categories.map((c) => [c.id, c.name])), [categories]);

  const line = homeLukasLine({
    summary,
    today,
    todayCount: items.filter((tx) => tx.date === today).length,
    event: event
      ? { kind: event.kind, categoryId: event.categoryId, amount: event.amount }
      : undefined,
    categoryName: (id) => names.get(id) ?? "",
    money,
  });
  // One of the key's variants, picked again only when the situation changes.
  const variant = useMemo(
    () => 1 + Math.floor(Math.random() * 3),
    [line.key, event?.id, summary.month],
  );
  const message = tRoot(
    (line.varied ? `${line.key}.${variant}` : line.key) as never,
    line.params as never,
  );

  const [celebrating, setCelebrating] = useState(false);
  // Only a new event starts a celebration (not near or over a limit: no party for that).
  useEffect(() => {
    if (!event) return;
    const state = summary.categories.find((c) => c.categoryId === event.categoryId)?.state;
    if (state === "near" || state === "over") return;
    setCelebrating(true);
    const timer = setTimeout(() => setCelebrating(false), CELEBRATE_MS);
    return () => clearTimeout(timer);
  }, [event?.id]);
  const closedGreen = summary.month < current && summary.budgetTotal > 0 && summary.remaining >= 0;

  return <LukasBubble message={message} mood={moodFor(summary, celebrating || closedGreen)} />;
}

// -- What is left ----------------------------------------------------------------------------------

function Hero({
  summary,
  currency,
  past,
  monthName,
}: {
  summary: MonthSummary;
  currency: string;
  past: boolean;
  monthName: string;
}) {
  const t = useTranslations("home");
  const { locale } = useLocale();
  const labelId = useId();
  const money = (cents: number) => formatMoney(cents, currency, locale);
  const hasBudget = summary.budgetTotal > 0;
  const over = hasBudget && summary.remaining < 0;
  const label = !hasBudget
    ? past
      ? t("spent_label_past", { month: monthName })
      : t("spent_label")
    : over
      ? past
        ? t("over_label_past", { month: monthName })
        : t("over_label")
      : past
        ? t("remaining_label_past", { month: monthName })
        : t("remaining_label");

  return (
    <section aria-labelledby={labelId} className="lk-hero">
      <h1 id={labelId} className="lk-hero-label m-0 text-[13px]">
        {label}
      </h1>
      <p className={cx("lk-hero-amount m-0", over && "text-over", !hasBudget && "text-ink")}>
        <Money
          cents={hasBudget ? Math.abs(summary.remaining) : summary.spent}
          currency={currency}
          animate
        />
      </p>
      {hasBudget ? (
        <>
          <div className="mt-(--space-2)">
            <BudgetBar
              spent={summary.spent}
              budget={summary.budgetTotal}
              state={overallState(summary.budgetTotal, summary.spent)}
              label={t("spent_meter", {
                spent: money(summary.spent),
                budget: money(summary.budgetTotal),
              })}
            />
          </div>
          <p className="lk-hero-meta mb-0">
            <span>{t("spent", { amount: money(summary.spent) })}</span>
            <span>{t("of_budget", { amount: money(summary.budgetTotal) })}</span>
          </p>
        </>
      ) : (
        <p className="lk-hero-meta mb-0">
          <span>{t("no_budget_meta")}</span>
        </p>
      )}
    </section>
  );
}

// -- Cards -----------------------------------------------------------------------------------------

/** For an account that skipped the setup: budgets, and bringing a history. Each can be put away. */
function Nudges({
  userId,
  categories,
  summary,
}: {
  userId: string;
  categories: CategoryDto[];
  summary: MonthSummary;
}) {
  const t = useTranslations("home");
  const hasTransactions = useHasTransactions();
  const [dismissed, dismiss] = useDismissed(userId);
  const appPath = useAppPath();
  // The demo has no import: settings turns it off there.
  const canImport = useApiMode() === "live";
  const noBudgets =
    summary.budgetTotal === 0 &&
    categories.some((c) => c.kind === "expense") &&
    categories.every((c) => c.currentBudget === null);
  const cards = [
    noBudgets && !dismissed.has("budgets")
      ? {
          id: "budgets",
          title: t("nudge_budgets_title"),
          lead: t("nudge_budgets_lead"),
          action: { label: t("nudge_budgets_action"), to: appPath("/categories") },
        }
      : null,
    canImport && hasTransactions.data === false && !dismissed.has("import")
      ? {
          id: "import",
          title: t("nudge_import_title"),
          lead: t("nudge_import_lead"),
          action: { label: t("nudge_import_action"), to: appPath("/import") },
        }
      : null,
  ].filter((card) => card !== null);
  if (cards.length === 0) return null;

  return (
    <aside aria-label={t("nudges_label")} className="flex flex-col gap-(--space-2)">
      {cards.map((card) => (
        <Nudge key={card.id} {...card} onDismiss={() => dismiss(card.id)} />
      ))}
    </aside>
  );
}

function Nudge({
  title,
  lead,
  action,
  onDismiss,
}: {
  title: string;
  lead: string;
  /** Where the card leads; without one it is marked "pronto". */
  action?: { label: string; to: string };
  onDismiss(): void;
}) {
  const t = useTranslations();
  const titleId = useId();
  return (
    <section aria-labelledby={titleId} className="lk-nudge">
      <div className="flex min-w-0 flex-1 flex-col gap-(--space-1)">
        <h2
          id={titleId}
          className="m-0 flex flex-wrap items-center gap-(--space-2) text-[14px] font-extrabold text-ink"
        >
          {title}
          {!action && <span className="lk-soon">{t("nav.soon")}</span>}
        </h2>
        <p className="m-0 text-[12px] font-bold text-ink-muted">{lead}</p>
        {action && (
          <PressLink to={action.to} variant="secondary" size="sm" className="self-start">
            {action.label}
          </PressLink>
        )}
      </div>
      <PressButton
        variant="ghost"
        size="sm"
        aria-label={t("home.nudge_dismiss", { title })}
        onClick={onDismiss}
      >
        {t("common.not_now")}
      </PressButton>
    </section>
  );
}

/** No category at all (everything was deselected in the setup): one tap brings the suggestions. */
function NoCategories() {
  const t = useTranslations("home");
  const tRoot = useTranslations() as unknown as Translator;
  const { locale } = useLocale();
  const api = useApi();
  const qc = useQueryClient();
  const toast = useToast();
  const [busy, setBusy] = useState(false);
  const titleId = useId();

  const useSuggested = async () => {
    if (busy) return;
    setBusy(true);
    try {
      await createSuggestions(api, new Set(SUGGESTED_CATEGORIES.map((c) => c.key)), locale);
      await qc.invalidateQueries({ queryKey: queryKeys.categories() });
      await qc.invalidateQueries({ queryKey: ["summary"] });
    } catch (problem) {
      toast.show({
        tone: "error",
        message:
          problem instanceof ApiProblem ? problemMessage(problem, tRoot) : tRoot("errors.generic"),
      });
    } finally {
      setBusy(false);
    }
  };

  return (
    <section aria-labelledby={titleId} className="lk-hero flex flex-col gap-(--space-2)">
      <h2 id={titleId} className="m-0 font-display text-[20px] font-bold text-ink">
        {t("no_categories_title")}
      </h2>
      <p className="m-0 text-[14px] font-bold text-ink-muted">{t("no_categories_lead")}</p>
      <PressButton onClick={() => void useSuggested()} disabled={busy} aria-busy={busy}>
        {t("use_suggested")}
      </PressButton>
    </section>
  );
}

// -- The lists -------------------------------------------------------------------------------------

interface ListsProps {
  view: HomeView;
  onView(view: HomeView): void;
  /** Phones: the two lists are the pager's pages. Wide screens (null): side by side. */
  pager: Pager | null;
  summary: MonthSummary | undefined;
  categories: CategoryDto[] | undefined;
  items: TransactionDto[] | undefined;
  /** The list's pages: "Ver más movimientos" while there are more. */
  pages: MorePages;
  today: string;
  currency: string;
  month: Month;
  monthName: string;
}

function Lists({
  view,
  onView,
  pager,
  summary,
  categories,
  items,
  pages,
  today,
  currency,
  month,
  monthName,
}: ListsProps) {
  const t = useTranslations("home");
  const transactions = (
    <section role="tabpanel" aria-label={t("view.transactions")} className="lk-panel flex">
      <h2 className="lk-panel-title">{t("view.transactions")}</h2>
      <Transactions
        items={items}
        pages={pages}
        categories={categories}
        today={today}
        currency={currency}
        monthName={monthName}
      />
    </section>
  );
  const budgets = (
    <section role="tabpanel" aria-label={t("view.budgets")} className="lk-panel flex">
      <h2 className="lk-panel-title">{t("view.budgets")}</h2>
      <Budgets summary={summary} categories={categories} currency={currency} month={month} />
    </section>
  );

  if (!pager) {
    return (
      <div className="grid grid-cols-2 items-start gap-(--space-6)">
        {transactions}
        {budgets}
      </div>
    );
  }
  return (
    <>
      {/* Stuck under the header once the summary scrolls away: a tap or a sideways drag on it
          reaches the pager anywhere in a long list (rows own the drags that start on them). */}
      <div className="lk-tabs-sticky">
        <SegmentedControl<HomeView>
          label={t("view.label")}
          value={view}
          position={pager.position}
          options={[
            { value: "transactions", label: t("view.transactions") },
            { value: "budgets", label: t("view.budgets") },
          ]}
          onChange={onView}
        />
      </div>
      <PagerTrack pager={pager}>
        {transactions}
        {budgets}
      </PagerTrack>
    </>
  );
}

function Budgets({
  summary,
  categories,
  currency,
  month,
}: {
  summary: MonthSummary | undefined;
  categories: CategoryDto[] | undefined;
  currency: string;
  month: Month;
}) {
  const t = useTranslations("home");
  const tTransaction = useTranslations("transaction");
  const navigate = useNavigate();
  const appPath = useAppPath();
  if (!summary || !categories) return <div className="min-h-[120px]" aria-busy="true" />;
  const byId = new Map(categories.map((c) => [c.id, c]));
  const rows = summary.categories
    .flatMap((s) => {
      const category = byId.get(s.categoryId);
      // The summary keeps an archived category only while it has spending that month.
      return category && category.kind === "expense" ? [{ s, category }] : [];
    })
    .sort((a, b) => a.category.sortOrder - b.category.sortOrder);
  if (rows.length === 0) {
    return <p className="m-0 text-[14px] font-bold text-ink-muted">{t("no_expense_categories")}</p>;
  }
  return (
    <>
      {rows.map(({ s, category }) => {
        const look = categoryLook(category);
        return (
          <CategoryRow
            key={category.id}
            name={category.name}
            glyph={look.glyph}
            tint={look.tint}
            budget={s.budget}
            spent={s.spent}
            remaining={s.remaining}
            state={s.state}
            currency={currency}
            {...(category.archived ? { note: tTransaction("archived") } : {})}
            // Its detail, in the month on screen.
            onOpen={() => navigate(appPath(`/categories/${category.id}?month=${month}`))}
          />
        );
      })}
    </>
  );
}

function Transactions({
  items,
  pages,
  categories,
  today,
  currency,
  monthName,
}: {
  items: TransactionDto[] | undefined;
  pages: MorePages;
  categories: CategoryDto[] | undefined;
  today: string;
  currency: string;
  monthName: string;
}) {
  const t = useTranslations();
  const { openAdd } = useTransactionSheet();
  if (!items || !categories) return <div className="min-h-[120px]" aria-busy="true" />;
  if (items.length === 0) {
    return (
      <div className="flex flex-col items-start gap-(--space-3)">
        <p className="m-0 text-[14px] font-bold text-ink-muted">
          {t("home.empty_transactions", { month: monthName })}
        </p>
        <PressButton variant="secondary" onClick={() => openAdd()}>
          {t("transaction.add_expense")}
        </PressButton>
      </div>
    );
  }
  const byId = new Map(categories.map((c) => [c.id, c]));
  return (
    <>
      {groupByDay(items, today).map((group) => (
        <Day key={group.date} group={group} byId={byId} currency={currency} />
      ))}
      <ShowMore pages={pages} />
    </>
  );
}

/** What "Ver más movimientos" needs of a paged list (`useTransactions`, `useCategoryTransactions`). */
export interface MorePages {
  hasNextPage: boolean;
  isFetchingNextPage: boolean;
  fetchNextPage(): Promise<{ error: Error | null }>;
}

/**
 * "Ver más movimientos" at the end of a list that has more than one page: brings the next page
 * (older rows) below the ones shown. A failure keeps the list as it is and says so in a toast.
 * Also used by a category's detail.
 */
export function ShowMore({ pages }: { pages: MorePages }) {
  const t = useTranslations("home");
  const tRoot = useTranslations() as unknown as Translator;
  const toast = useToast();
  if (!pages.hasNextPage) return null;
  const busy = pages.isFetchingNextPage;
  const more = async () => {
    if (busy) return;
    const { error } = await pages.fetchNextPage();
    if (error) {
      toast.show({
        tone: "error",
        message:
          error instanceof ApiProblem ? problemMessage(error, tRoot) : tRoot("errors.generic"),
      });
    }
  };
  return (
    <PressButton
      variant="secondary"
      className="self-center"
      onClick={() => void more()}
      disabled={busy}
      aria-busy={busy}
    >
      {t("more_transactions")}
    </PressButton>
  );
}

/**
 * One day of transactions: its heading (today, yesterday, upcoming) with the day's total, and its
 * rows, each opening the edit sheet; a pending one is paid from its badge. Also used by a
 * category's detail.
 */
export function Day({
  group,
  byId,
  currency,
}: {
  group: DayGroup;
  byId: Map<string, CategoryDto>;
  currency: string;
}) {
  const t = useTranslations("home");
  const { locale } = useLocale();
  const { openEdit, actions, restored } = useTransactionSheet();
  const [paidHere, setPaidHere] = useState<ReadonlySet<string>>(new Set());
  const headingId = useId();
  const day = formatDay(group.date, locale);
  const label =
    group.when === "today"
      ? t("day_today", { day })
      : group.when === "yesterday"
        ? t("day_yesterday", { day })
        : group.when === "upcoming"
          ? t("day_upcoming", { day })
          : day;

  const pay = async (tx: TransactionDto) => {
    setPaidHere((current) => new Set(current).add(tx.id));
    try {
      await actions.markPaid(tx);
    } catch (problem) {
      setPaidHere((current) => {
        const next = new Set(current);
        next.delete(tx.id);
        return next;
      });
      throw problem;
    }
  };

  return (
    <section aria-labelledby={headingId} className="flex flex-col gap-(--space-2)">
      <h3 id={headingId} className="lk-overline m-0 mt-(--space-1)">
        <span>{label}</span>
        <span className="lk-num">
          {formatMoney(group.total, currency, locale, {
            sign: group.total > 0 ? "always" : "auto",
          })}
        </span>
      </h3>
      {group.items.map((tx) => {
        const category = byId.get(tx.categoryId);
        // A row the API has not confirmed yet cannot be edited or paid.
        const draft = tx.id.startsWith("pending-");
        // Swipes are shortcuts: left deletes, right edits (or pays a pending one).
        return (
          <SwipeRow
            key={tx.id}
            enter={restored.has(tx.id)}
            onDelete={draft ? undefined : () => void actions.remove(tx)}
            right={
              draft
                ? undefined
                : tx.status === "pending"
                  ? {
                      kind: "paid",
                      // Paid once: a second quick swipe (or the badge) never pays it again.
                      run: () => {
                        if (!paidHere.has(tx.id)) void pay(tx).catch(() => {});
                      },
                    }
                  : { kind: "edit", run: () => openEdit(tx) }
            }
          >
            <TransactionRow
              name={tx.name}
              categoryName={category?.name ?? ""}
              glyph={category ? categoryLook(category).glyph : "🏷️"}
              amount={tx.amount}
              currency={currency}
              status={tx.status}
              paidHere={paidHere.has(tx.id)}
              onOpen={() => {
                if (!draft) openEdit(tx);
              }}
              {...(draft ? {} : { onPay: () => pay(tx) })}
            />
          </SwipeRow>
        );
      })}
    </section>
  );
}
