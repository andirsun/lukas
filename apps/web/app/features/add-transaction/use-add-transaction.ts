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
import { formatMoney, type Locale, lukasHint } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { centsOf, keypadText, wholeAmount } from "../../ui/keypad-input.ts";
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
  /** The movement's name, so Lukitas can say which one it was. */
  name: string;
  month: string;
}

export interface TransactionActionsDeps {
  currency: string;
  /** Opens the edit sheet ("Ponerle nombre" opens it on the name). */
  openEdit(tx: TransactionDto, options?: { focusName?: boolean }): void;
  report(event: Omit<TransactionEvent, "id">): void;
  /** A deleted transaction is coming back (Deshacer): its row slides in. */
  onRestored?(id: string): void;
}

/**
 * Whether sending the same request again can work: no answer at all (offline, a lost connection),
 * a server error or timeout, too many requests, or the first try still running. Not a refusal
 * (a 4xx such as an invalid amount), which says the same every time.
 */
export function canRetry(problem: unknown): boolean {
  if (!(problem instanceof ApiProblem)) return false;
  return (
    problem.status === 0 ||
    problem.status >= 500 ||
    problem.status === 408 ||
    problem.status === 429 ||
    problem.code === "idempotency_in_progress"
  );
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
export function useTransactionActions({
  currency,
  openEdit,
  report,
  onRestored,
}: TransactionActionsDeps) {
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
    onRestored?.(tx.id);
    try {
      await restore.mutateAsync({ transaction: tx });
      feedback("undo");
      toast.show({ message: t("restored", { name: tx.name }) });
    } catch (problem) {
      fail(problem);
    }
  }

  /**
   * Creates; the key is the sheet's (one per opening), so a repeated save is one transaction.
   * When it fails on the way (offline, a timeout, a server error), the error toast stays with
   * "Reintentar", which sends the same input with the same key: what was typed is kept, and if
   * the first try did reach the server, the retry gets its answer instead of a second one.
   */
  async function createOne(
    input: NewTransaction,
    idempotencyKey: string,
    details: { kind: Kind; categoryName: string; unnamed: boolean },
  ) {
    try {
      const created = await create.mutateAsync({ input, idempotencyKey });
      const month = monthOf(created.date);
      const after = qc.getQueryData<MonthSummary>(queryKeys.summary(month));
      feedback(feedbackForSave(after, created.categoryId, details.kind));
      report({
        kind: "saved",
        categoryId: created.categoryId,
        amount: created.amount,
        name: created.name,
        month,
      });
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
      if (!canRetry(problem)) {
        fail(problem);
        return;
      }
      toast.show({
        tone: "error",
        message: problemMessage(problem as ApiProblem, tRoot),
        persistent: true,
        actions: [
          {
            label: t("retry"),
            onClick: () => void createOne(input, idempotencyKey, details),
          },
        ],
      });
    }
  }

  return {
    create: createOne,

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
      feedback("delete");
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
      report({ kind: "paid", categoryId: tx.categoryId, amount: tx.amount, name: tx.name, month });
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
 * How many category chips show before "Más": two rows of four ("Más" being the eighth), or one
 * row on a short screen.
 */
export const VISIBLE_CHIPS = { rows2: 7, rows1: 3 } as const;

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
  /** How many category chips show before "Más" (the selected one always among them). */
  visibleChips?: number;
}

/** The add/edit sheet's state, its choices (categories, shortcuts) and what saving would send. */
export function useTransactionForm({
  editing,
  categoryId: initialCategory,
  timezone,
  currency,
  visibleChips = VISIBLE_CHIPS.rows2,
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
  // The name was typed in or picked: it is no longer the movement's own, untouched one.
  const [nameTouched, setNameTouched] = useState(false);
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
    recent.data ?? [],
  );
  // New transactions only go in active categories; an edited one keeps offering its own, even
  // archived (first, so it shows among the visible chips).
  const ofKind =
    editingCategory?.archived && editingCategory.kind === kind
      ? [editingCategory, ...active]
      : active;
  const selected =
    (categoryId && ofKind.find((c) => c.id === categoryId)) || ofKind[0] || undefined;
  // An edited transaction whose name is just its category's shows the name as the placeholder,
  // until the field is first edited: typing the category's name and more keeps every letter.
  const nameShown =
    editing && !nameTouched && editingCategory && name === editingCategory.name && !picked
      ? ""
      : name;

  let chips = ofKind;
  const overflow = ofKind.length > visibleChips + 1;
  if (overflow && !allChips) {
    chips = ofKind.slice(0, visibleChips);
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
      setNameTouched(true);
      if (next !== picked) setPicked(null);
    },
    pick(s: NameChoice) {
      setName(s.name);
      setNameTouched(true);
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
