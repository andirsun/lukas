import { expect, test } from "vitest";
import {
  addMonths,
  daysInMonth,
  firstDay,
  isIsoDate,
  isMonth,
  isValidTimeZone,
  lastDay,
  monthOf,
  monthsBetween,
  todayIn,
} from "../src/index.ts";

test("daysInMonth handles leap years", () => {
  expect(daysInMonth("2028-02")).toBe(29);
  expect(daysInMonth("2026-02")).toBe(28);
});

test("first and last day of a month", () => {
  expect(firstDay("2026-04")).toBe("2026-04-01");
  expect(lastDay("2026-04")).toBe("2026-04-30");
});

test("addMonths crosses years in both directions", () => {
  expect(addMonths("2026-11", 3)).toBe("2027-02");
  expect(addMonths("2026-01", -1)).toBe("2025-12");
});

test("monthsBetween is inclusive and empty when reversed", () => {
  expect(monthsBetween("2026-11", "2027-01")).toEqual(["2026-11", "2026-12", "2027-01"]);
  expect(monthsBetween("2027-01", "2026-11")).toEqual([]);
});

test("validates months and calendar dates", () => {
  expect(isMonth("2026-10")).toBe(true);
  expect(isMonth("2026-13")).toBe(false);
  expect(isIsoDate("2026-02-28")).toBe(true);
  expect(isIsoDate("2026-02-30")).toBe(false);
  expect(monthOf("2026-10-23")).toBe("2026-10");
});

test("todayIn respects the user's time zone", () => {
  const now = new Date("2026-11-01T03:00:00Z");
  expect(todayIn("America/Bogota", now)).toBe("2026-10-31");
  expect(todayIn("Europe/Lisbon", now)).toBe("2026-11-01");
});

test("isValidTimeZone", () => {
  expect(isValidTimeZone("Europe/Lisbon")).toBe(true);
  expect(isValidTimeZone("Mars/Base")).toBe(false);
});
