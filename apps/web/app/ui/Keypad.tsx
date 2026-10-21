import { useTranslations } from "use-intl";
import type { Locale } from "../i18n/format.ts";

export interface KeypadProps {
  /** The raw text typed so far (`6,08` in es, `6.08` in en); parse it with `parseAmountInput`. */
  value: string;
  onChange(value: string): void;
  locale: Locale;
}

/** Up to 9.999.999,99: far below the safe-integer limit of cents. */
const MAX_WHOLE_DIGITS = 7;
const MAX_DECIMALS = 2;

type Key = { kind: "digit"; digit: string } | { kind: "decimal" } | { kind: "backspace" };

function decimalSeparator(locale: Locale): string {
  return locale === "es" ? "," : ".";
}

/** The value after pressing `key`, or the same value when the key does not apply. */
function press(value: string, key: Key, separator: string): string {
  if (key.kind === "backspace") return value.slice(0, -1);
  const [whole = "", decimals] = value.split(separator);
  if (key.kind === "decimal") {
    if (decimals !== undefined) return value;
    return `${whole || "0"}${separator}`;
  }
  if (decimals !== undefined) {
    return decimals.length < MAX_DECIMALS ? value + key.digit : value;
  }
  if (whole === "0") return key.digit;
  return whole.length < MAX_WHOLE_DIGITS ? whole + key.digit : value;
}

/**
 * The value after typing `key` (a `KeyboardEvent.key`) on a physical keyboard: digits, either
 * decimal separator (`,` or `.`, so a desktop numpad works in both languages) and Backspace. Null
 * when the key is not one of those.
 */
export function typeOnKeypad(value: string, key: string, locale: Locale): string | null {
  if (/^[0-9]$/.test(key))
    return press(value, { kind: "digit", digit: key }, decimalSeparator(locale));
  if (key === "," || key === ".")
    return press(value, { kind: "decimal" }, decimalSeparator(locale));
  if (key === "Backspace") return press(value, { kind: "backspace" }, decimalSeparator(locale));
  return null;
}

/**
 * The add sheet's numeric keypad: digits, the locale's decimal key (`,` es, `.` en) and
 * backspace, at most two decimals. It edits the raw text and reports every change; keys that
 * would not change it (a third decimal, a second separator) are ignored.
 */
export function Keypad({ value, onChange, locale }: KeypadProps) {
  const t = useTranslations("keypad");
  const separator = decimalSeparator(locale);
  const keys: { key: Key; text: string; label?: string }[] = [
    ..."123456789"
      .split("")
      .map((digit) => ({ key: { kind: "digit", digit } as Key, text: digit })),
    { key: { kind: "decimal" }, text: separator, label: t("decimal") },
    { key: { kind: "digit", digit: "0" }, text: "0" },
    { key: { kind: "backspace" }, text: "⌫", label: t("backspace") },
  ];

  return (
    <div role="group" aria-label={t("label")} className="lk-keys">
      {keys.map(({ key, text, label }) => (
        <button
          key={text}
          type="button"
          className="lk-key min-h-11"
          aria-label={label}
          onClick={() => {
            const next = press(value, key, separator);
            if (next !== value) onChange(next);
          }}
        >
          {text}
        </button>
      ))}
    </div>
  );
}
