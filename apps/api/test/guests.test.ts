import { accounts, user } from "@lukas/db";
import { eq } from "@lukas/db/orm";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { createTestApp, type TestApp } from "./harness.ts";

type Guest = { userId: string; headers: { authorization: string } };

/** Guest sign-up as the app does it: no body beyond `{}`, the device's zone and language in headers. */
async function signUpGuest(t: TestApp, headers: Record<string, string> = {}) {
  return t.request("POST", "/auth/sign-in/anonymous", { body: {}, headers });
}

async function guest(t: TestApp, headers: Record<string, string> = {}): Promise<Guest> {
  const res = await signUpGuest(t, headers);
  if (res.status !== 200)
    throw new Error(`guest sign-up failed: ${res.status} ${await res.text()}`);
  const token = res.headers.get("set-auth-token");
  const json = (await res.json()) as { user: { id: string } };
  return { userId: json.user.id, headers: { authorization: `Bearer ${token}` } };
}

async function me(t: TestApp, headers: { authorization: string }) {
  const res = await t.request("GET", "/v1/me", { headers });
  expect(res.status).toBe(200);
  return (await res.json()) as {
    id: string;
    isAnonymous: boolean;
    timezone: string;
    locale: string;
    currency: string;
  };
}

describe("guest sign-up, open (with an allowlist set)", () => {
  let t: TestApp;
  beforeAll(async () => {
    t = await createTestApp({ SIGN_IN_ALLOWLIST: ["founder@lukas.test"] });
  });
  afterAll(() => t?.stop());

  test("a guest signs up without an email, even with an allowlist set", async () => {
    const res = await signUpGuest(t);
    expect(res.status).toBe(200);
    const token = res.headers.get("set-auth-token");
    expect(token).toBeTruthy();
    const { user: created } = (await res.json()) as { user: { id: string } };
    const headers = { authorization: `Bearer ${token}` };

    const profile = await me(t, headers);
    expect(profile).toMatchObject({ id: created.id, isAnonymous: true });

    // The default account exists, and it is empty.
    const rows = await t.admin.select().from(accounts).where(eq(accounts.userId, created.id));
    expect(rows).toHaveLength(1);
    expect(rows[0]?.isDefault).toBe(true);
    const list = await t.request("GET", "/v1/transactions", { headers });
    expect(list.status).toBe(200);
    expect(((await list.json()) as { items: unknown[] }).items).toEqual([]);

    // No email was sent, and the placeholder address never resolves.
    expect(t.mailer.sent).toHaveLength(0);
    const [stored] = await t.admin.select().from(user).where(eq(user.id, created.id));
    expect(stored?.email).toMatch(/@guest\.lukitas\.invalid$/);
  });

  test("an email user is not anonymous", async () => {
    const founder = await t.signIn("founder@lukas.test");
    expect((await me(t, founder.headers)).isAnonymous).toBe(false);
  });
});

describe("guest sign-up, turned off", () => {
  let t: TestApp;
  beforeAll(async () => {
    t = await createTestApp({ GUEST_SIGNUP: false });
  });
  afterAll(() => t?.stop());

  test("guest sign-up is refused when GUEST_SIGNUP is false", async () => {
    const res = await signUpGuest(t);
    expect(res.status).toBe(403);
    expect(await res.json()).toMatchObject({ code: "guest_signup_disabled" });
    expect(await t.admin.select().from(user)).toHaveLength(0);
  });

  test("email sign-in still works", async () => {
    const a = await t.signIn("a@lukas.test");
    expect((await me(t, a.headers)).isAnonymous).toBe(false);
  });
});

describe("guests", () => {
  let t: TestApp;
  beforeAll(async () => {
    t = await createTestApp();
  });
  afterAll(() => t?.stop());

  test("a guest's account currency follows the device", async () => {
    const cases: [timezone: string, currency: string][] = [
      ["America/Bogota", "COP"],
      ["Europe/Lisbon", "EUR"],
      ["America/New_York", "USD"],
    ];
    for (const [timezone, currency] of cases) {
      const g = await guest(t, { "x-lukas-timezone": timezone, "x-lukas-locale": "en" });
      expect(await me(t, g.headers)).toMatchObject({ timezone, locale: "en", currency });
    }
  });

  test("x-lukas-locale sets the locale; without it, Spanish", async () => {
    const es = await guest(t, { "x-lukas-timezone": "America/Bogota", "x-lukas-locale": "es" });
    expect((await me(t, es.headers)).locale).toBe("es");
    const none = await guest(t, { "x-lukas-timezone": "America/Bogota" });
    expect((await me(t, none.headers)).locale).toBe("es");
  });

  test("a region in x-lukas-locale counts, as on the web: es-CO in New York → COP", async () => {
    const g = await guest(t, { "x-lukas-timezone": "America/New_York", "x-lukas-locale": "es-CO" });
    expect(await me(t, g.headers)).toMatchObject({ locale: "es", currency: "COP" });
  });

  test("a zone that isn't an IANA name is ignored: UTC, and USD", async () => {
    for (const timezone of ["+05:00", "Not/AZone", "Europe/Lisbon; drop table", ""]) {
      const g = await guest(t, { "x-lukas-timezone": timezone });
      expect(await me(t, g.headers)).toMatchObject({ timezone: "UTC", currency: "USD" });
    }
  });

  test("RLS: a guest never sees another guest's rows", async () => {
    const a = await guest(t, { "x-lukas-timezone": "America/Bogota" });
    const b = await guest(t, { "x-lukas-timezone": "America/Bogota" });
    const cat = await t.request("POST", "/v1/categories", {
      headers: a.headers,
      body: { name: "Mercado", kind: "expense", icon: "cart", color: "orange" },
    });
    expect(cat.status).toBe(201);
    const { id: categoryId } = (await cat.json()) as { id: string };
    const created = await t.request("POST", "/v1/transactions", {
      headers: a.headers,
      body: { categoryId, name: "Arroz", amount: -500000, date: "2026-10-02" },
    });
    expect(created.status).toBe(201);
    const { id: transactionId } = (await created.json()) as { id: string };

    const list = await t.request("GET", "/v1/transactions", { headers: b.headers });
    expect(((await list.json()) as { items: unknown[] }).items).toEqual([]);
    const cats = await t.request("GET", "/v1/categories", { headers: b.headers });
    expect(await cats.json()).toEqual([]);
    const theirs = await t.request("PATCH", `/v1/transactions/${transactionId}`, {
      headers: b.headers,
      body: { name: "Mine now" },
    });
    expect(theirs.status).toBe(404);

    // A still sees its own.
    const own = await t.request("GET", "/v1/transactions", { headers: a.headers });
    expect(((await own.json()) as { items: unknown[] }).items).toHaveLength(1);
  });

  test("a guest who then signs in with an email keeps the guest account and its rows", async () => {
    const g = await guest(t, { "x-lukas-timezone": "America/Bogota" });
    const cat = await t.request("POST", "/v1/categories", {
      headers: g.headers,
      body: { name: "Mercado", kind: "expense", icon: "cart", color: "orange" },
    });
    expect(cat.status).toBe(201);

    // Signing in with the guest's session still attached must not delete the guest user.
    const sent = await t.request("POST", "/auth/email-otp/send-verification-otp", {
      headers: g.headers,
      body: { email: "owner@lukas.test", type: "sign-in" },
    });
    expect(sent.status).toBe(200);
    const mail = t.mailer.lastTo("owner@lukas.test");
    const code = /(\d{6})$/.exec(mail?.subject ?? "")?.[1];
    const signedIn = await t.request("POST", "/auth/sign-in/email-otp", {
      headers: g.headers,
      body: { email: "owner@lukas.test", otp: code },
    });
    expect(signedIn.status).toBe(200);

    const [still] = await t.admin.select().from(user).where(eq(user.id, g.userId));
    expect(still).toBeDefined();
    expect((await me(t, g.headers)).isAnonymous).toBe(true);
  });

  test("a placeholder address can't ask for a sign-in code", async () => {
    const g = await guest(t);
    const [stored] = await t.admin.select().from(user).where(eq(user.id, g.userId));
    const sentBefore = t.mailer.sent.length;
    const res = await t.request("POST", "/auth/email-otp/send-verification-otp", {
      body: { email: stored?.email, type: "sign-in" },
    });
    expect(res.status).toBe(403);
    expect(await res.json()).toMatchObject({ code: "sign_in_not_allowed" });
    expect(t.mailer.sent).toHaveLength(sentBefore);
  });
});
