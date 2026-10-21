import { useState } from "react";
import { useApi } from "../../api/ApiProvider.tsx";
import type { Locale } from "../../i18n/format.ts";
import type { NewCategory } from "./CategorySheet.tsx";
import { type CategoryChipModel, categoryChips, suggestionChipId } from "./category-chips.ts";
import {
  applyCategorySelection,
  archiveCategory,
  type Category,
  type CategoryEdit,
  countCategoryTransactions,
  dataOf,
  saveCategoryEdit,
} from "./onboarding-api.ts";
import type { OnboardingDraft } from "./onboarding-draft.ts";
import { SUGGESTED_CATEGORIES } from "./suggested-categories.ts";

export interface CategoriesStepDeps {
  /** The person's active categories (as `useCategories` has them); undefined while loading. */
  categories: Category[] | undefined;
  draft: OnboardingDraft | null;
  updateDraft(patch: OnboardingDraft): void;
  locale: Locale;
  /** The categories, refetched (throws when the read fails). */
  refreshCategories(): Promise<Category[]>;
}

/**
 * The categories step's chips, choice and writes. The chips are the person's categories first
 * (after an import, the file's) and then the suggestions they don't cover; with no categories at
 * all the suggestions come pre-selected, otherwise only what they have is. The choice and the
 * suggestions they removed live in the session draft, so a reload keeps them.
 */
export function useCategoriesStep({
  categories,
  draft,
  updateDraft,
  locale,
  refreshCategories,
}: CategoriesStepDeps) {
  const api = useApi();
  const [selected, setSelected] = useState<Set<string> | null>(null);

  const hidden = new Set(draft?.hiddenSuggestions ?? []);
  const chips: CategoryChipModel[] = categories
    ? categoryChips(categories, locale).filter(
        (c) => c.source === "category" || !hidden.has(c.suggestionKey ?? ""),
      )
    : [];

  if (selected === null && categories && draft) {
    const fresh = categories.length === 0 && !draft.categoriesDone;
    setSelected(
      new Set(
        draft.selected ??
          (fresh
            ? SUGGESTED_CATEGORIES.map((s) => suggestionChipId(s.key))
            : categories.map((c) => c.id)),
      ),
    );
  }

  const choose = (next: Set<string>) => {
    setSelected(next);
    updateDraft({ selected: [...next] });
  };
  const current = () => selected ?? new Set<string>();
  const replace = (from: string, to: string) => {
    const next = new Set(current());
    next.delete(from);
    next.add(to);
    choose(next);
  };
  const byId = (id: string) => categories?.find((c) => c.id === id);

  return {
    chips,
    selected,
    toggle(id: string) {
      const next = new Set(current());
      if (next.has(id)) next.delete(id);
      else next.add(id);
      choose(next);
    },

    /** "＋ Agregar categoría": made right away, and chosen. */
    async create(category: NewCategory) {
      const created = dataOf(
        await api.POST("/v1/categories", {
          body: {
            name: category.name,
            kind: category.kind,
            icon: category.glyph,
            color: category.tint,
          },
        }),
      );
      choose(new Set([...current(), created.id]));
      // The sheet closes once it is saved; the chip shows when the list comes back.
      void refreshCategories().catch(() => {});
    },

    /** How many transactions a chip's category has (a suggestion has none). */
    async transactionsOf(chipId: string) {
      const chip = chips.find((c) => c.id === chipId);
      if (!chip || chip.source === "suggestion") return { count: 0, capped: false };
      return countCategoryTransactions(api, chipId);
    },

    /**
     * Saves an edit. A suggestion is made right away with the edited values; one of their
     * categories is changed (and, for a new kind, made again: its id changes).
     */
    async edit(chipId: string, values: CategoryEdit) {
      const chip = chips.find((c) => c.id === chipId);
      if (!chip) return;
      if (chip.source === "suggestion") {
        const created = dataOf(
          await api.POST("/v1/categories", {
            body: { name: values.name, kind: values.kind, icon: values.glyph, color: values.tint },
          }),
        );
        replace(chipId, created.id);
      } else {
        const category = byId(chipId);
        if (!category) return;
        const saved = await saveCategoryEdit(api, category, values);
        if (saved.id !== chipId) replace(chipId, saved.id);
      }
      await refreshCategories();
    },

    /**
     * "Eliminar" (no transactions) or "Archivar": one of their categories is archived (the API has
     * no hard delete); a suggestion not made yet just leaves the step for this session.
     */
    async remove(chipId: string) {
      const chip = chips.find((c) => c.id === chipId);
      if (!chip) return;
      const next = new Set(current());
      next.delete(chipId);
      choose(next);
      if (chip.source === "suggestion") {
        updateDraft({ hiddenSuggestions: [...hidden, chip.suggestionKey ?? ""] });
        return;
      }
      await archiveCategory(api, chipId);
      await refreshCategories();
    },

    /** SIGUIENTE: makes the chosen suggestions, archives the deselected categories. */
    async save() {
      await applyCategorySelection(api, chips, current(), locale, { archive: true });
      await refreshCategories();
      updateDraft({ categoriesDone: true });
    },

    /** SALTAR: makes the chosen suggestions and never takes anything away. */
    async skip() {
      await applyCategorySelection(api, chips, current(), locale, { archive: false });
      await refreshCategories();
      updateDraft({ categoriesDone: true });
    },

    /** After an import: what it brought is chosen; the suggestions it doesn't cover are not. */
    imported(after: Category[]) {
      choose(new Set(after.filter((c) => !c.archived).map((c) => c.id)));
    },
  };
}
