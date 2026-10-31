import { describe, expect, it, vi } from "vitest";
import { ToolError } from "../src/index.ts";
import { idempotencyKey } from "../src/tools/write.ts";
import { call, NOW, setup, tool, transaction } from "./harness.ts";

const lunch = { name: "Almuerzo", amount: 18000, category: "comida" };

async function all(ctx: Parameters<typeof call>[2]) {
  return (await ctx.lukitas.listTransactions({ limit: 1000 })).items;
}

async function rejection(promise: Promise<unknown>): Promise<ToolError> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof ToolError) return error;
    throw error;
  }
  throw new Error("Expected a ToolError");
}

describe("add_transactions", () => {
  it("saves one expense with the sign, source mcp and today's date in the person's zone", async () => {
    const { ctx, cats } = setup();
    const { structured, text } = await call("add_transactions", { items: [lunch] }, ctx);
    expect(structured).toMatchObject({ alreadySaved: false, saved: 1 });
    expect(structured.items[0]).toMatchObject({
      name: "Almuerzo",
      kind: "expense",
      amount: 18000,
      formatted: "$18.000",
      category: "Comida",
      date: "2026-10-31",
    });
    const [saved] = await all(ctx);
    expect(saved).toMatchObject({
      amount: -1800000,
      categoryId: cats.comida.id,
      date: "2026-10-31",
      source: "mcp",
      status: "paid",
    });
    expect(text).toContain("«Almuerzo»");
    expect(text).toContain("$18.000");
  });

  it("takes the sign from the category's kind, rounding decimals and ignoring a minus", async () => {
    const { ctx } = setup();
    await call(
      "add_transactions",
      {
        items: [
          { name: "Quincena", amount: 2000000, category: "salario" },
          { name: "Propina", amount: 18.5, kind: "expense", category: "comida" },
          { name: "Taxi", amount: -18000, kind: "expense", category: "transporte" },
          { name: "Bono", amount: -50000, category: "Salario", date: "2026-10-01" },
        ],
      },
      ctx,
    );
    const byName = Object.fromEntries((await all(ctx)).map((t) => [t.name, t.amount]));
    expect(byName).toEqual({
      Quincena: 200000000,
      Propina: -1850,
      Taxi: -1800000,
      Bono: 5000000,
    });
  });

  it("refuses a kind that does not match the category", async () => {
    const { ctx } = setup();
    const error = await rejection(
      call("add_transactions", { items: [{ ...lunch, kind: "income" }] }, ctx),
    );
    expect(error.code).toBe("category_not_found");
  });

  it("refuses an amount that rounds to zero", async () => {
    const { ctx } = setup();
    const error = await rejection(
      call("add_transactions", { items: [{ ...lunch, amount: 0.001 }] }, ctx),
    );
    expect(error.code).toBe("invalid_amount");
  });

  it("saves 50 in chunks of 20 for the API, each with its own key", async () => {
    const { ctx } = setup();
    const spy = vi.spyOn(ctx.lukitas, "addTransactions");
    const items = Array.from({ length: 50 }, (_, i) => ({ ...lunch, amount: 1000 + i }));
    const { structured } = await call("add_transactions", { items }, ctx);
    expect(structured.saved).toBe(50);
    expect(spy.mock.calls.map(([chunk]) => chunk.length)).toEqual([20, 20, 10]);
    const keys = spy.mock.calls.map(([, key]) => key);
    expect(new Set(keys).size).toBe(3);
    for (const [index, [chunk, key]] of spy.mock.calls.entries()) {
      expect(key).toMatch(/^[0-9a-f]{64}$/);
      expect(key).toBe(await idempotencyKey("user-1", index, chunk, NOW));
    }
    expect(await all(ctx)).toHaveLength(50);
  });

  it("derives the key from the person, the chunk, its content and a 10-minute window", async () => {
    const chunk = [
      {
        name: "Almuerzo",
        amount: -1800000,
        categoryId: "00000000-0000-4000-8000-000000000001",
        date: "2026-10-31",
        status: "paid" as const,
        source: "mcp" as const,
      },
    ];
    const reordered = chunk.map(({ source, status, date, categoryId, amount, name }) => ({
      source,
      status,
      date,
      categoryId,
      amount,
      name,
    }));
    const key = await idempotencyKey("user-1", 0, chunk, NOW);
    expect(await idempotencyKey("user-1", 0, reordered, NOW)).toBe(key);
    expect(await idempotencyKey("user-1", 0, chunk, new Date(NOW.getTime() + 60_000))).toBe(key);
    expect(await idempotencyKey("user-2", 0, chunk, NOW)).not.toBe(key);
    expect(await idempotencyKey("user-1", 1, chunk, NOW)).not.toBe(key);
    expect(
      await idempotencyKey("user-1", 0, [{ ...chunk[0], amount: -1 }] as typeof chunk, NOW),
    ).not.toBe(key);
    expect(await idempotencyKey("user-1", 0, chunk, new Date(NOW.getTime() + 600_000))).not.toBe(
      key,
    );
  });

  it("a retry within the window saves nothing twice and says it was already saved", async () => {
    const { ctx } = setup();
    await call("add_transactions", { items: [lunch, lunch] }, ctx);
    const again = await call("add_transactions", { items: [lunch, lunch] }, ctx);
    expect(again.structured).toMatchObject({ alreadySaved: true, saved: 0 });
    expect(again.structured.items).toHaveLength(2);
    expect(again.text).toContain("Ya estaba guardado");
    // Two identical items inside one call stay two.
    expect(await all(ctx)).toHaveLength(2);
  });

  it("a retry after a broken first call saves only what was missing", async () => {
    const { ctx } = setup();
    const items = Array.from({ length: 50 }, (_, i) => ({ ...lunch, amount: 1000 + i }));
    const real = ctx.lukitas.addTransactions.bind(ctx.lukitas);
    const spy = vi
      .spyOn(ctx.lukitas, "addTransactions")
      .mockImplementationOnce(real)
      .mockImplementationOnce(() => Promise.reject(new Error("stream broke")));
    await expect(call("add_transactions", { items }, ctx)).rejects.toThrow("stream broke");
    expect(await all(ctx)).toHaveLength(20);

    spy.mockImplementation(real);
    const retry = await call("add_transactions", { items }, ctx);
    expect(retry.structured).toMatchObject({ alreadySaved: false, saved: 30 });
    expect(retry.structured.items).toHaveLength(50);
    expect(await all(ctx)).toHaveLength(50);
  });

  it("refuses 51 items", () => {
    const items = Array.from({ length: 51 }, () => lunch);
    expect(tool("add_transactions").input.safeParse({ items }).success).toBe(false);
    expect(tool("add_transactions").input.safeParse({ items: [] }).success).toBe(false);
  });

  it("resolves every category before saving anything", async () => {
    const { ctx } = setup();
    const items = [...Array.from({ length: 25 }, () => lunch), { ...lunch, category: "mascotas" }];
    const error = await rejection(call("add_transactions", { items }, ctx));
    expect(error.code).toBe("category_not_found");
    expect(error.message).toContain("Comida");
    expect((error.data as { candidates: string[] }).candidates).toEqual([
      "Comida",
      "Comida rápida",
      "Transporte",
      "Salario",
    ]);
    expect(await all(ctx)).toHaveLength(0);
  });

  it("refuses an ambiguous category, listing the candidates", async () => {
    const { ctx } = setup();
    const error = await rejection(
      call("add_transactions", { items: [{ ...lunch, category: "co" }] }, ctx),
    );
    expect(error.code).toBe("category_ambiguous");
    expect((error.data as { candidates: string[] }).candidates).toEqual([
      "Comida",
      "Comida rápida",
    ]);
  });

  it("never matches an archived category", async () => {
    const { ctx } = setup();
    const error = await rejection(
      call("add_transactions", { items: [{ ...lunch, category: "viajes" }] }, ctx),
    );
    expect(error.code).toBe("category_not_found");
  });
});

describe("update_transaction", () => {
  it("changes the amount keeping the kind of the category", async () => {
    const { ctx } = setup({
      transactions: (c) => [
        transaction(c.comida, -1800000, "2026-10-30", { name: "Almuerzo" }),
        transaction(c.salario, 200000000, "2026-10-15", { name: "Quincena" }),
      ],
    });
    const [almuerzo, quincena] = await all(ctx);
    await call("update_transaction", { id: almuerzo?.id, amount: 20000 }, ctx);
    const { structured } = await call(
      "update_transaction",
      { id: quincena?.id, amount: -2100000.4 },
      ctx,
    );
    expect(structured.transaction).toMatchObject({ kind: "income", amount: 2100000.4 });
    const amounts = Object.fromEntries((await all(ctx)).map((t) => [t.name, t.amount]));
    expect(amounts).toEqual({ Almuerzo: -2000000, Quincena: 210000040 });
  });

  it("moves it to another category, flipping the sign when the kind changes", async () => {
    const { ctx, cats } = setup({
      transactions: (c) => [transaction(c.comida, -1800000, "2026-10-30", { name: "Reembolso" })],
    });
    const [tx] = await all(ctx);
    await call("update_transaction", { id: tx?.id, category: "salario" }, ctx);
    expect((await all(ctx))[0]).toMatchObject({ categoryId: cats.salario.id, amount: 1800000 });
  });

  it("renames, re-dates, marks as paid and clears the note", async () => {
    const { ctx } = setup({
      transactions: (c) => [
        transaction(c.comida, -1800000, "2026-10-30", { status: "pending", note: "x" }),
      ],
    });
    const [tx] = await all(ctx);
    await call(
      "update_transaction",
      { id: tx?.id, name: "Mercado", date: "2026-10-29", status: "paid", note: null },
      ctx,
    );
    expect((await all(ctx))[0]).toMatchObject({
      name: "Mercado",
      date: "2026-10-29",
      status: "paid",
      note: null,
      amount: -1800000,
    });
  });

  it("needs something to change", () => {
    expect(
      tool("update_transaction").input.safeParse({ id: "00000000-0000-4000-8000-000000000001" })
        .success,
    ).toBe(false);
  });
});

describe("delete_transactions and restore_transactions", () => {
  it("deletes recoverably and restores them", async () => {
    const { ctx } = setup({
      transactions: (c) =>
        Array.from({ length: 30 }, () => transaction(c.comida, -1800000, "2026-10-30")),
    });
    const ids = (await all(ctx)).map((t) => t.id);
    const spy = vi.spyOn(ctx.lukitas, "deleteTransactions");
    const deleted = await call("delete_transactions", { ids }, ctx);
    expect(spy.mock.calls.map(([chunk]) => chunk.length)).toEqual([20, 10]);
    expect(deleted.structured.deleted).toBe(30);
    expect(deleted.text).toContain("restore_transactions");
    expect(await all(ctx)).toHaveLength(0);

    const restored = await call("restore_transactions", { ids: ids.slice(0, 2) }, ctx);
    expect(restored.structured.items).toHaveLength(2);
    expect(await all(ctx)).toHaveLength(2);
  });

  it("takes 1 to 50 ids", () => {
    const id = "00000000-0000-4000-8000-000000000001";
    expect(tool("delete_transactions").input.safeParse({ ids: [] }).success).toBe(false);
    expect(
      tool("delete_transactions").input.safeParse({ ids: Array.from({ length: 51 }, () => id) })
        .success,
    ).toBe(false);
  });
});

describe("set_budget", () => {
  it("defaults effectiveFrom to the current month", async () => {
    const { ctx, cats } = setup();
    const spy = vi.spyOn(ctx.lukitas, "setBudget");
    const { structured } = await call(
      "set_budget",
      { category: "transporte", amount: 150000 },
      ctx,
    );
    expect(spy).toHaveBeenCalledWith(cats.transporte.id, {
      amount: 15000000,
      effectiveFrom: "2026-10",
    });
    expect(structured).toMatchObject({
      category: "Transporte",
      effectiveFrom: "2026-10",
      budget: { amount: 150000, formatted: "$150.000" },
    });
  });

  it("only looks at expense categories", async () => {
    const { ctx } = setup();
    const error = await rejection(call("set_budget", { category: "salario", amount: 1 }, ctx));
    expect(error.code).toBe("category_not_found");
  });
});

describe("create_category and update_category", () => {
  it("creates a category", async () => {
    const { ctx } = setup();
    const { structured } = await call(
      "create_category",
      { name: "Mascotas", kind: "expense" },
      ctx,
    );
    expect(structured.category).toMatchObject({
      name: "Mascotas",
      kind: "expense",
      archived: false,
    });
  });

  it("refuses a name that matches an existing one ignoring case and accents", async () => {
    const { ctx } = setup();
    const error = await rejection(
      call("create_category", { name: "  comidá ", kind: "expense" }, ctx),
    );
    expect(error.code).toBe("category_name_taken");
  });

  it("renames and archives, and can bring an archived one back", async () => {
    const { ctx, cats } = setup();
    await call("update_category", { category: "transporte", name: "Movilidad" }, ctx);
    const archived = await call("update_category", { category: "movilidad", archived: true }, ctx);
    expect(archived.structured.category).toMatchObject({ name: "Movilidad", archived: true });
    const back = await call("update_category", { category: "viajes", archived: false }, ctx);
    expect(back.structured.category).toMatchObject({ id: cats.viajes.id, archived: false });
  });
});

describe("manage_recurring", () => {
  it("creates, updates and stops a recurring movement", async () => {
    const { ctx, cats } = setup();
    const created = await call(
      "manage_recurring",
      { action: "create", name: "Arriendo", amount: 1500000, category: "comida", dayOfMonth: 1 },
      ctx,
    );
    const id = created.structured.recurrence.id;
    expect(await ctx.lukitas.listRecurrences()).toEqual([
      expect.objectContaining({
        name: "Arriendo",
        amount: -150000000,
        categoryId: cats.comida.id,
        frequency: "monthly",
        dayOfMonth: 1,
        startDate: "2026-10-31",
      }),
    ]);

    await call("manage_recurring", { action: "update", id, amount: 1600000 }, ctx);
    expect((await ctx.lukitas.listRecurrences())[0]?.amount).toBe(-160000000);

    const stopped = await call("manage_recurring", { action: "stop", id }, ctx);
    expect(stopped.structured.action).toBe("stop");
    expect((await ctx.lukitas.listRecurrences())[0]?.endDate).toBe("2026-10-31");
  });

  it("stops a rule that has not started yet by removing it", async () => {
    const { ctx } = setup();
    const created = await call(
      "manage_recurring",
      {
        action: "create",
        name: "Gimnasio",
        amount: 90000,
        category: "comida",
        startDate: "2026-12-01",
      },
      ctx,
    );
    await call("manage_recurring", { action: "stop", id: created.structured.recurrence.id }, ctx);
    expect(await ctx.lukitas.listRecurrences()).toEqual([]);
  });

  it("asks for what each action needs", async () => {
    const { ctx } = setup();
    expect((await rejection(call("manage_recurring", { action: "stop" }, ctx))).code).toBe(
      "validation_failed",
    );
    expect(
      (await rejection(call("manage_recurring", { action: "create", name: "x" }, ctx))).code,
    ).toBe("validation_failed");
  });
});
