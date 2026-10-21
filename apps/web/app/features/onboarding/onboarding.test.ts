import { InvalidAmountError } from "@lukas/core";
import { describe, expect, it } from "vitest";
import { createApiClient } from "../../api/client.ts";
import { budgetExample, draftFromCents, parseBudgetInput } from "./budget-input.ts";
import { categoryChips } from "./category-chips.ts";
import { defaultCurrency } from "./currency.ts";
import { countCategoryTransactions, createSuggestions } from "./onboarding-api.ts";
import { passkeyOutcome } from "./passkey.ts";
import { nextStep, previousStep, STEPS, stepFromParam, stepPath } from "./steps.ts";
import { normalizeName, SUGGESTED_CATEGORIES, suggestionFor } from "./suggested-categories.ts";
import { browserTimeZone, timeZoneToSave } from "./timezone.ts";

describe("defaultCurrency", () => {
  // The rule (founder, 2026-10-21): Colombia → COP; Europe → EUR; anywhere else → USD.
  const cases: [languages: string[], timeZone: string | undefined, expected: string][] = [
    [["es-CO"], "America/Bogota", "COP"],
    [["es-CO"], "Europe/Madrid", "COP"],
    [["en-US", "es-CO"], "America/New_York", "COP"],
    [["es"], "America/Bogota", "COP"],
    [["en-US"], "America/Bogota", "COP"],
    [["es-ES"], "Europe/Madrid", "EUR"],
    [["pt-PT"], "Europe/Lisbon", "EUR"],
    [["en-GB"], "Europe/London", "EUR"],
    [["de-CH"], "Europe/Zurich", "EUR"],
    [["es"], "Europe/Madrid", "EUR"],
    [["en-US"], "Europe/Berlin", "EUR"],
    [["fr-FR"], undefined, "EUR"],
    [["en-US"], "America/New_York", "USD"],
    [["es-MX"], "America/Mexico_City", "USD"],
    [["es-AR"], "America/Argentina/Buenos_Aires", "USD"],
    [["es-CL"], "America/Santiago", "USD"],
    [["es-PE"], "America/Lima", "USD"],
    [["es"], "America/Mexico_City", "USD"],
    [["es"], undefined, "USD"],
    [[], undefined, "USD"],
    [["not a tag"], "Asia/Tokyo", "USD"],
  ];
  for (const [languages, timeZone, expected] of cases) {
    it(`${languages.join(",") || "(none)"} in ${timeZone ?? "(no zone)"} → ${expected}`, () => {
      expect(defaultCurrency(languages, timeZone)).toBe(expected);
    });
  }
});

describe("parseBudgetInput", () => {
  it("reads amounts in hundredths, with the locale's decimal separator", () => {
    expect(parseBudgetInput("300", "es")).toBe(30000);
    expect(parseBudgetInput("120,50", "es")).toBe(12050);
    expect(parseBudgetInput("120.50", "en")).toBe(12050);
  });

  it("accepts thousands separators, as people write pesos", () => {
    expect(parseBudgetInput("300.000", "es")).toBe(30_000_000);
    expect(parseBudgetInput("1.250.000,5", "es")).toBe(125_000_050);
    expect(parseBudgetInput("300,000", "en")).toBe(30_000_000);
    expect(parseBudgetInput(" $ 300.000 ", "es")).toBe(30_000_000);
  });

  it("is null when empty", () => {
    expect(parseBudgetInput("", "es")).toBeNull();
    expect(parseBudgetInput("   ", "en")).toBeNull();
  });

  it("rejects what is not an amount", () => {
    for (const text of ["abc", "-5", "1.5", "12,345,6", "1,2,3"]) {
      expect(() => parseBudgetInput(text, text === "12,345,6" ? "en" : "es"), text).toThrow(
        InvalidAmountError,
      );
    }
  });

  it("gives an example that parses", () => {
    for (const currency of ["COP", "EUR", "CLP", "USD"]) {
      for (const locale of ["es", "en"] as const) {
        expect(parseBudgetInput(budgetExample(currency, locale), locale)).toBeGreaterThan(0);
      }
    }
    expect(budgetExample("COP", "es")).toBe("300.000");
    expect(budgetExample("EUR", "es")).toBe("300");
  });
});

describe("steps", () => {
  it("are the welcome and the four setup steps, budgets last", () => {
    // The import comes before the categories, so they can start from what the file brought.
    expect(STEPS).toEqual(["welcome", "currency", "import", "categories", "budgets"]);
  });

  it("map to /welcome paths and back", () => {
    expect(stepPath("welcome")).toBe("/welcome");
    expect(stepPath("currency")).toBe("/welcome/currency");
    expect(stepFromParam(undefined)).toBe("welcome");
    expect(stepFromParam("import")).toBe("import");
    expect(stepFromParam("welcome")).toBeNull();
    expect(stepFromParam("passkey")).toBeNull();
    expect(stepFromParam("done")).toBeNull();
  });

  it("go forward and back in order", () => {
    expect(nextStep("welcome")).toBe("currency");
    expect(nextStep("currency")).toBe("import");
    expect(nextStep("import")).toBe("categories");
    expect(nextStep("categories")).toBe("budgets");
    expect(nextStep("budgets")).toBeNull();
    expect(previousStep("currency")).toBe("welcome");
    expect(previousStep("welcome")).toBeNull();
  });
});

describe("timeZoneToSave", () => {
  const supported = ["America/Bogota", "Europe/Madrid", "UTC"];

  it("saves the browser's zone while the profile still has the default", () => {
    expect(timeZoneToSave("UTC", "America/Bogota", supported)).toBe("America/Bogota");
  });

  it("leaves a zone the person already has", () => {
    expect(timeZoneToSave("Europe/Madrid", "America/Bogota", supported)).toBeNull();
  });

  it("ignores a zone the runtime doesn't know, a missing one, or UTC itself", () => {
    expect(timeZoneToSave("UTC", "Mars/Olympus", supported)).toBeNull();
    expect(timeZoneToSave("UTC", undefined, supported)).toBeNull();
    expect(timeZoneToSave("UTC", "UTC", supported)).toBeNull();
  });

  it("reads the real browser zone from a list the runtime supports", () => {
    const { zone, supported: known } = browserTimeZone();
    expect(typeof zone).toBe("string");
    expect(known.length).toBeGreaterThan(100);
  });
});

describe("SUGGESTED_CATEGORIES", () => {
  it("has the spec's eight, with one income", () => {
    expect(SUGGESTED_CATEGORIES.map((c) => c.names.es)).toEqual([
      "Supermercado",
      "Restaurante",
      "Casa",
      "Transporte",
      "Ocio",
      "Suscripciones",
      "Vida",
      "Salario",
    ]);
    expect(SUGGESTED_CATEGORIES.filter((c) => c.kind === "income").map((c) => c.key)).toEqual([
      "salary",
    ]);
    expect(new Set(SUGGESTED_CATEGORIES.map((c) => c.key)).size).toBe(8);
  });

  it("finds the suggestion behind a name, in either language, ignoring case and accents", () => {
    expect(suggestionFor("supermercado")?.key).toBe("groceries");
    expect(suggestionFor("Eating out")?.key).toBe("eating_out");
    expect(suggestionFor("Salário")?.key).toBe("salary");
    expect(suggestionFor("Taxes")).toBeUndefined();
  });
});

describe("passkeyOutcome", () => {
  it("is silent when the person closes the prompt", () => {
    for (const code of [
      "AUTH_CANCELLED",
      "ERROR_CEREMONY_ABORTED",
      "ERROR_PASSTHROUGH_SEE_CAUSE_PROPERTY",
    ]) {
      expect(passkeyOutcome({ code }), code).toBe("cancelled");
    }
  });

  it("counts a passkey this device already has as added", () => {
    expect(passkeyOutcome(null)).toBe("added");
    expect(passkeyOutcome({ code: "ERROR_AUTHENTICATOR_PREVIOUSLY_REGISTERED" })).toBe("added");
  });

  it("fails on anything else", () => {
    expect(passkeyOutcome({ code: "UNKNOWN_ERROR" })).toBe("failed");
    expect(passkeyOutcome({})).toBe("failed");
  });
});

describe("draftFromCents", () => {
  it("writes a stored amount the way the field reads it back", () => {
    expect(draftFromCents(3589, "es")).toBe("35,89");
    expect(draftFromCents(30_000_000, "es")).toBe("300.000");
    expect(draftFromCents(30_000_000, "en")).toBe("300,000");
    for (const cents of [3589, 30_000_000, 102_050, 125_000_050]) {
      for (const locale of ["es", "en"] as const) {
        expect(parseBudgetInput(draftFromCents(cents, locale), locale)).toBe(cents);
      }
    }
  });
});

describe("categoryChips", () => {
  const server = (name: string, kind: "expense" | "income" = "expense", archived = false) => ({
    id: `id-${name}`,
    name,
    kind,
    icon: "cart",
    color: "orange",
    archived,
  });

  it("is the suggestions, in order, when the person has no categories", () => {
    const chips = categoryChips([], "es");
    expect(chips.map((c) => c.name)).toEqual(SUGGESTED_CATEGORIES.map((s) => s.names.es));
    expect(chips.every((c) => c.source === "suggestion")).toBe(true);
    expect(chips[0]).toMatchObject({ id: "s:groceries", glyph: "🛒", kind: "expense" });
  });

  it("puts what they have (an import's categories) first, then the suggestions not covered", () => {
    const chips = categoryChips(
      [server("Taxes"), server("supermercado"), server("Salário", "income"), server("Ocio")],
      "es",
    );
    expect(chips.map((c) => c.name)).toEqual([
      "Taxes",
      "supermercado",
      "Salário",
      "Ocio",
      "Restaurante",
      "Casa",
      "Transporte",
      "Suscripciones",
      "Vida",
    ]);
    // The importer's icon names are shown as emoji.
    expect(chips[0]).toMatchObject({ id: "id-Taxes", source: "category", glyph: "🛒" });
  });

  it("treats names that differ in case or accents as the same", () => {
    const chips = categoryChips([server("SUPERMERCADO"), server("Suscripcíones")], "es");
    expect(chips.filter((c) => normalizeName(c.name) === "supermercado")).toHaveLength(1);
    expect(chips.filter((c) => normalizeName(c.name) === "suscripciones")).toHaveLength(1);
  });

  it("covers a suggestion by its English name too, and leaves out archived categories", () => {
    const chips = categoryChips([server("Groceries"), server("Casa", "expense", true)], "es");
    expect(chips.map((c) => c.name)).not.toContain("Supermercado");
    expect(chips.map((c) => c.name)).toContain("Casa");
    expect(chips.find((c) => c.name === "Casa")?.source).toBe("suggestion");
  });

  it("names the suggestions in the person's language", () => {
    expect(categoryChips([], "en")[0]?.name).toBe("Groceries");
  });
});

describe("createSuggestions", () => {
  /** An API client over a fake backend that records the writes. */
  function fakeApi(start: { name: string; archived: boolean }[]) {
    const writes: string[] = [];
    let categories = start.map((c, i) => ({
      id: `cat-${i}`,
      kind: "expense",
      icon: "🏷️",
      color: "#8e87b8",
      sortOrder: 0,
      currentBudget: null,
      ...c,
    }));
    const api = createApiClient({
      baseUrl: "http://test/api",
      onUnauthorized: () => {},
      fetch: async (input) => {
        const request = input as Request;
        const { pathname } = new URL(request.url);
        if (request.method === "GET") return Response.json(categories);
        const body = (await request.json()) as Record<string, unknown>;
        writes.push(`${request.method} ${pathname.replace("/api", "")} ${JSON.stringify(body)}`);
        const id = /categories\/([^/]+)$/.exec(pathname)?.[1];
        if (id) {
          categories = categories.map((c) => (c.id === id ? { ...c, ...body } : c));
          return Response.json(categories.find((c) => c.id === id));
        }
        const created = {
          ...categories[0],
          ...body,
          id: `cat-${categories.length}`,
          archived: false,
        };
        categories = [...categories, created as (typeof categories)[number]];
        return Response.json(created, { status: 201 });
      },
    });
    return { api, writes };
  }
  const every = SUGGESTED_CATEGORIES.map((s) => s.key);

  it("brings back suggestions that exist only archived, instead of skipping them", async () => {
    const { api, writes } = fakeApi(
      SUGGESTED_CATEGORIES.map((s) => ({ name: s.names.es, archived: true })),
    );
    await createSuggestions(api, new Set(every), "es");
    expect(writes).toHaveLength(8);
    expect(
      writes.every(
        (w) => w.startsWith("PATCH /v1/categories/") && w.endsWith('{"archived":false}'),
      ),
    ).toBe(true);
  });

  it("leaves active ones alone, restores archived ones and makes the missing ones", async () => {
    const { api, writes } = fakeApi([
      { name: "Supermercado", archived: false },
      { name: "restaurante", archived: true },
    ]);
    await createSuggestions(api, new Set(every), "es");
    expect(writes.filter((w) => w.startsWith("PATCH"))).toEqual([
      'PATCH /v1/categories/cat-1 {"archived":false}',
    ]);
    expect(writes.filter((w) => w.startsWith("POST"))).toHaveLength(6);
    expect(writes.some((w) => w.includes('"name":"Supermercado"'))).toBe(false);
  });
});

describe("countCategoryTransactions", () => {
  /** A client whose transaction list has `total` rows for the category, 200 per page. */
  function pagedApi(total: number) {
    const requests: string[] = [];
    const api = createApiClient({
      baseUrl: "http://test/api",
      onUnauthorized: () => {},
      fetch: async (input) => {
        const url = new URL((input as Request).url);
        requests.push(url.search);
        const page = Number(url.searchParams.get("cursor") ?? 0);
        const left = total - page * 200;
        return Response.json({
          items: Array.from({ length: Math.max(0, Math.min(200, left)) }, (_, i) => ({ id: i })),
          nextCursor: left > 200 ? String(page + 1) : null,
        });
      },
    });
    return { api, requests };
  }

  it("counts across pages", async () => {
    const { api, requests } = pagedApi(450);
    await expect(countCategoryTransactions(api, "c1")).resolves.toEqual({
      count: 450,
      capped: false,
    });
    expect(requests).toHaveLength(3);
    expect(requests[0]).toContain("category=c1");
  });

  it("stops at the cap and says so", async () => {
    const { api, requests } = pagedApi(5000);
    await expect(countCategoryTransactions(api, "c1", 400)).resolves.toEqual({
      count: 400,
      capped: true,
    });
    expect(requests).toHaveLength(2);
  });

  it("throws when a page fails (the sheet then offers only Archivar)", async () => {
    const api = createApiClient({
      baseUrl: "http://test/api",
      onUnauthorized: () => {},
      fetch: async () => Response.json({ code: "internal_error" }, { status: 503 }),
    });
    await expect(countCategoryTransactions(api, "c1")).rejects.toMatchObject({
      code: "internal_error",
    });
  });
});
