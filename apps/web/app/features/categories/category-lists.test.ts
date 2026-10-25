import type { CategoryDto, CategorySummary } from "@lukas/core";
import { describe, expect, it } from "vitest";
import { categoryLists } from "./category-lists.ts";

function category(id: string, kind: "expense" | "income", sortOrder: number, archived = false) {
  return {
    id,
    name: id,
    kind,
    icon: "🛒",
    color: "#ff9f1c",
    sortOrder,
    archived,
    currentBudget: null,
  } satisfies CategoryDto;
}

const line = (categoryId: string): CategorySummary => ({
  categoryId,
  budget: null,
  spent: 32000000,
  remaining: null,
  ratio: null,
  state: "ok",
});

const categories = [
  category("food", "expense", 0),
  category("restaurants", "expense", 1, true),
  category("transport", "expense", 2, true),
  category("salary", "income", 3, true),
];

describe("categoryLists", () => {
  it("keeps an archived spending category with spending this month among the rows, in order", () => {
    const lines = new Map([line("food"), line("restaurants")].map((l) => [l.categoryId, l]));
    const { rows, archived } = categoryLists(categories, lines, "expense");
    expect(rows.map((c) => c.id)).toEqual(["food", "restaurants"]);
    expect(archived.map((c) => c.id)).toEqual(["transport"]);
  });

  it("folds an archived category with no spending this month", () => {
    const { rows, archived } = categoryLists(categories, new Map(), "expense");
    expect(rows.map((c) => c.id)).toEqual(["food"]);
    expect(archived.map((c) => c.id)).toEqual(["restaurants", "transport"]);
  });

  it("leaves income alone: its archived categories stay in the fold", () => {
    const lines = new Map([line("salary")].map((l) => [l.categoryId, l]));
    const { rows, archived } = categoryLists(categories, lines, "income");
    expect(rows).toEqual([]);
    expect(archived.map((c) => c.id)).toEqual(["salary"]);
  });
});
