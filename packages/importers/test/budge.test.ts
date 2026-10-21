import { readFileSync } from "node:fs";
import { describe, expect, test } from "vitest";
import {
  averageMonthlySpending,
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
});
