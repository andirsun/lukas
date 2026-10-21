import type { CategoryDto, MonthSummary, TransactionDto } from "@lukas/core";
import { QueryClient } from "@tanstack/react-query";
import { beforeEach, describe, expect, it } from "vitest";
import {
  optimisticAdd,
  optimisticRemove,
  optimisticUpdate,
  patchSummary,
  type TransactionList,
} from "./optimistic.ts";

const MONTH = "2026-10";
const FOOD = "11111111-1111-4111-8111-111111111111";
const SALARY = "22222222-2222-4222-8222-222222222222";

const category = (id: string, kind: "expense" | "income"): CategoryDto => ({
  id,
  name: id,
  kind,
  icon: "x",
  color: "x",
  sortOrder: 0,
  archived: false,
  currentBudget: null,
});

const tx = (over: Partial<TransactionDto> & Pick<TransactionDto, "id">): TransactionDto => ({
  name: "Mercadona",
  amount: -1000,
  currency: "EUR",
  date: "2026-10-05",
  status: "paid",
  note: null,
  categoryId: FOOD,
  recurrenceId: null,
  importId: null,
  source: "app",
  createdAt: "2026-10-05T10:00:00.000Z",
  updatedAt: "2026-10-05T10:00:00.000Z",
  ...over,
});

const summary = (over: Partial<MonthSummary> = {}): MonthSummary => ({
  month: MONTH,
  budgetTotal: 10000,
  spent: 7000,
  remaining: 3000,
  income: 200000,
  balance: 193000,
  categories: [
    { categoryId: FOOD, budget: 10000, spent: 7000, remaining: 3000, ratio: 0.7, state: "ok" },
  ],
  ...over,
});

let qc: QueryClient;
beforeEach(() => {
  qc = new QueryClient();
  qc.setQueryData(["categories"], [category(FOOD, "expense"), category(SALARY, "income")]);
  qc.setQueryData(["summary", MONTH], summary());
  qc.setQueryData<TransactionList>(["transactions", MONTH], {
    items: [tx({ id: "b", date: "2026-10-06" }), tx({ id: "a", date: "2026-10-05" })],
    nextCursor: null,
  });
});

const items = (month = MONTH) =>
  qc.getQueryData<TransactionList>(["transactions", month])?.items.map((t) => t.id);
const cached = (month = MONTH) => qc.getQueryData<MonthSummary>(["summary", month]);

describe("patchSummary", () => {
  it("recomputes totals and the category state when spending grows", () => {
    const next = patchSummary(summary(), { categoryId: FOOD, amount: -1500 }, "expense", 1);
    expect(next.spent).toBe(8500);
    expect(next.remaining).toBe(1500);
    expect(next.balance).toBe(200000 - 8500);
    expect(next.categories[0]).toMatchObject({ spent: 8500, remaining: 1500, state: "near" });
  });

  it("goes over budget", () => {
    const next = patchSummary(summary(), { categoryId: FOOD, amount: -4000 }, "expense", 1);
    expect(next.categories[0]?.state).toBe("over");
    expect(next.remaining).toBe(-1000);
  });

  it("subtracts a removed transaction", () => {
    const next = patchSummary(summary(), { categoryId: FOOD, amount: -2000 }, "expense", -1);
    expect(next.spent).toBe(5000);
  });

  it("adds income", () => {
    const next = patchSummary(summary(), { categoryId: SALARY, amount: 5000 }, "income", 1);
    expect(next.income).toBe(205000);
    expect(next.spent).toBe(7000);
  });

  it("shows a category it has not seen yet, without a budget", () => {
    const other = "33333333-3333-4333-8333-333333333333";
    const next = patchSummary(summary(), { categoryId: other, amount: -300 }, "expense", 1);
    expect(next.categories.find((c) => c.categoryId === other)).toMatchObject({
      budget: null,
      spent: 300,
      state: "ok",
    });
    expect(next.spent).toBe(7300);
  });
});

describe("optimisticAdd", () => {
  it("puts the new transaction first in its month and updates the summary", () => {
    optimisticAdd(qc, tx({ id: "new", date: "2026-10-07", amount: -500 }));
    expect(items()).toEqual(["new", "b", "a"]);
    expect(cached()?.spent).toBe(7500);
  });

  it("keeps the list sorted newest first", () => {
    optimisticAdd(qc, tx({ id: "mid", date: "2026-10-05", createdAt: "2026-10-05T12:00:00.000Z" }));
    expect(items()?.[0]).toBe("b");
  });

  it("rolls back to exactly what was there", () => {
    const before = [qc.getQueryData(["transactions", MONTH]), cached()];
    const rollback = optimisticAdd(qc, tx({ id: "new", amount: -500 }));
    rollback();
    expect([qc.getQueryData(["transactions", MONTH]), cached()]).toEqual(before);
  });

  it("leaves months that are not cached alone", () => {
    optimisticAdd(qc, tx({ id: "far", date: "2026-03-01" }));
    expect(qc.getQueryData(["transactions", "2026-03"])).toBeUndefined();
    expect(cached()?.spent).toBe(7000);
  });

  it("does not create a summary or list out of nothing, and rollback keeps it that way", () => {
    const rollback = optimisticAdd(qc, tx({ id: "far", date: "2026-03-01" }));
    rollback();
    expect(qc.getQueryData(["summary", "2026-03"])).toBeUndefined();
  });
});

describe("optimisticRemove", () => {
  it("drops the transaction and its amount, and rolls back", () => {
    const rollback = optimisticRemove(qc, MONTH, "a");
    expect(items()).toEqual(["b"]);
    expect(cached()?.spent).toBe(6000);
    rollback();
    expect(items()).toEqual(["b", "a"]);
    expect(cached()?.spent).toBe(7000);
  });

  it("does nothing for a transaction it cannot see", () => {
    const rollback = optimisticRemove(qc, MONTH, "missing");
    expect(items()).toEqual(["b", "a"]);
    expect(cached()?.spent).toBe(7000);
    rollback();
    expect(items()).toEqual(["b", "a"]);
  });
});

describe("optimisticUpdate", () => {
  it("changes the amount in the list and the summary", () => {
    optimisticUpdate(qc, MONTH, "a", { amount: -3000 });
    const row = qc
      .getQueryData<TransactionList>(["transactions", MONTH])
      ?.items.find((t) => t.id === "a");
    expect(row?.amount).toBe(-3000);
    expect(cached()?.spent).toBe(9000);
  });

  it("marking paid leaves the totals alone", () => {
    optimisticUpdate(qc, MONTH, "a", { status: "paid" });
    expect(cached()?.spent).toBe(7000);
  });

  it("moves a transaction to another month's cache", () => {
    qc.setQueryData<TransactionList>(["transactions", "2026-09"], { items: [], nextCursor: null });
    qc.setQueryData(
      ["summary", "2026-09"],
      summary({ month: "2026-09", spent: 0, remaining: 10000, categories: [] }),
    );
    const rollback = optimisticUpdate(qc, MONTH, "a", { date: "2026-09-30" });
    expect(items()).toEqual(["b"]);
    expect(items("2026-09")).toEqual(["a"]);
    expect(cached()?.spent).toBe(6000);
    expect(cached("2026-09")?.spent).toBe(1000);
    rollback();
    expect(items()).toEqual(["b", "a"]);
    expect(items("2026-09")).toEqual([]);
    expect(cached("2026-09")?.spent).toBe(0);
  });
});
