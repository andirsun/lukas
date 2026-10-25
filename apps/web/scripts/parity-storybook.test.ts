import { readFileSync } from "node:fs";
import { join } from "node:path";
import { runInNewContext } from "node:vm";
import { describe, expect, it } from "vitest";
import { E2E_NOW } from "../e2e/helpers.ts";
import { APP_GETS, fixtureKey } from "./parity-fixtures.ts";
import {
  clockScript,
  EMOJI_UNICODE_RANGE,
  PARITY_DIR,
  PARITY_NOW,
  PARITY_TIMEZONE,
  parsePairs,
  readPairs,
  storyUrl,
} from "./parity-storybook.ts";

const pair = {
  id: "money-spanish",
  storyId: "ui-money--spanish",
  theme: "night",
  appTest: "test/parity/money_parity_test.dart",
};

describe("parity pairs", () => {
  it("reads the committed parity.json", () => {
    const pairs = readPairs();
    expect(pairs.length).toBeGreaterThan(0);
    expect(pairs.map((p) => p.theme)).toContain("day");
    expect(readPairs("money").every((p) => p.id.includes("money"))).toBe(true);
  });

  it("refuses a pair listed twice, an unknown theme and a bad story id", () => {
    expect(parsePairs([pair])).toEqual([pair]);
    expect(() => parsePairs([pair, pair])).toThrow("money-spanish-night is listed twice");
    expect(() => parsePairs([{ ...pair, theme: "dark" }])).toThrow('"night" or "day"');
    expect(() => parsePairs([{ ...pair, storyId: "UI/Money" }])).toThrow("Storybook id");
    expect(() => parsePairs([{ ...pair, id: "Money Spanish" }])).toThrow("kebab-case");
    expect(() => parsePairs({})).toThrow("a list");
  });

  it("lists, for each pair, an app test that exists", () => {
    for (const { appTest } of readPairs()) {
      expect(() => readFileSync(join(PARITY_DIR, "..", "..", appTest))).not.toThrow();
    }
  });
});

describe("the parity page", () => {
  it("opens the story alone, in the pair's theme", () => {
    expect(storyUrl("http://127.0.0.1:1234", "ui-money--spanish", "day")).toBe(
      "http://127.0.0.1:1234/iframe.html?id=ui-money--spanish&viewMode=story&globals=theme:day",
    );
  });

  it("pins the e2e suite's now, in the stories' time zone", () => {
    expect(PARITY_NOW).toBe(E2E_NOW);
    const harness = readFileSync(
      join(PARITY_DIR, "../../../web/app/features/home/story-harness.tsx"),
      "utf8",
    );
    expect(harness).toContain(`export const STORY_TIMEZONE = "${PARITY_TIMEZONE}";`);
  });

  it("moves the page's clock with the demo's fakeClock and keeps explicit dates", () => {
    class RealDate extends Date {}
    const page = { Date: RealDate } as { Date: DateConstructor };
    runInNewContext(clockScript(PARITY_NOW), page);
    expect(Math.abs(page.Date.now() - Date.parse(PARITY_NOW))).toBeLessThan(5_000);
    expect(new page.Date().toISOString().slice(0, 10)).toBe("2026-10-21");
    expect(new page.Date("2020-01-02T00:00:00Z").toISOString()).toBe("2020-01-02T00:00:00.000Z");
  });

  it("puts the emoji, and no Latin letter or digit, on the emoji font", () => {
    const ranges = EMOJI_UNICODE_RANGE.split(", ").map((r) => {
      const [from = "", to = from] = r.slice(2).split("-");
      return [Number.parseInt(from, 16), Number.parseInt(to, 16)] as const;
    });
    const covered = (char: string) => {
      const code = char.codePointAt(0) as number;
      return ranges.some(([from, to]) => code >= from && code <= to);
    };
    for (const emoji of ["🛒", "🍽", "⭐", "🚗", "💰", "🏠", "📱", "❤", "🧾", "\u{FE0F}"]) {
      expect(covered(emoji), emoji).toBe(true);
    }
    for (const text of ["a", "Z", "0", "9", "€", "$", "©", "®", "™", "−", " ", "ñ"]) {
      expect(covered(text), text).toBe(false);
    }
  });
});

describe("the fixtures' keys", () => {
  it("drop the web's /api mount and sort the query", () => {
    expect(fixtureKey("/api/v1/summary?month=2026-10")).toBe("/v1/summary?month=2026-10");
    expect(fixtureKey("/v1/transactions?month=2026-10&limit=50")).toBe(
      "/v1/transactions?limit=50&month=2026-10",
    );
    expect(fixtureKey("/v1/me")).toBe("/v1/me");
  });

  it("ask the app's GETs in the parity month", () => {
    expect(APP_GETS).toContain("/v1/summary?month=2026-10");
  });
});
