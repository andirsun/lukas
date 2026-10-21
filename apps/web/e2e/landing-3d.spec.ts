import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { gzipSync } from "node:zlib";
import { expect, type Page, test } from "@playwright/test";

/**
 * The 3D Lukas on the built landing page, with JavaScript on: it loads lazily once the page is
 * idle, travels with the scroll and never stands in the way; the prerendered 2D Lukas stays under
 * reduced motion, without WebGL and on low-memory devices. Also the JavaScript budget of `/`.
 */

test.use({ javaScriptEnabled: true });
// WebGL runs on the CPU in headless Chromium: keep this file's pages one at a time per project,
// and give them time on a loaded machine.
test.describe.configure({ mode: "default", timeout: 60_000 });

const CLIENT = fileURLToPath(new URL("../build/client/", import.meta.url));
const BUDGET_GZIP = 300 * 1024;

/** Collects console errors and page errors for the whole test. */
function collectErrors(page: Page): string[] {
  const errors: string[] = [];
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  page.on("pageerror", (error) => errors.push(error.message));
  return errors;
}

/** Gives the lazy loader time to decide (idle callback + chunk) before asserting an absence. */
async function settle(page: Page) {
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(1500);
}

test.describe("3D Lukas", () => {
  test("a canvas takes over the hero after load, without blocking the page", async ({ page }) => {
    const errors = collectErrors(page);
    await page.goto("/");
    const layer = page.locator("[data-lukas3d-layer]");
    await expect(layer.locator("canvas")).toBeVisible({ timeout: 30_000 });
    await expect(layer).toHaveAttribute("aria-hidden", "true");
    await expect(layer).toHaveAttribute("data-pose", "wave");
    await expect(page.locator("html")).toHaveAttribute("data-lukas3d", "live");

    // He stands where the 2D Lukas was; the slot keeps its accessible name, the sprite hides.
    const slot = page.locator("#hero [data-slot='hero-mascot']");
    await expect(slot).toHaveAttribute("role", "img");
    await expect(slot.locator(".lk-lukas")).toBeHidden();
    const [slotBox, layerBox] = [await slot.boundingBox(), await layer.boundingBox()];
    expect(slotBox && layerBox).toBeTruthy();
    if (slotBox && layerBox) {
      const center = (b: { x: number; y: number; width: number; height: number }) => ({
        x: b.x + b.width / 2,
        y: b.y + b.height / 2,
      });
      expect(Math.abs(center(slotBox).x - center(layerBox).x)).toBeLessThan(8);
      expect(Math.abs(center(slotBox).y - center(layerBox).y)).toBeLessThan(8);
    }

    // His body takes the pointer: a hover makes him jump, a tap spins him (and nothing breaks).
    const body = layer.locator(".lk-lukas3d-hit");
    await expect(body).toHaveCSS("pointer-events", "auto");
    await body.hover();
    await body.click();
    await expect(page).toHaveURL(/\/$/);

    // The primary action under the canvas layer still gets the click.
    const cta = page.locator("#hero").getByRole("link", { name: "Empieza ahora" });
    const hit = await cta.evaluate((el) => {
      const box = el.getBoundingClientRect();
      const top = document.elementFromPoint(box.x + box.width / 2, box.y + box.height / 2);
      return top === el || el.contains(top);
    });
    expect(hit).toBe(true);
    expect(errors).toEqual([]);
  });

  test("travels with the scroll and celebrates next to the final call to action", async ({
    page,
  }) => {
    const errors = collectErrors(page);
    await page.goto("/");
    const layer = page.locator("[data-lukas3d-layer]");
    await expect(layer.locator("canvas")).toBeVisible({ timeout: 30_000 });

    await page.locator("#how").scrollIntoViewIfNeeded();
    await page.evaluate(() =>
      document.querySelector("#how")?.scrollIntoView({ block: "start", behavior: "instant" }),
    );
    await expect(layer).not.toHaveAttribute("data-pose", "wave");

    await page.evaluate(() =>
      window.scrollTo({ top: document.documentElement.scrollHeight, behavior: "instant" }),
    );
    await expect(layer).toHaveAttribute("data-pose", "celebrate");
    const closing = page.locator("[data-lukas-spot='closing']");
    await expect(closing.locator(".lk-lukas")).toBeHidden();
    await expect
      .poll(async () => {
        const [spot, box] = [await closing.boundingBox(), await layer.boundingBox()];
        if (!spot || !box) return Number.POSITIVE_INFINITY;
        return Math.abs(spot.y + spot.height / 2 - (box.y + box.height / 2));
      })
      .toBeLessThan(8);

    // Nothing on the page is covered for clicks: the closing button still gets them.
    const cta = page.locator("#closing").getByRole("link");
    await cta.scrollIntoViewIfNeeded();
    const hit = await cta.evaluate((el) => {
      const box = el.getBoundingClientRect();
      const top = document.elementFromPoint(box.x + box.width / 2, box.y + box.height / 2);
      return top === el || el.contains(top);
    });
    expect(hit).toBe(true);
    expect(errors).toEqual([]);
  });

  test("rolls in once per session, then waves", async ({ page }) => {
    await page.goto("/");
    const layer = page.locator("[data-lukas3d-layer]");
    await expect(layer.locator("canvas")).toBeVisible({ timeout: 30_000 });
    // The text was there first: he only arrives after the page has rendered.
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    await expect(layer).toHaveAttribute("data-entrance", /playing|done/);
    await expect(layer).toHaveAttribute("data-entrance", "done", { timeout: 15_000 });
    await expect(layer).toHaveAttribute("data-pose", "wave");
    expect(await page.evaluate(() => sessionStorage.getItem("lukas:entrance"))).toBe("seen");

    // Same session: no second entrance.
    await page.reload();
    await expect(layer.locator("canvas")).toBeVisible({ timeout: 30_000 });
    await expect(layer).toHaveAttribute("data-entrance", "skipped");
  });

  test("skips the entrance when this session has seen it", async ({ page }) => {
    await page.addInitScript(() => sessionStorage.setItem("lukas:entrance", "seen"));
    await page.goto("/");
    const layer = page.locator("[data-lukas3d-layer]");
    await expect(layer.locator("canvas")).toBeVisible({ timeout: 30_000 });
    await expect(layer).toHaveAttribute("data-entrance", "skipped");
    await expect(layer.locator(".lk-lukas3d-stage")).toHaveCSS("transform", "none");
  });

  test("skips the entrance when the page is already past the hero", async ({ page }) => {
    // The fragment scrolls the page down while it loads, before the 3D Lukas can.
    await page.goto("/#closing");
    const layer = page.locator("[data-lukas3d-layer]");
    await expect(layer).toHaveAttribute("data-entrance", "skipped", { timeout: 30_000 });
    await expect(layer).toHaveAttribute("data-pose", "celebrate");
  });

  test("stops drawing while he is off screen", async ({ page }, testInfo) => {
    // The phone's "how it works" is a long column of cards: well into it, his spot (at its top)
    // has scrolled away and the next one hasn't arrived yet.
    test.skip(testInfo.project.name !== "built-phone", "needs the phone's long section");
    await page.goto("/");
    const layer = page.locator("[data-lukas3d-layer]");
    await expect(layer.locator("canvas")).toBeVisible({ timeout: 30_000 });
    await expect(layer).toHaveAttribute("data-rendering", "running");
    await page.evaluate(() => {
      const spot = document.querySelector("[data-lukas-spot='how']") as HTMLElement;
      const top = spot.getBoundingClientRect().top + window.scrollY;
      window.scrollTo({ top: top + 700, behavior: "instant" });
    });
    await expect(layer).toHaveAttribute("data-pose", "carry");
    await expect(layer).toHaveAttribute("data-rendering", "paused");
    await expect(layer).not.toBeInViewport();

    await page.evaluate(() => window.scrollTo({ top: 0, behavior: "instant" }));
    await expect(layer).toHaveAttribute("data-rendering", "running");
    await expect(layer).toHaveAttribute("data-pose", "wave");
  });

  test("keeps the still image under reduced motion", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.goto("/");
    await settle(page);
    await expect(page.locator("canvas")).toHaveCount(0);
    const sprite = page.locator("#hero [data-slot='hero-mascot'] .lk-lukas-sprite");
    await expect(sprite).toBeVisible();
    expect(await sprite.evaluate((el) => el.getAnimations().length)).toBe(0);
  });

  test("keeps the still image without WebGL", async ({ page }) => {
    await page.addInitScript(() => {
      const original = HTMLCanvasElement.prototype.getContext;
      HTMLCanvasElement.prototype.getContext = function (this: HTMLCanvasElement, ...args) {
        const [kind] = args;
        if (typeof kind === "string" && kind.startsWith("webgl")) return null;
        return original.apply(this, args as Parameters<typeof original>);
      } as typeof original;
    });
    await page.goto("/");
    await settle(page);
    await expect(page.locator("canvas")).toHaveCount(0);
    await expect(page.locator("#hero [data-slot='hero-mascot'] .lk-lukas")).toBeVisible();
  });

  test("keeps the still image on low-memory devices", async ({ page }) => {
    await page.addInitScript(() => {
      Object.defineProperty(Navigator.prototype, "deviceMemory", { get: () => 2 });
    });
    await page.goto("/");
    await settle(page);
    await expect(page.locator("canvas")).toHaveCount(0);
    await expect(page.locator("#hero [data-slot='hero-mascot'] .lk-lukas")).toBeVisible();
  });
});

interface ManifestChunk {
  file: string;
  src?: string;
  isEntry?: boolean;
  isDynamicEntry?: boolean;
  imports?: string[];
  dynamicImports?: string[];
}

test.describe("JavaScript budget", () => {
  test("the initial JavaScript of / stays under 300 KB gzipped; 3D loads lazily", async ({
    request,
  }, testInfo) => {
    const manifest = JSON.parse(readFileSync(`${CLIENT}.vite/manifest.json`, "utf8")) as Record<
      string,
      ManifestChunk
    >;
    const byFile = new Map(Object.entries(manifest).map(([key, chunk]) => [chunk.file, key]));

    // What the prerendered page loads: its module scripts and modulepreloads, plus everything
    // they import statically (never their dynamic imports: those load on demand).
    const html = await (await request.get("/")).text();
    const urls = [
      ...html.matchAll(/<(?:script|link)[^>]+(?:src|href)="\/(assets\/[^"]+\.js)"/g),
      ...html.matchAll(/import\(?\s*"\/(assets\/[^"]+\.js)"/g),
      ...html.matchAll(/from\s*"\/(assets\/[^"]+\.js)"/g),
    ].map((m) => m[1] as string);
    expect(urls.length).toBeGreaterThan(0);

    const initial = new Set<string>();
    const visit = (key: string) => {
      const chunk = manifest[key];
      if (!chunk || initial.has(chunk.file)) return;
      initial.add(chunk.file);
      for (const next of chunk.imports ?? []) visit(next);
    };
    for (const url of urls) {
      const key = byFile.get(url);
      // React Router's route manifest (assets/manifest-*.js) is written after Vite's: count it as is.
      if (key) visit(key);
      else initial.add(url);
    }
    expect([...initial].some((file) => manifest[byFile.get(file) ?? ""]?.isEntry)).toBe(true);

    // The 3D chunk is a dynamic import only, and three.js never reaches the initial set.
    const lazy = Object.entries(manifest).find(([key]) =>
      key.endsWith("app/lukas/experimental/Lukas3D.tsx"),
    );
    expect(lazy, "Lukas3D is its own chunk").toBeDefined();
    const [lazyKey, lazyChunk] = lazy as [string, ManifestChunk];
    expect(lazyChunk.isDynamicEntry).toBe(true);
    expect(initial.has(lazyChunk.file)).toBe(false);
    for (const file of initial) {
      const source = manifest[byFile.get(file) ?? ""]?.src ?? "";
      expect(source).not.toMatch(/node_modules\/(three|@react-three)\//);
    }

    const inline = [...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)]
      .map((m) => m[1] ?? "")
      .join("\n");
    const gzip = (text: string | Buffer) => gzipSync(text, { level: 9 }).length;
    const initialBytes =
      [...initial].reduce((sum, file) => sum + gzip(readFileSync(`${CLIENT}${file}`)), 0) +
      gzip(inline);

    // The lazy part: the 3D chunk and what only it pulls in.
    const lazyFiles = new Set<string>();
    const visitLazy = (key: string) => {
      const chunk = manifest[key];
      if (!chunk || initial.has(chunk.file) || lazyFiles.has(chunk.file)) return;
      lazyFiles.add(chunk.file);
      for (const next of chunk.imports ?? []) visitLazy(next);
    };
    visitLazy(lazyKey);
    const lazyBytes = [...lazyFiles].reduce(
      (sum, file) => sum + gzip(readFileSync(`${CLIENT}${file}`)),
      0,
    );
    testInfo.annotations.push({
      type: "js-budget",
      description: `initial ${(initialBytes / 1024).toFixed(1)} KB gz (${initial.size} files); lazy 3D ${(lazyBytes / 1024).toFixed(1)} KB gz (${lazyFiles.size} files)`,
    });
    console.log(testInfo.annotations.at(-1)?.description);
    expect(initialBytes).toBeLessThan(BUDGET_GZIP);
  });
});
