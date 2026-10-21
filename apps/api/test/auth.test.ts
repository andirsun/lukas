import { accounts, verification, withUser } from "@lukas/db";
import { eq, like } from "@lukas/db/orm";
import { afterAll, afterEach, beforeAll, describe, expect, test, vi } from "vitest";
import { codeFrom, createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
beforeAll(async () => {
  t = await createTestApp();
});
afterAll(() => t?.stop());
afterEach(() => {
  vi.useRealTimers();
});

const sendCode = (email: string, headers: Record<string, string> = {}) =>
  t.request("POST", "/auth/email-otp/send-verification-otp", {
    body: { email, type: "sign-in" },
    headers,
  });
const signInWith = (email: string, otp: string) =>
  t.request("POST", "/auth/sign-in/email-otp", { body: { email, otp } });

describe("email code + magic link", () => {
  test("one email carries the code and a magic link with the same code", async () => {
    expect((await sendCode("a@lukas.test")).status).toBe(200);
    const mail = t.mailer.lastTo("a@lukas.test");
    expect(mail).toBeDefined();
    const code = codeFrom(mail?.subject ?? "");
    expect(mail?.text).toContain(
      `http://localhost:5173/auth/verify?email=a%40lukas.test&code=${code}`,
    );
    expect(mail?.subject).toBe(`Tu código de Lukas: ${code}`);
  });

  test("signing in returns a bearer token that opens protected routes", async () => {
    await sendCode("b@lukas.test");
    const code = codeFrom(t.mailer.lastTo("b@lukas.test")?.subject ?? "");
    const res = await signInWith("b@lukas.test", code);
    expect(res.status).toBe(200);
    const token = res.headers.get("set-auth-token");
    expect(token).toBeTruthy();
    const me = await t.request("GET", "/v1/me", { headers: { authorization: `Bearer ${token}` } });
    expect(me.status).toBe(200);
    expect(await me.json()).toMatchObject({ email: "b@lukas.test" });
  });

  test("codes are not stored in plain text", async () => {
    await sendCode("hash@lukas.test");
    const code = codeFrom(t.mailer.lastTo("hash@lukas.test")?.subject ?? "");
    const rows = await t.admin
      .select()
      .from(verification)
      .where(like(verification.identifier, "%hash@lukas.test%"));
    expect(rows.length).toBeGreaterThan(0);
    for (const row of rows) expect(row.value).not.toContain(code);
    expect((await signInWith("hash@lukas.test", code)).status).toBe(200);
  });

  test("a code works only once", async () => {
    await sendCode("c@lukas.test");
    const code = codeFrom(t.mailer.lastTo("c@lukas.test")?.subject ?? "");
    expect((await signInWith("c@lukas.test", code)).status).toBe(200);
    expect((await signInWith("c@lukas.test", code)).status).not.toBe(200);
  });

  test("a code expires after 10 minutes", async () => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-10-20T10:00:00Z"));
    await sendCode("d@lukas.test");
    const code = codeFrom(t.mailer.lastTo("d@lukas.test")?.subject ?? "");
    vi.setSystemTime(new Date("2026-10-20T10:10:01Z"));
    expect((await signInWith("d@lukas.test", code)).status).not.toBe(200);
  });

  test("three wrong attempts burn the code", async () => {
    await sendCode("e@lukas.test");
    const code = codeFrom(t.mailer.lastTo("e@lukas.test")?.subject ?? "");
    const wrong = code === "000000" ? "111111" : "000000";
    for (let i = 0; i < 3; i++) await signInWith("e@lukas.test", wrong);
    expect((await signInWith("e@lukas.test", code)).status).not.toBe(200);
  });

  test("a sixth code to the same email within 15 minutes is throttled", async () => {
    for (let i = 0; i < 5; i++) expect((await sendCode("f@lukas.test")).status).toBe(200);
    expect((await sendCode("f@lukas.test")).status).toBe(429);
  });

  test("codes from one IP are rate limited", async () => {
    const ip = { "x-forwarded-for": "192.168.77.1" };
    const statuses: number[] = [];
    for (let i = 0; i < 6; i++) statuses.push((await sendCode(`ip${i}@lukas.test`, ip)).status);
    expect(statuses.slice(0, 5)).toEqual([200, 200, 200, 200, 200]);
    expect(statuses[5]).toBe(429);
  });

  test("spoofed leftmost X-Forwarded-For entries do not dodge the per-IP limit", async () => {
    const statuses: number[] = [];
    for (let i = 0; i < 6; i++) {
      const xff = { "x-forwarded-for": `${i}.${i}.${i}.${i}, 203.0.113.9, 10.0.0.1` };
      statuses.push((await sendCode(`spoof${i}@lukas.test`, xff)).status);
    }
    expect(statuses[5]).toBe(429);
  });

  test("a new user gets one default account", async () => {
    const { userId } = await t.signIn("g@lukas.test");
    const rows = await withUser(t.db, userId, (tx) =>
      tx.select().from(accounts).where(eq(accounts.userId, userId)),
    );
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({ name: "Main", currency: "EUR", isDefault: true });
  });
});

test("the OAuth authorization server metadata advertises the finance scopes", async () => {
  const res = await t.request("GET", "/.well-known/oauth-authorization-server");
  expect(res.status).toBe(200);
  const metadata = (await res.json()) as {
    scopes_supported: string[];
    registration_endpoint?: string;
  };
  expect(metadata.scopes_supported).toEqual(
    expect.arrayContaining(["finance:read", "finance:write"]),
  );
  expect(metadata.registration_endpoint).toBeDefined();
});
