import { addMonths, monthOf, todayIn } from "@lukas/core";
import { accounts, recurrences, type Tx, withUser } from "@lukas/db";
import { eq } from "@lukas/db/orm";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
let a: { authorization: string };
let subscriptions: string;
// Test users keep the default time zone, UTC: their "today" and month are UTC's.
const today = todayIn("UTC");
const month = monthOf(today);

interface Row {
  id: string;
  name: string;
  amount: number;
  date: string;
  status: string;
  source: string;
  recurrenceId: string | null;
}

beforeAll(async () => {
  t = await createTestApp();
  a = (await t.signIn("a@lukas.test")).headers;
  const res = await t.request("POST", "/v1/categories", {
    headers: a,
    body: { name: "suscripciones", kind: "expense", icon: "umbrella", color: "pink" },
  });
  subscriptions = ((await res.json()) as { id: string }).id;
});
afterAll(() => t?.stop());

const listMonth = async (m: string) =>
  (
    (await (await t.request("GET", `/v1/transactions?month=${m}`, { headers: a })).json()) as {
      items: Row[];
    }
  ).items;
const spotifyIn = async (m: string) => (await listMonth(m)).filter((i) => i.name === "Spotify");

describe("recurrences", () => {
  let recurrenceId: string;

  test("create a monthly recurrence", async () => {
    const res = await t.request("POST", "/v1/recurrences", {
      headers: a,
      body: {
        name: "Spotify",
        amount: -353,
        categoryId: subscriptions,
        frequency: "monthly",
        dayOfMonth: 23,
        startDate: `${addMonths(month, -3)}-01`,
      },
    });
    expect(res.status).toBe(201);
    recurrenceId = ((await res.json()) as { id: string }).id;
    const listed = (await (await t.request("GET", "/v1/recurrences", { headers: a })).json()) as {
      id: string;
    }[];
    expect(listed.map((r) => r.id)).toEqual([recurrenceId]);
  });

  test("listing a month materializes its occurrence once, as pending", async () => {
    await listMonth(month);
    const spotify = await spotifyIn(month);
    expect(spotify).toHaveLength(1);
    expect(spotify[0]).toMatchObject({
      amount: -353,
      status: "pending",
      source: "recurrence",
      recurrenceId,
    });
  });

  test("an edited occurrence is neither reset nor duplicated", async () => {
    const [occurrence] = await spotifyIn(month);
    await t.request("PATCH", `/v1/transactions/${occurrence?.id}`, {
      headers: a,
      body: { amount: -399 },
    });
    await t.request("GET", `/v1/summary?month=${month}`, { headers: a });
    const spotify = await spotifyIn(month);
    expect(spotify.map((s) => s.amount)).toEqual([-399]);
  });

  test("a deleted occurrence is not regenerated", async () => {
    const [occurrence] = await spotifyIn(month);
    await t.request("DELETE", `/v1/transactions/${occurrence?.id}`, { headers: a });
    expect(await spotifyIn(month)).toEqual([]);
    await t.request("GET", `/v1/summary?month=${month}`, { headers: a });
    expect(await spotifyIn(month)).toEqual([]);
  });

  test("next month is materialized but later months are not", async () => {
    expect(await spotifyIn(addMonths(month, 1))).toHaveLength(1);
    expect(await spotifyIn(addMonths(month, 2))).toEqual([]);
  });

  test("past months are materialized from the start date", async () => {
    expect(await spotifyIn(addMonths(month, -3))).toHaveLength(1);
    expect(await spotifyIn(addMonths(month, -4))).toEqual([]);
  });

  test("deleting a recurrence drops its pending rows from this month on, and keeps the past", async () => {
    const res = await t.request("DELETE", `/v1/recurrences/${recurrenceId}`, { headers: a });
    expect(res.status).toBe(204);
    // Next month's pending charge would look like a bill still due: it goes.
    expect(await spotifyIn(addMonths(month, 1))).toEqual([]);
    // Earlier months keep what was generated, no longer tied to the rule.
    const past = await spotifyIn(addMonths(month, -3));
    expect(past).toHaveLength(1);
    expect(past[0]?.recurrenceId).toBeNull();
  });

  test("deleting a recurrence keeps its paid rows, even from this month on", async () => {
    const created = await t.request("POST", "/v1/recurrences", {
      headers: a,
      body: {
        name: "Netflix",
        amount: -1299,
        categoryId: subscriptions,
        frequency: "monthly",
        dayOfMonth: 5,
        startDate: `${addMonths(month, -1)}-01`,
      },
    });
    const { id } = (await created.json()) as { id: string };
    const netflixIn = async (m: string) => (await listMonth(m)).filter((i) => i.name === "Netflix");
    const [paid] = await netflixIn(addMonths(month, 1));
    await t.request("PATCH", `/v1/transactions/${paid?.id}`, {
      headers: a,
      body: { status: "paid" },
    });
    expect(await netflixIn(month)).toHaveLength(1);
    expect(await netflixIn(addMonths(month, -1))).toHaveLength(1);

    expect((await t.request("DELETE", `/v1/recurrences/${id}`, { headers: a })).status).toBe(204);
    expect(await netflixIn(month)).toEqual([]);
    expect(await netflixIn(addMonths(month, 1))).toMatchObject([
      { id: paid?.id, status: "paid", recurrenceId: null },
    ]);
    expect(await netflixIn(addMonths(month, -1))).toMatchObject([
      { status: "pending", recurrenceId: null },
    ]);
  });

  test("switching back to yearly reuses the stored month", async () => {
    const res = await t.request("POST", "/v1/recurrences", {
      headers: a,
      body: {
        name: "Insurance",
        amount: -9000,
        categoryId: subscriptions,
        frequency: "yearly",
        monthOfYear: 3,
        dayOfMonth: 1,
        startDate: "2026-01-01",
      },
    });
    const { id } = (await res.json()) as { id: string };
    const toMonthly = await t.request("PATCH", `/v1/recurrences/${id}`, {
      headers: a,
      body: { frequency: "monthly" },
    });
    expect(toMonthly.status).toBe(200);
    const toYearly = await t.request("PATCH", `/v1/recurrences/${id}`, {
      headers: a,
      body: { frequency: "yearly" },
    });
    expect(toYearly.status).toBe(200);
    expect(await toYearly.json()).toMatchObject({ frequency: "yearly", monthOfYear: 3 });
  });

  test("yearly recurrences need monthOfYear", async () => {
    const res = await t.request("POST", "/v1/recurrences", {
      headers: a,
      body: {
        name: "Domain",
        amount: -1200,
        categoryId: subscriptions,
        frequency: "yearly",
        dayOfMonth: 1,
        startDate: "2026-01-01",
      },
    });
    expect(res.status).toBe(422);
  });

  describe("schedule edits never duplicate a month's charge", () => {
    let gym: string;
    const gymIn = async (m: string) => (await listMonth(m)).filter((i) => i.name === "Gym");

    test("setup: a monthly gym membership on the 10th", async () => {
      const res = await t.request("POST", "/v1/recurrences", {
        headers: a,
        body: {
          name: "Gym",
          amount: -3000,
          categoryId: subscriptions,
          frequency: "monthly",
          dayOfMonth: 10,
          startDate: `${addMonths(month, -1)}-01`,
        },
      });
      gym = ((await res.json()) as { id: string }).id;
      expect(await gymIn(month)).toHaveLength(1);
      expect(await gymIn(addMonths(month, 1))).toHaveLength(1);
    });

    test("moving one occurrence to another day keeps a single charge that month", async () => {
      const [occurrence] = await gymIn(month);
      await t.request("PATCH", `/v1/transactions/${occurrence?.id}`, {
        headers: a,
        body: { date: `${month}-20` },
      });
      await t.request("GET", `/v1/summary?month=${month}`, { headers: a });
      const rows = (await gymIn(month)) as Row[];
      expect(rows).toHaveLength(1);
    });

    test("changing the day of month moves already generated future pending charges", async () => {
      const patched = await t.request("PATCH", `/v1/recurrences/${gym}`, {
        headers: a,
        body: { dayOfMonth: 25 },
      });
      expect(patched.status, await patched.clone().text()).toBe(200);
      const next = (await gymIn(addMonths(month, 1))) as Row[];
      expect(next.map((g) => g.date)).toEqual([`${addMonths(month, 1)}-25`]);
    });
  });
});

describe("archiving a category stops its recurrences", () => {
  let home: string;
  let rent: string;
  let water: string;
  let later: string;
  let ended: string;
  const named = async (name: string, m: string) =>
    (await listMonth(m)).filter((i) => i.name === name);
  const rule = async (id: string) =>
    (
      (await (await t.request("GET", "/v1/recurrences", { headers: a })).json()) as {
        id: string;
        startDate: string;
        endDate: string | null;
      }[]
    ).find((r) => r.id === id);
  const create = async (body: Record<string, unknown>) =>
    (
      (await (
        await t.request("POST", "/v1/recurrences", {
          headers: a,
          body: { amount: -10000, categoryId: home, frequency: "monthly", ...body },
        })
      ).json()) as { id: string }
    ).id;

  test("setup: rent on the 1st (next month's already paid), water on the 28th, two others", async () => {
    const res = await t.request("POST", "/v1/categories", {
      headers: a,
      body: { name: "Casa", kind: "expense", icon: "house", color: "blue" },
    });
    home = ((await res.json()) as { id: string }).id;
    const start = `${addMonths(month, -1)}-01`;
    rent = await create({ name: "Arriendo", dayOfMonth: 1, startDate: start });
    water = await create({ name: "Agua", dayOfMonth: 28, startDate: start });
    later = await create({ name: "Seguro", dayOfMonth: 3, startDate: `${addMonths(month, 2)}-01` });
    ended = await create({
      name: "Gas",
      dayOfMonth: 2,
      startDate: `${addMonths(month, -3)}-01`,
      endDate: `${addMonths(month, -2)}-28`,
    });
    for (const m of [addMonths(month, -1), month, addMonths(month, 1)]) await listMonth(m);
    const [nextRent] = await named("Arriendo", addMonths(month, 1));
    await t.request("PATCH", `/v1/transactions/${nextRent?.id}`, {
      headers: a,
      body: { status: "paid" },
    });
  });

  test("archiving ends them today and drops their unpaid pending rows from today on", async () => {
    const res = await t.request("PATCH", `/v1/categories/${home}`, {
      headers: a,
      body: { archived: true },
    });
    expect(res.status).toBe(200);
    expect(await rule(rent)).toMatchObject({ endDate: today });
    expect(await rule(water)).toMatchObject({ endDate: today });
    // One still to start ends today too, and stays a valid rule (start ≤ end).
    expect(await rule(later)).toMatchObject({ startDate: today, endDate: today });
    // One that had already ended keeps its end.
    expect(await rule(ended)).toMatchObject({ endDate: `${addMonths(month, -2)}-28` });

    // Next month: the paid rent stays, the pending water goes.
    expect(await named("Arriendo", addMonths(month, 1))).toMatchObject([{ status: "paid" }]);
    expect(await named("Agua", addMonths(month, 1))).toEqual([]);
    // This month: what was due before today stays pending; from today on, nothing.
    for (const name of ["Arriendo", "Agua"]) {
      const rows = await named(name, month);
      expect(rows.every((r) => r.date < today && r.status === "pending")).toBe(true);
    }
    // Last month is untouched.
    expect(await named("Agua", addMonths(month, -1))).toHaveLength(1);
  });

  test("reading the months again brings nothing back", async () => {
    await t.request("GET", `/v1/summary?month=${month}`, { headers: a });
    await t.request("GET", `/v1/summary?month=${addMonths(month, 1)}`, { headers: a });
    expect(await named("Agua", addMonths(month, 1))).toEqual([]);
    expect((await named("Agua", month)).every((r) => r.date < today)).toBe(true);
    expect((await named("Arriendo", month)).every((r) => r.date < today)).toBe(true);
  });

  test("archiving again, or restoring, changes no rule", async () => {
    await t.request("PATCH", `/v1/categories/${home}`, { headers: a, body: { archived: false } });
    expect(await rule(rent)).toMatchObject({ endDate: today });
  });
});

/**
 * A recurrence materializes in the account's currency, so creating one and changing that
 * currency must serialize: both take the default account's row lock. Each test holds the lock in
 * one transaction (as the other side would) while the request runs in parallel, like the import
 * race in imports.test.ts.
 */
describe("recurrence and currency change race", () => {
  const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
  const lockAccount = (tx: Tx) =>
    tx.select().from(accounts).where(eq(accounts.isDefault, true)).for("update");
  const settledFlag = (promise: Promise<unknown>) => {
    const state = { settled: false };
    void promise.finally(() => {
      state.settled = true;
    });
    return state;
  };
  const category = async (headers: { authorization: string }) =>
    (
      (await (
        await t.request("POST", "/v1/categories", {
          headers,
          body: { name: "Casa", kind: "expense", icon: "house", color: "blue" },
        })
      ).json()) as { id: string }
    ).id;
  const rentBody = (categoryId: string) => ({
    name: "Arriendo",
    amount: -150_000_000,
    categoryId,
    frequency: "monthly",
    dayOfMonth: 5,
    startDate: "2099-01-01",
  });

  test("a new recurrence waits for a currency change in flight", async () => {
    const { userId, headers } = await t.signIn("race-recurrence@lukas.test");
    const categoryId = await category(headers);
    let created: Promise<Response> | undefined;
    await withUser(t.db, userId, async (tx) => {
      // The other side: the row lock a currency UPDATE takes (FOR NO KEY UPDATE), then the
      // switch. The recurrence's foreign key alone (FOR KEY SHARE) would not wait for it: only
      // the explicit account lock in POST /v1/recurrences does.
      await tx.select().from(accounts).where(eq(accounts.isDefault, true)).for("no key update");
      created = t.request("POST", "/v1/recurrences", { headers, body: rentBody(categoryId) });
      const flag = settledFlag(created);
      await sleep(300);
      expect(flag.settled).toBe(false);
      await tx.update(accounts).set({ currency: "COP" }).where(eq(accounts.isDefault, true));
    });
    expect((await (created as Promise<Response>)).status).toBe(201);
    // The rule now exists under the new currency, which is locked from here on.
    const res = await t.request("PATCH", "/v1/me", { headers, body: { currency: "EUR" } });
    expect(res.status).toBe(409);
  });

  test("a currency change waits for a recurrence being created, then finds the account locked", async () => {
    const { userId, headers } = await t.signIn("race-recurrence-patch@lukas.test");
    const categoryId = await category(headers);
    let patch: Promise<Response> | undefined;
    await withUser(t.db, userId, async (tx) => {
      // The POST's side: lock, then insert the rule.
      const [account] = await lockAccount(tx);
      patch = t.request("PATCH", "/v1/me", { headers, body: { currency: "COP" } });
      const flag = settledFlag(patch);
      await sleep(300);
      expect(flag.settled).toBe(false);
      await tx.insert(recurrences).values({
        ...rentBody(categoryId),
        frequency: "monthly",
        userId,
        accountId: account?.id as string,
      });
    });
    const res = await (patch as Promise<Response>);
    expect(res.status).toBe(409);
    expect(await res.json()).toMatchObject({ code: "currency_locked" });
  });
});
