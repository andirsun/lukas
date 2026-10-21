import { useTranslations } from "use-intl";
import { PressButton } from "../../ui/PressButton.tsx";
import { StepError, StepFrame } from "./StepFrame.tsx";

export interface WelcomeStepProps {
  /** The currency "Entrar directo" would set, named in the note. */
  currency: string;
  /** CONFIGURAR EN 1 MINUTO: on to the currency. */
  onSetup(): void;
  /** ENTRAR DIRECTO: defaults for everything, then the app. */
  onDirect(): void;
  /** While "Entrar directo" saves the defaults. */
  busy?: boolean;
  error?: string | null;
}

/**
 * The onboarding's first screen (spec §2.4): set up in a minute, or go straight in. Going straight
 * in still leaves a usable account (the region's currency, the suggested categories).
 */
export function WelcomeStep({
  currency,
  onSetup,
  onDirect,
  busy = false,
  error,
}: WelcomeStepProps) {
  const t = useTranslations("onboarding");
  return (
    <StepFrame step="welcome" title={t("welcome.title")} lead={t("welcome.lead")}>
      <PressButton className="w-full" onClick={onSetup} disabled={busy}>
        {t("welcome.setup")}
      </PressButton>
      <PressButton variant="secondary" className="w-full" onClick={onDirect} disabled={busy}>
        {busy ? t("saving") : t("welcome.direct")}
      </PressButton>
      <p className="text-[15px] text-ink-muted">{t("welcome.direct_note", { currency })}</p>
      {error && <StepError>{error}</StepError>}
    </StepFrame>
  );
}
