import { daysInMonth, type IsoDate, type Month } from "./dates.ts";

export interface RecurrenceRule {
  frequency: "monthly" | "yearly";
  dayOfMonth: number;
  monthOfYear: number | null;
  startDate: IsoDate;
  endDate: IsoDate | null;
}

/** Dates (0 or 1) on which the rule falls within `month`; days past the month's end clamp to its last day. */
export function occurrences(rule: RecurrenceRule, month: Month): IsoDate[] {
  if (rule.frequency === "yearly" && Number(month.slice(5, 7)) !== rule.monthOfYear) return [];
  const day = Math.min(rule.dayOfMonth, daysInMonth(month));
  const date = `${month}-${String(day).padStart(2, "0")}`;
  if (date < rule.startDate) return [];
  if (rule.endDate !== null && date > rule.endDate) return [];
  return [date];
}
