/** What a new profile's time zone is until the web sets it (the API's default). */
export const DEFAULT_TIME_ZONE = "UTC";

/**
 * The time zone to save on the profile, or null to leave it: only while the stored one is still
 * the default, and only a zone the runtime knows (`Intl.supportedValuesOf("timeZone")`), so a
 * person who chose one in settings keeps it. Without it every "today" and month boundary would be
 * UTC's: 5 hours off in Bogotá.
 */
export function timeZoneToSave(
  stored: string,
  browser: string | undefined,
  supported: readonly string[],
): string | null {
  if (stored !== DEFAULT_TIME_ZONE || !browser || browser === stored) return null;
  return supported.includes(browser) ? browser : null;
}

/** The browser's zone and the zones it knows, read safely (older engines lack `supportedValuesOf`). */
export function browserTimeZone(): { zone: string | undefined; supported: readonly string[] } {
  try {
    return {
      zone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      supported: Intl.supportedValuesOf("timeZone"),
    };
  } catch {
    return { zone: undefined, supported: [] };
  }
}
