import { describe, expect, it } from "vitest";
import type { Locale } from "../i18n/format.ts";
import {
  type AmountFormat,
  amountCents,
  pasteAmount,
  pastedNegative,
  pressKey,
  typeOnKeypad,
  wholeAmount,
} from "./keypad-input.ts";

/** Types `keys` (as `KeyboardEvent.key` values) from an empty amount; ignored keys change nothing. */
function type(keys: string[], format: AmountFormat): string {
  let value = "";
  for (const key of keys) value = typeOnKeypad(value, key, format) ?? value;
  return value;
}

const chars = (text: string) => [...text];

describe("typing an amount", () => {
  const cases: [Locale, string, string, string][] = [
    // locale, currency, keys typed, raw value
    ["es", "COP", "15.000", "15000"],
    // Pesos: the decimal separator ends the amount; what follows it does not count.
    ["es", "COP", "15.000,5", "15000,"],
    ["es", "COP", "50.000,50", "50000,"],
    ["es", "COP", "50000,5", "50000,"],
    ["es", "COP", "999999999", "999999999"],
    ["es", "COP", "1000000000", "100000000"],
    ["en", "COP", "15,000", "15000"],
    ["en", "COP", "50000.5", "50000."],
    ["en", "COP", "50,000.75", "50000."],
    ["es", "EUR", "6,08", "6,08"],
    ["es", "EUR", "15.000", "15000"],
    ["es", "EUR", "6,089", "6,08"],
    ["es", "EUR", "6,0,8", "6,08"],
    ["es", "EUR", ",5", "0,5"],
    ["es", "EUR", "007", "7"],
    ["en", "EUR", "6.08", "6.08"],
    ["en", "EUR", "1,234.5", "1234.5"],
    ["es", "USD", "1.250,75", "1250,75"],
    ["en", "USD", "1,250.75", "1250.75"],
    ["en", "USD", "999999999.99", "999999999.99"],
    ["en", "USD", "9999999999", "999999999"],
  ];
  it.each(cases)("%s %s: typing %s gives %s", (locale, currency, keys, raw) => {
    expect(type(chars(keys), { locale, currency })).toBe(raw);
  });

  it("Backspace removes the last character", () => {
    expect(typeOnKeypad("6,08", "Backspace", { locale: "es", currency: "EUR" })).toBe("6,0");
  });

  it("is null for keys that are not for the amount, so the page keeps them", () => {
    for (const key of ["a", "Enter", "Tab", " ", "-"]) {
      expect(typeOnKeypad("6", key, { locale: "es", currency: "EUR" })).toBeNull();
    }
    expect(typeOnKeypad("6", ".", { locale: "es", currency: "EUR" })).toBeNull();
    expect(typeOnKeypad("6", ".", { locale: "es", currency: "COP" })).toBeNull();
  });

  it("in pesos, the amount is what comes before the separator, and Backspace undoes it", () => {
    const cop = { locale: "es", currency: "COP" } as const;
    let value = type(chars("15.000,5"), cop);
    expect(wholeAmount(value, cop)).toBe("15000");
    value = typeOnKeypad(value, "Backspace", cop) ?? value;
    expect(value).toBe("15000");
    expect(typeOnKeypad(value, "7", cop)).toBe("150007");
    // A separator with nothing before it is ignored.
    expect(typeOnKeypad("", ",", cop)).toBe("");
    expect(wholeAmount("6,08", { locale: "es", currency: "EUR" })).toBe("6,08");
  });

  it("a decimal key ends a peso amount and starts euro decimals", () => {
    expect(pressKey("50", { kind: "decimal" }, { locale: "es", currency: "COP" })).toBe("50,");
    expect(pressKey("50,", { kind: "digit", digit: "5" }, { locale: "es", currency: "COP" })).toBe(
      "50,",
    );
    expect(pressKey("50", { kind: "decimal" }, { locale: "es", currency: "EUR" })).toBe("50,");
  });
});

describe("pasting an amount", () => {
  const cases: [Locale, string, string, string | null][] = [
    // Decimal currencies: a single separator followed by exactly 1–2 digits is the decimal one;
    // otherwise "." and "," are thousands separators. The same in either language.
    ["es", "EUR", "6.08", "6,08"],
    ["en", "EUR", "6.08", "6.08"],
    ["es", "USD", "$6.08", "6,08"],
    ["es", "EUR", "1.234", "1234"],
    ["en", "USD", "1.234", "1234"],
    ["es", "EUR", "1.234,56", "1234,56"],
    ["en", "EUR", "1.234,56", "1234.56"],
    ["es", "EUR", "1,234.56", "1234,56"],
    ["en", "USD", "€1,234.56", "1234.56"],
    ["es", "EUR", "$ 50.000", "50000"],
    ["en", "USD", "$ 50.000", "50000"],
    ["es", "EUR", "1.5", "1,5"],
    ["es", "EUR", "6,08 €", "6,08"],
    ["es", "EUR", "−6,08", "6,08"],
    ["es", "EUR", "6,089", "6089"],
    ["es", "USD", "US$ 1.250,75", "1250,75"],
    ["en", "USD", "1,000,000.50", "1000000.50"],
    ["en", "USD", "999,999,999.99", "999999999.99"],
    ["es", "EUR", "007", "7"],
    // Not one clear amount: nothing is pasted.
    ["es", "EUR", "1,2,3", null],
    ["es", "EUR", "1234,567", null],
    ["en", "USD", "lunch", null],
    ["es", "EUR", "2024-10-21", null],
    ["es", "EUR", "Total 2 items 50.000", null],
    // Pesos: the locale's decimal separator ends the amount; the other one is thousands.
    ["es", "COP", "$50.000", "50000"],
    ["es", "COP", "15.000", "15000"],
    ["es", "COP", "15.000,5", "15000"],
    ["es", "COP", "50.000,50", "50000"],
    ["es", "COP", "4.300.000", "4300000"],
    ["en", "COP", "COP 50,000", "50000"],
    ["en", "COP", "50,000.75", "50000"],
    ["es", "COP", "$6.08", null],
    ["es", "COP", "1.000.000.000", null],
  ];
  it.each(cases)("%s %s: pasting %j gives %j", (locale, currency, text, raw) => {
    expect(pasteAmount(text, { locale, currency })).toBe(raw);
  });

  it("typing and pasting the same peso text give the same amount", () => {
    const cop = { locale: "es", currency: "COP" } as const;
    for (const text of ["15.000,5", "50.000,50", "4.300.000"]) {
      expect(wholeAmount(type(chars(text), cop), cop)).toBe(pasteAmount(text, cop));
    }
  });
});

describe("amountCents: the keypad's text as the stored ×100 integer", () => {
  const cases: [Locale, string, string, number][] = [
    ["es", "COP", "", 0],
    ["es", "COP", "15000", 1_500_000],
    // Pesos: the decimal separator only ends the amount.
    ["es", "COP", "15000,", 1_500_000],
    ["es", "COP", "15000,5", 1_500_000],
    ["en", "COP", "50000.", 5_000_000],
    ["es", "EUR", "6,08", 608],
    ["es", "EUR", "6,", 600],
    ["en", "USD", "1250.5", 125_050],
    ["es", "EUR", "999999999,99", 99_999_999_999],
  ];
  it.each(cases)("%s %s: %j is %d", (locale, currency, raw, cents) => {
    expect(amountCents(raw, { locale, currency })).toBe(cents);
  });
});

describe("pastedNegative: a minus before the first digit", () => {
  it.each(["-50.000", "−6,08 €", "- 50", "$-15.000", "‑20", "–20"])("%j is negative", (text) => {
    expect(pastedNegative(text)).toBe(true);
  });
  it.each(["50-", "50.000", "6,08 €", "2026-10-21", "$ 15.000", ""])("%j is not", (text) => {
    expect(pastedNegative(text)).toBe(false);
  });
});
