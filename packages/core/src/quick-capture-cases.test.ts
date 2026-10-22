import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, test } from "vitest";
import { z } from "zod";
import { isIsoDate, isValidTimeZone } from "./dates.ts";

// The cases are shared with the Dart parser (apps/mobile) and a future TypeScript one.
// This file checks that they are well formed and consistent with spec section 5; it does not
// run a parser (there is none in this package).
const read = (name: string): unknown =>
  JSON.parse(
    readFileSync(fileURLToPath(new URL(`../quick-capture/${name}`, import.meta.url)), "utf8"),
  );

const schema = z.fromJSONSchema(
  read("cases.schema.json") as Parameters<typeof z.fromJSONSchema>[0],
);
const raw = read("cases.json");

interface Draft {
  amount: number;
  kind: "expense" | "income";
  name: string;
  categoryId: string | null;
  date: string;
}
interface Case {
  id: string;
  input: string;
  locale: "es" | "en";
  currency: "COP" | "EUR" | "USD";
  today: string;
  timeZone: string;
  categories: { id: string; name: string; kind: "expense" | "income" }[];
  usual: { name: string; categoryId: string }[];
  expected: { drafts: Draft[]; unread: string[] };
}

const parsed = schema.safeParse(raw);
const cases = (parsed.success ? parsed.data : []) as Case[];
const byId = new Map(cases.map((c) => [c.id, c]));
const get = (id: string): Case => {
  const c = byId.get(id);
  if (!c) throw new Error(`missing case ${id}`);
  return c;
};

const plain = (s: string) => s.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase().trim();

const addDays = (iso: string, n: number): string => {
  const d = new Date(`${iso}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
};
const dow = (iso: string) => new Date(`${iso}T00:00:00Z`).getUTCDay();

const RELATIVE: Record<string, number> = {
  hoy: 0,
  today: 0,
  ayer: -1,
  yesterday: -1,
  antier: -2,
  anteayer: -2,
};
const WEEKDAYS: Record<string, number> = {
  domingo: 0,
  sunday: 0,
  lunes: 1,
  monday: 1,
  martes: 2,
  tuesday: 2,
  miercoles: 3,
  wednesday: 3,
  jueves: 4,
  thursday: 4,
  viernes: 5,
  friday: 5,
  sabado: 6,
  saturday: 6,
};
const wordsOf = (input: string) => plain(input).match(/[a-z]+/g) ?? [];

describe("quick-capture cases file", () => {
  test("validates against cases.schema.json", () => {
    expect(parsed.success ? [] : parsed.error.issues).toEqual([]);
  });

  test("the schema rejects malformed cases", () => {
    const good = structuredClone(get("spike-s01"));
    expect(schema.safeParse([good]).success).toBe(true);
    const bad = (mutate: (c: Record<string, unknown>) => void) => {
      const c = structuredClone(good) as unknown as Record<string, unknown>;
      mutate(c);
      return schema.safeParse([c]).success;
    };
    const draft = (c: Record<string, unknown>) =>
      (c.expected as { drafts: Record<string, unknown>[] }).drafts[0] as Record<string, unknown>;
    expect(bad((c) => (draft(c).amount = 15.5))).toBe(false);
    expect(bad((c) => (draft(c).amount = 0))).toBe(false);
    expect(bad((c) => (draft(c).kind = "transfer"))).toBe(false);
    expect(bad((c) => (draft(c).date = "22/10/2026"))).toBe(false);
    expect(bad((c) => delete draft(c).categoryId)).toBe(false);
    expect(bad((c) => (c.currency = "MXN"))).toBe(false);
    expect(bad((c) => (c.locale = "fr"))).toBe(false);
    expect(bad((c) => (c.extra = 1))).toBe(false);
    expect(bad((c) => delete c.usual)).toBe(false);
    expect(bad((c) => (c.id = "Spike S01"))).toBe(false);
    expect(schema.safeParse({}).success).toBe(false);
  });

  test("has the volume and spread the brief asks for", () => {
    expect(cases.length).toBeGreaterThanOrEqual(60);
    // Most of them are Colombian: es, COP.
    const colombian = cases.filter((c) => c.locale === "es" && c.currency === "COP");
    expect(colombian.length).toBeGreaterThan(cases.length / 2);
    const prefixes = new Set(cases.map((c) => c.id.split("-")[0]));
    expect([...prefixes].sort()).toEqual(
      ["amount", "category", "date", "focus", "kind", "real", "spike", "split", "unread"].sort(),
    );
    expect(cases.filter((c) => c.id.startsWith("real-vosk-")).length).toBeGreaterThanOrEqual(10);
  });

  test("ids are unique and no case repeats the same situation", () => {
    expect(new Set(cases.map((c) => c.id)).size).toBe(cases.length);
    const keys = cases.map((c) => [c.input, c.locale, c.currency, c.today].join("|"));
    expect(new Set(keys).size).toBe(cases.length);
  });

  test("the 20 spike sentences are there, with 25 movements", () => {
    const spike = cases.filter((c) => c.id.startsWith("spike-"));
    expect(spike.map((c) => c.id)).toEqual(
      Array.from({ length: 20 }, (_, i) => `spike-s${String(i + 1).padStart(2, "0")}`),
    );
    expect(spike.reduce((n, c) => n + c.expected.drafts.length, 0)).toBe(25);
  });

  test("every case expects something", () => {
    for (const c of cases) {
      expect(c.expected.drafts.length + c.expected.unread.length, c.id).toBeGreaterThan(0);
    }
  });

  test("today and timeZone are real", () => {
    for (const c of cases) {
      expect(isIsoDate(c.today), c.id).toBe(true);
      expect(isValidTimeZone(c.timeZone), c.id).toBe(true);
      for (const d of c.expected.drafts) expect(isIsoDate(d.date), c.id).toBe(true);
    }
  });

  test("names are lowercase and trimmed", () => {
    for (const c of cases) {
      for (const d of c.expected.drafts) {
        expect(d.name, c.id).toBe(d.name.trim().toLowerCase());
      }
    }
  });

  test("categories: ids are unique and usual pairs point at real categories", () => {
    for (const c of cases) {
      const ids = c.categories.map((x) => x.id);
      expect(new Set(ids).size, c.id).toBe(ids.length);
      for (const u of c.usual) expect(ids, c.id).toContain(u.categoryId);
    }
  });

  test("categoryId follows the order in spec 5.2 among categories of the draft's kind: usual name, then category name ignoring accents, then none", () => {
    for (const c of cases) {
      for (const d of c.expected.drafts) {
        const sameKind = c.categories.filter((x) => x.kind === d.kind);
        const usual = c.usual.find(
          (u) => plain(u.name) === plain(d.name) && sameKind.some((x) => x.id === u.categoryId),
        );
        const named = sameKind.find((x) => plain(x.name) === plain(d.name));
        const expected = d.name === "" ? null : (usual?.categoryId ?? named?.id ?? null);
        expect(d.categoryId, `${c.id}: ${d.name}`).toBe(expected);
        if (d.categoryId !== null) {
          const cat = c.categories.find((x) => x.id === d.categoryId);
          expect(cat?.kind, `${c.id}: kind of category`).toBe(d.kind);
        }
      }
    }
  });

  test("dates follow the date word in the sentence", () => {
    for (const c of cases) {
      const words = wordsOf(c.input);
      const rel = words.filter((w) => w in RELATIVE);
      const wd = words.filter((w) => w in WEEKDAYS);
      if (rel.length + wd.length > 1) continue; // per-clause dates are checked by name below
      let want = c.today;
      if (rel[0] !== undefined) want = addDays(c.today, RELATIVE[rel[0]] as number);
      if (wd[0] !== undefined) {
        // Most recent past one: a weekday equal to today means last week.
        const back = (dow(c.today) - (WEEKDAYS[wd[0]] as number) + 7) % 7 || 7;
        want = addDays(c.today, -back);
      }
      // The date word carries over to later movements only: the drafts are dated today until
      // the movement that holds it, then `want`.
      const dates = c.expected.drafts.map((d) => d.date);
      const from = dates.indexOf(want);
      const expected = dates.map((_, i) => (from !== -1 && i >= from ? want : c.today));
      expect(dates, c.id).toEqual(expected);
      if (rel.length + wd.length === 1 && want !== c.today && c.expected.drafts.length > 0) {
        // Unless the date word sits in an unread fragment, some draft carries it.
        const inUnread = wordsOf(c.expected.unread.join(" ")).some(
          (w) => w in RELATIVE || w in WEEKDAYS,
        );
        if (!inUnread) expect(from, c.id).toBeGreaterThanOrEqual(0);
      }
    }
  });

  test("context carries over: kind and date", () => {
    const kinds = (id: string) => get(id).expected.drafts.map((d) => d.kind);
    const dates = (id: string) => get(id).expected.drafts.map((d) => d.date);
    expect(kinds("kind-carries-over")).toEqual(["income", "income"]);
    expect(kinds("kind-mixed-carry")).toEqual(["income", "expense"]);
    expect(kinds("kind-new-verb-carries")).toEqual(["income", "expense", "expense"]);
    expect(dates("date-carries-over")).toEqual(["2026-10-21", "2026-10-21"]);
    expect(dates("date-carries-forward-only")).toEqual(["2026-10-22", "2026-10-21"]);
    expect(dates("date-carries-until-next")).toEqual(["2026-10-21", "2026-10-22", "2026-10-22"]);
  });

  test("three digits after a separator are thousands; a scale after them is unread", () => {
    const amountOf = (id: string) => get(id).expected.drafts.map((d) => d.amount);
    expect(amountOf("amount-comma-thousands-cop")).toEqual([1_500_000]);
    expect(amountOf("amount-dollar-comma-thousands-cop")).toEqual([2_500_000, 800_000]);
    expect(amountOf("amount-eur-comma-thousands")).toEqual([150_000]);
    expect(amountOf("amount-eur-decimal-comma")).toEqual([950]);
    expect(get("amount-thousands-before-scale-unread").expected.drafts).toEqual([]);
  });

  test("amounts above 999 999 999 are unread", () => {
    for (const id of [
      "amount-over-cap-digits",
      "amount-over-cap-billion",
      "amount-over-cap-mil-millones",
    ]) {
      expect(get(id).expected.drafts, id).toEqual([]);
      expect(get(id).expected.unread, id).toEqual([get(id).input]);
    }
    expect(get("amount-cap-max").expected.drafts[0]?.amount).toBe(99_999_999_900);
    for (const c of cases) {
      for (const d of c.expected.drafts) expect(d.amount, c.id).toBeLessThanOrEqual(99_999_999_900);
    }
  });

  test("slang units outside COP are never read as an amount", () => {
    // 'lukas', 'luca' and 'palos' multiply only in COP; elsewhere the fragment is unread, not dropped.
    for (const c of cases.filter((x) => x.currency !== "COP")) {
      const slang = wordsOf(c.input).filter((w) => /^(lukas?|lucas?|palos?)$/.test(w));
      if (slang.length === 0) continue;
      const unread = wordsOf(c.expected.unread.join(" "));
      for (const w of slang) expect(unread, `${c.id}: ${w}`).toContain(w);
      for (const d of c.expected.drafts) expect(wordsOf(d.name), c.id).not.toContain(slang[0]);
    }
  });
});

describe("review focus cases", () => {
  test('"15 lukas" in a EUR account is never 15.000 EUR (nor 15 EUR): it is unread', () => {
    const c = get("focus-eur-lukas");
    expect(c.input).toBe("15 lukas");
    expect(c.currency).toBe("EUR");
    expect(c.expected).toEqual({ drafts: [], unread: ["15 lukas"] });
    for (const id of [
      "focus-eur-lukas-sentence",
      "focus-eur-luca",
      "focus-usd-palos",
      "focus-eur-two-slang",
    ]) {
      expect(get(id).expected.drafts, id).toEqual([]);
      expect(get(id).expected.unread.length, id).toBeGreaterThan(0);
    }
    // The same words still work in COP.
    expect(get("focus-cop-lukas-still-count").expected.drafts[0]?.amount).toBe(1_500_000);
  });

  test('"ayer" on 2026-10-01 in America/Bogota is 2026-09-30', () => {
    const c = get("focus-ayer-month-boundary");
    expect(c.today).toBe("2026-10-01");
    expect(c.timeZone).toBe("America/Bogota");
    expect(c.input).toContain("ayer");
    expect(c.expected.drafts.map((d) => d.date)).toEqual(["2026-09-30"]);
  });

  test("other calendar boundaries", () => {
    expect(get("focus-ayer-year-boundary").expected.drafts[0]?.date).toBe("2026-12-31");
    expect(get("focus-antier-month-boundary").expected.drafts[0]?.date).toBe("2026-02-27");
    expect(get("focus-ayer-leap-day").expected.drafts[0]?.date).toBe("2028-02-29");
    expect(get("date-weekday-month-boundary").expected.drafts[0]?.date).toBe("2026-09-28");
  });

  test("the spec 5.2 amount examples read as cents", () => {
    const amountOf = (id: string) => get(id).expected.drafts[0]?.amount;
    expect(amountOf("spike-s01")).toBe(1_500_000); // 15 mil COP
    expect(amountOf("spike-s09")).toBe(950); // 9,50 EUR
    expect(amountOf("spike-s05")).toBe(430_000_000); // 4,3 palos
    expect(amountOf("spike-s07")).toBe(50_000_000); // medio palo
    expect(amountOf("spike-s12")).toBe(100_000); // una luca
    expect(amountOf("amount-en-comma-thousands")).toBe(1_500_000);
    expect(amountOf("amount-en-twelve-fifty")).toBe(1250);
  });

  test('"pan y leche 8 mil" is one movement', () => {
    expect(get("split-pan-y-leche-before").expected.drafts.map((d) => d.name)).toEqual([
      "pan y leche",
    ]);
  });
});
