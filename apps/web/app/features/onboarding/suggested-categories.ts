import type { CategoryKind } from "@lukas/core";
import type { Locale } from "../../i18n/format.ts";

export interface SuggestedCategory {
  /** Stable id of the suggestion (not stored anywhere). */
  key: string;
  /** Emoji: saved as the category's `icon`. */
  glyph: string;
  /** Mid-tone color, mixed into the tile's surface so it reads in night and day: saved as `color`. */
  tint: string;
  kind: CategoryKind;
  /** The category's name in each language; the person's language decides which one is created. */
  names: Record<Locale, string>;
}

/** The onboarding's suggestions (spec §2.4). The names match the Budge import's usual categories. */
export const SUGGESTED_CATEGORIES: readonly SuggestedCategory[] = [
  {
    key: "groceries",
    glyph: "🛒",
    tint: "#ff9f1c",
    kind: "expense",
    names: { es: "Supermercado", en: "Groceries", it: "Supermercato", pt: "Supermercado" },
  },
  {
    key: "eating_out",
    glyph: "🍽️",
    tint: "#ff5c7a",
    kind: "expense",
    names: { es: "Restaurante", en: "Eating out", it: "Ristorante", pt: "Restaurante" },
  },
  {
    key: "home",
    glyph: "🏠",
    tint: "#6d6bff",
    kind: "expense",
    names: { es: "Casa", en: "Home", it: "Casa", pt: "Casa" },
  },
  {
    key: "transport",
    glyph: "🚗",
    tint: "#3fa7ff",
    kind: "expense",
    names: { es: "Transporte", en: "Transport", it: "Trasporti", pt: "Transportes" },
  },
  {
    key: "fun",
    glyph: "⭐",
    tint: "#a66bff",
    kind: "expense",
    names: { es: "Ocio", en: "Fun", it: "Tempo libero", pt: "Lazer" },
  },
  {
    key: "subscriptions",
    glyph: "☂️",
    tint: "#ff8fd8",
    kind: "expense",
    names: { es: "Suscripciones", en: "Subscriptions", it: "Abbonamenti", pt: "Subscrições" },
  },
  {
    key: "health",
    glyph: "❤️",
    tint: "#ffb547",
    kind: "expense",
    names: { es: "Vida", en: "Health", it: "Salute", pt: "Saúde" },
  },
  {
    key: "salary",
    glyph: "💰",
    tint: "#2fd388",
    kind: "income",
    names: { es: "Salario", en: "Salary", it: "Stipendio", pt: "Salário" },
  },
];

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
