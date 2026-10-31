import { describe, expect, it } from "vitest";
import { normalizeName, resolveCategory, ToolError } from "../src/index.ts";
import { category } from "./fixtures.ts";

function caught(fn: () => unknown): ToolError {
  try {
    fn();
  } catch (error) {
    if (error instanceof ToolError) return error;
    throw error;
  }
  throw new Error("Expected a ToolError");
}

describe("normalizeName", () => {
  it("lowercases, strips accents, trims and collapses spaces", () => {
    expect(normalizeName(" Comidá  Rápida ")).toBe("comida rapida");
    expect(normalizeName("ÑANDÚ\tgrande")).toBe("nandu grande");
  });
});

describe("resolveCategory", () => {
  const comida = category("Comida");
  const rapida = category("Comida rápida");
  const salario = category("Salario", "income");
  const viejo = category("Viajes", "expense", { archived: true });
  const all = [comida, rapida, salario, viejo];

  it("prefers an exact normalized match over longer names", () => {
    expect(resolveCategory("comida", all)).toBe(comida);
    expect(resolveCategory("COMIDÁ", all)).toBe(comida);
    expect(resolveCategory("comida  rapida", all)).toBe(rapida);
  });

  it("uses the one prefix or substring match", () => {
    expect(resolveCategory("rap", [rapida])).toBe(rapida);
    expect(resolveCategory("rap", all)).toBe(rapida);
    expect(resolveCategory("sala", all)).toBe(salario);
  });

  it("refuses to guess between several matches", () => {
    const error = caught(() => resolveCategory("co", [comida, rapida]));
    expect(error.code).toBe("category_ambiguous");
    expect(error.data).toEqual({ candidates: ["Comida", "Comida rápida"] });
    expect(error.message).toContain("Comida rápida");
  });

  it("lists every usable name when nothing matches", () => {
    const error = caught(() => resolveCategory("mascotas", all));
    expect(error.code).toBe("category_not_found");
    expect(error.data).toEqual({ candidates: ["Comida", "Comida rápida", "Salario"] });
  });

  it("never matches archived categories", () => {
    expect(caught(() => resolveCategory("Viajes", all)).code).toBe("category_not_found");
  });

  it("looks only at the kind asked for", () => {
    expect(caught(() => resolveCategory("salario", all, "expense")).code).toBe(
      "category_not_found",
    );
    expect(resolveCategory("salario", all, "income")).toBe(salario);
  });
});
