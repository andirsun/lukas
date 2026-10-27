import { type CategoryDto, type RecurrenceDto, todayIn } from "@lukas/core";
import { useId, useState } from "react";
import { useTranslations } from "use-intl";
import { ApiProblem, problemMessage, type Translator } from "../../api/errors.ts";
import { useAllCategories, useDeleteRecurrence, useMe, useRecurrences } from "../../api/queries.ts";
import { formatMoney, intlTag, type Locale, monthInSentence } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { ConfirmSheet } from "../../ui/ConfirmSheet.tsx";
import { categoryLook } from "../../ui/category-look.ts";
import { LukasBubble } from "../../ui/LukasBubble.tsx";
import { PageHeader } from "../../ui/PageHeader.tsx";
import { PressButton } from "../../ui/PressButton.tsx";
import { useToast } from "../../ui/Toast.tsx";
import { ManageFrame } from "../categories/CategoryDetail.tsx";
import { useAppPath } from "../home/app-path.ts";
import { RecurringForm } from "./RecurringForm.tsx";
import { nextOccurrence } from "./recurring-model.ts";

/** A date as `23 oct 2026` (es) or `Oct 23, 2026` (en). */
export function formatDate(date: string, locale: Locale): string {
  return new Intl.DateTimeFormat(intlTag(locale), { dateStyle: "medium", timeZone: "UTC" })
    .format(new Date(`${date}T00:00:00Z`))
    .replace(/\./g, "");
}

/**
 * Recurring transactions (`/app/recurring`, spec §2.7): each with its rule in words ("Cada mes,
 * el día 5") and its next date (today counts), newest rules last; tapping one edits it, and the
 * edit sheet deletes it after asking (the transactions it already made stay). The API adds each
 * one's pending transaction to this month and the next as they are read.
 */
export function RecurringPage() {
  const t = useTranslations("recurring");
  const tManage = useTranslations("manage");
  const appPath = useAppPath();
  const tRoot = useTranslations() as unknown as Translator;
  const me = useMe().data;
  if (!me) throw new Error("RecurringPage renders inside AppShell, which waits for the profile");
  const recurrences = useRecurrences();
  const categories = useAllCategories();
  const remove = useDeleteRecurrence();
  const toast = useToast();
  const today = todayIn(me.timezone);
  const [form, setForm] = useState<{ open: boolean; key: number; editing?: RecurrenceDto }>({
    open: false,
    key: 0,
  });
  const [confirmOpen, setConfirmOpen] = useState(false);
  if (recurrences.error && !recurrences.data) throw recurrences.error;
  if (categories.error && !categories.data) throw categories.error;

  const ready = recurrences.data && categories.data;
  const byId = new Map((categories.data ?? []).map((c) => [c.id, c]));
  const open = (editing?: RecurrenceDto) =>
    setForm((f) => ({ open: true, key: f.key + 1, ...(editing ? { editing } : {}) }));

  const confirmDelete = async () => {
    const target = form.editing;
    if (!target) return;
    try {
      await remove.mutateAsync({ id: target.id });
    } catch (problem) {
      toast.show({
        tone: "error",
        message:
          problem instanceof ApiProblem ? problemMessage(problem, tRoot) : tRoot("errors.generic"),
      });
      throw problem;
    }
    toast.show({ message: t("deleted", { name: target.name }) });
  };

  return (
    <ManageFrame busy={!ready}>
      <PageHeader back={{ to: appPath(), label: tManage("back"), short: tManage("back_short") }} />
      <main className="flex flex-col gap-(--space-3)">
        <div className="flex flex-wrap items-center justify-between gap-(--space-2)">
          <h1 className="m-0 font-display text-[28px] font-bold text-ink">{t("title")}</h1>
          <PressButton onClick={() => open()} disabled={!categories.data}>
            <span aria-hidden="true">＋</span>
            {t("add")}
          </PressButton>
        </div>
        {ready &&
          (recurrences.data.length === 0 ? (
            <LukasBubble message={t("empty")} mood="happy" />
          ) : (
            <>
              <p className="m-0 text-[14px] font-bold text-ink-muted">{t("lead")}</p>
              <ul className="m-0 flex list-none flex-col gap-(--space-2) p-0">
                {recurrences.data.map((r) => (
                  <li key={r.id}>
                    <RecurringItem
                      recurrence={r}
                      category={byId.get(r.categoryId)}
                      currency={me.currency}
                      today={today}
                      onOpen={() => open(r)}
                    />
                  </li>
                ))}
              </ul>
            </>
          ))}
      </main>
      {categories.data && (
        <RecurringForm
          key={form.key}
          open={form.open}
          onClose={() => setForm((f) => ({ ...f, open: false }))}
          editing={form.editing}
          categories={categories.data}
          currency={me.currency}
          today={today}
          onDelete={() => {
            setForm((f) => ({ ...f, open: false }));
            setConfirmOpen(true);
          }}
        />
      )}
      <ConfirmSheet
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
        title={t("delete_sheet.title", { name: form.editing?.name ?? "" })}
        body={t("delete_sheet.body")}
        confirmLabel={t("delete_sheet.confirm")}
        onConfirm={confirmDelete}
      />
    </ManageFrame>
  );
}

/** One recurrence: its category's tile, name and amount, the rule in words and its next date. */
function RecurringItem({
  recurrence,
  category,
  currency,
  today,
  onOpen,
}: {
  recurrence: RecurrenceDto;
  category: CategoryDto | undefined;
  currency: string;
  today: string;
  onOpen(): void;
}) {
  const t = useTranslations("recurring");
  const { locale } = useLocale();
  const id = useId();
  const look = category ? categoryLook(category) : { glyph: "🏷️", tint: "var(--stroke)" };
  const income = recurrence.amount > 0;
  const rule =
    recurrence.frequency === "yearly" && recurrence.monthOfYear !== null
      ? t("yearly_rule", {
          day: recurrence.dayOfMonth,
          month: monthName(recurrence.monthOfYear, locale),
        })
      : t("monthly_rule", { day: recurrence.dayOfMonth });
  const next = nextOccurrence(recurrence, today);
  const when = next ? t("next", { date: formatDate(next, locale) }) : t("ended");

  return (
    <div className="lk-rowcard lk-row">
      <button
        type="button"
        className="lk-row-hit"
        aria-labelledby={`${id}-name ${id}-amount ${id}-rule ${id}-next`}
        onClick={onOpen}
      />
      <span
        className="lk-tile"
        style={{ background: `color-mix(in srgb, ${look.tint} 45%, var(--surface-sunken))` }}
        aria-hidden="true"
      >
        {look.glyph}
      </span>
      <div className="lk-rowmain">
        <div className="lk-rowtop">
          <span id={`${id}-name`} className="truncate">
            {recurrence.name}
          </span>
          <span id={`${id}-amount`} className={income ? "lk-amount text-good" : "lk-amount"}>
            {formatMoney(recurrence.amount, currency, locale, { sign: income ? "always" : "auto" })}
          </span>
        </div>
        <div className="lk-status flex flex-wrap gap-x-(--space-2)">
          <span id={`${id}-rule`}>
            {rule}
            {category && ` · ${category.name}`}
          </span>
          <span id={`${id}-next`} className="text-ink">
            {when}
          </span>
        </div>
      </div>
    </div>
  );
}

/** A month of the year mid-sentence ("15 de marzo"; "March 15"). */
function monthName(month: number, locale: Locale): string {
  return monthInSentence(`2026-${String(month).padStart(2, "0")}`, locale);
}
