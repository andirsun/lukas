import { describe, expect, it } from "vitest";
import { safeNext, signInPath } from "./next.ts";

describe("safeNext", () => {
  it("keeps same-origin paths with their query and hash", () => {
    expect(safeNext("/app/insights")).toBe("/app/insights");
    expect(safeNext("/app/transactions?month=2026-10#top")).toBe(
      "/app/transactions?month=2026-10#top",
    );
  });

  it("never returns a value that starts a protocol-relative URL or holds a backslash", () => {
    for (const value of ["/.//x", "/..//x", "/%2e%2e//x", "/a/..//x", "/./\\x", "/\\x"]) {
      const result = safeNext(value);
      expect(result, value).not.toMatch(/^\/[/\\]/);
      expect(result, value).not.toContain("\\");
    }
  });

  it("keeps ordinary paths that merely contain dots and encodings", () => {
    expect(safeNext("/app/./insights")).toBe("/app/insights");
    expect(safeNext("/app/a%20b?q=%2F")).toBe("/app/a%20b?q=%2F");
  });

  it("falls back for missing values", () => {
    expect(safeNext(null)).toBe("/app");
    expect(safeNext(undefined)).toBe("/app");
    expect(safeNext("")).toBe("/app");
    expect(safeNext("", "/welcome")).toBe("/welcome");
  });

  it.each([
    "https://evil.example",
    "http://evil.example/app",
    "//evil.example",
    "//evil.example/app",
    "/\\evil.example",
    "\\\\evil.example",
    "/\t/evil.example",
    "/\n/evil.example",
    "javascript:alert(1)",
    "data:text/html,hi",
    "evil.example",
    "app/insights",
    // Dot-segments collapse into a protocol-relative URL once parsed.
    "/.//evil.example",
    "/..//evil.example",
    "/a/..//evil.example",
    "/%2e%2e//evil.example",
    "/%2E/%2e//evil.example",
    "/./\\evil.example",
    // Encoded slashes and backslashes.
    "%2F%2Fevil.example",
    "/%2F/evil.example",
    "/%2f/evil.example",
    "/%5Cevil.example",
    "/app\\..\\evil.example",
  ])("rejects %j", (value) => {
    expect(safeNext(value)).toBe("/app");
  });
});

describe("signInPath", () => {
  it("encodes the page to come back to", () => {
    expect(signInPath("/app/insights")).toBe("/sign-in?next=%2Fapp%2Finsights");
  });

  it("never carries an off-site next", () => {
    expect(signInPath("https://evil.example")).toBe("/sign-in?next=%2Fapp");
    expect(signInPath("//evil.example")).toBe("/sign-in?next=%2Fapp");
  });
});
