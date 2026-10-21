import { SUPPORTED_CURRENCIES, type SupportedCurrency } from "@lukas/core";
import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { StepFrame, type StepNavProps } from "./StepFrame.tsx";

export interface CurrencyStepProps extends StepNavProps {
  value: SupportedCurrency;
  onChange(currency: SupportedCurrency): void;
  /** While the choice is saved. */
  busy?: boolean;
  error?: string | null;
}

/** "Peso colombiano": the currency's name in the person's language, capitalized. */
function currencyName(code: string, locale: string): string {
  const name = new Intl.DisplayNames([locale], { type: "currency" }).of(code) ?? code;
  return name.charAt(0).toLocaleUpperCase(locale) + name.slice(1);
}

/** Step 0: the account's currency, one radio per supported currency, preselected by the flow. */
export function CurrencyStep({
  value,
  onChange,
  onBack,
  onNext,
  busy = false,
  error,
}: CurrencyStepProps) {
  const t = useTranslations("onboarding");
  const { locale } = useLocale();
  return (
    <StepFrame
      step="currency"
      title={t("currency.title")}
      lead={t("currency.lead")}
      onBack={onBack}
      next={{ label: busy ? t("saving") : t("continue"), onClick: onNext, disabled: busy }}
    >
      <fieldset className="flex flex-col gap-(--space-2)">
        <legend className="sr-only">{t("currency.label")}</legend>
        {SUPPORTED_CURRENCIES.map((code) => (
          <label
            key={code}
            className="flex min-h-11 cursor-pointer items-center gap-(--space-3) rounded-lg border-2 border-stroke bg-surface-row px-(--space-4) py-(--space-3) shadow-edge-sm has-checked:border-brand-glow has-focus-visible:outline-3 has-focus-visible:outline-focus has-focus-visible:outline-offset-2"
          >
            <input
              type="radio"
              name="currency"
              value={code}
              checked={value === code}
              onChange={() => onChange(code)}
              className="size-5 shrink-0 accent-brand outline-none"
            />
            <span className="flex-1 text-ink">{currencyName(code, locale)}</span>
            <span className="lk-num text-ink-muted">{code}</span>
          </label>
        ))}
      </fieldset>
      {error && (
        <p role="alert" className="text-[15px] text-over">
          {error}
        </p>
      )}
    </StepFrame>
  );
}
