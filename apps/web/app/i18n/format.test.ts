import { InvalidAmountError } from "@lukas/core";
import { describe, expect, it } from "vitest";
import {
  detectLocale,
  formatDay,
  formatMoney,
  formatMonth,
  localeFromPathname,
  lukasHint,
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

  it("stores every currency in hundredths, so COP shows whole pesos from pesos x 100", () => {
    // 50.000 pesos are stored as 5.000.000, the same convention as parseAmountInput.
    expect(formatMoney(5_000_000, "COP", "es")).toBe(`50.000${NBSP}COP`);
    expect(formatMoney(5_000_000, "COP", "en")).toBe(`COP${NBSP}50,000`);
    expect(formatMoney(-430_000_000, "COP", "es")).toBe(`−4.300.000${NBSP}COP`);
    expect(formatMoney(parseAmountInput("50000", "es"), "COP", "es")).toBe(`50.000${NBSP}COP`);
  });
});

/** The amount as stored: pesos x 100, like every other currency's minor units. */
const pesos = (n: number) => n * 100;

describe("lukasHint", () => {
  it("counts lukas (1.000 pesos) in Spanish", () => {
    expect(lukasHint(pesos(1000), "COP", "es")).toBe("1 luka");
    expect(lukasHint(pesos(50000), "COP", "es")).toBe("50 lukas");
    expect(lukasHint(pesos(15500), "COP", "es")).toBe("15,5 lukas");
    expect(lukasHint(pesos(15540), "COP", "es")).toBe("15,5 lukas");
    expect(lukasHint(pesos(15550), "COP", "es")).toBe("15,6 lukas");
    expect(lukasHint(pesos(15000), "COP", "es")).toBe("15 lukas");
    expect(lukasHint(pesos(1500), "COP", "es")).toBe("1,5 lukas");
    expect(lukasHint(pesos(999000), "COP", "es")).toBe("999 lukas");
  });

  it("counts palos (1.000.000 pesos) in Spanish, up to two decimals", () => {
    expect(lukasHint(pesos(1_000_000), "COP", "es")).toBe("1 palo");
    expect(lukasHint(pesos(4_300_000), "COP", "es")).toBe("4,3 palos");
    expect(lukasHint(pesos(1_250_000), "COP", "es")).toBe("1,25 palos");
    expect(lukasHint(pesos(1_256_000), "COP", "es")).toBe("1,26 palos");
    expect(lukasHint(pesos(12_000_000), "COP", "es")).toBe("12 palos");
  });

  it("moves to palos after rounding", () => {
    expect(lukasHint(pesos(999_990), "COP", "es")).toBe("1 palo");
    expect(lukasHint(pesos(999_950), "COP", "es")).toBe("1 palo");
    expect(lukasHint(pesos(999_940), "COP", "es")).toBe("999,9 lukas");
  });

  it("uses k and M in English", () => {
    expect(lukasHint(pesos(50000), "COP", "en")).toBe("50k");
    expect(lukasHint(pesos(15540), "COP", "en")).toBe("15.5k");
    expect(lukasHint(pesos(1000), "COP", "en")).toBe("1k");
    expect(lukasHint(pesos(4_300_000), "COP", "en")).toBe("4.3M");
    expect(lukasHint(pesos(1_250_000), "COP", "en")).toBe("1.25M");
    expect(lukasHint(pesos(999_990), "COP", "en")).toBe("1M");
  });

  it("returns null under 1.000 pesos", () => {
    expect(lukasHint(0, "COP", "es")).toBeNull();
    expect(lukasHint(pesos(999), "COP", "es")).toBeNull();
    expect(lukasHint(99_999, "COP", "es")).toBeNull();
    expect(lukasHint(pesos(999), "COP", "en")).toBeNull();
  });

  it("returns null for every other currency", () => {
    expect(lukasHint(pesos(50000), "EUR", "es")).toBeNull();
    expect(lukasHint(pesos(50000), "USD", "en")).toBeNull();
    expect(lukasHint(pesos(50000), "MXN", "es")).toBeNull();
  });

  it("describes the size of an amount, whatever its sign", () => {
    expect(lukasHint(-pesos(50000), "COP", "es")).toBe("50 lukas");
  });

  it("agrees with formatMoney for the same stored integer", () => {
    const stored = pesos(4_300_000);
    expect(formatMoney(stored, "COP", "es")).toBe(`4.300.000${NBSP}COP`);
    expect(lukasHint(stored, "COP", "es")).toBe("4,3 palos");
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
