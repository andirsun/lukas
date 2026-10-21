import { eq } from "drizzle-orm";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { categories, createDb, type Db, user, withUser } from "../src/index.ts";
import { startTestDatabase } from "../src/testing.ts";

let stop: () => Promise<void>;
let admin: { db: Db; close(): Promise<void> };
let app: { db: Db; close(): Promise<void> };
let categoryOfB: string;

const category = (userId: string) => ({
  userId,
  name: "Ocio",
  kind: "expense" as const,
  icon: "star",
  color: "purple",
});

beforeAll(async () => {
  const database = await startTestDatabase();
  stop = database.stop;
  admin = createDb(database.adminUrl);
  app = createDb(database.appUrl);
  await admin.db.insert(user).values([
    { id: "user-a", name: "A", email: "a@lukas.test" },
    { id: "user-b", name: "B", email: "b@lukas.test" },
  ]);
  await withUser(app.db, "user-a", (tx) => tx.insert(categories).values(category("user-a")));
  const [b] = await withUser(app.db, "user-b", (tx) =>
    tx.insert(categories).values(category("user-b")).returning(),
  );
  categoryOfB = b?.id ?? "";
}, 120_000);

afterAll(async () => {
  await app?.close();
  await admin?.close();
  await stop?.();
});

describe("row-level security", () => {
  test("a user only sees their own rows", async () => {
    const seen = await withUser(app.db, "user-a", (tx) => tx.select().from(categories));
    expect(seen.map((c) => c.userId)).toEqual(["user-a"]);
  });

  test("a user cannot insert rows for someone else", async () => {
    const error = await withUser(app.db, "user-a", (tx) =>
      tx.insert(categories).values({ ...category("user-b"), name: "Sneaky" }),
    ).catch((e: Error) => e);
    // Drizzle wraps the driver error; the Postgres message is on `cause`.
    expect(String((error as Error).cause)).toMatch(/row-level security/);
  });

  test("queries outside withUser see nothing", async () => {
    expect(await app.db.select().from(categories)).toEqual([]);
  });

  test("a user cannot update someone else's rows", async () => {
    const updated = await withUser(app.db, "user-a", (tx) =>
      tx.update(categories).set({ name: "x" }).where(eq(categories.id, categoryOfB)).returning(),
    );
    expect(updated).toEqual([]);
  });
});
