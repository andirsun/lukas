import type { CategoryKind } from "@lukas/core";
import type { Locale } from "../../i18n/format.ts";
import { categoryLook } from "../../ui/category-look.ts";
import {
  normalizeName,
  SUGGESTED_CATEGORIES,
  suggestionFor,
  suggestionName,
} from "./suggested-categories.ts";

/** A chip in the categories step: one of the person's categories, or a suggestion not made yet. */
export interface CategoryChipModel {
  /** The category's id, or `s:<key>` for a suggestion. */
  id: string;
  source: "category" | "suggestion";
  name: string;
  glyph: string;
  tint: string;
  kind: CategoryKind;
  /** For a suggestion: its key. */
  suggestionKey?: string;
}

interface ServerCategory {
  id: string;
  name: string;
  kind: CategoryKind;
  icon: string;
  color: string;
  archived: boolean;
}

export const suggestionChipId = (key: string) => `s:${key}`;

/**
 * The categories step's chips, in order: the person's active categories first (after an import,
 * the file's), then the suggestions none of them covers yet. Names are compared without case or
 * accents, in either language, so an imported "supermercado" or "Groceries" covers "Supermercado"
 * and no duplicate shows. Archived categories don't count: their suggestion can come back.
 */
export function categoryChips(categories: ServerCategory[], locale: Locale): CategoryChipModel[] {
  const active = categories.filter((c) => !c.archived);
  const own: CategoryChipModel[] = active.map((c) => ({
    id: c.id,
    source: "category",
    name: c.name,
    kind: c.kind,
    ...categoryLook(c),
  }));
  const names = new Set(active.map((c) => normalizeName(c.name)));
  const covered = new Set(active.map((c) => suggestionFor(c.name)?.key).filter(Boolean));
  const suggested: CategoryChipModel[] = SUGGESTED_CATEGORIES.filter(
    (s) => !covered.has(s.key) && !names.has(normalizeName(suggestionName(s, locale))),
  ).map((s) => ({
    id: suggestionChipId(s.key),
    source: "suggestion",
    name: suggestionName(s, locale),
    glyph: s.glyph,
    tint: s.tint,
    kind: s.kind,
    suggestionKey: s.key,
  }));
  return [...own, ...suggested];
}
