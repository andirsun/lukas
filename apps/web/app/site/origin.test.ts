import { describe, expect, it } from "vitest";
import { DEFAULT_SITE_ORIGIN, isLandingOnly, resolveSiteOrigin } from "./origin.ts";

describe("resolveSiteOrigin", () => {
  it("falls back to the placeholder origin when VITE_SITE_URL is unset or blank", () => {
    expect(resolveSiteOrigin(undefined)).toBe(DEFAULT_SITE_ORIGIN);
    expect(resolveSiteOrigin("")).toBe(DEFAULT_SITE_ORIGIN);
    expect(resolveSiteOrigin("   ")).toBe(DEFAULT_SITE_ORIGIN);
    expect(DEFAULT_SITE_ORIGIN).toBe("https://lukas.app");
  });

  it("uses the configured origin", () => {
    expect(resolveSiteOrigin("https://lukas.andersonlaverde.com")).toBe(
      "https://lukas.andersonlaverde.com",
    );
  });

  it("drops trailing slashes and surrounding whitespace", () => {
    expect(resolveSiteOrigin("https://lukas.andersonlaverde.com/")).toBe(
      "https://lukas.andersonlaverde.com",
    );
    expect(resolveSiteOrigin("  https://example.com//  ")).toBe("https://example.com");
  });

  it("keeps a port", () => {
    expect(resolveSiteOrigin("http://localhost:4180/")).toBe("http://localhost:4180");
  });

  it("fails clearly on something that is not an http(s) origin", () => {
    expect(() => resolveSiteOrigin("lukas.andersonlaverde.com")).toThrow(/VITE_SITE_URL/);
    expect(() => resolveSiteOrigin("ftp://example.com")).toThrow(/VITE_SITE_URL/);
    expect(() => resolveSiteOrigin("https://example.com/some/path")).toThrow(/VITE_SITE_URL/);
  });
});

describe("isLandingOnly", () => {
  it("is on only for the exact string true", () => {
    expect(isLandingOnly("true")).toBe(true);
    expect(isLandingOnly(undefined)).toBe(false);
    expect(isLandingOnly("")).toBe(false);
    expect(isLandingOnly("false")).toBe(false);
    expect(isLandingOnly("1")).toBe(false);
  });
});
