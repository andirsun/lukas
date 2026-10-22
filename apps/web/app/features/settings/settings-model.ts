/**
 * The settings screen's rules that need no React: confirming an account deletion by email, the
 * name of a downloaded export, and finding and naming time zones.
 */

/** Whether what was typed is the account's email: case-insensitive, surrounding spaces trimmed. */
export function emailMatches(typed: string, email: string): boolean {
  const wanted = email.trim().toLowerCase();
  return wanted !== "" && typed.trim().toLowerCase() === wanted;
}

/**
 * The file name a `content-disposition` header gives (`attachment; filename="x.csv"`), or
 * `fallback` when it gives none or one with a path in it.
 */
export function filenameFrom(disposition: string | null, fallback: string): string {
  const match = /filename\s*=\s*(?:"([^"]*)"|([^;\s]+))/i.exec(disposition ?? "");
  const name = (match?.[1] ?? match?.[2] ?? "").trim();
  return name && !/[/\\]/.test(name) && !name.startsWith(".") ? name : fallback;
}

const words = (part: string) => part.replaceAll("_", " ");

/** A zone's city: `America/Argentina/Buenos_Aires` → `Buenos Aires`; `UTC` stays `UTC`. */
export function zoneCity(zone: string): string {
  return words(zone.split("/").at(-1) ?? zone);
}

/** A zone's region: `America/Argentina/Buenos_Aires` → `America · Argentina`; none for `UTC`. */
export function zoneRegion(zone: string): string {
  return zone.split("/").slice(0, -1).map(words).join(" · ");
}

/** Lowercase, without accents, with `_` and `/` as spaces: "Bogotá" finds "America/Bogota". */
function normalize(text: string): string {
  return text
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .replace(/[_/]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * The zones matching `query` (any part of the name; zones whose city starts with it first, then
 * the rest in their given order), at most `limit` of them, and how many more matched.
 */
export function searchZones(
  zones: readonly string[],
  query: string,
  limit: number,
): { matches: string[]; more: number } {
  const wanted = normalize(query);
  const found = zones.filter((zone) => normalize(zone).includes(wanted));
  const cityFirst = [
    ...found.filter((zone) => normalize(zoneCity(zone)).startsWith(wanted)),
    ...found.filter((zone) => !normalize(zoneCity(zone)).startsWith(wanted)),
  ];
  return { matches: cityFirst.slice(0, limit), more: Math.max(0, cityFirst.length - limit) };
}

/** The zone's offset from UTC at `at` (`GMT-5`, `GMT+2`, `GMT`), or "" for a zone the runtime lacks. */
export function zoneOffset(zone: string, locale: string, at: Date = new Date()): string {
  try {
    const parts = new Intl.DateTimeFormat(locale, {
      timeZone: zone,
      timeZoneName: "shortOffset",
    }).formatToParts(at);
    return parts.find((part) => part.type === "timeZoneName")?.value ?? "";
  } catch {
    return "";
  }
}
