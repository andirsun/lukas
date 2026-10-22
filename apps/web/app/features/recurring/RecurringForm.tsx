import type { CategoryDto, IsoDate, RecurrenceDto } from "@lukas/core";
import { type FormEvent, useCallback, useEffect, useId, useRef, useState } from "react";
import { useTranslations } from "use-intl";
import { ApiProblem, problemMessage, type Translator } from "../../api/errors.ts";
import { type NewRecurrence, useCreateRecurrence, useUpdateRecurrence } from "../../api/queries.ts";
import { formatMonth } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { AmountField } from "../../ui/AmountField.tsx";
import { CategoryChip } from "../../ui/CategoryChip.tsx";
import { categoryLook } from "../../ui/category-look.ts";
import { cx } from "../../ui/cx.ts";
import { amountCents, keypadText } from "../../ui/keypad-input.ts";
import { PressButton } from "../../ui/PressButton.tsx";
import { SegmentedControl } from "../../ui/SegmentedControl.tsx";
import { Sheet } from "../../ui/Sheet.tsx";
import { useToast } from "../../ui/Toast.tsx";

type Kind = "expense" | "income";
type Frequency = "monthly" | "yearly";
type Field = "amount" | "name" | "category" | "month" | "start" | "end";
/** Fields that can carry an error, plus the day (which always has a valid value). */
type Input = Field | "day";

export interface RecurringFormProps {
  open: boolean;
  onClose(): void;
  /** The recurrence to edit; without one the form creates a new one. */
  editing?: RecurrenceDto | undefined;
  /** Active categories to choose from (plus the edited one's, even if archived since). */
  categories: CategoryDto[];
  currency: string;
  /** Today in the person's time zone: a new one starts today. */
  today: IsoDate;
  /** "Eliminar recurrente" (editing only): the page asks first, in its own sheet. */
  onDelete?: (() => void) | undefined;
}

const DAYS = Array.from({ length: 31 }, (_, i) => i + 1);
const MONTHS = Array.from({ length: 12 }, (_, i) => i + 1);

/** The first error of a draft, by field, or null when it can be sent. */
export function recurrenceProblem(draft: {
  cents: number;
  name: string;
  categoryId: string | null;
  frequency: Frequency;
  monthOfYear: number | null;
  startDate: string;
  endDate: string;
}): Field | null {
  if (draft.cents <= 0) return "amount";
  if (!draft.name.trim()) return "name";
  if (!draft.categoryId) return "category";
  if (draft.frequency === "yearly" && draft.monthOfYear === null) return "month";
  if (!draft.startDate) return "start";
  if (draft.endDate && draft.endDate < draft.startDate) return "end";
  return null;
}

/**
 * A recurring transaction's sheet (spec §2.7): expense or income, the amount on the shared
 * keypad, a name, its category, monthly or yearly, the day of the month (a later day than a month
 * has falls on its last), the month for a yearly one (required: nothing is sent without it), the
 * start (today by default) and an optional end. Mount it with a new `key` each time it opens.
 */
export function RecurringForm({
  open,
  onClose,
  editing,
  categories,
  currency,
  today,
  onDelete,
}: RecurringFormProps) {
  const t = useTranslations("recurring.form");
  const tRecurring = useTranslations("recurring");
  const tRoot = useTranslations() as unknown as Translator;
  const { locale } = useLocale();
  const toast = useToast();
  const create = useCreateRecurrence();
  const update = useUpdateRecurrence();
  const ids = { error: useId(), chips: useId(), day: useId(), month: useId(), dayNote: useId() };

  const startCategory = categories.find((c) => c.id === editing?.categoryId);
  const [kind, setKind] = useState<Kind>(
    startCategory?.kind ?? (editing && editing.amount > 0 ? "income" : "expense"),
  );
  const [raw, setRawState] = useState(() =>
    editing ? keypadText(editing.amount, locale, currency) : "",
  );
  const [name, setName] = useState(editing?.name ?? "");
  const [categoryId, setCategoryId] = useState<string | null>(editing?.categoryId ?? null);
  const [frequency, setFrequency] = useState<Frequency>(editing?.frequency ?? "monthly");
  const [day, setDay] = useState(editing?.dayOfMonth ?? Number(today.slice(8, 10)));
  const [monthOfYear, setMonthOfYear] = useState<number | null>(editing?.monthOfYear ?? null);
  const [startDate, setStartDate] = useState(editing?.startDate ?? today);
  const [endDate, setEndDate] = useState(editing?.endDate ?? "");
  const [problem, setProblem] = useState<{ field: Field | null; message: string } | null>(null);
  const saving = create.isPending || update.isPending;
  const errorRef = useRef<HTMLParagraphElement>(null);

  // The message sits above the sticky footer, which could cover it: bring it into view.
  useEffect(() => {
    if (problem) errorRef.current?.scrollIntoView({ block: "nearest" });
  }, [problem]);

  const setRaw = useCallback((next: string) => {
    setRawState(next);
    setProblem(null);
  }, []);
  const choices = categories.filter(
    (c) => c.kind === kind && (!c.archived || c.id === editing?.categoryId),
  );
  const cents = amountCents(raw, { locale, currency });

  const changeKind = (next: Kind) => {
    setKind(next);
    if (categories.find((c) => c.id === categoryId)?.kind !== next) setCategoryId(null);
  };

  const MESSAGES: Record<Field, string> = {
    amount: t("amount_required"),
    name: t("name_required"),
    category: t("category_required"),
    month: t("month_required"),
    start: t("start_required"),
    end: t("end_before_start"),
  };

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    if (saving) return;
    const field = recurrenceProblem({
      cents,
      name,
      categoryId,
      frequency,
      monthOfYear,
      startDate,
      endDate,
    });
    if (field) {
      setProblem({ field, message: MESSAGES[field] });
      return;
    }
    const body: NewRecurrence = {
      name: name.trim(),
      amount: kind === "expense" ? -cents : cents,
      categoryId: categoryId as string,
      frequency,
      dayOfMonth: day,
      monthOfYear: frequency === "yearly" ? monthOfYear : null,
      startDate,
      endDate: endDate || null,
    };
    try {
      if (editing) {
        // The category is sent only when it changed: one archived since stays without a 422.
        const { categoryId: chosen, ...rest } = body;
        const patch = chosen === editing.categoryId ? rest : body;
        await update.mutateAsync({ id: editing.id, patch });
      } else await create.mutateAsync(body);
    } catch (failure) {
      setProblem({
        field: null,
        message:
          failure instanceof ApiProblem ? problemMessage(failure, tRoot) : tRoot("errors.generic"),
      });
      return;
    }
    onClose();
    toast.show({ message: tRecurring("saved", { name: body.name }) });
  };

  const invalid = (field: Input) => problem?.field === field || undefined;
  const describedBy = (field: Field) => (problem?.field === field ? ids.error : undefined);
  const inputClass = (field: Input) =>
    cx("lk-input min-h-11 w-full font-text text-[16px] text-ink", invalid(field) && "border-over");

  return (
    <Sheet open={open} onClose={onClose} title={editing ? t("title_edit") : t("title_new")}>
      <form noValidate onSubmit={submit} className="flex flex-col gap-(--space-3) pt-(--space-2)">
        <SegmentedControl<Kind>
          label={t("kind_label")}
          value={kind}
          options={[
            { value: "expense", label: t("expense") },
            { value: "income", label: t("income") },
          ]}
          onChange={changeKind}
        />
        <AmountField
          active={open}
          raw={raw}
          setRaw={setRaw}
          currency={currency}
          sign={kind === "expense" ? "−" : "+"}
          tone={kind}
          testId="recurring-amount"
          invalid={problem?.field === "amount"}
        />

        <label className="flex flex-col gap-(--space-1) text-[13px] font-bold text-ink-muted">
          {t("name_label")}
          <input
            className={inputClass("name")}
            value={name}
            maxLength={120}
            autoComplete="off"
            placeholder={t("name_placeholder")}
            aria-invalid={invalid("name")}
            aria-describedby={describedBy("name")}
            onChange={(event) => {
              setName(event.target.value);
              setProblem(null);
            }}
          />
        </label>

        <span id={ids.chips} className="text-[13px] font-bold text-ink-muted">
          {t("category_label")}
        </span>
        {choices.length === 0 ? (
          <p className="m-0 text-[13px] font-bold text-ink-muted">
            {kind === "income" ? t("no_categories_income") : t("no_categories_expense")}
          </p>
        ) : (
          <div
            role="group"
            aria-labelledby={ids.chips}
            aria-describedby={describedBy("category")}
            className="lk-chips"
          >
            {choices.map((c) => (
              <CategoryChip
                key={c.id}
                glyph={categoryLook(c).glyph}
                label={c.name}
                selected={categoryId === c.id}
                onSelect={() => {
                  setCategoryId(c.id);
                  setProblem(null);
                }}
              />
            ))}
          </div>
        )}

        <span aria-hidden="true" className="text-[13px] font-bold text-ink-muted">
          {t("frequency_label")}
        </span>
        <SegmentedControl<Frequency>
          label={t("frequency_label")}
          value={frequency}
          options={[
            { value: "monthly", label: t("monthly") },
            { value: "yearly", label: t("yearly") },
          ]}
          onChange={(next) => {
            setFrequency(next);
            setProblem(null);
          }}
        />
        <div className="grid grid-cols-2 gap-(--space-2)">
          <label
            htmlFor={ids.day}
            className="flex flex-col gap-(--space-1) text-[13px] font-bold text-ink-muted"
          >
            {t("day_label")}
            <select
              id={ids.day}
              className={inputClass("day")}
              value={day}
              aria-describedby={day > 28 ? ids.dayNote : undefined}
              onChange={(event) => setDay(Number(event.target.value))}
            >
              {DAYS.map((d) => (
                <option key={d} value={d}>
                  {d}
                </option>
              ))}
            </select>
          </label>
          {frequency === "yearly" && (
            <label
              htmlFor={ids.month}
              className="flex flex-col gap-(--space-1) text-[13px] font-bold text-ink-muted"
            >
              {t("month_label")}
              <select
                id={ids.month}
                className={inputClass("month")}
                value={monthOfYear ?? ""}
                aria-invalid={invalid("month")}
                aria-describedby={describedBy("month")}
                onChange={(event) => {
                  setMonthOfYear(event.target.value ? Number(event.target.value) : null);
                  setProblem(null);
                }}
              >
                <option value="" disabled>
                  {t("month_placeholder")}
                </option>
                {MONTHS.map((m) => (
                  <option key={m} value={m}>
                    {formatMonth(`2026-${String(m).padStart(2, "0")}`, locale)}
                  </option>
                ))}
              </select>
            </label>
          )}
        </div>
        {day > 28 && (
          <p id={ids.dayNote} className="m-0 text-[13px] font-bold text-ink-muted">
            {t("short_months")}
          </p>
        )}
        <div className="grid grid-cols-2 gap-(--space-2)">
          <label className="flex flex-col gap-(--space-1) text-[13px] font-bold text-ink-muted">
            {t("start_label")}
            <input
              type="date"
              className={inputClass("start")}
              value={startDate}
              required
              aria-invalid={invalid("start")}
              aria-describedby={describedBy("start")}
              onChange={(event) => {
                setStartDate(event.target.value);
                setProblem(null);
              }}
            />
          </label>
          <label className="flex flex-col gap-(--space-1) text-[13px] font-bold text-ink-muted">
            {t("end_label")}
            <input
              type="date"
              className={inputClass("end")}
              value={endDate}
              min={startDate}
              aria-invalid={invalid("end")}
              aria-describedby={describedBy("end")}
              onChange={(event) => {
                setEndDate(event.target.value);
                setProblem(null);
              }}
            />
          </label>
        </div>

        {problem && (
          <p
            ref={errorRef}
            id={ids.error}
            role="alert"
            className="m-0 scroll-mb-24 text-[15px] font-bold text-over"
          >
            {problem.message}
          </p>
        )}
        <div className="lk-sheet-footer flex gap-(--space-2)">
          {editing && onDelete && (
            <PressButton variant="secondary" className="text-over" onClick={onDelete}>
              {t("delete")}
            </PressButton>
          )}
          <PressButton type="submit" className="flex-1" disabled={saving} aria-busy={saving}>
            {t("save")}
          </PressButton>
        </div>
      </form>
    </Sheet>
  );
}
