import type { CategoryKind } from "@lukas/core";
import { type FormEvent, useId, useState } from "react";
import { useTranslations } from "use-intl";
import { CATEGORY_GLYPHS, CATEGORY_TINTS } from "../../ui/category-look.ts";
import { cx } from "../../ui/cx.ts";
import { PressButton } from "../../ui/PressButton.tsx";
import { Sheet } from "../../ui/Sheet.tsx";
import { StepError } from "./StepFrame.tsx";

export interface NewCategory {
  name: string;
  /** Emoji, saved as the category's `icon`. */
  glyph: string;
  /** Hex color, saved as `color`. */
  tint: string;
  kind: CategoryKind;
}

export interface AddCategorySheetProps {
  open: boolean;
  onClose(): void;
  /** Creates it; a rejection (e.g. the name is taken) is shown in the sheet, which stays open. */
  onSave(category: NewCategory): Promise<void>;
  /** Turns a failure into the text to show. */
  errorText(problem: unknown): string;
}

const DEFAULT_GLYPH = CATEGORY_GLYPHS[0];
const DEFAULT_TINT = CATEGORY_TINTS[0]?.value ?? "#8e87b8";

/** The radio look: a tile that sits on its edge, outlined in gold when chosen. */
const OPTION =
  "flex min-h-11 min-w-11 cursor-pointer items-center justify-center rounded-md border-2 border-stroke shadow-edge-sm has-checked:outline-3 has-checked:outline-gold has-checked:outline-offset-1 has-focus-visible:outline-3 has-focus-visible:outline-focus has-focus-visible:outline-offset-2";

/**
 * "＋ Agregar categoría": a bottom sheet with the name, spending or income, an emoji and a tint.
 * Every choice is a native radio (arrow keys move within a group); the tints are named for screen
 * readers. Saving creates the category right away through the categories API.
 */
export function AddCategorySheet({ open, onClose, onSave, errorText }: AddCategorySheetProps) {
  const t = useTranslations("onboarding.categories");
  const nameId = useId();
  const errorId = useId();
  const [name, setName] = useState("");
  const [kind, setKind] = useState<CategoryKind>("expense");
  const [glyph, setGlyph] = useState<string>(DEFAULT_GLYPH);
  const [tint, setTint] = useState(DEFAULT_TINT);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const close = () => {
    setName("");
    setKind("expense");
    setGlyph(DEFAULT_GLYPH);
    setTint(DEFAULT_TINT);
    setError(null);
    onClose();
  };

  async function submit(event: FormEvent) {
    event.preventDefault();
    if (saving) return;
    const trimmed = name.trim();
    if (!trimmed) {
      setError(t("name_required"));
      return;
    }
    setSaving(true);
    setError(null);
    try {
      await onSave({ name: trimmed, glyph, tint, kind });
      close();
    } catch (problem) {
      setError(errorText(problem));
    } finally {
      setSaving(false);
    }
  }

  return (
    <Sheet open={open} onClose={close} title={t("add_title")}>
      <form noValidate onSubmit={submit} className="flex flex-col gap-(--space-4) pt-(--space-3)">
        <div className="flex flex-col gap-(--space-1)">
          <label htmlFor={nameId} className="text-[15px] text-ink-muted">
            {t("name_label")}
          </label>
          <div className={cx("lk-input min-h-11", error && !name.trim() && "border-over")}>
            <input
              id={nameId}
              value={name}
              maxLength={40}
              autoComplete="off"
              placeholder={t("name_placeholder")}
              aria-invalid={(error !== null && !name.trim()) || undefined}
              aria-describedby={error ? errorId : undefined}
              onChange={(event) => setName(event.target.value)}
              className="min-h-9 min-w-0 flex-1 border-0 bg-transparent p-0 font-text text-[16px] text-ink outline-none placeholder:font-normal placeholder:text-ink-muted"
            />
          </div>
        </div>

        <fieldset className="flex flex-col gap-(--space-2)">
          <legend className="pb-(--space-1) text-[15px] text-ink-muted">{t("kind_label")}</legend>
          <div className="grid grid-cols-2 gap-(--space-2)">
            {(["expense", "income"] as const).map((value) => (
              <label key={value} className={cx(OPTION, "bg-surface-row px-(--space-3) text-ink")}>
                <input
                  type="radio"
                  name="kind"
                  value={value}
                  checked={kind === value}
                  onChange={() => setKind(value)}
                  className="sr-only"
                />
                {value === "expense" ? t("kind_expense") : t("kind_income")}
              </label>
            ))}
          </div>
        </fieldset>

        <fieldset className="flex flex-col gap-(--space-2)">
          <legend className="pb-(--space-1) text-[15px] text-ink-muted">{t("glyph_label")}</legend>
          <div className="grid grid-cols-5 gap-(--space-2)">
            {CATEGORY_GLYPHS.map((value) => (
              <label key={value} className={cx(OPTION, "bg-surface-row text-[22px]")}>
                <input
                  type="radio"
                  name="glyph"
                  value={value}
                  aria-label={value}
                  checked={glyph === value}
                  onChange={() => setGlyph(value)}
                  className="sr-only"
                />
                <span aria-hidden="true">{value}</span>
              </label>
            ))}
          </div>
        </fieldset>

        <fieldset className="flex flex-col gap-(--space-2)">
          <legend className="pb-(--space-1) text-[15px] text-ink-muted">{t("tint_label")}</legend>
          <div className="grid grid-cols-5 gap-(--space-2)">
            {CATEGORY_TINTS.map(({ name: tintName, value }) => (
              <label
                key={tintName}
                className={OPTION}
                style={{ background: `color-mix(in srgb, ${value} 70%, var(--surface-sunken))` }}
              >
                <input
                  type="radio"
                  name="tint"
                  value={value}
                  aria-label={t(`tints.${tintName}`)}
                  checked={tint === value}
                  onChange={() => setTint(value)}
                  className="sr-only"
                />
              </label>
            ))}
          </div>
        </fieldset>

        {error && <StepError id={errorId}>{error}</StepError>}
        <PressButton type="submit" className="w-full" disabled={saving}>
          {t("save")}
        </PressButton>
      </form>
    </Sheet>
  );
}
