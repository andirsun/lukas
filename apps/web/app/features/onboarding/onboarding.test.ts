import { InvalidAmountError } from "@lukas/core";
import { describe, expect, it } from "vitest";
import { budgetExample, draftFromCents, parseBudgetInput } from "./budget-input.ts";
import { currencyFromLanguages } from "./currency.ts";
import { passkeyOutcome } from "./passkey.ts";
import { nextStep, previousStep, STEPS, stepFromParam, stepPath } from "./steps.ts";
import { SUGGESTED_CATEGORIES, suggestionFor } from "./suggested-categories.ts";

describe("currencyFromLanguages", () => {
  it("follows the browser's region", () => {
    expect(currencyFromLanguages(["es-CO"])).toBe("COP");
    expect(currencyFromLanguages(["es-ES"])).toBe("EUR");
    expect(currencyFromLanguages(["es-MX"])).toBe("MXN");
    expect(currencyFromLanguages(["en-US"])).toBe("USD");
    expect(currencyFromLanguages(["es-AR"])).toBe("ARS");
    expect(currencyFromLanguages(["es-CL"])).toBe("CLP");
    expect(currencyFromLanguages(["es-PE"])).toBe("PEN");
    expect(currencyFromLanguages(["pt-PT"])).toBe("EUR");
  });

  it("takes the first language that names a region it knows", () => {
    expect(currencyFromLanguages(["es", "es-CO", "en-US"])).toBe("COP");
    expect(currencyFromLanguages(["en-GB", "en-US"])).toBe("USD");
  });

  it("falls back to EUR", () => {
    expect(currencyFromLanguages([])).toBe("EUR");
    expect(currencyFromLanguages(["es"])).toBe("EUR");
    expect(currencyFromLanguages(["en-GB"])).toBe("EUR");
    expect(currencyFromLanguages(["not a tag"])).toBe("EUR");
  });
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
  it("are the six of the spec, in order", () => {
    expect(STEPS).toEqual(["currency", "passkey", "categories", "budgets", "import", "done"]);
  });

  it("map to /welcome paths and back", () => {
    expect(stepPath("currency")).toBe("/welcome");
    expect(stepPath("budgets")).toBe("/welcome/budgets");
    expect(stepFromParam(undefined)).toBe("currency");
    expect(stepFromParam("import")).toBe("import");
    expect(stepFromParam("nope")).toBeNull();
  });

  it("skip the passkey step when the browser has no passkeys", () => {
    expect(nextStep("currency", { passkeys: true })).toBe("passkey");
    expect(nextStep("currency", { passkeys: false })).toBe("categories");
    expect(previousStep("categories", { passkeys: false })).toBe("currency");
    expect(previousStep("categories", { passkeys: true })).toBe("passkey");
    expect(previousStep("currency", { passkeys: true })).toBeNull();
    expect(nextStep("done", { passkeys: true })).toBeNull();
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
