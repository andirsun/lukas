import { useTranslations } from "use-intl";
import type { Locale } from "../i18n/format.ts";
import { decimalSeparator, type KeypadKey, pressKey, takesDecimals } from "./keypad-input.ts";

export { typeOnKeypad } from "./keypad-input.ts";

export interface KeypadProps {
  /** The raw text typed so far (`6,08` in es, `6.08` in en); parse it with `parseAmountInput`. */
  value: string;
  onChange(value: string): void;
  locale: Locale;
  /**
   * ISO 4217 code. Whole-unit currencies (COP, CLP) get no decimal key: there are no fractional
   * pesos. Without one, decimals are allowed.
   */
  currency?: string;
}

/**
 * The add sheet's numeric keypad: digits, the locale's decimal key (`,` es, `.` en; none for
 * whole-unit currencies) and backspace, at most two decimals, capped at 999.999.999,99 (the
 * rules are in `keypad-input.ts`). It edits the raw text and reports every change; keys that
 * would not change it (a third decimal, a second separator, past the cap) are ignored.
 */
export function Keypad({ value, onChange, locale, currency }: KeypadProps) {
  const t = useTranslations("keypad");
  const decimals = takesDecimals(currency);
  const keys: ({ key: KeypadKey; text: string; label?: string } | null)[] = [
    ..."123456789"
      .split("")
      .map((digit) => ({ key: { kind: "digit", digit } as KeypadKey, text: digit })),
    decimals
      ? { key: { kind: "decimal" }, text: decimalSeparator(locale), label: t("decimal") }
      : null,
    { key: { kind: "digit", digit: "0" }, text: "0" },
    { key: { kind: "backspace" }, text: "⌫", label: t("backspace") },
  ];

  return (
    <div role="group" aria-label={t("label")} className="lk-keys">
      {keys.map((entry) =>
        entry === null ? (
          <span key="no-decimal" aria-hidden="true" />
        ) : (
          <button
            key={entry.text}
            type="button"
            className="lk-key min-h-11"
            aria-label={entry.label}
            onClick={() => {
              const next = pressKey(value, entry.key, { locale, currency });
              if (next !== value) onChange(next);
            }}
          >
            {entry.text}
          </button>
        ),
      )}
    </div>
  );
}
