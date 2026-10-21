import { OCTOBER_2026 } from "../../../packages/core/test/fixtures/october-2026.ts";
import type { TestApp } from "./harness.ts";

export { OCTOBER_2026 };

/** Creates the October 2026 categories, budgets (from 2026-01) and transactions through the API. */
export async function seedOctober2026(t: TestApp, headers: { authorization: string }) {
  const ids: Record<string, string> = {};
  const create = async (name: string, kind: "expense" | "income") => {
    const res = await t.request("POST", "/v1/categories", {
      headers,
      body: { name, kind, icon: "tag", color: "gray" },
    });
    return ((await res.json()) as { id: string }).id;
  };
  let day = 1;
  const post = (categoryId: string, name: string, amount: number) =>
    t.request("POST", "/v1/transactions", {
      headers,
      body: { categoryId, name, amount, date: `2026-10-${String(day++).padStart(2, "0")}` },
    });

  for (const c of OCTOBER_2026.expense) {
    ids[c.key] = await create(c.name, "expense");
    await t.request("PUT", `/v1/categories/${ids[c.key]}/budget`, {
      headers,
      body: { amount: c.budget, effectiveFrom: "2026-01" },
    });
    if (c.spent > 0) await post(ids[c.key] as string, c.name.toLowerCase(), -c.spent);
  }
  for (const c of OCTOBER_2026.income) {
    ids[c.key] = await create(c.name, "income");
    await post(ids[c.key] as string, c.name, c.received);
  }
  return ids;
}
