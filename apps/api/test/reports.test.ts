import { afterAll, afterEach, beforeAll, describe, expect, test, vi } from "vitest";
import { seedOctober2026 } from "./fixtures.ts";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
let a: { authorization: string };
let ids: Record<string, string>;

beforeAll(async () => {
  t = await createTestApp();
  a = (await t.signIn("a@lukas.test")).headers;
  ids = await seedOctober2026(t, a);
  await t.request("POST", "/v1/transactions", {
    headers: a,
    body: {
      categoryId: ids.ocio,
      name: "festival",
      amount: -5000,
      date: "2026-10-30",
      status: "pending",
    },
  });
});
afterAll(() => t?.stop());

interface ByCategory {
  total: number;
  items: { categoryId: string; name: string; total: number; share: number }[];
}
const get = async <T>(path: string) => {
  const res = await t.request("GET", path, { headers: a });
  return { status: res.status, body: (await res.json()) as T };
};

test("expenses by category for a month", async () => {
  const { body } = await get<ByCategory>(
    "/v1/reports/by-category?from=2026-10&to=2026-10&status=paid",
  );
  expect(body.total).toBe(223708);
  expect(body.items[0]).toMatchObject({
    categoryId: ids.casa,
    name: "Casa",
    total: 132978,
    share: 0.5944,
  });
  expect(body.items.map((i) => i.categoryId)).not.toContain(ids.transporte);
});

test("status filters and kind=income", async () => {
  const pending = await get<ByCategory>(
    "/v1/reports/by-category?from=2026-10&to=2026-10&status=pending",
  );
  expect(pending.body).toMatchObject({ total: 5000, items: [{ categoryId: ids.ocio, share: 1 }] });
  const income = await get<ByCategory>(
    "/v1/reports/by-category?from=2026-10&to=2026-10&kind=income",
  );
  expect(income.body.items).toEqual([
    expect.objectContaining({ name: "Salário", total: 620000, share: 1 }),
  ]);
  const both = await get<ByCategory>("/v1/reports/by-category?from=2026-10&to=2026-10");
  expect(both.body.total).toBe(228708);
});

test("trend includes empty months", async () => {
  const { body } = await get<{
    months: { month: string; income: number; expenses: number; budget: number }[];
  }>("/v1/reports/trend?from=2026-09&to=2026-11");
  expect(body.months).toEqual([
    { month: "2026-09", income: 0, expenses: 0, budget: 280000 },
    { month: "2026-10", income: 620000, expenses: 228708, budget: 280000 },
    { month: "2026-11", income: 0, expenses: 0, budget: 280000 },
  ]);
});

test("ranges are validated", async () => {
  const reversed = await get<{ code: string }>("/v1/reports/trend?from=2026-11&to=2026-09");
  expect(reversed).toMatchObject({ status: 422, body: { code: "validation_failed" } });
  const tooLong = await get<{ code: string }>("/v1/reports/by-category?from=2023-01&to=2026-01");
  expect(tooLong).toMatchObject({ status: 422, body: { code: "range_too_large" } });
});

describe("recurrences no screen has opened yet", () => {
  // Pending occurrences are created lazily, when a month is read. A report must see them even
  // when the home screen never opened those months (Insights opened first, straight after a
  // recurrence was created or edited): the same month gives the same figure whatever the range.
  let r: { authorization: string };
  let salary: string;
  let rent: string;
  const getR = async <T>(path: string) => {
    const res = await t.request("GET", path, { headers: r });
    return (await res.json()) as T;
  };

  beforeAll(async () => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-11-15T12:00:00Z"));
    r = (await t.signIn("r@lukas.test")).headers;
    const make = async (name: string, kind: "income" | "expense") => {
      const res = await t.request("POST", "/v1/categories", {
        headers: r,
        body: { name, icon: "💰", color: "green", kind },
      });
      return ((await res.json()) as { id: string }).id;
    };
    salary = await make("Sueldo", "income");
    rent = await make("Renta", "expense");
    const recur = (categoryId: string, amount: number, dayOfMonth: number) =>
      t.request("POST", "/v1/recurrences", {
        headers: r,
        body: {
          name: "recurring",
          amount,
          categoryId,
          frequency: "monthly",
          dayOfMonth,
          startDate: "2026-09-01",
        },
      });
    expect((await recur(salary, 500000, 28)).status).toBe(201);
    expect((await recur(rent, -150000, 5)).status).toBe(201);
    vi.useRealTimers();
  }, 60_000);
  afterEach(() => vi.useRealTimers());

  const fakeNovember = () => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-11-15T12:00:00Z"));
  };

  test("the trend counts them, for one month and for three alike", async () => {
    fakeNovember();
    type Trend = { months: { month: string; income: number; expenses: number }[] };
    const one = await getR<Trend>("/v1/reports/trend?from=2026-11&to=2026-11");
    expect(one.months).toEqual([expect.objectContaining({ income: 500000, expenses: 150000 })]);
    const three = await getR<Trend>("/v1/reports/trend?from=2026-09&to=2026-11");
    expect(three.months.map((m) => [m.month, m.income, m.expenses])).toEqual([
      ["2026-09", 500000, 150000],
      ["2026-10", 500000, 150000],
      ["2026-11", 500000, 150000],
    ]);
  });

  test("so does spending by category", async () => {
    fakeNovember();
    const spent = await getR<ByCategory>("/v1/reports/by-category?from=2026-09&to=2026-11");
    expect(spent.total).toBe(450000);
    expect(spent.items).toEqual([expect.objectContaining({ categoryId: rent, total: 450000 })]);
  });

  test("and what living costs, as fixed spending", async () => {
    fakeNovember();
    const living = await getR<{ total: number; fixed: number; variable: number }>(
      "/v1/reports/cost-of-living?months=2",
    );
    expect(living).toMatchObject({ total: 150000, fixed: 150000, variable: 0 });
  });
});

describe("cost of living", () => {
  interface CostOfLiving {
    months: number;
    total: number;
    fixed: number;
    variable: number;
    categories: { categoryId: string; average: number; type: "fixed" | "variable" }[];
  }
  let c: { authorization: string };
  let cIds: Record<string, string>;
  const costOfLiving = async (query: string) => {
    const res = await t.request("GET", `/v1/reports/cost-of-living${query}`, { headers: c });
    return { status: res.status, body: (await res.json()) as CostOfLiving };
  };

  beforeAll(async () => {
    // Sign in under the fake clock so the session is not expired relative to it.
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-11-15T12:00:00Z"));
    c = (await t.signIn("c@lukas.test")).headers;
    cIds = await seedOctober2026(t, c);
    const post = (categoryId: string, amount: number, date: string) =>
      t.request("POST", "/v1/transactions", {
        headers: c,
        body: { categoryId, name: "extra", amount, date },
      });
    await post(cIds.casa as string, -100000, "2026-09-10");
    // The current month is left out of the window.
    await post(cIds.casa as string, -777777, "2026-11-02");
    const recur = (categoryId: string, endDate: string | null) =>
      t.request("POST", "/v1/recurrences", {
        headers: c,
        body: {
          name: "recurring",
          amount: -1000,
          categoryId,
          frequency: "monthly",
          dayOfMonth: 5,
          startDate: "2026-01-01",
          ...(endDate ? { endDate } : {}),
        },
      });
    await recur(cIds.casa as string, null);
    // Ends inside the two-month window, but before the one-month window.
    await recur(cIds.vida as string, "2026-09-30");
    // Ended before any window.
    await recur(cIds.suscripciones as string, "2026-08-31");
    vi.useRealTimers();
  }, 60_000);
  afterEach(() => vi.useRealTimers());

  const fakeNovember = () => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-11-15T12:00:00Z"));
  };

  test("averages the complete months before the current one", async () => {
    fakeNovember();
    const { status, body } = await costOfLiving("?months=2");
    expect(status).toBe(200);
    // The recurrences' own occurrences count too (created as the months are read): Casa's 10,00
    // in September and October, Vida's 10,00 in September only (it ends on the 30th).
    expect(body).toMatchObject({ months: 2, total: 163355, fixed: 122905, variable: 40450 });
    expect(body.categories[0]).toEqual({
      categoryId: cIds.casa,
      average: 117489,
      type: "fixed",
    });
    const byId = new Map(body.categories.map((x) => [x.categoryId, x]));
    expect(byId.get(cIds.vida as string)).toEqual({
      categoryId: cIds.vida,
      average: 5416,
      type: "fixed",
    });
    expect(byId.get(cIds.suscripciones as string)).toMatchObject({
      average: 1845,
      type: "variable",
    });
    expect(byId.has(cIds.transporte as string)).toBe(false);
    expect(byId.has(cIds.salario as string)).toBe(false);
  });

  test("a single month is October alone, and ended recurrences stop being fixed", async () => {
    fakeNovember();
    const { body } = await costOfLiving("?months=1");
    expect(body).toMatchObject({ months: 1, total: 224708, fixed: 133978, variable: 90730 });
    expect(body.categories.find((x) => x.categoryId === cIds.vida)?.type).toBe("variable");
  });

  test("months is limited to 1-24", async () => {
    fakeNovember();
    expect((await costOfLiving("?months=25")).status).toBe(422);
    expect((await costOfLiving("?months=0")).status).toBe(422);
    expect((await costOfLiving("?months=abc")).status).toBe(422);
  });
});
