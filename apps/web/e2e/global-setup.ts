import { E2E_NOW } from "./helpers.ts";

/**
 * Before the app flows run (playwright.config.ts): the dev stack (`docker compose up -d`) must be
 * up. Waits for the API's health check and for Mailpit, which `docker compose up -d` leaves still
 * starting (the API applies migrations first), and checks that the API's clock is pinned to the
 * suite's "now" (E2E_NOW in helpers.ts): otherwise the specs that read the sample's months would
 * depend on the real date. In CI an unpinned API fails the run; locally it is a warning, so the
 * suite still runs against a stack started without it.
 */

const API = process.env.E2E_API_URL ?? "http://localhost:3000";
const MAILPIT = process.env.MAILPIT_URL ?? "http://localhost:8025";
const WAIT_MS = Number(process.env.E2E_STACK_WAIT_MS ?? 120_000);

async function waitFor<T>(what: string, probe: () => Promise<T | undefined>): Promise<T> {
  const deadline = Date.now() + WAIT_MS;
  let last: unknown;
  while (Date.now() < deadline) {
    try {
      const value = await probe();
      if (value !== undefined) return value;
    } catch (error) {
      last = error;
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(
    `${what} did not answer within ${WAIT_MS / 1000} s. Start the dev stack first: ` +
      `E2E_NOW=${E2E_NOW} docker compose up -d --build${last ? ` (last error: ${String(last)})` : ""}`,
  );
}

async function json(url: string): Promise<unknown> {
  const response = await fetch(url);
  return response.ok ? response.json() : undefined;
}

export default async function globalSetup() {
  const health = (await waitFor(`The API (${API}/api/health)`, () =>
    json(`${API}/api/health`),
  )) as { status: string; now?: string };
  await waitFor(`Mailpit (${MAILPIT})`, () => json(`${MAILPIT}/api/v1/info`));

  const expected = new Date(E2E_NOW).toISOString();
  if (health.now !== expected) {
    const message =
      `The API's clock is ${health.now ? `pinned to ${health.now}` : "the real one"}, not ` +
      `${expected}. Restart it with E2E_NOW=${E2E_NOW} docker compose up -d --build api.`;
    if (process.env.CI) throw new Error(message);
    console.warn(`\n[e2e] ${message} Specs that read the sample's months may fail.\n`);
  }
}
