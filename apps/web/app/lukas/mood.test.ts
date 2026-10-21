import type { CategorySummary, MonthSummary } from "@lukas/core";
import { describe, expect, it } from "vitest";
import { moodFor } from "./mood.ts";

function category(state: CategorySummary["state"], id: string): CategorySummary {
  return { categoryId: id, budget: 10000, spent: 0, remaining: 10000, ratio: 0, state };
}

function summary(...states: CategorySummary["state"][]): MonthSummary {
  return {
    month: "2026-10",
    budgetTotal: 30000,
    spent: 0,
    remaining: 30000,
    income: 0,
    balance: 0,
    categories: states.map((state, i) => category(state, `c${i}`)),
  };
}

describe("moodFor", () => {
  it("is happy when every category is ok", () => {
    expect(moodFor(summary("ok", "ok", "ok"), false)).toBe("happy");
  });

  it("is happy with no categories at all", () => {
    expect(moodFor(summary(), false)).toBe("happy");
  });

  it("is worried when any category is near its limit", () => {
    expect(moodFor(summary("ok", "near", "ok"), false)).toBe("worried");
  });

  it("is worried when any category is over its limit", () => {
    expect(moodFor(summary("ok", "ok", "over"), false)).toBe("worried");
  });

  it("lets the celebrating flag win over a worried month", () => {
    expect(moodFor(summary("over", "near"), true)).toBe("celebrating");
  });

  it("celebrates a happy month too", () => {
    expect(moodFor(summary("ok"), true)).toBe("celebrating");
  });
});
