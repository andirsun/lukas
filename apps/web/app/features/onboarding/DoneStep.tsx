import { useTranslations } from "use-intl";
import { AmountWithHint } from "./BudgetsStep.tsx";
import { StepError, StepFrame, type StepNavProps } from "./StepFrame.tsx";

export interface DoneStepProps extends StepNavProps {
  /** The month's total budget, in hundredths. */
  total: number;
  currency: string;
  /** While the budgets and the onboarding flag are saved. */
  busy?: boolean;
  error?: string | null;
}

/** Step 5: Lukitas celebrating, the month's budget, and "Empezar" into the app. */
export function DoneStep({ total, currency, busy = false, error, onBack, onNext }: DoneStepProps) {
  const t = useTranslations("onboarding");
  return (
    <StepFrame
      step="done"
      title={t("done.title")}
      lead={t("done.lead")}
      mood="celebrating"
      onBack={busy ? undefined : onBack}
      next={{ label: busy ? t("saving") : t("done.start"), onClick: onNext, disabled: busy }}
    >
      {total > 0 && (
        <div className="lk-hero">
          <p className="lk-hero-label text-[13px]">{t("done.total_label")}</p>
          <p className="lk-hero-amount text-[32px] wrap-anywhere">
            <AmountWithHint cents={total} currency={currency} />
          </p>
        </div>
      )}
      {error && <StepError>{error}</StepError>}
    </StepFrame>
  );
}
