import { describe, expect, test } from "vitest";
import {
  createRecurrenceSchema,
  createTransactionSchema,
  updateProfileSchema,
  updateTransactionSchema,
} from "../src/index.ts";

const validTx = {
  name: "continente",
  amount: -608,
  categoryId: "0192f5a0-0000-7000-8000-000000000001",
  date: "2026-10-20",
};

describe("createTransactionSchema", () => {
  test("defaults status to paid and source to app", () => {
    expect(createTransactionSchema.parse(validTx)).toMatchObject({ status: "paid", source: "app" });
  });

  test("trims the name", () => {
    expect(createTransactionSchema.parse({ ...validTx, name: "  café  " }).name).toBe("café");
  });

  test.each([
    ["zero amount", { amount: 0 }],
    ["fractional amount", { amount: 1.5 }],
    ["impossible date", { date: "2026-02-30" }],
    ["empty name", { name: "   " }],
    ["non-uuid category", { categoryId: "ocio" }],
  ])("rejects %s", (_label, patch) => {
    expect(createTransactionSchema.safeParse({ ...validTx, ...patch }).success).toBe(false);
  });

  test("accepts refunds and income in any category (no sign rule)", () => {
    expect(createTransactionSchema.safeParse({ ...validTx, amount: 500 }).success).toBe(true);
  });
});

test("updateTransactionSchema requires at least one field", () => {
  expect(() => updateTransactionSchema.parse({})).toThrow();
  expect(updateTransactionSchema.parse({ amount: -399 })).toEqual({ amount: -399 });
});

describe("createRecurrenceSchema", () => {
  const base = {
    name: "Spotify",
    amount: -353,
    categoryId: validTx.categoryId,
    frequency: "monthly",
    dayOfMonth: 23,
    startDate: "2026-01-23",
  };

  test("accepts a monthly recurrence", () => {
    expect(createRecurrenceSchema.safeParse(base).success).toBe(true);
  });

  test("requires monthOfYear for yearly recurrences", () => {
    const result = createRecurrenceSchema.safeParse({ ...base, frequency: "yearly" });
    expect(result.success).toBe(false);
    expect(result.error?.issues[0]?.path).toEqual(["monthOfYear"]);
  });

  test("rejects an end date before the start date", () => {
    expect(createRecurrenceSchema.safeParse({ ...base, endDate: "2025-12-31" }).success).toBe(
      false,
    );
  });
});

test("updateProfileSchema validates time zones", () => {
  expect(updateProfileSchema.safeParse({ timezone: "Mars/Base" }).success).toBe(false);
  expect(updateProfileSchema.parse({ timezone: "America/Bogota", locale: "en" })).toEqual({
    timezone: "America/Bogota",
    locale: "en",
  });
});
