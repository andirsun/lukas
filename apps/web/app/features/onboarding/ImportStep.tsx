import { type RefObject, useEffect, useId, useRef } from "react";
import { useTranslations } from "use-intl";
import type { Locale } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { PressButton } from "../../ui/PressButton.tsx";
import { type CurrencyNote, type ImportDto, type ImportState, newRows } from "./import-state.ts";
import { StepError, StepFrame, type StepNavProps } from "./StepFrame.tsx";

export interface ImportStepProps extends StepNavProps {
  state: ImportState;
  /** The account's currency now. */
  currency: string;
  onFile(file: File): void;
  onConfirm(): void;
  /** Drops the preview, to pick another file. */
  onDiscard(): void;
  /** From the list of sources to Budge's how-to and picker, and back. */
  onSource(source: "budge" | null): void;
  /** After an import whose follow-up (reading the categories again) failed. */
  onRetry?: () => void;
  /** Where prefilled budgets came from, shown under the result. */
  prefillBasis?: string | null;
}

/** Rejected rows listed before "y N más". */
const REJECTED_SHOWN = 20;

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
 * "¿Traes tu historial?": a list of sources. Budge opens a short how-to and the file picker, then
 * the preview (transactions, duplicates, rows with problems, new categories) and the confirm. The
 * others are "Pronto" for now. SALTAR moves on without importing (dropping a pending preview).
 */
export function ImportStep({
  state,
  onFile,
  onConfirm,
  onDiscard,
  onSource,
  onRetry,
  prefillBasis,
  onBack,
  onNext,
  onSkip,
  busy = false,
}: ImportStepProps) {
  const t = useTranslations("onboarding");
  const tCommon = useTranslations("common");
  const sourcesHeading = useRef<HTMLHeadingElement>(null);
  const budgeHeading = useRef<HTMLHeadingElement>(null);
  const pickerInput = useRef<HTMLInputElement>(null);
  const previewHeading = useRef<HTMLHeadingElement>(null);
  const importedHeading = useRef<HTMLHeadingElement>(null);
  const shownPhase = useRef(state.phase);

  // The file input is gone once a file is chosen, so focus would drop to the page. Each new phase
  // takes it instead: the preview and the result by their headings (read out by screen readers),
  // the picker again after "Usar otro archivo". (On arriving at the step, the title has it.)
  useEffect(() => {
    const previous = shownPhase.current;
    if (previous === state.phase) return;
    shownPhase.current = state.phase;
    if (state.phase === "preview") previewHeading.current?.focus();
    else if (state.phase === "imported") importedHeading.current?.focus();
    else if (state.phase === "sources") sourcesHeading.current?.focus();
    else if (state.phase === "idle") {
      // After "Usar otro archivo", straight back to the picker; from the list, to the how-to.
      if (previous === "preview") pickerInput.current?.focus();
      else budgeHeading.current?.focus();
    }
  }, [state.phase]);

  const skip = { label: t("skip"), onClick: onSkip, disabled: busy };
  const next = (() => {
    const plain = { label: t("next"), onClick: onNext, disabled: busy };
    switch (state.phase) {
      case "sources":
      case "idle":
        return plain;
      case "reading":
        return { label: t("import.reading"), onClick: () => {}, disabled: true };
      case "preview": {
        const count = newRows(state.preview);
        if (count === 0) return plain;
        return {
          label: state.confirming ? t("import.importing") : t("import.confirm", { count }),
          onClick: onConfirm,
          disabled: state.confirming || state.discarding || busy,
        };
      }
      case "imported":
        return { ...plain, disabled: state.retrying || busy };
    }
  })();

  return (
    <StepFrame
      step="import"
      title={t("import.title")}
      lead={state.phase === "sources" ? t("import.lead") : undefined}
      onBack={onBack}
      skip={state.phase === "imported" ? undefined : skip}
      next={next}
    >
      {state.phase === "sources" && (
        <Sources headingRef={sourcesHeading} onBudge={() => onSource("budge")} />
      )}
      {state.phase === "idle" && (
        <BudgeHowTo
          headingRef={budgeHeading}
          inputRef={pickerInput}
          onFile={onFile}
          onOtherSource={() => onSource(null)}
          error={state.error ?? null}
        />
      )}
      {state.phase === "reading" && (
        <p role="status" className="text-ink-muted">
          {t("import.reading")}
        </p>
      )}
      {state.phase === "preview" && (
        <>
          <Preview
            headingRef={previewHeading}
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
          <h2
            ref={importedHeading}
            tabIndex={-1}
            className="font-display text-[20px] font-bold text-good outline-none"
          >
            {t("import.imported", {
              count: state.result.stats.inserted ?? newRows(state.result),
            })}
          </h2>
          {state.currencyNote?.kind === "switched" && <CurrencyLine note={state.currencyNote} />}
          {state.error && (
            <>
              <StepError>{state.error}</StepError>
              <PressButton variant="secondary" onClick={onRetry} disabled={state.retrying}>
                {tCommon("retry")}
              </PressButton>
            </>
          )}
          {state.prefilled && (
            <>
              <p className="text-ink">{t("import.prefilled")}</p>
              {prefillBasis && <p className="text-[15px] text-ink-muted">{prefillBasis}</p>}
            </>
          )}
        </div>
      )}
    </StepFrame>
  );
}

/** A source in the list: Budge opens its how-to; the rest say "Pronto" and do nothing yet. */
function Sources({
  headingRef,
  onBudge,
}: {
  headingRef: RefObject<HTMLHeadingElement | null>;
  onBudge(): void;
}) {
  const t = useTranslations("onboarding.import");
  const headingId = useId();
  const soon = (label: string) => (
    <li className="flex min-h-11 items-center justify-between gap-(--space-3) rounded-lg border-2 border-stroke px-(--space-4) py-(--space-3) text-ink-muted">
      <span>{label}</span>
      <span className="rounded-pill bg-surface-sunken px-(--space-2) py-(--space-1) text-[13px] text-ink-muted">
        {t("soon")}
      </span>
    </li>
  );
  return (
    <section aria-labelledby={headingId} className="flex flex-col gap-(--space-2)">
      <h2
        ref={headingRef}
        id={headingId}
        tabIndex={-1}
        className="font-display text-[18px] font-bold text-ink outline-none"
      >
        {t("sources_label")}
      </h2>
      <ul className="flex flex-col gap-(--space-2)">
        <li>
          <button
            type="button"
            onClick={onBudge}
            className="lk-rowcard lk-press flex min-h-11 w-full items-center justify-between gap-(--space-3) px-(--space-4) py-(--space-3) text-left font-display text-[18px] font-bold text-ink focus-visible:outline-3 focus-visible:outline-focus focus-visible:outline-offset-2"
          >
            {t("source_budge")}
            <ChevronIcon />
          </button>
        </li>
        {/* Task 10d makes this one an upload with column mapping. */}
        {soon(t("source_sheet"))}
        {soon(t("source_buddy"))}
        {soon(t("source_other"))}
      </ul>
    </section>
  );
}

/**
 * How to get the CSV out of Budge, then the picker.
 * The steps are deliberately neutral: the founder still has to confirm Budge's exact menu path,
 * and then `budge_step_1` in the catalogs gets the real one.
 */
function BudgeHowTo({
  headingRef,
  inputRef,
  onFile,
  onOtherSource,
  error,
}: {
  headingRef: RefObject<HTMLHeadingElement | null>;
  inputRef: RefObject<HTMLInputElement | null>;
  onFile(file: File): void;
  onOtherSource(): void;
  error: string | null;
}) {
  const t = useTranslations("onboarding.import");
  const errorId = useId();
  return (
    <div className="flex flex-col gap-(--space-3)">
      <h2
        ref={headingRef}
        tabIndex={-1}
        className="font-display text-[20px] font-bold text-ink outline-none"
      >
        {t("budge_title")}
      </h2>
      <ol className="flex list-decimal flex-col gap-(--space-2) pl-(--space-5) text-ink marker:font-display marker:text-ink-muted">
        <li>{t("budge_step_1")}</li>
        <li>{t("budge_step_2")}</li>
        <li>{t("budge_step_3")}</li>
      </ol>
      <label className="lk-btn lk-btn-secondary inline-flex min-h-11 w-full cursor-pointer items-center justify-center gap-(--space-2) has-focus-visible:outline-3 has-focus-visible:outline-focus has-focus-visible:outline-offset-2">
        <input
          ref={inputRef}
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
        {t("choose")}
      </label>
      {error && <StepError id={errorId}>{error}</StepError>}
      <PressButton variant="ghost" className="self-start" onClick={onOtherSource}>
        {t("other_source")}
      </PressButton>
    </div>
  );
}

function ChevronIcon() {
  return (
    <svg
      width="22"
      height="22"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="m9 5 7 7-7 7" />
    </svg>
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
  headingRef,
  preview,
  fileName,
  currencyNote,
}: {
  headingRef: RefObject<HTMLHeadingElement | null>;
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
      <h2
        ref={headingRef}
        id={titleId}
        tabIndex={-1}
        className="font-display text-[20px] font-bold text-ink outline-none"
      >
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
          <ul
            aria-label={t("import.rejected")}
            className="flex flex-col gap-(--space-1) pt-(--space-1) text-ink-muted"
          >
            {stats.rejected.slice(0, REJECTED_SHOWN).map((row) => (
              <li key={`${row.line}-${row.reason}`}>
                {t("import.rejected_line", { line: row.line, reason: reason(row.reason) })}
              </li>
            ))}
          </ul>
          {stats.rejected.length > REJECTED_SHOWN && (
            <p className="pt-(--space-1) text-ink-muted">
              {t("import.rejected_more", { count: stats.rejected.length - REJECTED_SHOWN })}
            </p>
          )}
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
