import { accounts, categories, session, transactions, user } from "@lukas/db";
import { eq, inArray, sql } from "@lukas/db/orm";
import { afterAll, beforeAll, beforeEach, describe, expect, test, vi } from "vitest";
import {
  cleanupInactiveGuests,
  GUEST_CLEANUP_LOCK,
  scheduleGuestCleanup,
} from "../src/services/guest-cleanup.ts";
import { createTestApp, type TestApp } from "./harness.ts";

const DAY = 24 * 60 * 60 * 1000;
const NOW = new Date("2026-10-22T12:00:00.000Z");
const daysAgo = (days: number) => new Date(NOW.getTime() - days * DAY);

let t: TestApp;
beforeAll(async () => {
  t = await createTestApp();
});
afterAll(() => t?.stop());

/** Removes everything the previous test left, so each test counts from zero. */
beforeEach(async () => {
  await t.admin.delete(user);
});

async function newGuest() {
  const res = await t.request("POST", "/auth/sign-in/anonymous", { body: {} });
  if (res.status !== 200) throw new Error(`guest sign-up failed: ${res.status}`);
  const token = res.headers.get("set-auth-token");
  const json = (await res.json()) as { user: { id: string } };
  return { userId: json.user.id, headers: { authorization: `Bearer ${token}` } };
}

/** Makes the user's sessions last active `days` days before NOW. */
async function lastActive(userId: string, days: number) {
  await t.admin
    .update(session)
    .set({ updatedAt: daysAgo(days) })
    .where(eq(session.userId, userId));
}

const exists = async (userId: string) =>
  (await t.admin.select({ id: user.id }).from(user).where(eq(user.id, userId))).length === 1;

describe("cleanupInactiveGuests", () => {
  test("deletes a guest inactive for 61 days with its data", async () => {
    const g = await newGuest();
    const cat = await t.request("POST", "/v1/categories", {
      headers: g.headers,
      body: { name: "Food", kind: "expense", icon: "tag", color: "gray" },
    });
    const categoryId = ((await cat.json()) as { id: string }).id;
    const tx = await t.request("POST", "/v1/transactions", {
      headers: g.headers,
      body: { categoryId, name: "Lunch", amount: -1200, date: "2026-10-01" },
    });
    expect(tx.status).toBe(201);
    await lastActive(g.userId, 61);

    expect(await cleanupInactiveGuests(t.db, NOW)).toBe(1);

    expect(await exists(g.userId)).toBe(false);
    for (const table of [accounts, categories, transactions]) {
      expect(await t.admin.select().from(table).where(eq(table.userId, g.userId))).toHaveLength(0);
    }
    expect(await t.admin.select().from(session).where(eq(session.userId, g.userId))).toHaveLength(
      0,
    );
  });

  test("keeps a guest active 59 days ago", async () => {
    const g = await newGuest();
    await lastActive(g.userId, 59);

    expect(await cleanupInactiveGuests(t.db, NOW)).toBe(0);

    expect(await exists(g.userId)).toBe(true);
    expect(await t.admin.select().from(accounts).where(eq(accounts.userId, g.userId))).toHaveLength(
      1,
    );
  });

  test("goes by the latest session, not the oldest", async () => {
    const g = await newGuest();
    await lastActive(g.userId, 90);
    // A second device signed in later.
    const [first] = await t.admin.select().from(session).where(eq(session.userId, g.userId));
    await t.admin.insert(session).values({
      ...(first as typeof session.$inferSelect),
      id: "second-session",
      token: "second-token",
      updatedAt: daysAgo(3),
    });

    expect(await cleanupInactiveGuests(t.db, NOW)).toBe(0);
    expect(await exists(g.userId)).toBe(true);
  });

  test("a guest without any session counts from when it was created", async () => {
    const old = await newGuest();
    const recent = await newGuest();
    await t.admin.delete(session);
    await t.admin
      .update(user)
      .set({ createdAt: daysAgo(70) })
      .where(eq(user.id, old.userId));
    await t.admin
      .update(user)
      .set({ createdAt: daysAgo(10) })
      .where(eq(user.id, recent.userId));

    expect(await cleanupInactiveGuests(t.db, NOW)).toBe(1);

    expect(await exists(old.userId)).toBe(false);
    expect(await exists(recent.userId)).toBe(true);
  });

  test("never deletes a user with an email, however old", async () => {
    const member = await t.signIn("old-timer@lukas.test");
    await lastActive(member.userId, 5000);
    await t.admin
      .update(user)
      .set({ createdAt: daysAgo(5000) })
      .where(eq(user.id, member.userId));
    // A guest that claimed an email is a member from then on.
    const claimed = await newGuest();
    await t.admin
      .update(user)
      .set({ email: "claimed@lukas.test", isAnonymous: false })
      .where(eq(user.id, claimed.userId));
    await lastActive(claimed.userId, 400);

    expect(await cleanupInactiveGuests(t.db, NOW)).toBe(0);

    expect(await exists(member.userId)).toBe(true);
    expect(await exists(claimed.userId)).toBe(true);
  });

  test("two runs at once delete once", async () => {
    const guests = await Promise.all([newGuest(), newGuest(), newGuest()]);
    for (const g of guests) await lastActive(g.userId, 100);

    const counts = await Promise.all([
      cleanupInactiveGuests(t.db, NOW),
      cleanupInactiveGuests(t.db, NOW),
    ]);

    expect(counts.reduce((a, b) => a + b, 0)).toBe(3);
    const left = await t.admin
      .select({ id: user.id })
      .from(user)
      .where(
        inArray(
          user.id,
          guests.map((g) => g.userId),
        ),
      );
    expect(left).toHaveLength(0);
  });

  test("a run does nothing while another holds the advisory lock", async () => {
    const g = await newGuest();
    await lastActive(g.userId, 100);

    await t.admin.transaction(async (tx) => {
      await tx.execute(sql`select pg_advisory_xact_lock(${GUEST_CLEANUP_LOCK})`);
      expect(await cleanupInactiveGuests(t.db, NOW)).toBe(0);
      expect(await exists(g.userId)).toBe(true);
    });

    // The lock is gone with that transaction: the next run goes through.
    expect(await cleanupInactiveGuests(t.db, NOW)).toBe(1);
    expect(await exists(g.userId)).toBe(false);
  });

  test("the lock key is the one the brief names", () => {
    expect(GUEST_CLEANUP_LOCK).toBe(0x6c756b61);
  });
});

describe("scheduleGuestCleanup", () => {
  test("runs at start and then once a day, and stops when asked", async () => {
    vi.useFakeTimers();
    try {
      const cleanup = vi.fn(async () => 2);
      const log = vi.fn();
      const stop = scheduleGuestCleanup({ db: t.db, cleanup, log });
      await vi.advanceTimersByTimeAsync(0);
      expect(cleanup).toHaveBeenCalledTimes(1);
      expect(log).toHaveBeenCalledWith(expect.stringContaining("2"));

      await vi.advanceTimersByTimeAsync(DAY - 1);
      expect(cleanup).toHaveBeenCalledTimes(1);
      await vi.advanceTimersByTimeAsync(1);
      expect(cleanup).toHaveBeenCalledTimes(2);

      stop();
      await vi.advanceTimersByTimeAsync(3 * DAY);
      expect(cleanup).toHaveBeenCalledTimes(2);
    } finally {
      vi.useRealTimers();
    }
  });

  test("a failed run is logged and the next day's run still happens", async () => {
    vi.useFakeTimers();
    try {
      const cleanup = vi
        .fn<() => Promise<number>>()
        .mockRejectedValueOnce(new Error("db down"))
        .mockResolvedValue(0);
      const logError = vi.fn();
      const stop = scheduleGuestCleanup({ db: t.db, cleanup, logError });
      await vi.advanceTimersByTimeAsync(0);
      expect(logError).toHaveBeenCalledTimes(1);

      await vi.advanceTimersByTimeAsync(DAY);
      expect(cleanup).toHaveBeenCalledTimes(2);
      stop();
    } finally {
      vi.useRealTimers();
    }
  });
});
