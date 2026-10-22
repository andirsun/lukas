import { emailThrottle, transactions, user, verification } from "@lukas/db";
import { eq, sql } from "@lukas/db/orm";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { codeFrom, createTestApp, type TestApp } from "./harness.ts";

type Session = { userId: string; headers: { authorization: string } };

const ALLOWED = [
  "keep@lukas.test",
  "english@lukas.test",
  "taken@lukas.test",
  "race@lukas.test",
  "owner@lukas.test",
  "wrong@lukas.test",
  "retry@lukas.test",
  "expired@lukas.test",
  "mine@lukas.test",
  "throttle@lukas.test",
  "other@lukas.test",
];

async function guest(t: TestApp, headers: Record<string, string> = {}): Promise<Session> {
  const res = await t.request("POST", "/auth/sign-in/anonymous", { body: {}, headers });
  if (res.status !== 200) throw new Error(`guest sign-up failed: ${res.status}`);
  const json = (await res.json()) as { user: { id: string } };
  return {
    userId: json.user.id,
    headers: { authorization: `Bearer ${res.headers.get("set-auth-token")}` },
  };
}

async function me(t: TestApp, headers: { authorization: string }) {
  const res = await t.request("GET", "/v1/me", { headers });
  expect(res.status).toBe(200);
  return (await res.json()) as { id: string; email: string; isAnonymous: boolean };
}

const send = (t: TestApp, who: Session, email: string) =>
  t.request("POST", "/v1/me/claim-email/send", { headers: who.headers, body: { email } });

const verify = (t: TestApp, who: Session, email: string, code: string) =>
  t.request("POST", "/v1/me/claim-email/verify", { headers: who.headers, body: { email, code } });

/** Sends a claim code and reads it back from the test mailer. */
async function sendAndRead(t: TestApp, who: Session, email: string): Promise<string> {
  const before = t.mailer.sent.length;
  const res = await send(t, who, email);
  expect(res.status).toBe(204);
  expect(t.mailer.sent).toHaveLength(before + 1);
  const mail = t.mailer.lastTo(email);
  if (!mail) throw new Error("no claim mail");
  return codeFrom(mail.subject);
}

/** A six-digit code that is not `code`. */
const wrongCode = (code: string) => String((Number(code) + 1) % 1_000_000).padStart(6, "0");

async function addTransactions(t: TestApp, who: Session, count: number) {
  const cat = await t.request("POST", "/v1/categories", {
    headers: who.headers,
    body: { name: "Mercado", kind: "expense", icon: "cart", color: "orange" },
  });
  expect(cat.status).toBe(201);
  const { id: categoryId } = (await cat.json()) as { id: string };
  for (let i = 0; i < count; i++) {
    const res = await t.request("POST", "/v1/transactions", {
      headers: who.headers,
      body: { categoryId, name: `Arroz ${i}`, amount: -500000, date: "2026-10-02" },
    });
    expect(res.status).toBe(201);
  }
}

async function transactionCount(t: TestApp, headers: { authorization: string }) {
  const res = await t.request("GET", "/v1/transactions", { headers });
  expect(res.status).toBe(200);
  return ((await res.json()) as { items: unknown[] }).items.length;
}

async function waitFor(check: () => Promise<boolean>, what: string, timeoutMs = 10_000) {
  const until = Date.now() + timeoutMs;
  while (!(await check())) {
    if (Date.now() > until) throw new Error(`timed out waiting for ${what}`);
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
}

describe("a guest claims an email in place", () => {
  let t: TestApp;
  beforeAll(async () => {
    t = await createTestApp({ SIGN_IN_ALLOWLIST: ALLOWED });
  });
  afterAll(() => t?.stop());

  test("claiming an allowlisted email keeps the same user id and every transaction", async () => {
    const g = await guest(t, { "x-lukas-timezone": "America/Bogota", "x-lukas-locale": "es" });
    await addTransactions(t, g, 3);

    const code = await sendAndRead(t, g, "keep@lukas.test");
    const mail = t.mailer.lastTo("keep@lukas.test");
    expect(mail?.subject).toBe(`Tu código para guardar tu progreso: ${code}`);

    const res = await verify(t, g, "keep@lukas.test", code);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toMatchObject({ id: g.userId, email: "keep@lukas.test", isAnonymous: false });
    // The same profile DTO as GET /v1/me, and the guest's session still works.
    expect(body).toEqual(await me(t, g.headers));
    expect(await transactionCount(t, g.headers)).toBe(3);

    const [stored] = await t.admin.select().from(user).where(eq(user.id, g.userId));
    expect(stored).toMatchObject({ email: "keep@lukas.test", emailVerified: true });
    expect(stored?.isAnonymous).toBe(false);
    const rows = await t.admin.select().from(transactions).where(eq(transactions.userId, g.userId));
    expect(rows).toHaveLength(3);
    // The code is single-use: nothing is left in the store.
    const codes = await t.admin
      .select()
      .from(verification)
      .where(sql`${verification.identifier} like ${"claim-email-%"}`);
    expect(codes.filter((row) => row.identifier.includes(g.userId))).toEqual([]);

    // A later email sign-in reaches the same user and its data.
    const signedIn = await t.signIn("keep@lukas.test");
    expect(signedIn.userId).toBe(g.userId);
    expect(await transactionCount(t, signedIn.headers)).toBe(3);
  });

  test("the claim email is in the guest's language", async () => {
    const g = await guest(t, { "x-lukas-locale": "en" });
    const code = await sendAndRead(t, g, "english@lukas.test");
    const mail = t.mailer.lastTo("english@lukas.test");
    expect(mail?.subject).toBe(`Your code to save your progress: ${code}`);
    expect(mail?.text).toContain("Your code to save your progress");
  });

  test("a non-allowlisted email gets sign_in_not_allowed and no mail is sent", async () => {
    const g = await guest(t);
    const before = t.mailer.sent.length;
    for (const email of ["stranger@lukas.test", "temp-x@guest.lukitas.invalid"]) {
      const res = await send(t, g, email);
      expect(res.status).toBe(403);
      expect(await res.json()).toMatchObject({ code: "sign_in_not_allowed" });
    }
    expect(t.mailer.sent).toHaveLength(before);
    const throttle = await t.admin.select().from(emailThrottle);
    expect(throttle.map((row) => row.email)).not.toContain("stranger@lukas.test");
    expect((await me(t, g.headers)).isAnonymous).toBe(true);
  });

  test("an email that belongs to another user gets email_taken, no mail, the guest unchanged", async () => {
    const owner = await t.signIn("taken@lukas.test");
    const g = await guest(t);
    const profileBefore = await me(t, g.headers);
    const before = t.mailer.sent.length;

    for (const email of ["taken@lukas.test", " Taken@Lukas.TEST "]) {
      const res = await send(t, g, email);
      expect(res.status).toBe(409);
      expect(await res.json()).toMatchObject({ code: "email_taken" });
    }
    expect(t.mailer.sent).toHaveLength(before);
    expect(await me(t, g.headers)).toEqual(profileBefore);
    // The owner is untouched too.
    expect((await me(t, owner.headers)).email).toBe("taken@lukas.test");
  });

  test("two guests claiming the same email: exactly one wins, the other gets email_taken", async () => {
    const a = await guest(t);
    const b = await guest(t);
    const codeA = await sendAndRead(t, a, "race@lukas.test");
    const codeB = await sendAndRead(t, b, "race@lukas.test");

    // Hold both claims at their UPDATE until both are there, so they really race: the unique
    // email constraint, not an earlier check, has to decide.
    let release = () => {};
    const released = new Promise<void>((resolve) => {
      release = resolve;
    });
    let locked = () => {};
    const isLocked = new Promise<void>((resolve) => {
      locked = resolve;
    });
    const holder = t.admin.transaction(async (tx) => {
      await tx.execute(sql`lock table "user" in share mode`);
      locked();
      await released;
    });
    await isLocked;

    const both = Promise.all([
      verify(t, a, "race@lukas.test", codeA),
      verify(t, b, "race@lukas.test", codeB),
    ]);
    try {
      await waitFor(async () => {
        const rows = await t.admin.execute<{ n: number }>(
          sql`select count(*)::int as n from pg_stat_activity
              where wait_event_type = 'Lock' and query ilike 'update "user"%'`,
        );
        return rows[0]?.n === 2;
      }, "both claims to wait at their UPDATE");
    } finally {
      release();
      await holder;
    }
    const responses = await both;

    const statuses = responses.map((r) => r.status).sort();
    expect(statuses).toEqual([200, 409]);
    const loserIndex = responses.findIndex((r) => r.status === 409);
    const loserResponse = responses[loserIndex];
    expect(await loserResponse?.json()).toMatchObject({ code: "email_taken" });
    const [winner, loser] = loserIndex === 0 ? [b, a] : [a, b];
    expect(await me(t, winner.headers)).toMatchObject({
      email: "race@lukas.test",
      isAnonymous: false,
    });
    expect((await me(t, loser.headers)).isAnonymous).toBe(true);
    const owners = await t.admin.select().from(user).where(eq(user.email, "race@lukas.test"));
    expect(owners.map((row) => row.id)).toEqual([winner.userId]);
  });

  test("a non-guest session gets not_a_guest", async () => {
    const owner = await t.signIn("owner@lukas.test");
    const before = t.mailer.sent.length;
    const sent = await send(t, owner, "mine@lukas.test");
    expect(sent.status).toBe(409);
    expect(await sent.json()).toMatchObject({ code: "not_a_guest" });
    expect(t.mailer.sent).toHaveLength(before);

    const verified = await verify(t, owner, "mine@lukas.test", "123456");
    expect(verified.status).toBe(409);
    expect(await verified.json()).toMatchObject({ code: "not_a_guest" });
    expect((await me(t, owner.headers)).email).toBe("owner@lukas.test");
  });

  test("a wrong code 3 times invalidates it", async () => {
    const g = await guest(t);
    const code = await sendAndRead(t, g, "wrong@lukas.test");
    for (let i = 0; i < 3; i++) {
      const res = await verify(t, g, "wrong@lukas.test", wrongCode(code));
      expect(res.status).toBe(400);
      expect(await res.json()).toMatchObject({ code: "invalid_or_expired_code" });
    }
    const res = await verify(t, g, "wrong@lukas.test", code);
    expect(res.status).toBe(400);
    expect(await res.json()).toMatchObject({ code: "invalid_or_expired_code" });
    expect((await me(t, g.headers)).isAnonymous).toBe(true);
  });

  test("two wrong tries still leave the right code working", async () => {
    const g = await guest(t);
    const code = await sendAndRead(t, g, "retry@lukas.test");
    for (let i = 0; i < 2; i++) {
      expect((await verify(t, g, "retry@lukas.test", wrongCode(code))).status).toBe(400);
    }
    expect((await verify(t, g, "retry@lukas.test", code)).status).toBe(200);
  });

  test("an expired code is refused", async () => {
    const g = await guest(t);
    const code = await sendAndRead(t, g, "expired@lukas.test");
    await t.admin
      .update(verification)
      .set({ expiresAt: new Date(Date.now() - 1000) })
      .where(sql`${verification.identifier} like ${`%${g.userId}%`}`);
    const res = await verify(t, g, "expired@lukas.test", code);
    expect(res.status).toBe(400);
    expect(await res.json()).toMatchObject({ code: "invalid_or_expired_code" });
    expect((await me(t, g.headers)).isAnonymous).toBe(true);
  });

  test("a code only works for the guest it was sent for, and for that email", async () => {
    const a = await guest(t);
    const b = await guest(t);
    const code = await sendAndRead(t, a, "mine@lukas.test");
    const stolen = await verify(t, b, "mine@lukas.test", code);
    expect(stolen.status).toBe(400);
    expect(await stolen.json()).toMatchObject({ code: "invalid_or_expired_code" });
    const otherEmail = await verify(t, a, "other@lukas.test", code);
    expect(otherEmail.status).toBe(400);
    expect((await me(t, b.headers)).isAnonymous).toBe(true);
    // A's code still works for A.
    expect((await verify(t, a, "mine@lukas.test", code)).status).toBe(200);
  });

  test("sign-in codes and claim codes share the per-email throttle", async () => {
    const g = await guest(t);
    for (let i = 0; i < 2; i++) {
      const res = await t.request("POST", "/auth/email-otp/send-verification-otp", {
        body: { email: "throttle@lukas.test", type: "sign-in" },
      });
      expect(res.status).toBe(200);
    }
    for (let i = 0; i < 3; i++) {
      expect((await send(t, g, "throttle@lukas.test")).status).toBe(204);
    }
    const before = t.mailer.sent.length;
    const res = await send(t, g, "throttle@lukas.test");
    expect(res.status).toBe(429);
    expect(await res.json()).toMatchObject({ code: "too_many_requests" });
    expect(t.mailer.sent).toHaveLength(before);
  });
});
