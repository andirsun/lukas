import {
  type CategoryDto,
  type MonthSummary,
  monthOf,
  type TransactionDto,
  todayIn,
} from "@lukas/core";
import { useQueryClient } from "@tanstack/react-query";
import { createElement, Fragment, useMemo, useState } from "react";
import { useTranslations } from "use-intl";
import { ApiProblem, problemMessage, type Translator } from "../../api/errors.ts";
import {
  type NewTransaction,
  queryKeys,
  type TransactionPatch,
  useAllCategories,
  useCreateTransaction,
  useDeleteTransaction,
  useMarkPaid,
  useRestoreTransaction,
  useSuggestions,
  useTransactions,
  useUpdateTransaction,
} from "../../api/queries.ts";
import { feedback } from "../../feedback/feedback.ts";
import {
  formatMoney,
  isWholeUnit,
  type Locale,
  lukasHint,
  parseAmountInput,
} from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { wholeAmount } from "../../ui/keypad-input.ts";
import { useToast } from "../../ui/Toast.tsx";
import { feedbackForSave, orderByUse } from "../home/home-model.ts";

export type Kind = "expense" | "income";

/** Something that just happened on a transaction, for Lukitas's line and mood on home. */
export interface TransactionEvent {
  /** Grows with each event, so the same kind of event twice still counts as new. */
  id: number;
  kind: "saved" | "paid";
  categoryId: string;
  /** Signed cents, as stored. */
  amount: number;
  month: string;
}

export interface TransactionActionsDeps {
  currency: string;
  /** Opens the edit sheet ("Ponerle nombre" opens it on the name). */
  openEdit(tx: TransactionDto, options?: { focusName?: boolean }): void;
  report(event: Omit<TransactionEvent, "id">): void;
}

/** "−6,08 €"-style money, and the COP hint ("50 lukas") as a small muted part after it. */
function moneyWithHint(cents: number, currency: string, locale: Locale) {
  const amount = formatMoney(Math.abs(cents), currency, locale);
  const hint = lukasHint(cents, currency, locale);
  return { amount, hint };
}

/**
 * The writes behind the sheet and home, with what follows each one (spec §2.6, §3.3, §4.1): the
 * change shows at once (optimistic), then the feedback event, a toast (with Deshacer, and
 * "Ponerle nombre" after an unnamed save), and Lukitas's event. A failure rolls the change back
 * (the mutations do) and shows the error in an `alert` toast. Kept in the always-mounted provider,
 * so an undo works after the sheet is gone.
 */
export function useTransactionActions({ currency, openEdit, report }: TransactionActionsDeps) {
  const t = useTranslations("transaction");
  const tRoot = useTranslations() as unknown as Translator;
  const { locale } = useLocale();
  const qc = useQueryClient();
  const toast = useToast();
  const create = useCreateTransaction();
  const update = useUpdateTransaction();
  const remove = useDeleteTransaction();
  const restore = useRestoreTransaction();
  const pay = useMarkPaid();

  const fail = (problem: unknown) =>
    toast.show({
      tone: "error",
      message:
        problem instanceof ApiProblem ? problemMessage(problem, tRoot) : tRoot("errors.generic"),
    });

  async function undoCreate(created: TransactionDto) {
    try {
      await remove.mutateAsync({ id: created.id, month: monthOf(created.date) });
      feedback("undo");
      toast.show({ message: t("undone", { name: created.name }) });
    } catch (problem) {
      fail(problem);
    }
  }

  async function bringBack(tx: TransactionDto) {
    try {
      await restore.mutateAsync({ transaction: tx });
      feedback("undo");
      toast.show({ message: t("restored", { name: tx.name }) });
    } catch (problem) {
      fail(problem);
    }
  }

  return {
    /** Creates; the key is the sheet's (one per opening), so a repeated save is one transaction. */
    async create(
      input: NewTransaction,
      idempotencyKey: string,
      details: { kind: Kind; categoryName: string; unnamed: boolean },
    ) {
      try {
        const created = await create.mutateAsync({ input, idempotencyKey });
        const month = monthOf(created.date);
        const after = qc.getQueryData<MonthSummary>(queryKeys.summary(month));
        feedback(feedbackForSave(after, created.categoryId, details.kind));
        report({ kind: "saved", categoryId: created.categoryId, amount: created.amount, month });
        const { amount, hint } = moneyWithHint(created.amount, currency, locale);
        const line = t(details.kind === "income" ? "saved_income" : "saved_expense", {
          category: details.categoryName,
          amount,
        });
        toast.show({
          message: hint
            ? createElement(
                Fragment,
                null,
                `${line} `,
                createElement("span", { className: "text-[11px] text-ink-muted" }, `(${hint})`),
              )
            : line,
          actions: [
            { label: tRoot("common.undo"), onClick: () => void undoCreate(created) },
            ...(details.unnamed
              ? [{ label: t("name_it"), onClick: () => openEdit(created, { focusName: true }) }]
              : []),
          ],
        });
      } catch (problem) {
        fail(problem);
      }
    },

    /** Saves only what changed. */
    async update(tx: TransactionDto, patch: TransactionPatch) {
      if (Object.keys(patch).length === 0) return;
      try {
        const saved = await update.mutateAsync({ id: tx.id, month: monthOf(tx.date), patch });
        toast.show({ message: t("updated", { name: saved.name }) });
      } catch (problem) {
        fail(problem);
      }
    },

    /** Deletes (the API keeps it), with Deshacer to bring it back. */
    async remove(tx: TransactionDto) {
      try {
        await remove.mutateAsync({ id: tx.id, month: monthOf(tx.date) });
        toast.show({
          message: t("deleted", { name: tx.name }),
          actions: [{ label: tRoot("common.undo"), onClick: () => void bringBack(tx) }],
        });
      } catch (problem) {
        fail(problem);
      }
    },

    /**
     * Marks a pending transaction paid: a small celebration and a status toast (so screen readers
     * hear it). Rejects on failure, after the error toast, so the badge goes back to "Pendiente".
     */
    async markPaid(tx: TransactionDto) {
      const month = monthOf(tx.date);
      try {
        await pay.mutateAsync({ id: tx.id, month });
      } catch (problem) {
        fail(problem);
        throw problem;
      }
      feedback("paid");
      report({ kind: "paid", categoryId: tx.categoryId, amount: tx.amount, month });
      toast.show({
        message: t("paid", {
          name: tx.name,
          amount: formatMoney(tx.amount, currency, locale),
        }),
      });
    },
  };
}

export type TransactionActions = ReturnType<typeof useTransactionActions>;

// -- The form --------------------------------------------------------------------------------------

/**
 * Stored cents as keypad text in the locale (`26280` → `262,80`; `5000` → `50`). Whole-unit
 * currencies (COP) are rounded to whole pesos: the keypad never holds fractional pesos.
 */
export function keypadText(cents: number, locale: Locale, currency?: string): string {
  const abs = Math.abs(cents);
  if (currency && isWholeUnit(currency)) return String(Math.round(abs / 100));
  const whole = Math.floor(abs / 100);
  const rest = abs % 100;
  return rest === 0
    ? String(whole)
    : `${whole}${locale === "es" ? "," : "."}${String(rest).padStart(2, "0")}`;
}

/** The typed amount in cents, or 0 while it is empty or not a number yet. */
export function centsOf(raw: string, locale: Locale): number {
  if (!raw) return 0;
  try {
    return parseAmountInput(raw, locale);
  } catch {
    return 0;
  }
}

/** How many category chips show before "Más" (two rows of four, "Más" being the eighth). */
const VISIBLE_CHIPS = 7;

/** A recent name with the category it usually goes in. */
export interface NameChoice {
  name: string;
  categoryId: string;
  categoryName: string;
  kind: Kind;
}

export interface FormOptions {
  editing?: TransactionDto | undefined;
  /** A category to start with (e.g. from a budget row). */
  categoryId?: string | undefined;
  timezone: string;
  currency: string;
}

/** The add/edit sheet's state, its choices (categories, shortcuts) and what saving would send. */
export function useTransactionForm({
  editing,
  categoryId: initialCategory,
  timezone,
  currency,
}: FormOptions) {
  const { locale } = useLocale();
  // Archived ones too: the transaction being edited may be in one (it is never moved silently).
  const categoriesQuery = useAllCategories();
  const categories: CategoryDto[] = categoriesQuery.data ?? [];
  const today = todayIn(timezone);
  const recent = useTransactions(monthOf(today));
  const byId = useMemo(() => new Map(categories.map((c) => [c.id, c])), [categories]);

  const editingCategory = editing ? byId.get(editing.categoryId) : undefined;
  const [kindState, setKindState] = useState<Kind | null>(() =>
    editing ? (editing.amount > 0 ? "income" : "expense") : null,
  );
  const presetKind = initialCategory ? byId.get(initialCategory)?.kind : undefined;
  const kind: Kind = kindState ?? editingCategory?.kind ?? presetKind ?? "expense";

  const [raw, setRaw] = useState(() =>
    editing ? keypadText(editing.amount, locale, currency) : "",
  );
  const [name, setName] = useState(() => editing?.name ?? "");
  const [picked, setPicked] = useState<string | null>(null);
  const [categoryId, setCategoryId] = useState<string | null>(
    () => editing?.categoryId ?? initialCategory ?? null,
  );
  // Only a category the person picked goes into an edit's patch: never a fallback.
  const [categoryChosen, setCategoryChosen] = useState(false);
  const choose = (id: string | null) => {
    setCategoryId(id);
    setCategoryChosen(true);
  };
  const [date, setDate] = useState(() => editing?.date ?? today);
  const [pending, setPending] = useState(() => editing?.status === "pending");
  const [note, setNote] = useState(() => editing?.note ?? "");
  const [allChips, setAllChips] = useState(false);
  // One key per opening of the sheet: any repeat of this save is the same request to the API.
  const [idempotencyKey] = useState(() => crypto.randomUUID());

  const active = orderByUse(
    categories.filter((c) => !c.archived && c.kind === kind),
    recent.data?.items ?? [],
  );
  // New transactions only go in active categories; an edited one keeps offering its own, even
  // archived (first, so it shows among the visible chips).
  const ofKind =
    editingCategory?.archived && editingCategory.kind === kind
      ? [editingCategory, ...active]
      : active;
  const selected =
    (categoryId && ofKind.find((c) => c.id === categoryId)) || ofKind[0] || undefined;
  // An edited transaction whose name is just its category's shows the name as the placeholder.
  const nameShown =
    editing && editingCategory && name === editingCategory.name && !picked ? "" : name;

  let chips = ofKind;
  const overflow = ofKind.length > VISIBLE_CHIPS + 1;
  if (overflow && !allChips) {
    chips = ofKind.slice(0, VISIBLE_CHIPS);
    if (selected && !chips.includes(selected)) chips = [...chips.slice(0, -1), selected];
  }

  // After a pick the full list stays: the API filters only while the person is typing.
  const query = picked !== null && name === picked ? "" : name.trim();
  const suggestions = (useSuggestions(query).data?.items ?? []).flatMap((s): NameChoice[] => {
    const category = byId.get(s.categoryId);
    return category && !category.archived
      ? [
          {
            name: s.name,
            categoryId: s.categoryId,
            categoryName: category.name,
            kind: category.kind,
          },
        ]
      : [];
  });

  // Pesos: a typed separator only ends the amount; what comes before it is the amount.
  const cents = centsOf(wholeAmount(raw, { locale, currency }), locale);
  const valid = cents > 0 && selected !== undefined && date !== "";

  /** What a new transaction would be: unnamed, it takes its category's name. */
  const input = (): NewTransaction | null => {
    if (!valid || !selected) return null;
    const trimmed = nameShown.trim();
    return {
      name: trimmed || selected.name,
      amount: kind === "expense" ? -cents : cents,
      categoryId: selected.id,
      date,
      status: pending ? "pending" : "paid",
      ...(note.trim() ? { note: note.trim() } : {}),
      source: "web",
    };
  };

  return {
    loading: !categoriesQuery.data,
    kind,
    setKind(next: Kind) {
      setKindState(next);
      if (selected?.kind !== next) choose(null);
    },
    raw,
    setRaw,
    cents,
    name: nameShown,
    setName(next: string) {
      setName(next);
      if (next !== picked) setPicked(null);
    },
    pick(s: NameChoice) {
      setName(s.name);
      setPicked(s.name);
      setKindState(s.kind);
      choose(s.categoryId);
    },
    suggestions,
    selected,
    select: choose,
    chips,
    overflow,
    allChips,
    setAllChips,
    date,
    setDate,
    today,
    pending,
    setPending,
    note,
    setNote,
    idempotencyKey,
    valid,
    input,
    /** The fields of `editing` that changed. */
    patch(): TransactionPatch {
      const next = input();
      if (!editing || !next) return {};
      const patch: TransactionPatch = {};
      if (next.name !== editing.name) patch.name = next.name;
      if (next.amount !== editing.amount) patch.amount = next.amount;
      if (categoryChosen && next.categoryId !== editing.categoryId) {
        patch.categoryId = next.categoryId;
      }
      if (next.date !== editing.date) patch.date = next.date;
      if (next.status !== editing.status) patch.status = next.status;
      const nextNote = note.trim() || null;
      if (nextNote !== editing.note) patch.note = nextNote;
      return patch;
    },
  };
}

export type TransactionForm = ReturnType<typeof useTransactionForm>;
