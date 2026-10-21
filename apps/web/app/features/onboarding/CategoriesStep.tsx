import type { CategoryKind } from "@lukas/core";
import { type ReactNode, useId, useState } from "react";
import { useTranslations } from "use-intl";
import { CategoryChip } from "../../ui/CategoryChip.tsx";
import { cx } from "../../ui/cx.ts";
import { PressButton } from "../../ui/PressButton.tsx";
import { type CategoryRemoval, CategorySheet, type NewCategory } from "./CategorySheet.tsx";
import type { CategoryChipModel } from "./category-chips.ts";
import { StepError, StepFrame, type StepNavProps, useStepActions } from "./StepFrame.tsx";

export interface CategoriesStepProps extends StepNavProps {
  /** Their categories first (after an import, the file's), then the suggestions not covered. */
  chips: CategoryChipModel[];
  /** Chip ids that are chosen. */
  selected: ReadonlySet<string>;
  onToggle(chipId: string): void;
  onCreate(category: NewCategory): Promise<void>;
  onEdit(chipId: string, category: NewCategory): Promise<void>;
  /** Deletes (archives) or archives a category; a suggestion just leaves the step. */
  onRemove(chipId: string): Promise<void>;
  /** How many transactions a chip's category has (decides delete or archive). */
  transactionsOf(chipId: string): Promise<{ count: number; capped: boolean }>;
  errorText(problem: unknown): string;
  error?: string | null;
}

type SheetState =
  | { mode: "closed" }
  | { mode: "add" }
  | { mode: "edit"; chip: CategoryChipModel; removal: CategoryRemoval };

/**
 * The categories: their own first, then the suggestions they don't cover, spending apart from
 * income. Tapping a chip chooses or drops it (with no categories yet, the suggestions come
 * pre-selected; SIGUIENTE works with no input). "Editar categorías" turns the chips into edit
 * buttons: rename, emoji, tint, kind, and delete (archive with transactions). "＋ Agregar
 * categoría" makes a new one.
 */
export function CategoriesStep({
  chips,
  selected,
  onToggle,
  onCreate,
  onEdit,
  onRemove,
  transactionsOf,
  errorText,
  error,
  ...nav
}: CategoriesStepProps) {
  const t = useTranslations("onboarding");
  const { skip, next } = useStepActions(nav);
  const [editing, setEditing] = useState(false);
  const [sheet, setSheet] = useState<SheetState>({ mode: "closed" });
  const [opened, setOpened] = useState(0);

  function openEdit(chip: CategoryChipModel) {
    setOpened((n) => n + 1);
    setSheet({ mode: "edit", chip, removal: { kind: "counting" } });
    const remove = () => onRemove(chip.id);
    transactionsOf(chip.id).then(
      ({ count, capped }) =>
        setSheet((current) =>
          current.mode === "edit" && current.chip.id === chip.id
            ? {
                ...current,
                removal:
                  count === 0
                    ? { kind: "delete", onRemove: remove }
                    : { kind: "archive", count, capped, onRemove: remove },
              }
            : current,
        ),
      // Not knowing the count, only archiving is safe.
      () =>
        setSheet((current) =>
          current.mode === "edit" && current.chip.id === chip.id
            ? { ...current, removal: { kind: "archive", count: 0, capped: true, onRemove: remove } }
            : current,
        ),
    );
  }

  const group = (kind: CategoryKind, label: string) => (
    <ChipGroup label={label}>
      {chips
        .filter((c) => c.kind === kind)
        .map((c) =>
          editing ? (
            <button
              key={c.id}
              type="button"
              aria-label={t("categories.edit_label", { name: c.name })}
              onClick={() => openEdit(c)}
              className="lk-chip lk-chip-button min-h-11 min-w-11"
            >
              <span
                className="lk-chip-tile border-dashed"
                aria-hidden="true"
                style={{ background: `color-mix(in srgb, ${c.tint} 35%, var(--surface-row))` }}
              >
                {c.glyph}
              </span>
              <span className="max-w-full truncate">{c.name}</span>
            </button>
          ) : (
            <CategoryChip
              key={c.id}
              glyph={c.glyph}
              label={c.name}
              selected={selected.has(c.id)}
              onSelect={() => onToggle(c.id)}
            />
          ),
        )}
    </ChipGroup>
  );

  return (
    <StepFrame
      step="categories"
      title={t("categories.title")}
      lead={t("categories.lead")}
      onBack={nav.onBack}
      skip={skip}
      next={next}
    >
      <div className="flex items-center justify-between gap-(--space-2)">
        <p className={cx("text-[15px] text-ink-muted", !editing && "sr-only")} aria-live="polite">
          {editing ? t("categories.edit_hint") : ""}
        </p>
        <PressButton
          variant="ghost"
          size="sm"
          aria-pressed={editing}
          onClick={() => setEditing((on) => !on)}
        >
          {editing ? t("categories.edit_done") : t("categories.edit_toggle")}
        </PressButton>
      </div>
      {group("expense", t("categories.expenses"))}
      {group("income", t("categories.income"))}
      <PressButton
        variant="secondary"
        className="w-full"
        onClick={() => {
          setOpened((n) => n + 1);
          setSheet({ mode: "add" });
        }}
      >
        <span aria-hidden="true">＋</span>
        {t("categories.add")}
      </PressButton>
      {error && <StepError>{error}</StepError>}
      <CategorySheet
        key={opened}
        open={sheet.mode !== "closed"}
        onClose={() => setSheet({ mode: "closed" })}
        initial={
          sheet.mode === "edit"
            ? {
                name: sheet.chip.name,
                glyph: sheet.chip.glyph,
                tint: sheet.chip.tint,
                kind: sheet.chip.kind,
              }
            : undefined
        }
        removal={sheet.mode === "edit" ? sheet.removal : undefined}
        onSave={(values) =>
          sheet.mode === "edit" ? onEdit(sheet.chip.id, values) : onCreate(values)
        }
        errorText={errorText}
      />
    </StepFrame>
  );
}

function ChipGroup({ label, children }: { label: string; children: ReactNode }) {
  const id = useId();
  return (
    <div role="group" aria-labelledby={id} className="flex flex-col gap-(--space-2)">
      <h2 id={id} className="font-display text-[18px] font-bold text-ink">
        {label}
      </h2>
      <div className="lk-chips">{children}</div>
    </div>
  );
}
