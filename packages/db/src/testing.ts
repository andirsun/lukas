import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { createServer } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { PostgreSqlContainer } from "@testcontainers/postgresql";
import postgres from "postgres";
import { runMigrations } from "./migrate.ts";

const exec = promisify(execFile);
// Postgres refuses to start on macOS without a valid locale in the environment.
const run = (cmd: string, args: string[]) =>
  exec(cmd, args, { env: { ...process.env, LC_ALL: "C", LANG: "C" } });
const INIT_SQL = new URL("../../../docker/postgres/init.sql", import.meta.url);

interface TestDatabase {
  adminUrl: string;
  appUrl: string;
  stop(): Promise<void>;
}

/** A throwaway Postgres with nothing in it: no `lukas_app` role, no tables. */
export async function startBareDatabase(): Promise<Pick<TestDatabase, "adminUrl" | "stop">> {
  return process.env.LUKAS_TEST_DB === "local" ? startLocalCluster() : startContainer();
}

/**
 * Starts a throwaway Postgres with the `lukas_app` role and all migrations applied.
 * Uses a Docker container by default; set LUKAS_TEST_DB=local to use the `initdb`/`pg_ctl`
 * binaries on PATH instead (handy when Docker is not running).
 */
export async function startTestDatabase(): Promise<TestDatabase> {
  const { adminUrl, stop } =
    process.env.LUKAS_TEST_DB === "local" ? await startLocalCluster() : await startContainer();
  const admin = postgres(adminUrl, { max: 1, onnotice: () => {} });
  await admin.unsafe(await readFile(INIT_SQL, "utf8"));
  await admin.end();
  await runMigrations(adminUrl);
  const app = new URL(adminUrl);
  app.username = "lukas_app";
  app.password = "lukas_app";
  return { adminUrl, appUrl: app.toString(), stop };
}

async function startContainer() {
  const container = await new PostgreSqlContainer("postgres:17-alpine").start();
  return {
    adminUrl: container.getConnectionUri(),
    stop: async () => {
      await container.stop();
    },
  };
}

async function freePort(): Promise<number> {
  return new Promise((resolve, reject) => {
    const server = createServer().listen(0, "127.0.0.1", () => {
      const address = server.address();
      server.close(() =>
        typeof address === "object" && address ? resolve(address.port) : reject(),
      );
    });
  });
}

async function startLocalCluster() {
  const dir = await mkdtemp(join(tmpdir(), "lukas-pg-"));
  const data = join(dir, "data");
  const port = await freePort();
  await run("initdb", ["-D", data, "-U", "postgres", "--auth=trust", "-E", "UTF8"]);
  await run("pg_ctl", [
    "-D",
    data,
    "-l",
    join(dir, "log"),
    "-o",
    `-p ${port} -c listen_addresses=127.0.0.1 -c unix_socket_directories=`,
    "-w",
    "start",
  ]);
  return {
    adminUrl: `postgres://postgres@127.0.0.1:${port}/postgres`,
    stop: async () => {
      await run("pg_ctl", ["-D", data, "-m", "immediate", "-w", "stop"]);
      await rm(dir, { recursive: true, force: true });
    },
  };
}
