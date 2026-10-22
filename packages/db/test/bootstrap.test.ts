import postgres from "postgres";
import { afterAll, beforeAll, describe, expect, test, vi } from "vitest";
import { ensureAppRole, prepareDatabase } from "../src/bootstrap.ts";
import { startBareDatabase } from "../src/testing.ts";

// Each test migrates a database or starts a container; a loaded machine needs more than 5 s.
vi.setConfig({ testTimeout: 60_000 });

const PASSWORD = "first-app-password-0123456789";
const NEXT_PASSWORD = "second-app-password-9876543210";

let adminUrl: string;
let stop: () => Promise<void>;

const asApp = (password: string) => {
  const url = new URL(adminUrl);
  url.username = "lukas_app";
  url.password = password;
  return postgres(url.toString(), { max: 1, onnotice: () => {} });
};

beforeAll(async () => {
  ({ adminUrl, stop } = await startBareDatabase());
}, 120_000);
afterAll(async () => {
  await stop?.();
});

describe("prepareDatabase", () => {
  test("on an empty server: creates the app role with its password, then migrates", async () => {
    await prepareDatabase(adminUrl, PASSWORD);

    const app = asApp(PASSWORD);
    try {
      const [role] = await app`
        select rolsuper, rolbypassrls, rolcreatedb, rolcreaterole from pg_roles where rolname = current_user`;
      expect(role).toEqual({
        rolsuper: false,
        rolbypassrls: false,
        rolcreatedb: false,
        rolcreaterole: false,
      });
      // The migrations ran and granted the role its table privileges; row-level security hides
      // rows when no user is set, and the role cannot create tables.
      expect(await app`select * from "user"`).toHaveLength(0);
      await expect(app`create table intruder (id int)`).rejects.toThrow(/permission denied/);
    } finally {
      await app.end();
    }
  });

  test("is idempotent, and a new password replaces the old one", async () => {
    await prepareDatabase(adminUrl, PASSWORD);
    await prepareDatabase(adminUrl, NEXT_PASSWORD);

    const stale = asApp(PASSWORD);
    await expect(stale`select 1`).rejects.toThrow(/password authentication failed/);
    await stale.end();

    const fresh = asApp(NEXT_PASSWORD);
    expect(await fresh`select 1 as one`).toEqual([{ one: 1 }]);
    await fresh.end();
  });

  test("keeps the data it finds", async () => {
    const admin = postgres(adminUrl, { max: 1, onnotice: () => {} });
    await admin`insert into "user" (id, name, email) values ('keep-me', 'K', 'k@lukas.test')`;
    await prepareDatabase(adminUrl, NEXT_PASSWORD);
    expect(await admin`select id from "user" where id = 'keep-me'`).toHaveLength(1);
    await admin.end();
  });

  test.each([
    ["too short", "short"],
    ["the development password", "lukas_app"],
    ["blank", ""],
  ])("refuses a password that is %s, before touching the database", async (_why, password) => {
    await expect(prepareDatabase("postgres://nobody@127.0.0.1:1/none", password)).rejects.toThrow(
      /APP_DB_PASSWORD/,
    );
  });

  test("a password with quotes and backslashes is stored as typed, not interpreted", async () => {
    const odd = `it's a "tricky" pass\\word 0123456789`;
    await prepareDatabase(adminUrl, odd);
    const app = asApp(odd);
    expect(await app`select 1 as one`).toEqual([{ one: 1 }]);
    await app.end();
  });
});

describe("ensureAppRole", () => {
  test("creates the role and nothing else: no tables, so a dump can be restored over it", async () => {
    const empty = await startBareDatabase();
    try {
      await ensureAppRole(empty.adminUrl, PASSWORD);
      const admin = postgres(empty.adminUrl, { max: 1, onnotice: () => {} });
      const [role] =
        await admin`select rolsuper, rolbypassrls from pg_roles where rolname = 'lukas_app'`;
      expect(role).toEqual({ rolsuper: false, rolbypassrls: false });
      expect(await admin`select tablename from pg_tables where schemaname = 'public'`).toHaveLength(
        0,
      );
      await admin.end();
    } finally {
      await empty.stop();
    }
  });
});
