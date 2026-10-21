import { type ReactNode, useEffect, useId, useRef } from "react";
import { useTranslations } from "use-intl";
import { Lukas, type LukasMood } from "../../lukas/Lukas.tsx";
import { cx } from "../../ui/cx.ts";
import { PressButton } from "../../ui/PressButton.tsx";
import { ThemeToggle } from "../../ui/ThemeToggle.tsx";
import { STEPS, type StepId } from "./steps.ts";

/** What every step gets from the flow: where Back and Continue go. No `onBack` on the first step. */
export interface StepNavProps {
  onBack?: (() => void) | undefined;
  onNext(): void;
}

export interface StepAction {
  label: string;
  onClick(): void;
  disabled?: boolean;
  variant?: "primary" | "secondary";
  /** Id of the text that says why the action is disabled. */
  describedBy?: string | undefined;
}

export interface StepFrameProps {
  step: StepId;
  title: string;
  lead?: ReactNode;
  mood?: LukasMood;
  onBack?: (() => void) | undefined;
  next: StepAction;
  /** Shown above Back / Continue, so it stays in view while the content scrolls (a running total). */
  summary?: ReactNode;
  children?: ReactNode;
}

/** Lukitas' size beside a step's title: friendly, never crowding it. */
const MASCOT_PX = 72;

/**
 * The frame of an onboarding step: the wordmark and the day/night switch, the progress ("Paso 2 de
 * 6"), Lukitas beside the title, the step's content, and Back / Continue at the bottom (they stay
 * in reach while the content scrolls). The title takes focus when the step shows, so a screen
 * reader starts there and keyboard users continue from it.
 */
export function StepFrame({
  step,
  title,
  lead,
  mood = "happy",
  onBack,
  next,
  summary,
  children,
}: StepFrameProps) {
  const t = useTranslations("onboarding");
  const heading = useRef<HTMLHeadingElement>(null);
  const progressId = useId();
  const current = STEPS.indexOf(step) + 1;

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
        <p id={progressId} className="text-[15px] text-ink-muted">
          {t("progress", { current, total: STEPS.length })}
        </p>
        <div className="mt-(--space-2) flex gap-(--space-1)" aria-hidden="true">
          {STEPS.map((s, index) => (
            <span
              key={s}
              className={cx(
                "h-1.5 flex-1 rounded-pill",
                index < current ? "bg-brand-glow" : "bg-stroke",
              )}
            />
          ))}
        </div>
        <div className="mt-(--space-4) flex items-center gap-(--space-3)">
          <span className="shrink-0">
            <Lukas mood={mood} size={MASCOT_PX} />
          </span>
          <h1
            ref={heading}
            tabIndex={-1}
            aria-describedby={progressId}
            className="font-display text-[26px] leading-tight font-bold text-ink outline-none"
          >
            {title}
          </h1>
        </div>
        {lead && <p className="mt-(--space-3) text-ink-muted">{lead}</p>}
        <div className="mt-(--space-4) flex flex-1 flex-col gap-(--space-4) pb-(--space-4)">
          {children}
        </div>
        <div className="sticky bottom-0 -mx-(--space-4) flex flex-col gap-(--space-3) bg-bg px-(--space-4) pt-(--space-3) pb-[max(var(--space-4),env(safe-area-inset-bottom))]">
          {summary}
          <div className="flex items-center gap-(--space-3)">
            {onBack && (
              <PressButton variant="ghost" onClick={onBack}>
                {t("back")}
              </PressButton>
            )}
            <PressButton
              variant={next.variant ?? "primary"}
              className="flex-1"
              disabled={next.disabled}
              aria-describedby={next.describedBy}
              onClick={next.onClick}
            >
              {next.label}
            </PressButton>
          </div>
        </div>
      </main>
    </div>
  );
}

/** An error under the control it is about, read out when it appears. */
export function StepError({ id, children }: { id?: string; children: ReactNode }) {
  return (
    <p id={id} role="alert" className="text-[15px] text-over">
      {children}
    </p>
  );
}
