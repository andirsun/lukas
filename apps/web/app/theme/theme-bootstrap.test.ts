import { describe, expect, it } from "vitest";
import { resolveTheme, THEME_BOOTSTRAP_SCRIPT } from "./theme-bootstrap.ts";

interface Env {
  stored?: string | null;
  prefersDark?: boolean;
  storageThrows?: boolean;
  noMatchMedia?: boolean;
}

/** Runs the inline script against a fake document, localStorage and matchMedia. */
function run(env: Env): { theme: string | undefined } {
  const dataset: Record<string, string> = {};
  const document = { documentElement: { dataset } };
  const localStorage = {
    getItem(key: string) {
      if (env.storageThrows) throw new Error("storage blocked");
      return key === "lukas.theme" ? (env.stored ?? null) : null;
    },
  };
  const matchMedia = (query: string) => ({
    matches: query === "(prefers-color-scheme: dark)" ? (env.prefersDark ?? false) : false,
  });
  const args: unknown[] = [document, localStorage, env.noMatchMedia ? undefined : matchMedia];
  new Function("document", "localStorage", "matchMedia", THEME_BOOTSTRAP_SCRIPT)(...args);
  return { theme: dataset.theme };
}

describe("THEME_BOOTSTRAP_SCRIPT (theme flash)", () => {
  it("applies the stored day theme even when the OS prefers dark", () => {
    expect(run({ stored: "day", prefersDark: true }).theme).toBe("day");
  });

  it("applies the stored night theme even when the OS prefers light", () => {
    expect(run({ stored: "night", prefersDark: false }).theme).toBe("night");
  });

  it("follows the OS for auto and for a missing preference", () => {
    expect(run({ stored: "auto", prefersDark: true }).theme).toBe("night");
    expect(run({ stored: "auto", prefersDark: false }).theme).toBe("day");
    expect(run({ stored: null, prefersDark: false }).theme).toBe("day");
    expect(run({ stored: null, prefersDark: true }).theme).toBe("night");
  });

  it("ignores an unknown stored value", () => {
    expect(run({ stored: "purple", prefersDark: true }).theme).toBe("night");
  });

  it("falls back to the OS preference when localStorage throws", () => {
    expect(run({ storageThrows: true, prefersDark: false }).theme).toBe("day");
    expect(run({ storageThrows: true, prefersDark: true }).theme).toBe("night");
  });

  it("defaults to night without matchMedia", () => {
    expect(run({ stored: null, noMatchMedia: true }).theme).toBe("night");
  });
});

describe("resolveTheme", () => {
  it("returns explicit choices and resolves auto from the OS", () => {
    expect(resolveTheme("day", true)).toBe("day");
    expect(resolveTheme("night", false)).toBe("night");
    expect(resolveTheme("auto", true)).toBe("night");
    expect(resolveTheme("auto", false)).toBe("day");
  });
});
