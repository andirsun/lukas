import { describe, expect, test } from "vitest";
import { lukasMessage, type MonthSummary, monthSummary } from "../src/index.ts";
import { OCTOBER_2026 } from "./fixtures/october-2026.ts";

/**
 * October 2026 summary. `spent` overrides the fixture's spending per expense category (cents,
 * positive); `extra` adds more spending on top, as if an event had just been applied.
 */
function october(
  options: { spent?: Record<string, number>; extra?: Record<string, number> } = {},
): MonthSummary {
  return monthSummary({
    month: OCTOBER_2026.month,
    categories: [
      ...OCTOBER_2026.expense.map((c) => ({ id: c.key, kind: "expense" as const })),
      ...OCTOBER_2026.income.map((c) => ({ id: c.key, kind: "income" as const })),
    ],
    budgets: OCTOBER_2026.expense.map((c) => ({
      categoryId: c.key,
      amount: c.budget,
      effectiveFrom: "2026-01",
    })),
    transactions: [
      ...OCTOBER_2026.expense.map((c) => ({
        categoryId: c.key,
        amount: -((options.spent?.[c.key] ?? c.spent) + (options.extra?.[c.key] ?? 0)),
      })),
      ...OCTOBER_2026.income.map((c) => ({ categoryId: c.key, amount: c.received })),
    ],
  });
}

/** Every expense category comfortably under budget. */
const ALL_OK = {
  supermercado: 5000,
  restaurante: 5000,
  ocio: 5000,
  casa: 5000,
  transporte: 0,
  suscripciones: 1000,
  vida: 1000,
  taxes: 1000,
};

describe("lukasMessage", () => {
  test("1: a paid pending transaction → pending_paid with the absolute amount and its name", () => {
    expect(
      lukasMessage({
        summary: october(),
        today: "2026-10-21",
        todayCount: 3,
        event: { kind: "paid", categoryId: "casa", amount: -3200, name: "gym" },
      }),
    ).toEqual({
      key: "pending_paid",
      params: { amount: 3200, name: "gym", categoryId: "casa" },
    });
  });

  test("1: an unnamed movement gets an empty name (the client says its category instead)", () => {
    expect(
      lukasMessage({
        summary: october(),
        today: "2026-10-21",
        todayCount: 3,
        event: { kind: "paid", categoryId: "casa", amount: -120000, name: "  " },
      }).params,
    ).toEqual({ amount: 120000, name: "", categoryId: "casa" });
    expect(
      lukasMessage({
        summary: october(),
        today: "2026-10-21",
        todayCount: 3,
        event: { kind: "paid", categoryId: "casa", amount: -120000 },
      }).params,
    ).toEqual({ amount: 120000, name: "", categoryId: "casa" });
  });

  test("1: a pending income marked paid is income received, not a payment", () => {
    expect(
      lukasMessage({
        summary: october(),
        today: "2026-10-21",
        todayCount: 3,
        event: { kind: "paid", categoryId: "salario", amount: 620000, name: "Nómina" },
      }),
    ).toEqual({
      key: "income_received",
      params: { amount: 620000, name: "Nómina", categoryId: "salario" },
    });
  });

  test("1: pending_paid wins even when the category is over budget", () => {
    expect(
      lukasMessage({
        summary: october(),
        today: "2026-10-21",
        todayCount: 1,
        event: { kind: "paid", categoryId: "supermercado", amount: -500 },
      }).key,
    ).toBe("pending_paid");
  });

  test("2: saving income → income_received", () => {
    expect(
      lukasMessage({
        summary: october(),
        today: "2026-10-21",
        todayCount: 1,
        event: { kind: "saved", categoryId: "salario", amount: 620000, name: "Nómina" },
      }),
    ).toEqual({
      key: "income_received",
      params: { amount: 620000, name: "Nómina", categoryId: "salario" },
    });
  });

  test("3: saving −500 in Supermercado → over_budget with the overspend", () => {
    expect(
      lukasMessage({
        summary: october({ extra: { supermercado: 500 } }),
        today: "2026-10-21",
        todayCount: 2,
        event: { kind: "saved", categoryId: "supermercado", amount: -500 },
      }),
    ).toEqual({ key: "over_budget", params: { categoryId: "supermercado", over: 1912 } });
  });

  test("4: saving into a category that reaches the near-limit zone → near_limit", () => {
    // Ocio: 26280 of 65000 spent; push it to 80% (52000).
    expect(
      lukasMessage({
        summary: october({ spent: { ocio: 52000 } }),
        today: "2026-10-21",
        todayCount: 2,
        event: { kind: "saved", categoryId: "ocio", amount: -25720 },
      }),
    ).toEqual({ key: "near_limit", params: { categoryId: "ocio", remaining: 13000 } });
  });

  test("5: the first save of the day in an ok category → first_of_day", () => {
    expect(
      lukasMessage({
        summary: october(),
        today: "2026-10-21",
        todayCount: 1,
        event: { kind: "saved", categoryId: "vida", amount: -200, name: "café" },
      }),
    ).toEqual({ key: "first_of_day", params: { name: "café", categoryId: "vida" } });
  });

  test("5: a later save of the day is not first_of_day", () => {
    expect(
      lukasMessage({
        summary: october({ spent: ALL_OK }),
        today: "2026-10-21",
        todayCount: 2,
        event: { kind: "saved", categoryId: "vida", amount: -200 },
      }).key,
    ).toBe("on_track");
  });

  test("a saved expense with an unknown category does not match the category rows", () => {
    expect(
      lukasMessage({
        summary: october({ spent: ALL_OK }),
        today: "2026-10-21",
        todayCount: 1,
        event: { kind: "saved", categoryId: "nope", amount: -200 },
      }).key,
    ).toBe("first_of_day");
  });

  test("6: a closed month that ended in the green → month_closed_green", () => {
    const summary = { ...october({ spent: ALL_OK }), month: "2026-09", remaining: 100 };
    expect(lukasMessage({ summary, today: "2026-10-01", todayCount: 0 })).toEqual({
      key: "month_closed_green",
      params: { remaining: 100 },
    });
  });

  test("6: a closed month that ended in the red is not month_closed_green", () => {
    const summary = { ...october({ spent: ALL_OK }), month: "2026-09", remaining: -100 };
    expect(lukasMessage({ summary, today: "2026-10-01", todayCount: 0 }).key).toBe("on_track");
  });

  test("7: the last day of the month → month_last_day", () => {
    const summary = october({ spent: ALL_OK });
    expect(lukasMessage({ summary, today: "2026-10-31", todayCount: 0 })).toEqual({
      key: "month_last_day",
      params: { remaining: summary.remaining },
    });
  });

  test("7: month_last_day beats an over category without event", () => {
    expect(lukasMessage({ summary: october(), today: "2026-10-31", todayCount: 0 }).key).toBe(
      "month_last_day",
    );
  });

  test("8: no event and categories over → the worst overspend", () => {
    // Over: supermercado −1412, suscripciones −689, taxes −150.
    expect(lukasMessage({ summary: october(), today: "2026-10-21", todayCount: 0 })).toEqual({
      key: "over_budget",
      params: { categoryId: "supermercado", over: 1412 },
    });
  });

  test("9: no event, none over, some near → the near one with the least remaining", () => {
    // Casa (remaining 2022) and restaurante (4633) are near.
    const summary = october({ spent: { supermercado: 5000, suscripciones: 1000, taxes: 1000 } });
    expect(lukasMessage({ summary, today: "2026-10-21", todayCount: 0 })).toEqual({
      key: "near_limit",
      params: { categoryId: "casa", remaining: 2022 },
    });
  });

  test("10: everything ok → on_track with remaining and days left", () => {
    const summary = october({ spent: ALL_OK });
    expect(lukasMessage({ summary, today: "2026-10-21", todayCount: 0 })).toEqual({
      key: "on_track",
      params: { remaining: summary.remaining, daysLeft: 11 },
    });
  });
});
