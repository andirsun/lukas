import { SUGGESTED_CATEGORIES, type SuggestedCategory } from "@lukas/core";
import type { Locale } from "../../i18n/format.ts";

export { SUGGESTED_CATEGORIES, type SuggestedCategory };

/** A suggestion's name in a language. */
export function suggestionName(suggestion: SuggestedCategory, locale: Locale): string {
  return suggestion.names[locale];
}

/** Lowercase, without accents: how the API and the importer compare category names. */
export function normalizeName(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "");
}

/** The suggestion a category name stands for, in any language ("Salário" → salary). */
export function suggestionFor(name: string): SuggestedCategory | undefined {
  const key = normalizeName(name);
  return SUGGESTED_CATEGORIES.find((c) =>
    Object.values(c.names).some((n) => normalizeName(n) === key),
  );
}
