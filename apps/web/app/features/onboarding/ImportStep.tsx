import { useId } from "react";
import { useTranslations } from "use-intl";
import type { Locale } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { PressButton } from "../../ui/PressButton.tsx";
import type { CurrencyNote, ImportDto, ImportState } from "./import-state.ts";
import { StepError, StepFrame, type StepNavProps } from "./StepFrame.tsx";

export interface ImportStepProps extends StepNavProps {
  state: ImportState;
  /** The account's currency now. */
  currency: string;
  onFile(file: File): void;
  onConfirm(): void;
  /** Drops the preview, to pick another file. */
  onDiscard(): void;
  /** Back to the budgets, after they were prefilled. */
  onReviewBudgets(): void;
}

const REASONS = [
  "invalid_date",
  "invalid_amount",
  "zero_amount",
  "missing_category",
  "currency_mismatch",
] as const;

function formatDate(iso: string, locale: Locale): string {
  return new Intl.DateTimeFormat(locale, {
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "UTC",
  }).format(new Date(`${iso}T00:00:00Z`));
}

/**
 * Step 4, optional: upload a Budge export (CSV), see what it holds (transactions, duplicates,
 * rows with problems, new categories) and confirm. Without a file, Continue reads "Saltar".
 */
export function ImportStep({
  state,
  onFile,
  onConfirm,
  onDiscard,
  onReviewBudgets,
  onBack,
  onNext,
}: ImportStepProps) {
  const t = useTranslations("onboarding");

  const next = (() => {
    switch (state.phase) {
      case "idle":
        return { label: t("skip"), onClick: onNext, variant: "secondary" as const };
      case "reading":
        return { label: t("import.reading"), onClick: () => {}, disabled: true };
      case "preview": {
        const count = state.preview.stats.transactions;
        if (count === 0) {
          return { label: t("skip"), onClick: onNext, variant: "secondary" as const };
        }
        return {
          label: state.confirming ? t("import.importing") : t("import.confirm", { count }),
          onClick: onConfirm,
          disabled: state.confirming || state.discarding,
        };
      }
      case "imported":
        return { label: t("continue"), onClick: onNext };
    }
  })();

  return (
    <StepFrame
      step="import"
      title={t("import.title")}
      lead={state.phase === "idle" || state.phase === "reading" ? t("import.lead") : undefined}
      onBack={onBack}
      next={next}
    >
      {state.phase === "idle" && <FilePicker onFile={onFile} error={state.error ?? null} />}
      {state.phase === "reading" && (
        <p role="status" className="text-ink-muted">
          {t("import.reading")}
        </p>
      )}
      {state.phase === "preview" && (
        <>
          <Preview
            preview={state.preview}
            fileName={state.fileName}
            currencyNote={state.currencyNote}
          />
          {state.error && <StepError>{state.error}</StepError>}
          <PressButton
            variant="secondary"
            onClick={onDiscard}
            disabled={state.confirming || state.discarding}
          >
            {t("import.other_file")}
          </PressButton>
        </>
      )}
      {state.phase === "imported" && (
        <div className="flex flex-col gap-(--space-3)">
          <p role="status" className="font-display text-[20px] font-bold text-good">
            {t("import.imported", {
              count: state.result.stats.inserted ?? state.result.stats.transactions,
            })}
          </p>
          {state.currencyNote?.kind === "switched" && <CurrencyLine note={state.currencyNote} />}
          {state.prefilled && (
            <>
              <p className="text-ink">{t("import.prefilled")}</p>
              <PressButton variant="secondary" onClick={onReviewBudgets}>
                {t("import.review_budgets")}
              </PressButton>
            </>
          )}
        </div>
      )}
    </StepFrame>
  );
}

function FilePicker({ onFile, error }: { onFile(file: File): void; error: string | null }) {
  const t = useTranslations("onboarding");
  const errorId = useId();
  return (
    <>
      <label className="lk-btn lk-btn-primary inline-flex min-h-11 w-full cursor-pointer items-center justify-center gap-(--space-2) has-focus-visible:outline-3 has-focus-visible:outline-focus has-focus-visible:outline-offset-2">
        <input
          type="file"
          accept=".csv,text/csv"
          className="sr-only"
          aria-describedby={error ? errorId : undefined}
          onChange={(event) => {
            const file = event.target.files?.[0];
            // Cleared, so choosing the same file again still fires a change.
            event.target.value = "";
            if (file) onFile(file);
          }}
        />
        <UploadIcon />
        {t("import.choose")}
      </label>
      {error && <StepError id={errorId}>{error}</StepError>}
    </>
  );
}

function CurrencyLine({ note }: { note: NonNullable<CurrencyNote> }) {
  const t = useTranslations("onboarding");
  return (
    <p className="rounded-md border-2 border-gold px-(--space-3) py-(--space-2) text-[15px] text-ink">
      {note.kind === "switched"
        ? t("import.currency_switched", { currency: note.file })
        : t("import.currency_locked", { file: note.file, account: note.account })}
    </p>
  );
}

function Preview({
  preview,
  fileName,
  currencyNote,
}: {
  preview: ImportDto;
  fileName: string;
  currencyNote: CurrencyNote;
}) {
  const t = useTranslations("onboarding");
  const { locale } = useLocale();
  const titleId = useId();
  const { stats } = preview;
  const reason = (code: string) =>
    (REASONS as readonly string[]).includes(code)
      ? t(`import.reasons.${code as (typeof REASONS)[number]}`)
      : t("import.reasons.other");

  return (
    <section
      aria-labelledby={titleId}
      className="flex flex-col gap-(--space-3) rounded-xl border-2 border-stroke bg-surface p-(--space-4) shadow-edge-md"
    >
      <h2 id={titleId} className="font-display text-[20px] font-bold text-ink">
        {t("import.preview_title")}
      </h2>
      <div className="text-[15px] text-ink-muted">
        <p className="wrap-anywhere">{t("import.file", { name: fileName })}</p>
        {stats.from && stats.to && (
          <p>
            {t("import.range", {
              from: formatDate(stats.from, locale),
              to: formatDate(stats.to, locale),
            })}
          </p>
        )}
      </div>
      {currencyNote && <CurrencyLine note={currencyNote} />}
      <dl className="grid grid-cols-3 gap-(--space-2) text-center">
        <Stat term={t("import.transactions")} value={stats.transactions} tone="text-good" />
        <Stat term={t("import.duplicates")} value={stats.duplicates} tone="text-ink" />
        <Stat
          term={t("import.rejected")}
          value={stats.rejected.length}
          tone={stats.rejected.length > 0 ? "text-near" : "text-ink"}
        />
      </dl>
      {stats.newCategories.length > 0 && (
        <dl className="text-[15px]">
          <dt className="text-ink-muted">{t("import.new_categories")}</dt>
          <dd className="text-ink">{stats.newCategories.join(", ")}</dd>
        </dl>
      )}
      {stats.rejected.length > 0 && (
        <details className="text-[15px]">
          <summary className="flex min-h-11 cursor-pointer items-center text-ink underline underline-offset-3">
            {t("import.rejected_details")}
          </summary>
          <ul className="flex flex-col gap-(--space-1) pt-(--space-1) text-ink-muted">
            {stats.rejected.map((row) => (
              <li key={`${row.line}-${row.reason}`}>
                {t("import.rejected_line", { line: row.line, reason: reason(row.reason) })}
              </li>
            ))}
          </ul>
        </details>
      )}
    </section>
  );
}

function Stat({ term, value, tone }: { term: string; value: number; tone: string }) {
  return (
    <div className="flex flex-col-reverse justify-end gap-(--space-1) rounded-md bg-surface-sunken p-(--space-2)">
      <dt className="text-[13px] leading-tight text-ink-muted">{term}</dt>
      <dd className={`lk-num font-display text-[26px] font-bold ${tone}`}>{value}</dd>
    </div>
  );
}

function UploadIcon() {
  return (
    <svg
      width="22"
      height="22"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M12 16V4" />
      <path d="m7 9 5-5 5 5" />
      <path d="M5 20h14" />
    </svg>
  );
}
