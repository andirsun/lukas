import { describe, expect, test } from "vitest";
import { costOfLiving } from "../src/index.ts";

const categories = [
  { id: "casa", kind: "expense" as const },
  { id: "restaurante", kind: "expense" as const },
  { id: "ocio", kind: "expense" as const },
  { id: "salario", kind: "income" as const },
];

const transactions = [
  { categoryId: "casa", amount: -100000, date: "2026-09-05" },
  { categoryId: "casa", amount: -120000, date: "2026-10-05" },
  { categoryId: "restaurante", amount: -30000, date: "2026-09-12" },
  { categoryId: "restaurante", amount: -10000, date: "2026-10-12" },
  { categoryId: "restaurante", amount: 5000, date: "2026-10-20" },
  { categoryId: "salario", amount: 620000, date: "2026-10-01" },
];

describe("costOfLiving", () => {
  test("averages net expenses per month and splits fixed from variable", () => {
    expect(
      costOfLiving({
        months: ["2026-09", "2026-10"],
        categories,
        fixedCategoryIds: ["casa"],
        transactions,
      }),
    ).toEqual({
      months: 2,
      total: 127500,
      fixed: 110000,
      variable: 17500,
      categories: [
        { categoryId: "casa", average: 110000, type: "fixed" },
        { categoryId: "restaurante", average: 17500, type: "variable" },
      ],
    });
  });

  test("ignores transactions outside the months", () => {
    const result = costOfLiving({
      months: ["2026-09", "2026-10"],
      categories,
      fixedCategoryIds: ["casa"],
      transactions: [
        ...transactions,
        { categoryId: "casa", amount: -999999, date: "2026-08-31" },
        { categoryId: "ocio", amount: -999999, date: "2026-11-01" },
      ],
    });
    expect(result.total).toBe(127500);
    expect(result.categories.map((c) => c.categoryId)).toEqual(["casa", "restaurante"]);
  });

  test("omits zero averages and rounds to whole cents", () => {
    const result = costOfLiving({
      months: ["2026-09", "2026-10", "2026-11"],
      categories,
      fixedCategoryIds: [],
      transactions: [
        { categoryId: "ocio", amount: -100, date: "2026-09-01" },
        { categoryId: "restaurante", amount: -50, date: "2026-10-01" },
        { categoryId: "restaurante", amount: 50, date: "2026-10-02" },
      ],
    });
    expect(result).toEqual({
      months: 3,
      total: 33,
      fixed: 0,
      variable: 33,
      categories: [{ categoryId: "ocio", average: 33, type: "variable" }],
    });
  });

  test("an empty window costs nothing", () => {
    expect(costOfLiving({ months: [], categories, fixedCategoryIds: [], transactions })).toEqual({
      months: 0,
      total: 0,
      fixed: 0,
      variable: 0,
      categories: [],
    });
  });
});
