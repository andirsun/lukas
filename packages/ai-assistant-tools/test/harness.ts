import type { CategoryDto, TransactionDto } from "@lukas/core";
import { MemoryLukitas, type Profile, TOOLS, type ToolContext } from "../src/index.ts";
import { category, transaction } from "./fixtures.ts";

/** 2026-11-01 03:00 UTC is still Saturday 2026-10-31 in Bogotá. */
export const NOW = new Date("2026-11-01T03:00:00Z");

export function setup(
  opts: {
    profile?: Partial<Profile>;
    transactions?: (c: Categories) => TransactionDto[];
    now?: () => Date;
  } = {},
) {
  const cats = {
    comida: category("Comida", "expense", { currentBudget: 50000000 }),
    rapida: category("Comida rápida"),
    transporte: category("Transporte", "expense", { currentBudget: 10000000 }),
    salario: category("Salario", "income"),
    viajes: category("Viajes", "expense", { archived: true }),
  };
  const now = opts.now ?? (() => NOW);
  const lukitas = new MemoryLukitas({
    profile: opts.profile,
    categories: Object.values(cats),
    transactions: opts.transactions?.(cats) ?? [],
    now,
  });
  const ctx: ToolContext = { lukitas, userId: "user-1", now };
  return { cats, lukitas, ctx };
}

export type Categories = Record<
  "comida" | "rapida" | "transporte" | "salario" | "viajes",
  CategoryDto
>;

export function tool(name: string) {
  const found = TOOLS.find((t) => t.name === name);
  if (!found) throw new Error(`No tool ${name}`);
  return found;
}

/**
 * Calls a tool the way a transport does: the input parsed by its schema, and the structured
 * answer checked against its output schema.
 */
export async function call(name: string, input: unknown, ctx: ToolContext) {
  const t = tool(name);
  const result = await t.handler(t.input.parse(input), ctx);
  t.output.parse(result.structured);
  return result;
}

export { category, transaction };
