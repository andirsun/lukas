import { describe, expect, it } from "vitest";
import { formatMoney, ToolError, toMinor } from "../src/index.ts";

describe("toMinor", () => {
  it("multiplies by 100 and makes expenses negative", () => {
    expect(toMinor(18000, "expense")).toBe(-1800000);
  });

  it("keeps two decimals and makes income positive", () => {
    expect(toMinor(18.5, "income")).toBe(1850);
  });

  it("takes the sign from the kind only", () => {
    expect(toMinor(-18000, "expense")).toBe(-1800000);
    expect(toMinor(-18000, "income")).toBe(1800000);
  });

  it("rounds to the minor unit", () => {
    expect(toMinor(18.555, "income")).toBe(1856);
    expect(toMinor(0.1 + 0.2, "expense")).toBe(-30);
  });

  it("refuses zero, amounts that round to zero and non-finite numbers", () => {
    for (const amount of [0, 0.001, Number.NaN, Number.POSITIVE_INFINITY, 1e20]) {
      expect(() => toMinor(amount, "expense")).toThrow(ToolError);
      try {
        toMinor(amount, "expense");
      } catch (error) {
        expect((error as ToolError).code).toBe("invalid_amount");
      }
    }
  });
});

describe("formatMoney", () => {
  it("writes pesos the Colombian way in Spanish", () => {
    expect(formatMoney(1800000, "COP", "es")).toBe("$18.000");
    expect(formatMoney(-1800000, "COP", "es")).toBe("-$18.000");
  });

  it("shows no decimals for COP, rounding the stored hundredths", () => {
    expect(formatMoney(1850, "COP", "es")).toBe("$19");
  });

  it("keeps the code for COP in English, so it does not read as dollars", () => {
    expect(formatMoney(1800000, "COP", "en")).toMatch(/^COP\s?18,000$/);
  });

  it("uses two decimals and the locale's conventions for other currencies", () => {
    expect(formatMoney(56292, "EUR", "es")).toBe("562,92\u00a0€");
    expect(formatMoney(1850, "USD", "en")).toBe("$18.50");
    expect(formatMoney(-608, "EUR", "pt")).toBe("-6,08\u00a0€");
  });
});
