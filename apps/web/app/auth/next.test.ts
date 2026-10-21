import { describe, expect, it } from "vitest";
import { safeNext, signInPath } from "./next.ts";

describe("safeNext", () => {
  it("keeps same-origin paths with their query and hash", () => {
    expect(safeNext("/app/insights")).toBe("/app/insights");
    expect(safeNext("/app/transactions?month=2026-10#top")).toBe(
      "/app/transactions?month=2026-10#top",
    );
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
