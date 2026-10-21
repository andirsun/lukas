import type { TransactionDto } from "@lukas/core";
import { useEffect, useId, useRef, useState } from "react";
import { useTranslations } from "use-intl";
import { formatAmountInput, formatDay, lukasHint } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { CategoryChip } from "../../ui/CategoryChip.tsx";
import { categoryLook } from "../../ui/category-look.ts";
import { cx } from "../../ui/cx.ts";
import { Keypad, typeOnKeypad } from "../../ui/Keypad.tsx";
import { NameField } from "../../ui/NameField.tsx";
import { PressButton } from "../../ui/PressButton.tsx";
import { SegmentedControl } from "../../ui/SegmentedControl.tsx";
import { Sheet } from "../../ui/Sheet.tsx";
import { useTransactionSheet } from "./TransactionSheetProvider.tsx";
import { type Kind, type NameChoice, useTransactionForm } from "./use-add-transaction.ts";

export interface AddTransactionSheetProps {
  open: boolean;
  onClose(): void;
  /** The transaction to edit; without it the sheet adds a new one. */
  editing?: TransactionDto | undefined;
  /** A category to start in (adding). */
  categoryId?: string | undefined;
  /** Focus the name when it opens ("Ponerle nombre"). */
  focusName?: boolean | undefined;
  /** The account's currency and the person's time zone. */
  currency: string;
  timezone: string;
}

/**
 * Add or edit a transaction (spec §2.6): expense or income, the amount first on a big keypad (a
 * physical keyboard types too), the optional name with recent names as shortcuts (a shortcut also
 * picks its usual category), category chips (most used first, "Más" for the rest), and in "Más
 * opciones" the date (today in the person's time zone), pending and a note. In pesos, a small
 * muted lukas hint follows the amount (§2.6c).
 *
 * Guardar closes the sheet at once; the save itself (optimistic, with a key made when the sheet
 * opened, so a double tap is one transaction) and what follows are the provider's actions.
 */
export function AddTransactionSheet({
  open,
  onClose,
  editing,
  categoryId,
  focusName,
  currency,
  timezone,
}: AddTransactionSheetProps) {
  const t = useTranslations("transaction");
  const tRoot = useTranslations();
  const { locale } = useLocale();
  const { actions } = useTransactionSheet();
  const form = useTransactionForm({ editing, categoryId, timezone });
  const [moreOpen, setMoreOpen] = useState(false);
  const [nameInput, setNameInput] = useState<HTMLInputElement | null>(null);
  const saving = useRef(false);
  const moreId = useId();
  const chipsLabelId = useId();

  // "Ponerle nombre": once the field exists (after the sheet took focus), move focus to it.
  useEffect(() => {
    if (open && focusName && nameInput) nameInput.focus();
  }, [open, focusName, nameInput]);

  // Typing on a keyboard fills the amount, unless a text field has the keys.
  const { raw, setRaw } = form;
  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => {
      const target = event.target;
      if (
        event.metaKey ||
        event.ctrlKey ||
        event.altKey ||
        target instanceof HTMLInputElement ||
        target instanceof HTMLTextAreaElement
      ) {
        return;
      }
      const next = typeOnKeypad(raw, event.key, locale);
      if (next === null) return;
      event.preventDefault();
      setRaw(next);
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open, raw, setRaw, locale]);

  const save = () => {
    if (saving.current || !form.valid || !form.selected) return;
    const input = form.input();
    if (!input) return;
    saving.current = true;
    onClose();
    if (editing) {
      void actions.update(editing, form.patch());
    } else {
      void actions.create(input, form.idempotencyKey, {
        kind: form.kind,
        categoryName: form.selected.name,
        unnamed: form.name.trim() === "",
      });
    }
  };

  const remove = () => {
    if (!editing || saving.current) return;
    saving.current = true;
    onClose();
    void actions.remove(editing);
  };

  const title = editing
    ? t("title_edit")
    : form.kind === "income"
      ? t("title_income")
      : t("title_expense");
  const hint = lukasHint(form.cents, currency, locale);
  const sign = form.cents > 0 ? (form.kind === "expense" ? "−" : "+") : "";
  const dateText =
    form.date === form.today ? t("today") : form.date ? formatDay(form.date, locale) : "";
  const statusText = form.pending ? tRoot("common.pending") : tRoot("common.paid");

  return (
    <Sheet open={open} onClose={onClose} title={title}>
      <div className="flex flex-col gap-(--space-2)">
        <SegmentedControl<Kind>
          label={t("kind_label")}
          value={form.kind}
          options={[
            { value: "expense", label: t("expense") },
            { value: "income", label: t("income") },
          ]}
          onChange={form.setKind}
        />

        <p
          data-testid="amount"
          className={cx(
            "lk-amount-display m-0",
            form.kind === "expense" ? "is-expense" : "is-income",
          )}
        >
          {sign}
          {formatAmountInput(form.raw, currency, locale)}
          {hint && " "}
          {hint && (
            <span className="align-middle font-text text-[14px] font-bold text-ink-muted">
              ({hint})
            </span>
          )}
        </p>

        <NameField<NameChoice>
          value={form.name}
          placeholder={form.selected?.name ?? tRoot("name_field.label")}
          suggestions={form.suggestions}
          onChange={form.setName}
          onPick={form.pick}
          inputRef={setNameInput}
        />

        <span id={chipsLabelId} className="sr-only">
          {t("category_label")}
        </span>
        {form.loading ? null : form.chips.length === 0 ? (
          <p className="m-0 text-[13px] font-bold text-ink-muted">
            {form.kind === "income" ? t("no_categories_income") : t("no_categories_expense")}
          </p>
        ) : (
          <div role="group" aria-labelledby={chipsLabelId} className="lk-chips">
            {form.chips.map((c) => (
              <CategoryChip
                key={c.id}
                glyph={categoryLook(c).glyph}
                label={c.name}
                selected={form.selected?.id === c.id}
                onSelect={() => form.select(c.id)}
              />
            ))}
            {form.overflow && (
              <button
                type="button"
                className="lk-chip lk-chip-button min-h-11 min-w-11"
                aria-expanded={form.allChips}
                onClick={() => form.setAllChips(!form.allChips)}
              >
                <span className="lk-chip-tile" aria-hidden="true">
                  {form.allChips ? "−" : "⋯"}
                </span>
                <span>{form.allChips ? t("fewer_categories") : t("more_categories")}</span>
              </button>
            )}
          </div>
        )}

        <button
          type="button"
          className="lk-more-row"
          aria-expanded={moreOpen}
          aria-controls={moreId}
          onClick={() => setMoreOpen((current) => !current)}
        >
          <span>{t("more_options")}</span>
          <span className="text-ink-muted">
            {dateText} · {statusText}
          </span>
          <span aria-hidden="true" className="ml-auto">
            {moreOpen ? "▴" : "▾"}
          </span>
        </button>
        <div id={moreId} hidden={!moreOpen} className="flex flex-col gap-(--space-2)">
          <label className="flex flex-col gap-(--space-1) text-[13px] font-bold text-ink-muted">
            {t("date_label")}
            <input
              type="date"
              className="lk-input min-h-11 font-text text-ink"
              value={form.date}
              required
              onChange={(event) => form.setDate(event.target.value)}
            />
          </label>
          <label className="flex min-h-11 items-center gap-(--space-2) text-[14px] font-bold text-ink">
            <input
              type="checkbox"
              className="size-5 accent-brand"
              checked={form.pending}
              onChange={(event) => form.setPending(event.target.checked)}
            />
            {t("pending_label")}
          </label>
          <label className="flex flex-col gap-(--space-1) text-[13px] font-bold text-ink-muted">
            {t("note_label")}
            <textarea
              className="lk-input min-h-11 resize-y font-text text-ink"
              rows={2}
              maxLength={1000}
              value={form.note}
              onChange={(event) => form.setNote(event.target.value)}
            />
          </label>
        </div>

        <Keypad value={form.raw} onChange={form.setRaw} locale={locale} />

        <div className="flex gap-(--space-2)">
          {editing && (
            <PressButton variant="secondary" onClick={remove}>
              {t("delete")}
            </PressButton>
          )}
          <PressButton className="flex-1" disabled={!form.valid} onClick={save}>
            {editing ? t("save_changes") : tRoot("common.save")}
          </PressButton>
        </div>
      </div>
    </Sheet>
  );
}
