/**
 * The web half of each parity pair (docs/mobile/parity.md): every story in
 * apps/mobile/test/parity/parity.json as the phone shows it, saved as
 * test/parity/web/<id>-<theme>.png beside the app's golden (test/parity/app/<id>-<theme>.png).
 *
 * Builds the static Storybook and opens each story alone (its iframe) at 412 × 915 CSS pixels and
 * a device pixel ratio of 2, in the pair's theme (the toolbar's `theme` global), with the clock
 * pinned to the parity "now" as the fixtures are. Once Storybook says the story has rendered,
 * played and finished its animations, emoji move onto the shared Noto Color Emoji, and the page
 * is taken when two pictures in a row come out the same, with CSS animations at rest.
 *
 *   pnpm --filter @lukas/web parity:shots [id filter]
 */
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { chromium, type Page } from "playwright";
import {
  buildStorybook,
  openStory,
  PARITY_DIR,
  phoneContext,
  readPairs,
  serveStorybook,
  useParityEmoji,
} from "./parity-storybook.ts";

/**
 * Pictures of the page until two in a row are the same (fonts in, transitions done). CSS
 * animations are taken at rest: a finite one at its end, an endless one (Lukitas' sprite) at its
 * first frame, as Playwright's `animations: "disabled"` does.
 */
async function settledShot(page: Page, tries = 20): Promise<Buffer> {
  const shoot = () => page.screenshot({ animations: "disabled", caret: "hide" });
  let last = await shoot();
  for (let i = 0; i < tries; i++) {
    await page.waitForTimeout(150);
    const next = await shoot();
    if (next.equals(last)) return next;
    last = next;
  }
  throw new Error(`the page kept changing for ${tries} pictures (an endless animation?)`);
}

async function main() {
  const pairs = readPairs(process.argv[2]);
  buildStorybook();
  const server = await serveStorybook();
  const browser = await chromium.launch();
  try {
    mkdirSync(join(PARITY_DIR, "web"), { recursive: true });
    for (const pair of pairs) {
      // A fresh page each time: nothing a story stored reaches the next one.
      const context = await phoneContext(browser);
      const { page, errors } = await openStory(context, server.base, pair);
      await useParityEmoji(page);
      const shot = await settledShot(page);
      const file = join(PARITY_DIR, "web", `${pair.id}-${pair.theme}.png`);
      writeFileSync(file, shot);
      await context.close();
      console.log(`${pair.id}-${pair.theme}: ${pair.storyId}`);
      for (const error of errors) console.warn(`  page error: ${error}`);
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
