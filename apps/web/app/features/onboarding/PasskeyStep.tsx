import { useId } from "react";
import { useTranslations } from "use-intl";
import { PressButton } from "../../ui/PressButton.tsx";
import { FingerprintIcon } from "../sign-in/SignIn.tsx";
import { StepError, StepFrame, type StepNavProps } from "./StepFrame.tsx";

export interface PasskeyStepProps extends StepNavProps {
  onAdd(): void;
  /** While the browser's prompt is open. */
  adding: boolean;
  error?: string | null;
}

/**
 * Step 1: "¿Entrar con tu huella la próxima vez?" Adding a passkey is the main action; "Ahora no"
 * (Continue) skips it. The flow skips the whole step on browsers without WebAuthn.
 */
export function PasskeyStep({ onAdd, adding, error, onBack, onNext }: PasskeyStepProps) {
  const t = useTranslations("onboarding");
  const tCommon = useTranslations("common");
  const errorId = useId();
  return (
    <StepFrame
      step="passkey"
      title={t("passkey.title")}
      lead={t("passkey.lead")}
      onBack={onBack}
      next={{
        label: tCommon("not_now"),
        onClick: onNext,
        disabled: adding,
        variant: "secondary",
      }}
    >
      <PressButton
        className="w-full"
        onClick={onAdd}
        disabled={adding}
        aria-describedby={error ? errorId : undefined}
      >
        <FingerprintIcon />
        {adding ? t("passkey.adding") : t("passkey.add")}
      </PressButton>
      {error && <StepError id={errorId}>{error}</StepError>}
    </StepFrame>
  );
}
