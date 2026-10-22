import { describe, expect, it } from "vitest";
import {
  emailMatches,
  filenameFrom,
  searchZones,
  zoneCity,
  zoneOffset,
  zoneRegion,
} from "./settings-model.ts";

describe("emailMatches", () => {
  it("accepts the exact email, ignoring case and surrounding spaces", () => {
    expect(emailMatches("ana@example.com", "ana@example.com")).toBe(true);
    expect(emailMatches("  ANA@Example.com ", "ana@example.com")).toBe(true);
    expect(emailMatches("ana@example.com", "Ana@Example.COM")).toBe(true);
  });

  it("refuses anything else", () => {
    expect(emailMatches("", "ana@example.com")).toBe(false);
    expect(emailMatches("ana@example.co", "ana@example.com")).toBe(false);
    expect(emailMatches("ana @example.com", "ana@example.com")).toBe(false);
    expect(emailMatches("ana@example.com.", "ana@example.com")).toBe(false);
  });
});

describe("filenameFrom", () => {
  it("reads the quoted or bare filename of a content-disposition", () => {
    expect(filenameFrom('attachment; filename="lukas-export-2026-10-22.csv"', "x")).toBe(
      "lukas-export-2026-10-22.csv",
    );
    expect(filenameFrom("attachment; filename=lukas.json", "x")).toBe("lukas.json");
  });

  it("falls back when there is none, or it carries a path", () => {
    expect(filenameFrom(null, "lukas-export.json")).toBe("lukas-export.json");
    expect(filenameFrom("attachment", "lukas-export.json")).toBe("lukas-export.json");
    expect(filenameFrom('attachment; filename="../x.csv"', "lukas-export.csv")).toBe(
      "lukas-export.csv",
    );
  });
});

describe("zones", () => {
  const zones = [
    "America/Argentina/Buenos_Aires",
    "America/Bogota",
    "America/New_York",
    "Europe/Madrid",
    "Europe/Lisbon",
    "UTC",
  ];

  it("names a zone by its city and region", () => {
    expect(zoneCity("America/Argentina/Buenos_Aires")).toBe("Buenos Aires");
    expect(zoneRegion("America/Argentina/Buenos_Aires")).toBe("America · Argentina");
    expect(zoneCity("UTC")).toBe("UTC");
    expect(zoneRegion("UTC")).toBe("");
  });

  it("finds zones by any part of their name, without accents, case or underscores", () => {
    expect(searchZones(zones, "bogotá", 10)).toEqual({ matches: ["America/Bogota"], more: 0 });
    expect(searchZones(zones, "NEW YORK", 10).matches).toEqual(["America/New_York"]);
    expect(searchZones(zones, "buenos_aires", 10).matches).toEqual([
      "America/Argentina/Buenos_Aires",
    ]);
    expect(searchZones(zones, "europe", 10).matches).toEqual(["Europe/Madrid", "Europe/Lisbon"]);
  });

  it("puts zones whose city starts with the query first, and caps the list", () => {
    expect(searchZones(zones, "a", 10).matches.slice(0, 1)).toEqual([
      "America/Argentina/Buenos_Aires",
    ]);
    expect(searchZones(zones, "", 2)).toEqual({
      matches: ["America/Argentina/Buenos_Aires", "America/Bogota"],
      more: 4,
    });
    expect(searchZones(zones, "lis", 10).matches).toEqual(["Europe/Lisbon"]);
  });

  it("writes the zone's offset from UTC at a given moment", () => {
    const october = new Date("2026-10-22T12:00:00Z");
    expect(zoneOffset("America/Bogota", "es", october)).toBe("GMT-5");
    expect(zoneOffset("Europe/Madrid", "en", october)).toBe("GMT+2");
    expect(zoneOffset("UTC", "es", october)).toMatch(/^GMT(\+0)?$/);
    expect(zoneOffset("Not/AZone", "es", october)).toBe("");
  });
});
