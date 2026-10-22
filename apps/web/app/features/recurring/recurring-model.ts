import { addMonths, type IsoDate, monthOf, occurrences, type RecurrenceRule } from "@lukas/core";

/** A yearly rule comes round within 12 months of any month, so 13 months always find it. */
const LOOKAHEAD_MONTHS = 13;

/**
 * The next date a recurrence falls on, today included (or its start, if later), or null once it
 * has ended. The dates come from core's `occurrences` (the rule the API materializes with): for a
 * monthly rule this month or the next, for a yearly one the next time its month comes round.
 */
export function nextOccurrence(rule: RecurrenceRule, today: IsoDate): IsoDate | null {
  const from = rule.startDate > today ? rule.startDate : today;
  for (let step = 0; step < LOOKAHEAD_MONTHS; step++) {
    const date = occurrences(rule, addMonths(monthOf(from), step))[0];
    if (date && date >= from) return date;
  }
  return null;
}
