import { describe, expect, test } from "vitest";
import { nextOccurrence } from "./recurring-model.ts";

const monthly = {
  frequency: "monthly" as const,
  dayOfMonth: 23,
  monthOfYear: null,
  startDate: "2026-01-01",
  endDate: null,
};

describe("nextOccurrence", () => {
  test("later this month, today included", () => {
    expect(nextOccurrence(monthly, "2026-10-21")).toBe("2026-10-23");
    expect(nextOccurrence(monthly, "2026-10-23")).toBe("2026-10-23");
  });

  test("past this month: next month's", () => {
    expect(nextOccurrence(monthly, "2026-10-24")).toBe("2026-11-23");
  });

  test("a day past the month's end falls on its last day", () => {
    expect(nextOccurrence({ ...monthly, dayOfMonth: 31 }, "2026-11-02")).toBe("2026-11-30");
    expect(nextOccurrence({ ...monthly, dayOfMonth: 31 }, "2027-02-01")).toBe("2027-02-28");
  });

  test("not before it starts", () => {
    expect(nextOccurrence({ ...monthly, startDate: "2027-03-10" }, "2026-10-21")).toBe(
      "2027-03-23",
    );
  });

  test("none once it ended", () => {
    expect(nextOccurrence({ ...monthly, endDate: "2026-10-20" }, "2026-10-21")).toBeNull();
    expect(nextOccurrence({ ...monthly, endDate: "2026-11-23" }, "2026-10-24")).toBe("2026-11-23");
  });

  test("yearly: the next time its month comes round", () => {
    const yearly = { ...monthly, frequency: "yearly" as const, dayOfMonth: 15, monthOfYear: 3 };
    expect(nextOccurrence(yearly, "2026-10-21")).toBe("2027-03-15");
    expect(nextOccurrence(yearly, "2027-03-15")).toBe("2027-03-15");
    expect(nextOccurrence(yearly, "2027-03-16")).toBe("2028-03-15");
  });
});
