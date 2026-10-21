import { InvalidAmountError } from "@lukas/core";
import { describe, expect, it } from "vitest";
import {
  detectLocale,
  formatDay,
  formatMoney,
  formatMonth,
  localeFromPathname,
  parseAmountInput,
} from "./format.ts";

const NBSP = " ";

describe("detectLocale", () => {
  it("maps Spanish variants to es and everything else to en", () => {
    expect(detectLocale("es")).toBe("es");
    expect(detectLocale("es-CO")).toBe("es");
    expect(detectLocale("ES-mx")).toBe("es");
    expect(detectLocale("en-US")).toBe("en");
    expect(detectLocale("fr")).toBe("en");
    expect(detectLocale(undefined)).toBe("en");
  });
});

describe("localeFromPathname", () => {
  it("uses en only under the /en prefix", () => {
    expect(localeFromPathname("/en")).toBe("en");
    expect(localeFromPathname("/en/")).toBe("en");
    expect(localeFromPathname("/en/privacy")).toBe("en");
    expect(localeFromPathname("/")).toBe("es");
    expect(localeFromPathname("/entradas")).toBe("es");
    expect(localeFromPathname("/privacidad")).toBe("es");
  });
});

describe("formatMoney", () => {
  it("formats with the locale's conventions", () => {
    expect(formatMoney(56292, "EUR", "en")).toBe("€562.92");
    expect(formatMoney(56292, "EUR", "es")).toBe(`562,92${NBSP}€`);
    expect(formatMoney(123456, "EUR", "en")).toBe("€1,234.56");
  });

  it("uses the real minus sign U+2212 for negatives", () => {
    expect(formatMoney(-608, "EUR", "es")).toBe(`−6,08${NBSP}€`);
    expect(formatMoney(-608, "EUR", "en")).toBe("−€6.08");
    expect(formatMoney(-608, "EUR", "en")).not.toContain("-");
  });

  it("shows an explicit plus with sign: always", () => {
    expect(formatMoney(1500, "EUR", "en", { sign: "always" })).toBe("+€15.00");
    expect(formatMoney(-1500, "EUR", "en", { sign: "always" })).toBe("−€15.00");
    expect(formatMoney(0, "EUR", "en", { sign: "always" })).toBe("€0.00");
  });

  it("never renders a negative zero", () => {
    expect(formatMoney(-0, "EUR", "en")).toBe("€0.00");
  });

  it("honours the currency's own minor units", () => {
    expect(formatMoney(1500, "COP", "es")).toContain("15");
  });
});

describe("formatDay / formatMonth", () => {
  it("formats a short weekday and the day of month", () => {
    expect(formatDay("2026-10-21", "es")).toBe("mié 21");
    expect(formatDay("2026-10-21", "en")).toBe("Wed 21");
    expect(formatDay("2026-10-06", "en")).toBe("Tue 6");
  });

  it("formats the month name capitalized", () => {
    expect(formatMonth("2026-10", "es")).toBe("Octubre");
    expect(formatMonth("2026-10", "en")).toBe("October");
  });
});

describe("parseAmountInput", () => {
  it("accepts the locale's decimal separator", () => {
    expect(parseAmountInput("6,08", "es")).toBe(608);
    expect(parseAmountInput("6.08", "en")).toBe(608);
    expect(parseAmountInput("-30,7", "es")).toBe(-3070);
    expect(parseAmountInput(" 12 ", "en")).toBe(1200);
  });

  it("rejects the other locale's separator", () => {
    expect(() => parseAmountInput("6.08", "es")).toThrow(InvalidAmountError);
    expect(() => parseAmountInput("6,08", "en")).toThrow(InvalidAmountError);
  });

  it("rejects garbage", () => {
    expect(() => parseAmountInput("abc", "es")).toThrow(InvalidAmountError);
    expect(() => parseAmountInput("", "en")).toThrow(InvalidAmountError);
  });
});
