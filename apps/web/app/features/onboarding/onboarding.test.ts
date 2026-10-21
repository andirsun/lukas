import { InvalidAmountError } from "@lukas/core";
import { describe, expect, it } from "vitest";
import { budgetExample, draftFromCents, parseBudgetInput } from "./budget-input.ts";
import { defaultCurrency } from "./currency.ts";
import { passkeyOutcome } from "./passkey.ts";
import { nextStep, previousStep, STEPS, stepFromParam, stepPath } from "./steps.ts";
import { SUGGESTED_CATEGORIES, suggestionFor } from "./suggested-categories.ts";
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
    expect(STEPS).toEqual(["welcome", "currency", "categories", "import", "budgets"]);
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
    expect(nextStep("import")).toBe("budgets");
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
