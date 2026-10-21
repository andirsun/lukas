import { readFileSync } from "node:fs";
import { addMonths } from "@lukas/core";
import { describe, expect, test } from "vitest";
import {
  averageMonthlySpending,
  type BudgeRow,
  fileCurrency,
  inferCategoryKinds,
  parseBudgeCsv,
  rowHashes,
  UnrecognizedFormatError,
} from "../src/index.ts";

const FIXTURE = readFileSync(new URL("./fixtures/budge-sample.csv", import.meta.url), "utf8");
const FAKE_USER_ID = "FAKEuserID000000000000000000";

describe("parseBudgeCsv", () => {
  const { rows, rejected } = parseBudgeCsv(FIXTURE);

  test("parses every valid transaction row", () => {
    expect(rows).toHaveLength(22);
  });

  test("rejects impossible dates with their line number", () => {
    expect(rejected).toEqual([{ line: 19, reason: "invalid_date" }]);
  });

  test("parses quoted names with commas and exact amounts", () => {
    expect(rows.find((r) => r.name === "vitamins C, Zinc")?.amount).toBe(-5900);
    expect(rows.find((r) => r.name === "metro")?.amount).toBe(-460);
    expect(rows.find((r) => r.name === "electricity")?.amount).toBe(-1600);
  });

  test("maps the paid flag, dates, trimmed names and descriptions", () => {
    expect(rows.filter((r) => r.status === "pending").map((r) => r.name)).toEqual([
      "video streaming",
      "internet",
    ]);
    expect(rows[1]).toMatchObject({ date: "2026-09-02", name: "groceries", currency: "EUR" });
    expect(rows.find((r) => r.name === "flights (1/3)")?.note).toBe("split in three payments");
    expect(rows.find((r) => r.name === "metro")?.note).toBeNull();
  });

  test("never keeps the Budge user id", () => {
    expect(JSON.stringify(parseBudgeCsv(FIXTURE))).not.toContain(FAKE_USER_ID);
  });

  test("throws on files that are not Budge exports", () => {
    expect(() => parseBudgeCsv("a,b\n1,2")).toThrow(UnrecognizedFormatError);
  });
});

describe("derived data", () => {
  const { rows } = parseBudgeCsv(FIXTURE);

  test("infers category kinds by majority sign", () => {
    const kinds = inferCategoryKinds(rows);
    expect(kinds.get("salario")).toBe("income");
    expect(kinds.get("investimento")).toBe("income");
    expect(kinds.get("ocio")).toBe("expense");
  });

  test("hashes identical rows differently and stably across overlapping exports", () => {
    const hashes = rowHashes(rows);
    expect(new Set(hashes).size).toBe(hashes.length);
    expect(rowHashes(rows.slice(5))).toEqual(hashes.slice(5));
  });

  test("averages monthly spending over the months the file spans", () => {
    const average = averageMonthlySpending(rows);
    // Restaurante: 1.20 + 1.20 + 12.40 + 35 = 49.80 over 2 months
    expect(average.find((a) => a.category === "Restaurante")?.amount).toBe(2490);
    expect(average.find((a) => a.category === "Salário")).toBeUndefined();
    expect(average[0]?.category).toBe("Ocio");
  });

  test("the file's currency is the one most of its rows use", () => {
    expect(fileCurrency(rows)).toBe("EUR");
    const mixed = [
      ...rows.slice(0, 2),
      ...rows.slice(0, 3).map((r) => ({ ...r, currency: "COP" })),
    ];
    expect(fileCurrency(mixed)).toBe("COP");
    expect(fileCurrency([])).toBeNull();
  });
});

describe("averageMonthlySpending over the most recent months", () => {
  /**
   * Three years of invented history (Nov 2023 to Oct 2026), built here: rent every month, groceries
   * every month that doubles in 2026, a gym dropped at the end of 2024, a one-off tax payment in
   * 2025, salary as income. No real export is ever used.
   */
  const months: string[] = [];
  for (let m = "2023-11"; m <= "2026-10"; m = addMonths(m, 1)) months.push(m);
  const row = (date: string, category: string, amount: number): BudgeRow => ({
    line: 0,
    date,
    name: category.toLowerCase(),
    amount,
    currency: "EUR",
    category,
    note: null,
    status: "paid",
  });
  const history: BudgeRow[] = months.flatMap((m) => [
    row(`${m}-01`, "Salario", 300_000),
    row(`${m}-02`, "Casa", -80_000),
    row(`${m}-10`, "Supermercado", m >= "2026-01" ? -40_000 : -20_000),
    ...(m <= "2024-12" ? [row(`${m}-15`, "Gimnasio", -3_000)] : []),
    ...(m === "2025-04" ? [row(`${m}-20`, "Impuestos", -120_000)] : []),
  ]);
  const amountOf = (result: { category: string; amount: number }[], category: string) =>
    result.find((a) => a.category === category)?.amount;

  test("averages the last N complete months before `until`", () => {
    // October 2026 is still running: July, August and September count.
    const recent = averageMonthlySpending(history, { months: 3, until: "2026-10" });
    expect(amountOf(recent, "Casa")).toBe(80_000);
    expect(amountOf(recent, "Supermercado")).toBe(40_000);
  });

  test("leaves out categories with no spending in the window", () => {
    const recent = averageMonthlySpending(history, { months: 3, until: "2026-10" });
    expect(recent.map((a) => a.category).sort()).toEqual(["Casa", "Supermercado"]);
    expect(amountOf(recent, "Gimnasio")).toBeUndefined();
    expect(amountOf(recent, "Impuestos")).toBeUndefined();
    expect(amountOf(recent, "Salario")).toBeUndefined();
  });

  test("divides by the window's length, even when a month in it has no rows", () => {
    const sparse = history.filter(
      (r) => !(r.category === "Supermercado" && r.date.startsWith("2026-08")),
    );
    const recent = averageMonthlySpending(sparse, { months: 3, until: "2026-10" });
    expect(amountOf(recent, "Supermercado")).toBe(26_667);
  });

  test("an older export ends its window at its own last month", () => {
    const old = history.filter((r) => r.date < "2025-06-01");
    const recent = averageMonthlySpending(old, { months: 3, until: "2026-10" });
    // March, April and May 2025: the tax payment counts, the gym (dropped in 2024) does not.
    expect(amountOf(recent, "Impuestos")).toBe(40_000);
    expect(amountOf(recent, "Gimnasio")).toBeUndefined();
    expect(amountOf(recent, "Supermercado")).toBe(20_000);
  });

  test("without a window it keeps averaging the whole span", () => {
    const all = averageMonthlySpending(history);
    // 36 months; the 120 € tax payment spread over all of them.
    expect(amountOf(all, "Impuestos")).toBe(Math.round(120_000 / 36));
    expect(amountOf(all, "Gimnasio")).toBe(Math.round((14 * 3_000) / 36));
  });
});
