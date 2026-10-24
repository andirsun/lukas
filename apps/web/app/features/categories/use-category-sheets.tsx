import { type CategoryDto, type RecurrenceDto, todayIn } from "@lukas/core";
import { useQuery } from "@tanstack/react-query";
import { type ReactNode, useState } from "react";
import { useTranslations } from "use-intl";
import { useApi } from "../../api/ApiProvider.tsx";
import { ApiProblem, problemMessage, type Translator } from "../../api/errors.ts";
import { useCreateCategory, useMe, useRecurrences, useUpdateCategory } from "../../api/queries.ts";
import { ConfirmSheet } from "../../ui/ConfirmSheet.tsx";
import { categoryLook } from "../../ui/category-look.ts";
import { useToast } from "../../ui/Toast.tsx";
import { countCategoryTransactions } from "../onboarding/onboarding-api.ts";
import { CategoryForm, type NewCategory } from "./CategoryForm.tsx";

type Target =
  | { kind: "create"; key: number }
  | { kind: "edit"; category: CategoryDto; key: number };

/**
 * Whether a category has any transaction: then its kind is fixed (the API refuses the change
 * with 409 `category_has_transactions`; this only says so up front). One page is enough to know.
 */
function useHasTransactions(categoryId: string | null) {
  const api = useApi();
  return useQuery({
    queryKey: ["transactions", "category-count", categoryId],
    queryFn: async () => (await countCategoryTransactions(api, categoryId as string, 1)).count > 0,
    enabled: categoryId !== null,
  });
}

/** The rules archiving a category stops: its own, not ended before today (the API's rule). */
export function activeRecurrencesIn(
  recurrences: readonly RecurrenceDto[],
  categoryId: string,
  today: string,
): number {
  return recurrences.filter(
    (r) => r.categoryId === categoryId && (r.endDate === null || r.endDate >= today),
  ).length;
}

/**
 * The sheets that change categories, for home's Categorías tab ("Nueva categoría", restoring an
 * archived one) and a category's detail (editing one: name, kind, emoji, tint; and archiving it,
 * which asks first in its own sheet). Restoring needs no question. Each change ends in a toast; a refusal (a name already
 * taken, say) stays in the edit sheet, and a failed archive or restore is an error toast.
 */
export function useCategorySheets() {
  const t = useTranslations("categories");
  const tRoot = useTranslations() as unknown as Translator;
  const toast = useToast();
  const create = useCreateCategory();
  const update = useUpdateCategory();
  const me = useMe().data;
  const [target, setTarget] = useState<Target | null>(null);
  const [formOpen, setFormOpen] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const editing = target?.kind === "edit" ? target.category : null;
  // Only an edit can archive: the recurrences are fetched once one is opened, not with the screen.
  const recurrences = useRecurrences({ enabled: editing !== null });
  const hasTransactions = useHasTransactions(formOpen && editing ? editing.id : null);

  const errorText = (problem: unknown) =>
    problem instanceof ApiProblem ? problemMessage(problem, tRoot) : tRoot("errors.generic");
  const fail = (problem: unknown) => {
    toast.show({ tone: "error", message: errorText(problem) });
    throw problem;
  };

  const save = async (values: NewCategory) => {
    if (!editing) {
      await create.mutateAsync({
        name: values.name,
        kind: values.kind,
        icon: values.glyph,
        color: values.tint,
      });
      toast.show({ message: t("created", { name: values.name }) });
      return;
    }
    await update.mutateAsync({
      id: editing.id,
      patch: {
        name: values.name,
        icon: values.glyph,
        color: values.tint,
        ...(values.kind !== editing.kind ? { kind: values.kind } : {}),
      },
    });
    toast.show({ message: t("saved", { name: values.name }) });
  };

  const archive = async () => {
    if (!editing) return;
    try {
      await update.mutateAsync({ id: editing.id, patch: { archived: true } });
    } catch (problem) {
      fail(problem);
    }
    toast.show({ message: t("archived_toast", { name: editing.name }) });
  };

  const initial = editing
    ? {
        name: editing.name,
        glyph: categoryLook(editing).glyph,
        tint: categoryLook(editing).tint,
        kind: editing.kind,
      }
    : undefined;

  // Archiving also ends the category's recurrences (the sheet says how many).
  const stopping =
    editing && me && recurrences.data
      ? activeRecurrencesIn(recurrences.data, editing.id, todayIn(me.timezone))
      : 0;

  const sheets: ReactNode = (
    <>
      <CategoryForm
        key={target?.key ?? 0}
        open={formOpen}
        onClose={() => setFormOpen(false)}
        initial={initial}
        onSave={save}
        errorText={errorText}
        kindLocked={
          editing ? (hasTransactions.isPending ? "counting" : hasTransactions.data === true) : false
        }
        onArchive={
          editing && !editing.archived
            ? () => {
                setFormOpen(false);
                setConfirmOpen(true);
              }
            : undefined
        }
      />
      <ConfirmSheet
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
        title={t("archive_sheet.title", { name: editing?.name ?? "" })}
        body={t("archive_sheet.body")}
        note={stopping > 0 ? t("archive_sheet.stops_recurring", { count: stopping }) : undefined}
        confirmLabel={t("archive_sheet.confirm")}
        onConfirm={archive}
      />
    </>
  );

  return {
    sheets,
    startCreate() {
      setTarget({ kind: "create", key: Date.now() });
      setFormOpen(true);
    },
    startEdit(category: CategoryDto) {
      setTarget({ kind: "edit", category, key: Date.now() });
      setFormOpen(true);
    },
    async restore(category: CategoryDto) {
      try {
        await update.mutateAsync({ id: category.id, patch: { archived: false } });
      } catch (problem) {
        toast.show({ tone: "error", message: errorText(problem) });
        return;
      }
      toast.show({ message: t("restored", { name: category.name }) });
    },
  };
}
