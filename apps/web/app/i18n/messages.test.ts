import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import type { LukasMessageKey } from "@lukas/core";
import { createTranslator } from "use-intl/core";
import { describe, expect, it } from "vitest";
import en from "./messages/en.json" with { type: "json" };
import es from "./messages/es.json" with { type: "json" };

type Tree = { [key: string]: string | Tree };

function flatten(tree: Tree, prefix = ""): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(tree)) {
    const path = prefix ? `${prefix}.${key}` : key;
    if (typeof value === "string") out[path] = value;
    else Object.assign(out, flatten(value, path));
  }
  return out;
}

const catalogs = { es: flatten(es), en: flatten(en) } as const;

/** Exhaustive by construction: adding or removing a LukasMessageKey fails the type check. */
const LUKAS_KEYS = {
  first_of_day: {},
  on_track: { remaining: "120,00 €", daysLeft: 9 },
  near_limit: { category: "Comida", remaining: "8,00 €" },
  over_budget: { category: "Comida", over: "6,08 €" },
  income_received: { amount: "1.200,00 €" },
  pending_paid: { amount: "45,00 €" },
  month_last_day: { remaining: "120,00 €" },
  month_closed_green: { remaining: "120,00 €" },
} satisfies Record<LukasMessageKey, Record<string, string | number>>;

/** Sorted, de-duplicated argument names of an ICU message (`{name}`, `{name, plural, ...}`). */
function icuArguments(message: string): string[] {
  const names = new Set<string>();
  for (const match of message.matchAll(/\{\s*([A-Za-z_]\w*)\s*[,}]/g))
    names.add(match[1] as string);
  return [...names].sort();
}

function apiErrorCodes(): string[] {
  const root = fileURLToPath(new URL("../../../api/src", import.meta.url));
  const codes = new Set<string>();
  const walk = (dir: string) => {
    for (const name of readdirSync(dir)) {
      const path = join(dir, name);
      if (statSync(path).isDirectory()) walk(path);
      else if (path.endsWith(".ts") && !path.endsWith(".test.ts")) {
        const source = readFileSync(path, "utf8");
        for (const match of source.matchAll(/new ApiError\(\s*\d+,\s*"([a-z_]+)"/g)) {
          codes.add(match[1] as string);
        }
      }
    }
  };
  walk(root);
  return [...codes];
}

describe("message catalogs", () => {
  it("es and en have identical key sets", () => {
    expect(Object.keys(catalogs.es).sort()).toEqual(Object.keys(catalogs.en).sort());
  });

  it("uses the same ICU argument names in es and en for every key", () => {
    for (const key of Object.keys(catalogs.es)) {
      expect(icuArguments(catalogs.en[key] ?? ""), key).toEqual(
        icuArguments(catalogs.es[key] ?? ""),
      );
    }
  });

  it("has no empty messages", () => {
    for (const locale of ["es", "en"] as const) {
      for (const [key, value] of Object.entries(catalogs[locale])) {
        expect(value.trim(), `${locale}:${key}`).not.toBe("");
      }
    }
  });

  for (const locale of ["es", "en"] as const) {
    describe(locale, () => {
      for (const [key, params] of Object.entries(LUKAS_KEYS)) {
        it(`has 3+ variants for lukas.${key} that all format`, () => {
          const variants = Object.keys(catalogs[locale]).filter((k) =>
            new RegExp(`^lukas\\.${key}\\.\\d+$`).test(k),
          );
          expect(variants.length).toBeGreaterThanOrEqual(3);
          // A bad ICU string or a missing param must fail the test, not fall back to the key path.
          const t = createTranslator({
            locale,
            messages: locale === "es" ? es : en,
            onError: (error) => {
              throw error;
            },
          });
          for (const variant of variants) {
            const text = t(variant as never, params as never);
            expect(text, variant).not.toBe(variant);
            expect(text, variant).not.toMatch(/[{}]/);
            expect(text.length, variant).toBeGreaterThan(0);
          }
        });
      }

      it("has no lukas messages for unknown keys", () => {
        const known = new Set(Object.keys(LUKAS_KEYS));
        for (const path of Object.keys(catalogs[locale])) {
          const match = /^lukas\.([a-z_]+)\./.exec(path);
          if (match) expect(known.has(match[1] as string), path).toBe(true);
        }
      });
    });
  }

  it("covers every API error code", () => {
    const codes = apiErrorCodes();
    expect(codes.length).toBeGreaterThan(10);
    for (const code of [...codes, "generic"]) {
      expect(catalogs.es, `es errors.${code}`).toHaveProperty([`errors.${code}`]);
      expect(catalogs.en, `en errors.${code}`).toHaveProperty([`errors.${code}`]);
    }
  });
});
