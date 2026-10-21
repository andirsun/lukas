import { describe, expect, it } from "vitest";
import type { Locale } from "../i18n/format.ts";
import { type AmountFormat, pasteAmount, pressKey, typeOnKeypad } from "./keypad-input.ts";

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
    ["es", "COP", "50000,5", "500005"],
    ["es", "COP", "999999999", "999999999"],
    ["es", "COP", "1000000000", "100000000"],
    ["en", "COP", "15,000", "15000"],
    ["en", "COP", "50000.5", "500005"],
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
    expect(typeOnKeypad("6", ",", { locale: "es", currency: "COP" })).toBeNull();
    expect(typeOnKeypad("6", ".", { locale: "es", currency: "EUR" })).toBeNull();
  });

  it("the keypad's decimal key does nothing for whole-unit currencies", () => {
    expect(pressKey("50", { kind: "decimal" }, { locale: "es", currency: "COP" })).toBe("50");
    expect(pressKey("50", { kind: "decimal" }, { locale: "es", currency: "EUR" })).toBe("50,");
  });
});

describe("pasting an amount", () => {
  const cases: [Locale, string, string, string | null][] = [
    ["es", "COP", "$50.000", "50000"],
    ["es", "COP", "15.000", "15000"],
    ["es", "COP", "4.300.000", "4300000"],
    ["es", "COP", "50.000,50", "50000"],
    ["en", "COP", "COP 50,000", "50000"],
    ["en", "COP", "50,000.75", "50000"],
    ["es", "COP", "1.000.000.000", null],
    ["es", "EUR", "6,08 €", "6,08"],
    ["es", "EUR", "1.234,56", "1234,56"],
    ["es", "EUR", "−6,08", "6,08"],
    ["es", "EUR", "6,089", null],
    ["es", "EUR", "1,2,3", null],
    ["en", "EUR", "€1,234.56", "1234.56"],
    ["en", "USD", "$6.08", "6.08"],
    ["es", "USD", "US$ 1.250,75", "1250,75"],
    ["en", "USD", "999,999,999.99", "999999999.99"],
    ["en", "USD", "lunch", null],
    ["es", "EUR", "007", "7"],
  ];
  it.each(cases)("%s %s: pasting %j gives %j", (locale, currency, text, raw) => {
    expect(pasteAmount(text, { locale, currency })).toBe(raw);
  });
});
