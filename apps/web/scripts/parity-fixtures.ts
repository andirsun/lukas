/**
 * The parity fixtures (docs/mobile/parity.md): for each story in apps/mobile/test/parity/parity.json,
 * the JSON its own fake API answers, saved as test/parity/fixtures/<storyId>.json for the app's
 * golden, so both sides draw the same movements, budgets and names (spec §4's shared export).
 *
 * Each story is opened in the static Storybook, with the page's clock pinned to the parity "now"
 * (the demo's fakeClock), exactly as `parity-shots.ts` opens it: its harness builds its fake API
 * with the story's own options, the story renders and plays, and then every GET the story made and
 * every GET in APP_GETS is asked again of that same API. A story without a fake API (a component's)
 * gets a fixture with the clock and no answers.
 *
 *   pnpm --filter @lukas/web parity:fixtures [id filter]
 */
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { monthOf, todayIn } from "@lukas/core";
import { chromium } from "playwright";
import {
  buildStorybook,
  openStory,
  PARITY_DIR,
  PARITY_NOW,
  PARITY_TIMEZONE,
  type ParityPair,
  phoneContext,
  readPairs,
  serveStorybook,
} from "./parity-storybook.ts";

const MONTH = monthOf(todayIn(PARITY_TIMEZONE, new Date(PARITY_NOW)));

/**
 * The GETs the app's screens make (apps/mobile/lib/*_repository.dart), with the month the parity
 * clock is in. A task that brings a screen to parity adds the GETs that screen makes.
 */
export const APP_GETS = [
  "/v1/me",
  "/v1/categories",
  `/v1/summary?month=${MONTH}`,
  `/v1/transactions?month=${MONTH}&limit=50`,
  "/v1/recurrences",
];

/**
 * The fixture's key for a request: the API's path (without the web's `/api` mount) and its query
 * with the parameters sorted, so `?b=2&a=1` and `?a=1&b=2` are one answer. The app's
 * ParityFixtures (test/support/parity.dart) builds the same key.
 */
export function fixtureKey(pathAndQuery: string): string {
  const url = new URL(pathAndQuery, "http://parity.invalid");
  const path = url.pathname.replace(/^\/api(?=\/v1\/)/, "");
  const query = [...url.searchParams.entries()]
    .sort(([a, x], [b, y]) => (a === b ? (x < y ? -1 : 1) : a < b ? -1 : 1))
    .map(([name, value]) => `${encodeURIComponent(name)}=${encodeURIComponent(value)}`)
    .join("&");
  return query ? `${path}?${query}` : path;
}

export interface ParityFixture {
  storyId: string;
  /** The page's clock when the story ran: the app test pins its own to it. */
  now: string;
  timezone: string;
  /** Whether the story has a fake API at all (a component's story has none). */
  api: boolean;
  /** `GET <key>` → the status and JSON body the story's fake API answered. */
  responses: Record<string, { status: number; body: unknown }>;
}

async function fixtureOf(
  context: Parameters<typeof openStory>[0],
  base: string,
  pair: ParityPair,
): Promise<ParityFixture> {
  const { page } = await openStory(context, base, pair);
  const answers = await page.evaluate(async (appGets) => {
    const api = window.__lukasStoryFetch;
    if (!api) return null;
    const asked = [...(window.__lukasStoryGets ?? [])].map((path) => path.replace(/^\/api/, ""));
    const out: { path: string; status: number; body: unknown }[] = [];
    for (const path of new Set([...asked, ...appGets])) {
      const response = await api(new Request(new URL(`/api${path}`, location.href)));
      const text = await response.text();
      out.push({ path, status: response.status, body: text ? JSON.parse(text) : null });
    }
    return out;
  }, APP_GETS);
  await page.close();
  const responses: ParityFixture["responses"] = {};
  for (const { path, status, body } of (answers ?? []).sort((a, b) =>
    fixtureKey(a.path) < fixtureKey(b.path) ? -1 : 1,
  )) {
    responses[`GET ${fixtureKey(path)}`] = { status, body };
  }
  return {
    storyId: pair.storyId,
    now: new Date(PARITY_NOW).toISOString(),
    timezone: PARITY_TIMEZONE,
    api: answers !== null,
    responses,
  };
}

async function main() {
  const pairs = readPairs(process.argv[2]);
  // One fixture per story, whatever the theme: the data does not change with it.
  const stories = new Map(pairs.map((pair) => [pair.storyId, pair]));
  buildStorybook();
  const server = await serveStorybook();
  const browser = await chromium.launch();
  try {
    mkdirSync(join(PARITY_DIR, "fixtures"), { recursive: true });
    for (const pair of stories.values()) {
      // A fresh page each time: nothing a story stored reaches the next one.
      const context = await phoneContext(browser);
      const fixture = await fixtureOf(context, server.base, pair);
      await context.close();
      const file = join(PARITY_DIR, "fixtures", `${pair.storyId}.json`);
      writeFileSync(file, `${JSON.stringify(fixture, null, 2)}\n`);
      const count = Object.keys(fixture.responses).length;
      console.log(`${pair.storyId}: ${fixture.api ? `${count} answers` : "no fake API"}`);
    }
  } finally {
    await browser.close();
    await server.close();
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
