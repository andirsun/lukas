import { addMonths, monthOf, type SupportedCurrency, todayIn } from "@lukas/core";
import { useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { useTranslations } from "use-intl";
import { useApi } from "../../api/ApiProvider.tsx";
import { ApiProblem } from "../../api/errors.ts";
import { queryKeys } from "../../api/queries.ts";
import type { Locale } from "../../i18n/format.ts";
import { categoryLook } from "../../ui/category-look.ts";
import { draftFromCents } from "./budget-input.ts";
import { isSupportedCurrency } from "./currency.ts";
import type { CurrencyNote, ImportDto, ImportState } from "./import-state.ts";
import {
  type Category,
  dataOf,
  type Profile,
  patchCurrency,
  uploadImport,
} from "./onboarding-api.ts";
import { normalizeName } from "./suggested-categories.ts";

export interface ImportFlowDeps {
  profile: Profile;
  locale: Locale;
  /** Turns a failure into the text to show. */
  message(problem: unknown): string;
  /** The categories, refetched (throws when the read fails). */
  refreshCategories(): Promise<Category[]>;
  /** The account's currency changed for (or back from) an import. */
  onCurrency(code: SupportedCurrency): void;
  /** Budget drafts by category id, and the way to replace them. */
  drafts: Readonly<Record<string, string>>;
  setDrafts(drafts: Record<string, string>): void;
  /** The categories after an import (new ones get chosen). */
  onImported(categories: Category[]): void;
}

/**
 * The import step's state and writes: reading a Budge file (switching an empty account to the
 * file's currency, then reading it again), discarding, confirming, the follow-up refresh with its
 * prefill, and skipping. While a file is read, confirmed or discarded the step is `locked`: SALTAR
 * and Back wait, so nobody leaves (or reverts) an import halfway.
 */
export function useImportFlow(deps: ImportFlowDeps) {
  const { profile, locale, message, refreshCategories, onCurrency } = deps;
  const t = useTranslations("onboarding");
  const api = useApi();
  const queryClient = useQueryClient();
  const [state, setState] = useState<ImportState>({ phase: "sources" });

  const locked =
    state.phase === "reading" ||
    (state.phase === "preview" && (state.confirming || Boolean(state.discarding))) ||
    (state.phase === "imported" && Boolean(state.retrying));

  async function switchCurrency(code: SupportedCurrency) {
    queryClient.setQueryData(queryKeys.me(), await patchCurrency(api, code));
    onCurrency(code);
  }

  /**
   * Reads the file. The importer only takes rows in the account's currency, so when the file is in
   * another one and the account is still empty, the file wins: the account switches, the first
   * preview (made under the old currency, so with its rows rejected) is dropped and the file is
   * read again. The preview the person confirms is always one made under the final currency.
   */
  async function readFile(file: File) {
    if (locked) return;
    setState({ phase: "reading", fileName: file.name });
    try {
      let preview = await uploadImport(api, file);
      let note: CurrencyNote = null;
      const account = profile.currency;
      const fileCurrency = preview.stats.currency;
      if (fileCurrency && fileCurrency !== account) {
        note = { kind: "locked", file: fileCurrency, account };
        if (isSupportedCurrency(fileCurrency)) {
          try {
            await switchCurrency(fileCurrency);
            note = { kind: "switched", file: fileCurrency, account };
            // The stale preview is only clutter; failing to drop it changes nothing.
            await api
              .DELETE("/v1/imports/{id}", { params: { path: { id: preview.id } } })
              .catch(() => {});
            preview = await uploadImport(api, file);
          } catch (problem) {
            // Transactions already: the currency stays, and so does the preview (rows rejected).
            if (!(problem instanceof ApiProblem && problem.code === "currency_locked")) {
              throw problem;
            }
          }
        }
      }
      setState({
        phase: "preview",
        fileName: file.name,
        preview,
        currencyNote: note,
        confirming: false,
      });
    } catch (problem) {
      setState({ phase: "idle", error: message(problem) });
    }
  }

  /**
   * Drops the preview (never one being confirmed); a currency switched for it goes back to what it
   * was. True when it is gone; on failure the step says why and stays.
   */
  async function discard(): Promise<boolean> {
    if (state.phase !== "preview" || state.confirming || state.discarding) return false;
    const current = state;
    setState({ ...current, discarding: true, error: null });
    try {
      await api.DELETE("/v1/imports/{id}", { params: { path: { id: current.preview.id } } });
      const note = current.currencyNote;
      if (note?.kind === "switched" && isSupportedCurrency(note.account)) {
        await switchCurrency(note.account);
      }
      setState({ phase: "idle" });
      return true;
    } catch (problem) {
      setState({ ...current, discarding: false, error: message(problem) });
      return false;
    }
  }

  async function confirm() {
    if (state.phase !== "preview" || state.confirming || state.discarding) return;
    const current = state;
    setState({ ...current, confirming: true, error: null });
    let result: ImportDto;
    try {
      result = dataOf(
        await api.POST("/v1/imports/{id}/confirm", {
          params: { path: { id: current.preview.id } },
        }),
      );
    } catch (problem) {
      setState({ ...current, confirming: false, error: message(problem) });
      return;
    }
    // From here the rows are in: whatever happens next, the step says so (confirming again could
    // only fail), and a failed follow-up gets a retry.
    await afterImport(result, current.currencyNote);
  }

  /**
   * Refreshes what the import changed, then fills budgets from the file's recent months (the
   * preview's `averageMonthlySpending`): the empty ones, or all of them when the currency switched
   * (amounts typed in the old currency mean nothing now). Categories without spending in those
   * months keep no budget.
   */
  async function afterImport(result: ImportDto, currencyNote: CurrencyNote) {
    const imported = { phase: "imported" as const, result, currencyNote };
    setState({ ...imported, prefilled: false, retrying: true });
    try {
      // Everything built from transactions changed; so did the categories (new ones).
      void queryClient.invalidateQueries({
        predicate: (query) => query.queryKey[0] !== "me" && query.queryKey[0] !== "categories",
      });
      const categories = await refreshCategories();
      const averages = new Map(
        result.stats.averageMonthlySpending.map((a) => [normalizeName(a.category), a.amount]),
      );
      const switched = currencyNote?.kind === "switched";
      const next: Record<string, string> = { ...deps.drafts };
      let prefilled = false;
      for (const c of categories.filter((c) => c.kind === "expense" && !c.archived)) {
        const average = averages.get(normalizeName(c.name));
        const empty = !next[c.id]?.trim();
        if (average && average > 0 && (empty || switched)) {
          next[c.id] = draftFromCents(average, locale);
          prefilled = true;
        } else if (switched) {
          next[c.id] = "";
        }
      }
      deps.setDrafts(next);
      deps.onImported(categories);
      setState({ ...imported, prefilled });
    } catch (problem) {
      setState({ ...imported, prefilled: false, error: message(problem) });
    }
  }

  function retry() {
    if (state.phase === "imported" && !state.retrying) {
      void afterImport(state.result, state.currencyNote);
    }
  }

  /**
   * SALTAR: true when the step may be left. Never while locked; a pending preview is discarded
   * first, and a failed discard keeps the step (with the reason) instead of moving on.
   */
  async function skip(): Promise<boolean> {
    if (locked) return false;
    if (state.phase === "preview") return discard();
    return true;
  }

  /** "Basado en lo que gastaste en tus últimos 3 meses", or "…con movimientos" for an old export. */
  function prefillBasis(): string | null {
    if (state.phase !== "imported" || !state.prefilled) return null;
    const window = state.result.stats.averageWindow;
    if (!window) return null;
    const lastComplete = addMonths(monthOf(todayIn(profile.timezone)), -1);
    return window.to === lastComplete
      ? t("prefill_basis", { months: window.months })
      : t("prefill_basis_activity", { months: window.months });
  }

  return {
    state,
    locked,
    chooseSource: (source: "budge" | null) => setState({ phase: source ? "idle" : "sources" }),
    readFile,
    discard,
    confirm,
    retry,
    skip,
    prefillBasis,
  };
}

/** Active spending categories, as the budgets step lists them. */
export function spendingOf(categories: Category[]) {
  return categories
    .filter((c) => c.kind === "expense" && !c.archived)
    .map((c) => ({ id: c.id, name: c.name, ...categoryLook(c) }));
}
