import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import type { LukasMessageKey } from "@lukas/core";
import { createTranslator } from "use-intl/core";
import { describe, expect, it } from "vitest";
import { CATALOGS } from "./catalog.ts";
import appEn from "./messages/app.en.json" with { type: "json" };
import appEs from "./messages/app.es.json" with { type: "json" };
import siteEn from "./messages/en.json" with { type: "json" };
import siteEs from "./messages/es.json" with { type: "json" };

const { es, en } = CATALOGS;

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

/** Sorted rich-text tag names of a message (`<mark>lukas</mark>` → `mark`), for `t.rich`. */
function richTags(message: string): string[] {
  return [...message.matchAll(/<([A-Za-z_]\w*)>/g)].map((match) => match[1] as string).sort();
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
  it("come in two parts, the public pages' and the app's, each namespace in one part only", () => {
    // What the landing and roadmap render (Landing, Roadmap, SiteHeader, Footer, ThemeToggle,
    // HeroMascot): the root's IntlProvider holds only these, so the landing ships nothing else.
    const site = ["app", "landing", "language", "mascot", "roadmap", "theme"];
    expect(Object.keys(siteEs).sort()).toEqual(site);
    expect(Object.keys(siteEn).sort()).toEqual(site);
    expect(Object.keys(appEn).sort()).toEqual(Object.keys(appEs).sort());
    expect(Object.keys(appEs).filter((namespace) => site.includes(namespace))).toEqual([]);
    expect(Object.keys(es).sort()).toEqual([...site, ...Object.keys(appEs)].sort());
  });

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

  it("uses the same rich-text tags in es and en for every key", () => {
    for (const key of Object.keys(catalogs.es)) {
      expect(richTags(catalogs.en[key] ?? ""), key).toEqual(richTags(catalogs.es[key] ?? ""));
    }
  });

  it("never names the product or the mascot Lukas (it is Lukitas; the slang word is lowercase)", () => {
    for (const locale of ["es", "en"] as const) {
      for (const [key, value] of Object.entries(catalogs[locale])) {
        expect(value, `${locale}:${key}`).not.toMatch(/\bLukas\b/);
      }
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

describe("deleting an account promises what is true (backups keep it up to 14 days)", () => {
  const DELETION = {
    es: "Borramos tu cuenta y todos tus movimientos de inmediato. Las copias de seguridad que los incluyan se borran solas en 14 días.",
    en: "We delete your account and all your entries right away. Backups that include them delete themselves within 14 days.",
  } as const;

  for (const locale of ["es", "en"] as const) {
    it(`${locale}: says when the backups go, and never "forever"`, () => {
      const lines = Object.entries(catalogs[locale]).filter(([key]) =>
        key.startsWith("settings.delete."),
      );
      expect(catalogs[locale]["settings.delete.lead"]).toBe(DELETION[locale]);
      for (const [key, line] of lines) {
        expect(line, key).not.toMatch(
          /para siempre|recuperarlos|no se puede deshacer|forever|for good|get them back|can't be undone/i,
        );
      }
    });
  }
});

describe("the privacy answer claims only what open code shows", () => {
  const site = { es: flatten(siteEs as Tree), en: flatten(siteEn as Tree) } as const;
  const ANSWER = {
    es: "El código es abierto: cualquiera puede leer el código que los maneja.",
    en: "The code is open source: anyone can read the code that handles it.",
  } as const;

  for (const locale of ["es", "en"] as const) {
    it(`${locale}: open code shows what the code does, not what a server does`, () => {
      expect(site[locale]["landing.faq.privacy.a"]).toContain(ANSWER[locale]);
      for (const [key, line] of Object.entries(site[locale])) {
        expect(line, key).not.toMatch(
          /comprobar qué hacemos|qué hacemos con ellos|check what we do|what we do with it/i,
        );
      }
    });
  }
});
