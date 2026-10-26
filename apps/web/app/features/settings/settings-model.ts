/**
 * The settings screen's rules that need no React: confirming an account deletion by email, the
 * name of a downloaded export, and finding and naming time zones.
 */

import { intlTag } from "../../i18n/format.ts";

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
 * Countries whose zones `Intl` doesn't name after them (Spain's is "Central European Time", the
 * United States' "Eastern Time"…), by the names people type, in Spanish and English.
 */
export const ZONE_ALIASES: Readonly<Record<string, readonly string[]>> = {
  "Europe/Madrid": ["España", "Spain"],
  "America/New_York": ["Estados Unidos", "EEUU", "EE UU", "USA", "United States"],
  "America/Chicago": ["Estados Unidos", "EEUU", "EE UU", "USA", "United States"],
  "America/Denver": ["Estados Unidos", "EEUU", "EE UU", "USA", "United States"],
  "America/Los_Angeles": ["Estados Unidos", "EEUU", "EE UU", "USA", "United States"],
  "America/Mexico_City": ["México", "Mexico"],
};

/** The zone's generic name in `locale` ("hora estándar de Colombia"), or "" where there is none. */
function genericName(zone: string, locale: string): string {
  try {
    return (
      new Intl.DateTimeFormat(intlTag(locale), { timeZone: zone, timeZoneName: "longGeneric" })
        .formatToParts(0)
        .find((part) => part.type === "timeZoneName")?.value ?? ""
    );
  } catch {
    return "";
  }
}

/** What a search matches each zone against: its id, its generic names and its aliases. */
export type ZoneSearchIndex = ReadonlyMap<string, string>;

const indexes = new WeakMap<readonly string[], ZoneSearchIndex>();

/**
 * The search text of every zone: the id, the generic name in Spanish and English (so "Colombia",
 * "Perú" or "Chile" find their zones) and the aliases above, normalized. Built once per list of
 * zones (a few hundred `Intl` formatters, some tens of ms) and kept.
 */
export function zoneSearchIndex(zones: readonly string[]): ZoneSearchIndex {
  const cached = indexes.get(zones);
  if (cached) return cached;
  const index = new Map(
    zones.map((zone) => [
      zone,
      normalize(
        [
          zone,
          genericName(zone, "es"),
          genericName(zone, "en"),
          ...(ZONE_ALIASES[zone] ?? []),
        ].join(" "),
      ),
    ]),
  );
  indexes.set(zones, index);
  return index;
}

/**
 * The zones matching `query` (any part of the name, or of the zone's text in `index`; zones whose
 * city starts with it first, then the rest in their given order), at most `limit` of them, and
 * how many more matched.
 */
export function searchZones(
  zones: readonly string[],
  query: string,
  limit: number,
  index?: ZoneSearchIndex,
): { matches: string[]; more: number } {
  const wanted = normalize(query);
  const found = zones.filter((zone) => (index?.get(zone) ?? normalize(zone)).includes(wanted));
  const cityFirst = [
    ...found.filter((zone) => normalize(zoneCity(zone)).startsWith(wanted)),
    ...found.filter((zone) => !normalize(zoneCity(zone)).startsWith(wanted)),
  ];
  return { matches: cityFirst.slice(0, limit), more: Math.max(0, cityFirst.length - limit) };
}

/** The zone's offset from UTC at `at` (`GMT-5`, `GMT+2`, `GMT`), or "" for a zone the runtime lacks. */
export function zoneOffset(zone: string, locale: string, at: Date = new Date()): string {
  try {
    const parts = new Intl.DateTimeFormat(intlTag(locale), {
      timeZone: zone,
      timeZoneName: "shortOffset",
    }).formatToParts(at);
    return parts.find((part) => part.type === "timeZoneName")?.value ?? "";
  } catch {
    return "";
  }
}
