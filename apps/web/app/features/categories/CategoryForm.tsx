import type { CategoryKind } from "@lukas/core";
import { type FormEvent, useId, useState } from "react";
import { useTranslations } from "use-intl";
import { CATEGORY_GLYPHS, CATEGORY_TINTS } from "../../ui/category-look.ts";
import { cx } from "../../ui/cx.ts";
import { PressButton } from "../../ui/PressButton.tsx";
import { Sheet } from "../../ui/Sheet.tsx";

export interface NewCategory {
  name: string;
  /** Emoji, saved as the category's `icon`. */
  glyph: string;
  /** Hex color, saved as `color`. */
  tint: string;
  kind: CategoryKind;
}

/**
 * What the sheet offers besides saving, when editing: deleting (no transactions; the API archives),
 * archiving (it has transactions, so it can't go), or nothing yet while they are counted.
 */
export type CategoryRemoval =
  | { kind: "counting" }
  | { kind: "delete"; onRemove(): Promise<void> }
  | { kind: "archive"; count: number; capped: boolean; onRemove(): Promise<void> }
  /** The count failed: only archiving is safe. */
  | { kind: "unknown"; onRemove(): Promise<void> };

export interface CategoryFormProps {
  open: boolean;
  onClose(): void;
  /** Editing an existing category (or a suggestion) rather than adding one. */
  initial?: NewCategory | undefined;
  /** Saves; a rejection (e.g. the name is taken) is shown in the sheet, which stays open. */
  onSave(category: NewCategory): Promise<void>;
  /** Editing only: delete or archive, once the transactions are counted. */
  removal?: CategoryRemoval | undefined;
  /** Turns a failure into the text to show. */
  errorText(problem: unknown): string;
  /**
   * Home's Categorías tab and the detail: the kind is fixed (it has transactions, or they are being counted), with
   * the line saying why when `true`. Onboarding derives this from `removal` instead.
   */
  kindLocked?: boolean | "counting" | undefined;
  /** A category's detail: "Archivar categoría", which asks for confirmation elsewhere. */
  onArchive?: (() => void) | undefined;
}

const DEFAULT: NewCategory = {
  name: "",
  glyph: CATEGORY_GLYPHS[0],
  tint: CATEGORY_TINTS[0]?.value ?? "#8e87b8",
  kind: "expense",
};

/** The radio look: a tile that sits on its edge, outlined in gold when chosen. */
const OPTION =
  "flex min-h-11 min-w-11 cursor-pointer items-center justify-center rounded-md border-2 border-stroke shadow-edge-sm has-checked:outline-3 has-checked:outline-gold has-checked:outline-offset-1 has-focus-visible:outline-3 has-focus-visible:outline-focus has-focus-visible:outline-offset-2 has-disabled:cursor-not-allowed has-disabled:opacity-60";

/**
 * A category's sheet: "＋ Agregar categoría", or editing one (from onboarding's categories step,
 * or a category's detail; "Nueva categoría" on home's Categorías tab). Name,
 * spending or income, an emoji and a tint, each a native radio group (the tints named for screen
 * readers). Editing adds "Eliminar categoría" when it has no transactions; with transactions it says
 * how many, offers "Archivar" instead, and its kind can't change here. Mount it with a `key` per
 * category, so its fields start from `initial`.
 */
export function CategoryForm({
  open,
  onClose,
  initial,
  onSave,
  removal,
  errorText,
  kindLocked: lockedHere,
  onArchive,
}: CategoryFormProps) {
  const t = useTranslations("onboarding.categories");
  const nameId = useId();
  const errorId = useId();
  const editing = initial !== undefined;
  const [values, setValues] = useState<NewCategory>(() => initial ?? DEFAULT);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const kindLocked =
    Boolean(lockedHere) ||
    removal?.kind === "archive" ||
    removal?.kind === "counting" ||
    removal?.kind === "unknown";
  const sayKindLocked =
    lockedHere === true || removal?.kind === "archive" || removal?.kind === "unknown";
  const set = (patch: Partial<NewCategory>) => setValues((current) => ({ ...current, ...patch }));

  const close = () => {
    setValues(initial ?? DEFAULT);
    setError(null);
    onClose();
  };

  async function act(write: () => Promise<void>) {
    if (saving) return;
    setSaving(true);
    setError(null);
    try {
      await write();
      close();
    } catch (problem) {
      setError(errorText(problem));
    } finally {
      setSaving(false);
    }
  }

  function submit(event: FormEvent) {
    event.preventDefault();
    const name = values.name.trim();
    if (!name) {
      setError(t("name_required"));
      return;
    }
    void act(() => onSave({ ...values, name }));
  }

  return (
    <Sheet open={open} onClose={close} title={editing ? t("edit_title") : t("add_title")}>
      <form noValidate onSubmit={submit} className="flex flex-col gap-(--space-4) pt-(--space-3)">
        <div className="flex flex-col gap-(--space-1)">
          <label htmlFor={nameId} className="text-[15px] text-ink-muted">
            {t("name_label")}
          </label>
          <div className={cx("lk-input min-h-11", error && !values.name.trim() && "border-over")}>
            <input
              id={nameId}
              value={values.name}
              maxLength={40}
              autoComplete="off"
              placeholder={t("name_placeholder")}
              aria-invalid={(error !== null && !values.name.trim()) || undefined}
              aria-describedby={error ? errorId : undefined}
              onChange={(event) => set({ name: event.target.value })}
              className="min-h-9 min-w-0 flex-1 border-0 bg-transparent p-0 font-text text-[16px] text-ink outline-none placeholder:font-normal placeholder:text-ink-muted"
            />
          </div>
        </div>

        <fieldset className="flex flex-col gap-(--space-2)" disabled={kindLocked}>
          <legend className="pb-(--space-1) text-[15px] text-ink-muted">{t("kind_label")}</legend>
          <div className="grid grid-cols-2 gap-(--space-2)">
            {(["expense", "income"] as const).map((value) => (
              <label key={value} className={cx(OPTION, "bg-surface-row px-(--space-3) text-ink")}>
                <input
                  type="radio"
                  name="kind"
                  value={value}
                  checked={values.kind === value}
                  onChange={() => set({ kind: value })}
                  className="sr-only"
                />
                {value === "expense" ? t("kind_expense") : t("kind_income")}
              </label>
            ))}
          </div>
          {sayKindLocked && <p className="text-[15px] text-ink-muted">{t("kind_locked")}</p>}
        </fieldset>

        <fieldset className="flex flex-col gap-(--space-2)">
          <legend className="pb-(--space-1) text-[15px] text-ink-muted">{t("glyph_label")}</legend>
          <div className="grid grid-cols-5 gap-(--space-2)">
            {[...new Set([values.glyph, ...CATEGORY_GLYPHS])].map((value) => (
              <label key={value} className={cx(OPTION, "bg-surface-row text-[22px]")}>
                <input
                  type="radio"
                  name="glyph"
                  value={value}
                  aria-label={value}
                  checked={values.glyph === value}
                  onChange={() => set({ glyph: value })}
                  className="sr-only"
                />
                <span aria-hidden="true">{value}</span>
              </label>
            ))}
          </div>
        </fieldset>

        <fieldset className="flex flex-col gap-(--space-2)">
          <legend className="pb-(--space-1) text-[15px] text-ink-muted">{t("tint_label")}</legend>
          <div className="grid grid-cols-6 gap-(--space-2)">
            {CATEGORY_TINTS.map(({ name, value }) => (
              <label
                key={name}
                className={OPTION}
                style={{ background: `color-mix(in srgb, ${value} 70%, var(--surface-sunken))` }}
              >
                <input
                  type="radio"
                  name="tint"
                  value={value}
                  aria-label={t(`tints.${name}`)}
                  checked={values.tint === value}
                  onChange={() => set({ tint: value })}
                  className="sr-only"
                />
              </label>
            ))}
          </div>
        </fieldset>

        {error && (
          <p id={errorId} role="alert" className="text-[15px] text-over">
            {error}
          </p>
        )}
        <PressButton type="submit" className="w-full" disabled={saving}>
          {t("save")}
        </PressButton>

        {onArchive && (
          <PressButton
            variant="ghost"
            className="self-center text-over"
            disabled={saving}
            onClick={onArchive}
          >
            {t("archive")}
          </PressButton>
        )}
        {removal?.kind === "counting" && (
          <p role="status" className="text-[15px] text-ink-muted">
            {t("counting")}
          </p>
        )}
        {removal?.kind === "delete" && (
          <PressButton
            variant="ghost"
            className="self-center text-over"
            disabled={saving}
            onClick={() => void act(removal.onRemove)}
          >
            {t("delete")}
          </PressButton>
        )}
        {(removal?.kind === "archive" || removal?.kind === "unknown") && (
          <div className="flex flex-col gap-(--space-2)">
            <p className="text-[15px] text-ink">
              {removal.kind === "unknown"
                ? t("count_failed")
                : removal.capped
                  ? t("has_many_transactions", { count: removal.count })
                  : t("has_transactions", { count: removal.count })}
            </p>
            <PressButton
              variant="secondary"
              disabled={saving}
              onClick={() => void act(removal.onRemove)}
            >
              {t("archive")}
            </PressButton>
          </div>
        )}
      </form>
    </Sheet>
  );
}
