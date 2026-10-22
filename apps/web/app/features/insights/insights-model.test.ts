import { describe, expect, it } from "vitest";
import {
  formatShare,
  fraction,
  isSpan,
  livingPeriod,
  livingWindow,
  monthLabel,
  periodOf,
  shortMonth,
  trendPeriod,
} from "./insights-model.ts";

const NBSP = "\u00a0";

describe("periods", () => {
  it("ends a span at the month on screen", () => {
    expect(periodOf("2026-10", 1)).toEqual({ from: "2026-10", to: "2026-10" });
    expect(periodOf("2026-10", 3)).toEqual({ from: "2026-08", to: "2026-10" });
    expect(periodOf("2026-02", 12)).toEqual({ from: "2025-03", to: "2026-02" });
  });

  it("shows six months of trend, or a year for a year", () => {
    expect(trendPeriod("2026-10", 1)).toEqual({ from: "2026-05", to: "2026-10" });
    expect(trendPeriod("2026-10", 6)).toEqual({ from: "2026-05", to: "2026-10" });
    expect(trendPeriod("2026-10", 12)).toEqual({ from: "2025-11", to: "2026-10" });
  });

  it("knows the spans", () => {
    expect(isSpan(3)).toBe(true);
    expect(isSpan(2)).toBe(false);
  });
});

describe("cost of living window", () => {
  it("is the six complete months before the current one", () => {
    expect(livingPeriod("2026-10")).toEqual({ from: "2026-04", to: "2026-09" });
    expect(livingPeriod("2026-01")).toEqual({ from: "2025-07", to: "2025-12" });
  });

  const month = (income: number, expenses: number) => ({ income, expenses });

  it("starts at the first month with anything in it", () => {
    const empty = month(0, 0);
    expect(livingWindow([empty, empty, empty, empty, empty, month(0, 13313)])).toBe(1);
    expect(livingWindow([empty, month(300000, 0), empty, month(0, 5), empty, empty])).toBe(5);
    expect(livingWindow(Array.from({ length: 6 }, () => month(1, 1)))).toBe(6);
  });

  it("is 0 without any complete month with transactions", () => {
    expect(livingWindow(Array.from({ length: 6 }, () => month(0, 0)))).toBe(0);
    expect(livingWindow([])).toBe(0);
  });
});

describe("formatting", () => {
  it("writes shares with at most one decimal", () => {
    expect(formatShare(0.5944, "es")).toBe(`59,4${NBSP}%`);
    expect(formatShare(0.5944, "en")).toBe("59.4%");
    expect(formatShare(1, "es")).toBe(`100${NBSP}%`);
    expect(formatShare(0.05, "en")).toBe("5%");
  });

  it("names months mid-sentence, with the year only when it is another one", () => {
    expect(monthLabel("2026-10", "2026-10", "es")).toBe("octubre");
    expect(monthLabel("2025-12", "2026-10", "es")).toBe("diciembre de 2025");
    expect(monthLabel("2026-10", "2026-10", "en")).toBe("October");
    expect(monthLabel("2025-12", "2026-10", "en")).toBe("December 2025");
  });

  it("shortens months for the axis", () => {
    expect(shortMonth("2026-10", "es")).toBe("oct");
    expect(shortMonth("2026-10", "en")).toBe("Oct");
  });

  it("clamps fractions for bars", () => {
    expect(fraction(50, 200)).toBe(0.25);
    expect(fraction(-5, 200)).toBe(0);
    expect(fraction(5, 0)).toBe(0);
    expect(fraction(300, 200)).toBe(1);
  });
});
