import { type ReactNode, useEffect, useId, useRef } from "react";
import { useTranslations } from "use-intl";
import { Lukas, type LukasMood } from "../../lukas/Lukas.tsx";
import { cx } from "../../ui/cx.ts";
import { PressButton } from "../../ui/PressButton.tsx";
import { ThemeToggle } from "../../ui/ThemeToggle.tsx";
import { SETUP_STEPS, type StepId } from "./steps.ts";

/**
 * What every setup step gets from the flow: Back (none on the first), SALTAR (move on with this
 * step's defaults, nothing typed is required) and SIGUIENTE (apply what is on screen).
 */
export interface StepNavProps {
  onBack?: (() => void) | undefined;
  onSkip(): void;
  onNext(): void;
  /** While the step's write is in flight: the buttons wait. */
  busy?: boolean;
}

export interface StepAction {
  label: string;
  onClick(): void;
  disabled?: boolean;
}

export interface StepFrameProps {
  step: StepId;
  title: string;
  lead?: ReactNode;
  mood?: LukasMood;
  onBack?: (() => void) | undefined;
  /** Back waits too (e.g. while an import is being read or confirmed). */
  backDisabled?: boolean;
  /** SALTAR. */
  skip?: StepAction | undefined;
  /** SIGUIENTE, or the step's own main action (e.g. "Importar 22 movimientos"). */
  next?: StepAction | undefined;
  /** Shown above the buttons, so it stays in view while the content scrolls (a running total). */
  summary?: ReactNode;
  children?: ReactNode;
}

/** Lukitas' size beside a step's title: friendly, never crowding it. */
const MASCOT_PX = 72;

/**
 * The frame of an onboarding step: the wordmark and the day/night switch, the progress ("Paso 2 de
 * 4", not on the welcome), Lukitas beside the title, the content, and Back / SALTAR / SIGUIENTE at
 * the bottom (they stay in reach while the content scrolls). The title takes focus when the step
 * shows, so a screen reader starts there and keyboard users continue from it.
 */
export function StepFrame({
  step,
  title,
  lead,
  mood = "happy",
  onBack,
  backDisabled = false,
  skip,
  next,
  summary,
  children,
}: StepFrameProps) {
  const t = useTranslations("onboarding");
  const heading = useRef<HTMLHeadingElement>(null);
  const progressId = useId();
  const current = (SETUP_STEPS as readonly StepId[]).indexOf(step) + 1;
  const counted = current > 0;

  useEffect(() => {
    heading.current?.focus();
  }, [step]);

  return (
    <div className="lk-screen flex min-h-dvh flex-col">
      <header className="mx-auto flex w-full max-w-[480px] items-center justify-between px-(--space-4) py-(--space-3)">
        <span className="lk-logo inline-flex min-h-11 items-center">Lukitas</span>
        <ThemeToggle />
      </header>
      <main className="mx-auto flex w-full max-w-[480px] flex-1 flex-col px-(--space-4)">
        {counted && (
          <>
            <p id={progressId} className="text-[15px] text-ink-muted">
              {t("progress", { current, total: SETUP_STEPS.length })}
            </p>
            <div className="mt-(--space-2) flex gap-(--space-1)" aria-hidden="true">
              {SETUP_STEPS.map((s, index) => (
                <span
                  key={s}
                  className={cx(
                    "h-1.5 flex-1 rounded-pill",
                    index < current ? "bg-brand-glow" : "bg-stroke",
                  )}
                />
              ))}
            </div>
          </>
        )}
        <div className="mt-(--space-4) flex items-center gap-(--space-3)">
          <span className="shrink-0">
            <Lukas mood={mood} size={MASCOT_PX} />
          </span>
          <h1
            ref={heading}
            tabIndex={-1}
            aria-describedby={counted ? progressId : undefined}
            className="font-display text-[26px] leading-tight font-bold text-ink outline-none"
          >
            {title}
          </h1>
        </div>
        {lead && <p className="mt-(--space-3) text-ink-muted">{lead}</p>}
        <div className="mt-(--space-4) flex flex-1 flex-col gap-(--space-4) pb-(--space-4)">
          {children}
        </div>
        {(next || skip || summary) && (
          <div className="sticky bottom-0 -mx-(--space-4) flex flex-col gap-(--space-3) bg-bg px-(--space-4) pt-(--space-3) pb-[max(var(--space-4),env(safe-area-inset-bottom))]">
            {summary}
            <div className="flex items-center gap-(--space-2)">
              {onBack && (
                <PressButton
                  variant="ghost"
                  aria-label={t("back")}
                  disabled={backDisabled}
                  onClick={onBack}
                >
                  <BackIcon />
                </PressButton>
              )}
              {skip && (
                <PressButton variant="ghost" disabled={skip.disabled} onClick={skip.onClick}>
                  {skip.label}
                </PressButton>
              )}
              {next && (
                <PressButton className="flex-1" disabled={next.disabled} onClick={next.onClick}>
                  {next.label}
                </PressButton>
              )}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

/** The SALTAR and SIGUIENTE of a step that has nothing special about them. */
export function useStepActions({ onSkip, onNext, busy = false }: StepNavProps) {
  const t = useTranslations("onboarding");
  return {
    skip: { label: t("skip"), onClick: onSkip, disabled: busy },
    next: { label: busy ? t("saving") : t("next"), onClick: onNext, disabled: busy },
  };
}

/** An error under the control it is about, read out when it appears. */
export function StepError({ id, children }: { id?: string; children: ReactNode }) {
  return (
    <p id={id} role="alert" className="text-[15px] text-over">
      {children}
    </p>
  );
}

function BackIcon() {
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
      <path d="M15 5l-7 7 7 7" />
    </svg>
  );
}
