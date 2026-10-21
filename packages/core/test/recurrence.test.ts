import { expect, test } from "vitest";
import { occurrences, type RecurrenceRule } from "../src/index.ts";

const monthly: RecurrenceRule = {
  frequency: "monthly",
  dayOfMonth: 31,
  monthOfYear: null,
  startDate: "2026-01-15",
  endDate: null,
};

test("clamps to the last day of shorter months", () => {
  expect(occurrences(monthly, "2026-02")).toEqual(["2026-02-28"]);
  expect(occurrences(monthly, "2028-02")).toEqual(["2028-02-29"]);
  expect(occurrences(monthly, "2026-04")).toEqual(["2026-04-30"]);
});

test("respects the start date", () => {
  expect(occurrences(monthly, "2025-12")).toEqual([]);
  expect(occurrences({ ...monthly, dayOfMonth: 10 }, "2026-01")).toEqual([]);
  expect(occurrences({ ...monthly, dayOfMonth: 15 }, "2026-01")).toEqual(["2026-01-15"]);
});

test("respects the end date", () => {
  expect(occurrences({ ...monthly, endDate: "2026-06-30" }, "2026-06")).toEqual(["2026-06-30"]);
  expect(occurrences({ ...monthly, endDate: "2026-06-30" }, "2026-07")).toEqual([]);
});

test("yearly recurrences only fall in their month", () => {
  const yearly: RecurrenceRule = {
    frequency: "yearly",
    dayOfMonth: 29,
    monthOfYear: 2,
    startDate: "2026-01-01",
    endDate: null,
  };
  expect(occurrences(yearly, "2027-02")).toEqual(["2027-02-28"]);
  expect(occurrences(yearly, "2028-02")).toEqual(["2028-02-29"]);
  expect(occurrences(yearly, "2027-03")).toEqual([]);
});
