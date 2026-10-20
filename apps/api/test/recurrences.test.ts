import { addMonths, monthOf, todayIn } from "@lukas/core";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
let a: { authorization: string };
let subscriptions: string;
const month = monthOf(todayIn("UTC"));

interface Tx {
  id: string;
  name: string;
  amount: number;
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
}, 120_000);
afterAll(() => t?.stop());

const listMonth = async (m: string) =>
  (
    (await (await t.request("GET", `/v1/transactions?month=${m}`, { headers: a })).json()) as {
      items: Tx[];
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

  test("deleting a recurrence keeps the generated transactions", async () => {
    const res = await t.request("DELETE", `/v1/recurrences/${recurrenceId}`, { headers: a });
    expect(res.status).toBe(204);
    const next = await spotifyIn(addMonths(month, 1));
    expect(next).toHaveLength(1);
    expect(next[0]?.recurrenceId).toBeNull();
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
});
