/**
 * What the two parity scripts share (docs/mobile/parity.md): the list of pairs in
 * apps/mobile/test/parity/parity.json, the pinned clock, the phone's size, and opening a story of
 * the static Storybook build in Playwright the same way every time.
 *
 * - `parity-fixtures.ts` saves the JSON answers of each story's own fake API, for the app's test.
 * - `parity-shots.ts` saves each story as the phone shows it, next to the app's golden.
 */
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync, statSync } from "node:fs";
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { extname, join, normalize, sep } from "node:path";
import { fileURLToPath } from "node:url";
import type { Browser, BrowserContext, Page } from "playwright";
import { fakeClock } from "../app/demo/fake-clock.ts";

/** apps/web. */
export const WEB_DIR = fileURLToPath(new URL("..", import.meta.url));
/** apps/mobile/test/parity: parity.json, fixtures/, web/ (these shots), app/ (the goldens), fonts/. */
export const PARITY_DIR = fileURLToPath(new URL("../../mobile/test/parity/", import.meta.url));
/** Where the parity scripts build Storybook (git-ignored, like `storybook build`'s default). */
export const STORYBOOK_DIR = join(WEB_DIR, "storybook-static");

/**
 * The parity "now", in the story pages and in the fixtures: the e2e suite's (E2E_NOW in
 * e2e/helpers.ts), 21 October 2026 at 15:00 UTC. The stories' "today" (STORY_TODAY) and month are
 * read from the clock when the page loads, so the shots and the fixtures pin it before anything runs.
 */
export const PARITY_NOW = "2026-10-21T15:00:00Z";
/** The made-up person's time zone (STORY_TIMEZONE in features/home/story-harness.tsx). */
export const PARITY_TIMEZONE = "Europe/Madrid";

/** The phone: 412 × 915 CSS pixels at a device pixel ratio of 2 (spec §4). */
export const VIEWPORT = { width: 412, height: 915 } as const;
export const SCALE = 2;

export type ParityTheme = "night" | "day";

/** One pair: a web story in one theme and the app test that renders its golden. */
export interface ParityPair {
  /** File name stem: the shot is web/<id>-<theme>.png, the golden app/<id>-<theme>.png. */
  id: string;
  /** Storybook story id, e.g. `ui-money--spanish`. */
  storyId: string;
  theme: ParityTheme;
  /** The Flutter test that renders the app's side, from apps/mobile. */
  appTest: string;
}

const ID = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const STORY_ID = /^[a-z0-9-]+--[a-z0-9-]+$/;

/** parity.json's pairs, checked: known fields, kebab-case ids, each id and theme once. */
export function parsePairs(json: unknown): ParityPair[] {
  if (!Array.isArray(json)) throw new Error("parity.json must be a list of pairs");
  const seen = new Set<string>();
  return json.map((entry, i) => {
    const pair = entry as Partial<ParityPair>;
    const where = `parity.json[${i}]`;
    if (typeof pair.id !== "string" || !ID.test(pair.id)) {
      throw new Error(`${where}: id must be kebab-case, got ${JSON.stringify(pair.id)}`);
    }
    if (typeof pair.storyId !== "string" || !STORY_ID.test(pair.storyId)) {
      throw new Error(
        `${where}: storyId must be a Storybook id, got ${JSON.stringify(pair.storyId)}`,
      );
    }
    if (pair.theme !== "night" && pair.theme !== "day") {
      throw new Error(
        `${where}: theme must be "night" or "day", got ${JSON.stringify(pair.theme)}`,
      );
    }
    if (typeof pair.appTest !== "string" || !pair.appTest.endsWith("_test.dart")) {
      throw new Error(`${where}: appTest must be a Flutter test file`);
    }
    const key = `${pair.id}-${pair.theme}`;
    if (seen.has(key)) throw new Error(`${where}: ${key} is listed twice`);
    seen.add(key);
    return { id: pair.id, storyId: pair.storyId, theme: pair.theme, appTest: pair.appTest };
  });
}

/** The pairs in apps/mobile/test/parity/parity.json; `only` keeps those whose id contains it. */
export function readPairs(only?: string): ParityPair[] {
  const pairs = parsePairs(JSON.parse(readFileSync(join(PARITY_DIR, "parity.json"), "utf8")));
  return only ? pairs.filter((pair) => pair.id.includes(only)) : pairs;
}

/**
 * A story alone in Storybook's iframe, in the theme the toolbar would pick (preview.tsx reads the
 * `theme` global; a story that pins its own `globals.theme` keeps it).
 */
export function storyUrl(base: string, storyId: string, theme: ParityTheme): string {
  return `${base}/iframe.html?id=${encodeURIComponent(storyId)}&viewMode=story&globals=theme:${theme}`;
}

/** Builds the static Storybook into storybook-static/ (a few seconds). */
export function buildStorybook(): void {
  const run = spawnSync("pnpm", ["exec", "storybook", "build", "-o", STORYBOOK_DIR, "--quiet"], {
    cwd: WEB_DIR,
    stdio: ["ignore", "ignore", "inherit"],
  });
  if (run.status !== 0) throw new Error(`storybook build failed (exit ${run.status})`);
}

const TYPES: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json",
  ".png": "image/png",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf",
  ".mp3": "audio/mpeg",
};

/**
 * Serves the static Storybook on a free local port, plus the shared emoji font at
 * `/__parity/emoji.ttf`, until `close`.
 */
export async function serveStorybook(): Promise<{ base: string; close: () => Promise<void> }> {
  const root = STORYBOOK_DIR;
  if (!existsSync(join(root, "iframe.html"))) throw new Error(`No Storybook build in ${root}`);
  const server = createServer((req, res) => {
    const { pathname } = new URL(req.url ?? "/", "http://localhost");
    const file =
      pathname === EMOJI_FONT_PATH
        ? EMOJI_FONT_FILE
        : pathname === DINGBATS_FONT_PATH
          ? DINGBATS_FONT_FILE
          : normalize(join(root, decodeURIComponent(pathname)));
    if (file !== EMOJI_FONT_FILE && file !== DINGBATS_FONT_FILE && !file.startsWith(root + sep)) {
      res.writeHead(403).end();
      return;
    }
    if (!existsSync(file) || !statSync(file).isFile()) {
      res.writeHead(404).end();
      return;
    }
    res.writeHead(200, { "content-type": TYPES[extname(file)] ?? "application/octet-stream" });
    res.end(readFileSync(file));
  });
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address() as AddressInfo;
  return {
    base: `http://127.0.0.1:${port}`,
    close: () => new Promise((resolve) => server.close(() => resolve())),
  };
}

/**
 * Noto Color Emoji (SIL OFL 1.1), committed with the app's parity tests: the app's goldens draw
 * emoji with it, and so do the shots, instead of the Mac's own emoji font.
 */
export const EMOJI_FONT_FILE = join(PARITY_DIR, "fonts", "NotoColorEmoji.ttf");
const EMOJI_FONT_PATH = "/__parity/emoji.ttf";

/**
 * The ✓ of the "Pagado" badge is in no web font of the app, so Chrome on the Mac falls back to
 * Zapf Dingbats and thickens it, because the badge asks for weight 900 and that font has one
 * weight. Flutter's tests thicken nothing, so both sides draw the check from this one file at its
 * own weight, as they draw emoji from the shared emoji font. It is Apple's, so it is read from
 * the Mac the shots are taken on (the pictures are the Mac's, docs/mobile/parity.md), never
 * committed.
 */
export const DINGBATS_FONT_FILE = "/System/Library/Fonts/ZapfDingbats.ttf";
const DINGBATS_FONT_PATH = "/__parity/dingbats.ttf";

/**
 * The emoji code points (Unicode's emoji blocks, the dingbats and arrows that have emoji forms,
 * the variation selector and the joiner), and none a text font draws: Latin, digits, ©, ®, ™.
 */
export const EMOJI_UNICODE_RANGE = [
  "U+200D",
  "U+203C",
  "U+2049",
  "U+20E3",
  "U+2139",
  "U+2194-2199",
  "U+21A9-21AA",
  "U+231A-231B",
  "U+2328",
  "U+23CF",
  "U+23E9-23F3",
  "U+23F8-23FA",
  "U+24C2",
  "U+25AA-25AB",
  "U+25B6",
  "U+25C0",
  "U+25FB-25FE",
  "U+2600-27BF",
  "U+2934-2935",
  "U+2B05-2B07",
  "U+2B1B-2B1C",
  "U+2B50",
  "U+2B55",
  "U+3030",
  "U+303D",
  "U+3297",
  "U+3299",
  "U+FE0F",
  "U+1F000-1FAFF",
  "U+E0020-E007F",
].join(", ");

/**
 * Runs in the page before anything else: moves its clock to `now` with the demo stories' own
 * `fakeClock` (app/demo/fake-clock.ts), which shifts `new Date()` and `Date.now()` and leaves
 * timers and animation frames on real time. (`__name` stands in for the helper the TypeScript
 * loader may wrap named functions in.)
 */
export function clockScript(now: string): string {
  return `(() => {
  const __name = (target) => target;
  (${fakeClock.toString()})(new Date(${JSON.stringify(now)}));
})();`;
}

/** A phone-sized page: 412 × 915 at 2×, touch, in Madrid, at the parity "now". */
export async function phoneContext(browser: Browser): Promise<BrowserContext> {
  const context = await browser.newContext({
    viewport: VIEWPORT,
    deviceScaleFactor: SCALE,
    isMobile: true,
    hasTouch: true,
    timezoneId: PARITY_TIMEZONE,
    locale: "es-ES",
    colorScheme: "dark",
    reducedMotion: "no-preference",
  });
  await context.addInitScript({ content: clockScript(PARITY_NOW) });
  return context;
}

/**
 * Opens a story and waits until Storybook has rendered it, run its play function and waited for
 * its animations (the "finished" phase). Throws when the story or its play function failed, or
 * when the page is not in the pair's theme (a story that pins the other one).
 */
export async function openStory(context: BrowserContext, base: string, pair: ParityPair) {
  const page = await context.newPage();
  const errors: string[] = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto(storyUrl(base, pair.storyId, pair.theme));
  await page.waitForFunction(
    () => {
      const preview = (window as { __STORYBOOK_PREVIEW__?: { currentRender?: { phase?: string } } })
        .__STORYBOOK_PREVIEW__;
      return preview?.currentRender?.phase === "finished";
    },
    undefined,
    { timeout: 60_000, polling: 100 },
  );
  const failed = await page.evaluate(
    () =>
      document.body.classList.contains("sb-show-errordisplay") ||
      document.body.classList.contains("sb-show-nopreview"),
  );
  if (failed) {
    const message = await page.locator("#error-message, #error-stack").allInnerTexts();
    throw new Error(`${pair.storyId} failed to render: ${message.join("\n") || errors.join("\n")}`);
  }
  const theme = await page.evaluate(() => document.documentElement.dataset.theme);
  if (theme !== pair.theme) {
    throw new Error(`${pair.storyId} shows the ${theme} theme, not ${pair.theme}: fix parity.json`);
  }
  return { page, errors };
}

/**
 * Draws emoji with the shared Noto Color Emoji: adds it to every face of the page's font families
 * (Fredoka, Nunito, …) for the emoji code points only, with the face's own weight and style, so
 * it comes before the system's emoji font in any text. Then waits for the fonts.
 */
export async function useParityEmoji(page: Page): Promise<void> {
  await page.evaluate(
    async ({ url, range, dingbatsUrl }) => {
      await document.fonts.ready;
      const faces = new Map<string, FontFace>();
      for (const face of document.fonts) {
        if (face.family.includes("Parity")) continue;
        faces.set(`${face.family}|${face.weight}|${face.style}|${face.stretch}`, face);
      }
      for (const face of faces.values()) {
        const emoji = new FontFace(face.family, `url(${url})`, {
          weight: face.weight,
          style: face.style,
          stretch: face.stretch,
          unicodeRange: range,
        });
        document.fonts.add(emoji);
        await emoji.load();
      }
      // The check mark (U+2713) comes from the dingbats font; declared after the emoji one, it is
      // tried first, and it is the face's own weight, so nothing is thickened.
      for (const face of faces.values()) {
        const dingbats = new FontFace(face.family, `url(${dingbatsUrl})`, {
          weight: face.weight,
          style: face.style,
          stretch: face.stretch,
          unicodeRange: "U+2713",
        });
        document.fonts.add(dingbats);
        await dingbats.load();
      }
      await document.fonts.ready;
    },
    { url: EMOJI_FONT_PATH, range: EMOJI_UNICODE_RANGE, dingbatsUrl: DINGBATS_FONT_PATH },
  );
}
