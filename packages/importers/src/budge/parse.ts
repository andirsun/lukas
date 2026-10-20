import { InvalidAmountError, type IsoDate, isIsoDate, parseDecimalToMinor } from "@lukas/core";
import { parse } from "csv-parse/sync";

export interface BudgeRow {
  line: number;
  date: IsoDate;
  name: string;
  amount: number;
  currency: string;
  category: string;
  note: string | null;
  status: "paid" | "pending";
}

export type BudgeRejectReason =
  | "invalid_date"
  | "invalid_amount"
  | "zero_amount"
  | "missing_category";

export interface BudgeParseResult {
  rows: BudgeRow[];
  rejected: { line: number; reason: BudgeRejectReason }[];
}

export class UnrecognizedFormatError extends Error {
  constructor() {
    super("Not a Budge CSV export");
    this.name = "UnrecognizedFormatError";
  }
}

const TRANSACTIONS_HEADER = "Date,Payment";

function toIsoDate(budgeDate: string): IsoDate | null {
  const match = /^(\d{2})-(\d{2})-(\d{4})$/.exec(budgeDate.trim());
  if (!match) return null;
  const iso = `${match[3]}-${match[2]}-${match[1]}`;
  return isIsoDate(iso) ? iso : null;
}

/**
 * Parses a Budge export ("Format version 1"): blocks separated by `###` lines, of which only the
 * transactions block is read. The metadata block (with Budge's user id) and accounts block are ignored.
 */
export function parseBudgeCsv(text: string): BudgeParseResult {
  const lines = text.replace(/^﻿/, "").split(/\r?\n/);
  const start = lines.findIndex((l) => l.startsWith(TRANSACTIONS_HEADER));
  if (start === -1) throw new UnrecognizedFormatError();
  let end = lines.findIndex((l, i) => i > start && l.trim() === "###");
  if (end === -1) end = lines.length;

  const records: Record<string, string>[] = parse(lines.slice(start, end).join("\n"), {
    columns: true,
    skip_empty_lines: true,
    relax_column_count: true,
    info: false,
  });
  // csv-parse drops empty lines, so recover file line numbers from the raw lines.
  const recordLines = lines
    .slice(start + 1, end)
    .map((l, i) => ({ l, line: start + 2 + i }))
    .filter(({ l }) => l.trim() !== "")
    .map(({ line }) => line);

  const result: BudgeParseResult = { rows: [], rejected: [] };
  records.forEach((record, i) => {
    const line = recordLines[i] ?? 0;
    const date = toIsoDate(record.Date ?? "");
    if (!date) return result.rejected.push({ line, reason: "invalid_date" });
    const category = (record.Category ?? "").trim();
    if (!category) return result.rejected.push({ line, reason: "missing_category" });
    let amount: number;
    try {
      amount = parseDecimalToMinor(record.Amount ?? "");
    } catch (error) {
      if (error instanceof InvalidAmountError)
        return result.rejected.push({ line, reason: "invalid_amount" });
      throw error;
    }
    if (amount === 0) return result.rejected.push({ line, reason: "zero_amount" });
    const note = (record.Description ?? "").trim();
    result.rows.push({
      line,
      date,
      name: (record.Payment ?? "").trim(),
      amount,
      currency: (record.Currency ?? "").trim().toUpperCase(),
      category,
      note: note === "" ? null : note,
      status: record["Is paid"]?.trim() === "false" ? "pending" : "paid",
    });
  });
  return result;
}
