import type { paths } from "../../api/schema";

/** An import as the API returns it (preview or confirmed). */
export type ImportDto =
  paths["/v1/imports"]["post"]["responses"][201]["content"]["application/json"];

/**
 * What the import does with the file's currency, from the preview's stats. `switching`: the
 * account is still empty, so confirming switches it to the file's currency (the API does it in the
 * same transaction as the inserts; `dropsBudgets` when budgets in the old one go with it).
 * `switched`: it did. `locked`: the account already has transactions in `account`, so the file's
 * rows are rejected. Nothing changes the currency before the confirm.
 */
export type CurrencyNote = {
  kind: "switching" | "switched" | "locked";
  file: string;
  account: string;
  dropsBudgets?: boolean;
} | null;

/**
 * The import step: the list of sources, then (Budge) the how-to with the file picker (`idle`), from
 * there to a confirmed import.
 */
export type ImportState =
  | { phase: "sources" }
  | { phase: "idle"; error?: string | null }
  | { phase: "reading"; fileName: string }
  | {
      phase: "preview";
      fileName: string;
      preview: ImportDto;
      currencyNote: CurrencyNote;
      confirming: boolean;
      discarding?: boolean;
      error?: string | null;
    }
  | {
      phase: "imported";
      result: ImportDto;
      prefilled: boolean;
      currencyNote: CurrencyNote;
      /** The import went in, but reading the categories again failed: offer a retry. */
      error?: string | null;
      retrying?: boolean;
    };

/** Rows the import will add: the file's rows minus those already there. */
export const newRows = (preview: ImportDto) =>
  Math.max(preview.stats.transactions - preview.stats.duplicates, 0);
