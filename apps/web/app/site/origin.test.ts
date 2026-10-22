import { describe, expect, it } from "vitest";
import {
  DEFAULT_SITE_ORIGIN,
  isComingSoon,
  isLandingOnly,
  landingTarget,
  resolveAppOrigin,
  resolveLandingOrigin,
  resolveSiteOrigin,
} from "./origin.ts";

describe("resolveSiteOrigin", () => {
  it("falls back to the placeholder origin when VITE_SITE_URL is unset or blank", () => {
    expect(resolveSiteOrigin(undefined)).toBe(DEFAULT_SITE_ORIGIN);
    expect(resolveSiteOrigin("")).toBe(DEFAULT_SITE_ORIGIN);
    expect(resolveSiteOrigin("   ")).toBe(DEFAULT_SITE_ORIGIN);
    expect(DEFAULT_SITE_ORIGIN).toBe("https://lukas.app");
  });

  it("uses the configured origin", () => {
    expect(resolveSiteOrigin("https://lukitas.andersonlaverde.com")).toBe(
      "https://lukitas.andersonlaverde.com",
    );
  });

  it("drops trailing slashes and surrounding whitespace", () => {
    expect(resolveSiteOrigin("https://lukitas.andersonlaverde.com/")).toBe(
      "https://lukitas.andersonlaverde.com",
    );
    expect(resolveSiteOrigin("  https://example.com//  ")).toBe("https://example.com");
  });

  it("keeps a port", () => {
    expect(resolveSiteOrigin("http://localhost:4180/")).toBe("http://localhost:4180");
  });

  it("fails clearly on something that is not an http(s) origin", () => {
    expect(() => resolveSiteOrigin("lukitas.andersonlaverde.com")).toThrow(/VITE_SITE_URL/);
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

describe("resolveAppOrigin", () => {
  it("is undefined when VITE_APP_URL is unset or blank: there is no app to open", () => {
    expect(resolveAppOrigin(undefined)).toBeUndefined();
    expect(resolveAppOrigin("")).toBeUndefined();
    expect(resolveAppOrigin("   ")).toBeUndefined();
  });

  it("uses the configured origin, without trailing slashes or whitespace", () => {
    expect(resolveAppOrigin("https://app-lukas.andersonlaverde.com")).toBe(
      "https://app-lukas.andersonlaverde.com",
    );
    expect(resolveAppOrigin("  https://app-lukas.andersonlaverde.com//  ")).toBe(
      "https://app-lukas.andersonlaverde.com",
    );
    expect(resolveAppOrigin("http://localhost:5173/")).toBe("http://localhost:5173");
  });

  it("fails clearly, naming VITE_APP_URL, on something that is not an http(s) origin", () => {
    expect(() => resolveAppOrigin("app-lukas.andersonlaverde.com")).toThrow(/VITE_APP_URL/);
    expect(() => resolveAppOrigin("ftp://example.com")).toThrow(/VITE_APP_URL/);
    expect(() => resolveAppOrigin("https://example.com/sign-in")).toThrow(/VITE_APP_URL/);
    expect(() => resolveAppOrigin("https://example.com/?a=1")).toThrow(/VITE_APP_URL/);
  });
});

describe("isComingSoon", () => {
  it("is on only for a landing-only release with no app to open", () => {
    expect(isComingSoon(true, undefined)).toBe(true);
    expect(isComingSoon(true, "https://app.example.test")).toBe(false);
    expect(isComingSoon(false, undefined)).toBe(false);
    expect(isComingSoon(false, "https://app.example.test")).toBe(false);
  });
});

describe("resolveLandingOrigin", () => {
  it("is undefined when VITE_LANDING_URL is unset or blank: the landing is this site's own", () => {
    expect(resolveLandingOrigin(undefined)).toBeUndefined();
    expect(resolveLandingOrigin(" ")).toBeUndefined();
  });

  it("uses the configured origin, and fails clearly naming VITE_LANDING_URL", () => {
    expect(resolveLandingOrigin("https://lukitas.andersonlaverde.com/")).toBe(
      "https://lukitas.andersonlaverde.com",
    );
    expect(() => resolveLandingOrigin("lukitas.andersonlaverde.com")).toThrow(/VITE_LANDING_URL/);
  });
});

describe("landingTarget", () => {
  it("stays inside the app when the landing is its own", () => {
    expect(landingTarget(undefined, "/")).toEqual({ external: false, href: "/" });
  });

  it("leaves for the landing's site, a full page load, when it lives elsewhere", () => {
    expect(landingTarget("https://lukitas.andersonlaverde.com", "/")).toEqual({
      external: true,
      href: "https://lukitas.andersonlaverde.com/",
    });
    expect(landingTarget("https://lukitas.andersonlaverde.com", "/en")).toEqual({
      external: true,
      href: "https://lukitas.andersonlaverde.com/en",
    });
  });
});
