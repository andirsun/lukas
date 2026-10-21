import type { paths } from "../../api/schema";

/** An import as the API returns it (preview or confirmed). */
export type ImportDto =
  paths["/v1/imports"]["post"]["responses"][201]["content"]["application/json"];

/**
 * What happened with the file's currency. `switched`: the account was still empty and now uses the
 * file's currency (`account` is the one it had before, to put back if the file is dropped).
 * `locked`: the account already has transactions in `account`, so the file's rows are rejected.
 */
export type CurrencyNote = { kind: "switched" | "locked"; file: string; account: string } | null;

/** The import step, from no file to a confirmed import. */
export type ImportState =
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
