/** "YYYY-MM" */
export type Month = string;
/** "YYYY-MM-DD" */
export type IsoDate = string;

const MONTH = /^(\d{4})-(\d{2})$/;
const DATE = /^(\d{4})-(\d{2})-(\d{2})$/;

const pad = (n: number, width = 2) => String(n).padStart(width, "0");

function parts(m: Month): [number, number] {
  const match = MONTH.exec(m);
  if (!match) throw new RangeError(`Invalid month: ${m}`);
  return [Number(match[1]), Number(match[2])];
}

export function isMonth(s: string): boolean {
  const match = MONTH.exec(s);
  if (!match) return false;
  const month = Number(match[2]);
  return month >= 1 && month <= 12;
}

export function isIsoDate(s: string): boolean {
  const match = DATE.exec(s);
  if (!match) return false;
  const m = `${match[1]}-${match[2]}`;
  const day = Number(match[3]);
  return isMonth(m) && day >= 1 && day <= daysInMonth(m);
}

export function daysInMonth(m: Month): number {
  const [year, month] = parts(m);
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

export function monthOf(date: IsoDate): Month {
  return date.slice(0, 7);
}

export function firstDay(m: Month): IsoDate {
  parts(m);
  return `${m}-01`;
}

export function lastDay(m: Month): IsoDate {
  return `${m}-${pad(daysInMonth(m))}`;
}

export function addMonths(m: Month, n: number): Month {
  const [year, month] = parts(m);
  const index = year * 12 + (month - 1) + n;
  return `${pad(Math.floor(index / 12), 4)}-${pad((index % 12) + 1)}`;
}

export function monthsBetween(from: Month, to: Month): Month[] {
  const result: Month[] = [];
  for (let m = from; m <= to; m = addMonths(m, 1)) result.push(m);
  return result;
}

export function todayIn(timeZone: string, now: Date = new Date()): IsoDate {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
}

export function isValidTimeZone(tz: string): boolean {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}
