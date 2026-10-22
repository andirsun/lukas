import { useEffect, useState } from "react";
import { formatAmountInput, lukasHint } from "../i18n/format.ts";
import { useLocale } from "../i18n/IntlProvider.tsx";
import { cx } from "./cx.ts";
import { Keypad } from "./Keypad.tsx";
import {
  amountCents,
  pasteAmount,
  pastedNegative,
  typeOnKeypad,
  wholeAmount,
} from "./keypad-input.ts";

/** How long typing must pause before the amount is announced. */
const ANNOUNCE_AFTER_MS = 500;

/** `value` once it has stopped changing for `ms`. */
function useSettled<T>(value: T, ms: number): T {
  const [settled, setSettled] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setSettled(value), ms);
    return () => clearTimeout(timer);
  }, [value, ms]);
  return settled;
}

const inField = (target: EventTarget | null) =>
  target instanceof HTMLInputElement ||
  target instanceof HTMLTextAreaElement ||
  target instanceof HTMLSelectElement;

export interface AmountKeysOptions {
  /** Listen only while the form is on screen (its sheet is open). */
  active: boolean;
  raw: string;
  setRaw(raw: string): void;
  currency: string;
  /**
   * A minus typed or a negative amount pasted. Without it they are ignored (a typed `-`) or the
   * sign is dropped (a paste), as in the add sheet, whose sign comes from expense / income.
   */
  onNegative?: (() => void) | undefined;
}

/**
 * A physical keyboard and the clipboard type on the keypad, unless a text field or a select has
 * the keys. The thousands separator is ignored ("15.000" in Spanish is 15000) and pesos take no
 * decimals (`keypad-input.ts`).
 */
export function useAmountKeys({ active, raw, setRaw, currency, onNegative }: AmountKeysOptions) {
  const { locale } = useLocale();
  useEffect(() => {
    if (!active) return;
    const format = { locale, currency };
    const onKey = (event: KeyboardEvent) => {
      if (event.metaKey || event.ctrlKey || event.altKey || inField(event.target)) return;
      if (onNegative && (event.key === "-" || event.key === "Subtract")) {
        event.preventDefault();
        onNegative();
        return;
      }
      const next = typeOnKeypad(raw, event.key, format);
      if (next === null) return;
      event.preventDefault();
      setRaw(next);
    };
    const onPaste = (event: ClipboardEvent) => {
      if (inField(event.target)) return;
      const text = event.clipboardData?.getData("text") ?? "";
      if (onNegative && pastedNegative(text)) {
        event.preventDefault();
        onNegative();
        return;
      }
      const next = pasteAmount(text, format);
      if (next === null) return;
      event.preventDefault();
      setRaw(next);
    };
    document.addEventListener("keydown", onKey);
    document.addEventListener("paste", onPaste);
    return () => {
      document.removeEventListener("keydown", onKey);
      document.removeEventListener("paste", onPaste);
    };
  }, [active, raw, setRaw, locale, currency, onNegative]);
}

export interface AmountFieldProps extends AmountKeysOptions {
  /** Shown before the amount once there is one: `−` for spending, `+` for income. */
  sign?: "−" | "+" | "";
  /** Colors the figure like the add sheet: spending, income, or neither (a budget). */
  tone?: "expense" | "income" | "neutral";
  /** For tests: the figure's `data-testid`. */
  testId?: string;
  /** Ties an error message to the figure. */
  invalid?: boolean;
}

/**
 * The amount as the add sheet takes it, for any sheet: the big figure (with the muted lukas hint
 * in pesos), the numeric keypad under it, and a physical keyboard or a paste typing too. Screen
 * readers hear the amount once typing pauses.
 */
export function AmountField({
  sign = "",
  tone = "neutral",
  testId,
  invalid = false,
  ...keys
}: AmountFieldProps) {
  const { locale } = useLocale();
  useAmountKeys(keys);
  const { raw, setRaw, currency } = keys;
  const format = { locale, currency };
  const cents = amountCents(raw, format);
  const hint = lukasHint(cents, currency, locale);
  const text = `${cents > 0 ? sign : ""}${formatAmountInput(wholeAmount(raw, format), currency, locale)}`;
  const announced = useSettled(hint ? `${text} (${hint})` : text, ANNOUNCE_AFTER_MS);

  return (
    <>
      <p
        data-testid={testId}
        aria-hidden="true"
        className={cx(
          "lk-amount-display lk-sheet-amount",
          tone === "expense" && "is-expense",
          tone === "income" && "is-income",
          invalid && "text-over",
        )}
      >
        {text}
        {hint && " "}
        {hint && (
          <span className="align-middle font-text text-[14px] font-bold text-ink-muted">
            ({hint})
          </span>
        )}
      </p>
      <p className="sr-only" aria-live="polite">
        {announced}
      </p>
      <Keypad value={raw} onChange={setRaw} locale={locale} currency={currency} />
    </>
  );
}
