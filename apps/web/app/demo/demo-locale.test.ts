import { describe, expect, it } from "vitest";
import { DEMO_LANG_KEY, demoLocale, rememberDemoLocale } from "./demo-locale.ts";

const store = (initial: Record<string, string> = {}) => {
  const data = new Map(Object.entries(initial));
  return {
    getItem: (key: string) => data.get(key) ?? null,
    setItem: (key: string, value: string) => void data.set(key, value),
  };
};

describe("demoLocale", () => {
  it("takes the landing's ?lang= first", () => {
    expect(demoLocale("?lang=en", store({ [DEMO_LANG_KEY]: "es" }), "es-CO")).toBe("en");
    expect(demoLocale("?lang=es", store(), "en-US")).toBe("es");
  });

  it("then what the tab remembered, so reloading /demo/insights keeps the language", () => {
    const tab = store();
    rememberDemoLocale("en", tab);
    expect(demoLocale("", tab, "es-CO")).toBe("en");
  });

  it("then the browser's language; anything else in ?lang or storage is ignored", () => {
    expect(demoLocale("?lang=fr", store({ [DEMO_LANG_KEY]: "de" }), "es-CO")).toBe("es");
    expect(demoLocale("", store(), "en-GB")).toBe("en");
  });

  it("survives blocked storage", () => {
    const blocked = {
      getItem: () => {
        throw new Error("blocked");
      },
      setItem: () => {
        throw new Error("blocked");
      },
    };
    expect(demoLocale("", blocked, "es")).toBe("es");
    expect(() => rememberDemoLocale("en", blocked)).not.toThrow();
  });
});
