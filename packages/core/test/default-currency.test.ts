import { describe, expect, test } from "vitest";
import { defaultCurrencyFor, isIanaTimeZone } from "../src/index.ts";

describe("defaultCurrencyFor", () => {
  // The rule (founder, 2026-10-21): Colombia → COP; Europe → EUR; anywhere else → USD.
  const cases: [timezone: string, region: string | undefined, expected: string][] = [
    ["America/Bogota", undefined, "COP"],
    ["America/Bogota", "US", "COP"],
    ["America/New_York", "CO", "COP"],
    ["Europe/Madrid", "CO", "COP"],
    ["Europe/Lisbon", undefined, "EUR"],
    ["Europe/London", "GB", "EUR"],
    ["Europe/Berlin", "US", "EUR"],
    ["UTC", "FR", "EUR"],
    ["", "CH", "EUR"],
    ["America/New_York", undefined, "USD"],
    ["America/New_York", "US", "USD"],
    ["America/Mexico_City", "MX", "USD"],
    ["America/Argentina/Buenos_Aires", "AR", "USD"],
    ["Asia/Tokyo", "JP", "USD"],
    ["UTC", undefined, "USD"],
    ["", undefined, "USD"],
  ];
  for (const [timezone, region, expected] of cases) {
    test(`${timezone || "(no zone)"}, region ${region ?? "(none)"} → ${expected}`, () => {
      expect(defaultCurrencyFor(timezone, region)).toBe(expected);
    });
  }

  test("a region is read case-insensitively", () => {
    expect(defaultCurrencyFor("America/New_York", "co")).toBe("COP");
    expect(defaultCurrencyFor("America/New_York", "pt")).toBe("EUR");
  });
});

describe("isIanaTimeZone", () => {
  test("named zones the runtime knows, aliases included", () => {
    for (const zone of ["America/Bogota", "Europe/Lisbon", "UTC", "Asia/Calcutta"]) {
      expect(isIanaTimeZone(zone)).toBe(true);
    }
  });

  test("offsets, unknown names, junk and over-long input are refused", () => {
    for (const zone of [
      "+05:00",
      "-03",
      "Not/AZone",
      "",
      " ",
      "Europe/Lisbon; x",
      "a".repeat(200),
    ]) {
      expect(isIanaTimeZone(zone)).toBe(false);
    }
  });
});
