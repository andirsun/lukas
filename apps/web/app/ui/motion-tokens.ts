export type DurationToken = "--press" | "--sheet" | "--count-up" | "--celebrate";

/**
 * Reads a duration token (`--sheet: 260ms`) from the stylesheet, in seconds, for Motion. The
 * tokens stay the single source of timing; without a document (prerender) it is 0.
 */
export function durationToken(name: DurationToken): number {
  if (typeof document === "undefined") return 0;
  const raw = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  const value = Number.parseFloat(raw);
  if (!Number.isFinite(value)) return 0;
  return raw.endsWith("ms") ? value / 1000 : value;
}
