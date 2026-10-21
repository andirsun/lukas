import { existsSync, readdirSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { gzipSync } from "node:zlib";
import { expect, type Page, test } from "@playwright/test";

/**
 * The 2.5D Lukas on the built landing page, with JavaScript on: the founder's sprite sheets in an
 * overlay that mounts once the page is idle, rolls in once per session, takes each spot's mood,
 * never stands over text and never takes clicks but on his body; the prerendered 2D Lukas stays
 * under reduced motion. No WebGL, no three.js. Also the JavaScript budget of `/`.
 */

test.use({ javaScriptEnabled: true });
test.describe.configure({ timeout: 60_000 });

const BUILD = fileURLToPath(new URL("../build/", import.meta.url));
const CLIENT = `${BUILD}client/`;
const BUDGET_GZIP = 300 * 1024;
/** A string every three.js build carries (its renderer's class name survives minification). */
const THREE_SIGNATURE = "WebGLRenderer";

/** Collects console errors and page errors for the whole test. */
function collectErrors(page: Page): string[] {
  const errors: string[] = [];
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  page.on("pageerror", (error) => errors.push(error.message));
  return errors;
}

/** Gives the idle loader time to decide before asserting an absence. */
async function settle(page: Page) {
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(1500);
}

/** Scrolls so a spot's center sits where it takes over (40% down the viewport). */
async function scrollToSpot(page: Page, id: string) {
  await page.evaluate((spotId) => {
    const spot = document.querySelector<HTMLElement>(`[data-lukas-spot='${spotId}']`);
    const box = spot?.getBoundingClientRect();
    if (!box) throw new Error(`no spot ${spotId}`);
    const top = box.top + window.scrollY + box.height / 2 - window.innerHeight * 0.4 + 2;
    window.scrollTo({ top, behavior: "instant" });
  }, id);
}

/** The computed sheet of the mood he is showing. */
function activeSheet(page: Page) {
  return page
    .locator("[data-lukas-traveler] .lk-traveler-mood.is-active .lk-lukas-sprite")
    .evaluate((el) => getComputedStyle(el).backgroundImage);
}

/** Whether the element's center gets the pointer (nothing covers it). */
function getsThePointer(page: Page, selector: string) {
  return page.locator(selector).evaluate((el) => {
    const box = el.getBoundingClientRect();
    const top = document.elementFromPoint(box.x + box.width / 2, box.y + box.height / 2);
    return top === el || el.contains(top);
  });
}

async function centerDistance(page: Page, a: string, b: string): Promise<number> {
  const [boxA, boxB] = [await page.locator(a).boundingBox(), await page.locator(b).boundingBox()];
  if (!boxA || !boxB) return Number.POSITIVE_INFINITY;
  return Math.hypot(
    boxA.x + boxA.width / 2 - (boxB.x + boxB.width / 2),
    boxA.y + boxA.height / 2 - (boxB.y + boxB.height / 2),
  );
}

test.describe("2.5D Lukas", () => {
  test("appears after load from the sprite sheets: no canvas, no three.js", async ({ page }) => {
    const errors = collectErrors(page);
    const scripts: string[] = [];
    page.on("response", async (response) => {
      if (response.url().endsWith(".js")) scripts.push(await response.text().catch(() => ""));
    });
    await page.addInitScript(() => sessionStorage.setItem("lukas:entrance", "seen"));
    await page.goto("/");
    const layer = page.locator("[data-lukas-traveler]");
    await expect(layer).toBeVisible({ timeout: 30_000 });
    await expect(layer).toHaveAttribute("aria-hidden", "true");
    await expect(layer).toHaveAttribute("data-spot", "hero");
    await expect(layer).toHaveAttribute("data-mood", "happy");
    await expect(page.locator("html")).toHaveAttribute("data-lukas-live", "live");
    expect(await activeSheet(page)).toContain("/lukas/wave.webp");
    await expect(page.locator("canvas")).toHaveCount(0);
    await page.waitForLoadState("networkidle");
    expect(scripts.length).toBeGreaterThan(0);
    expect(scripts.filter((source) => source.includes(THREE_SIGNATURE))).toEqual([]);

    // He stands where the prerendered Lukas was; the box keeps its accessible name, the sprite hides.
    const slot = page.locator("#hero [data-slot='hero-mascot']");
    await expect(slot).toHaveAttribute("role", "img");
    await expect(slot).toHaveAttribute("aria-label", /.+/);
    await expect(slot.locator(".lk-lukas")).toBeHidden();
    await expect
      .poll(() => centerDistance(page, "#hero [data-slot='hero-mascot']", "[data-lukas-traveler]"))
      .toBeLessThan(8);

    // Only his body takes the pointer: a hover (or tap) makes him hop, and nothing navigates.
    const body = layer.locator(".lk-traveler-hit");
    await expect(layer).toHaveCSS("pointer-events", "none");
    await expect(body).toHaveCSS("pointer-events", "auto");
    await body.hover();
    await body.click();
    await expect(layer.locator(".lk-traveler-hop.is-hopping")).toHaveCount(1);
    await expect(page).toHaveURL(/\/$/);
    expect(await getsThePointer(page, "#hero a.lk-btn")).toBe(true);
    expect(errors).toEqual([]);
  });

  test("rolls in once per session, then waves", async ({ page }) => {
    await page.goto("/");
    const layer = page.locator("[data-lukas-traveler]");
    await expect(layer).toBeAttached({ timeout: 30_000 });
    // The text was there first: he only arrives after the page has rendered.
    await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    await expect(layer).toHaveAttribute("data-entrance", /playing|done/);
    expect(await page.evaluate(() => sessionStorage.getItem("lukas:entrance"))).toBe("seen");
    await expect(layer).toHaveAttribute("data-entrance", "done", { timeout: 15_000 });
    // Standing and waving: the wave sheet plays, nothing tucked or turned.
    await expect(layer.locator(".lk-traveler-body")).toHaveCSS("clip-path", "none");
    await expect(layer.locator(".lk-traveler-roller")).toHaveCSS("transform", "none");
    await expect(layer.locator(".lk-traveler-mood.is-active .lk-lukas-sprite")).toHaveClass(
      /is-playing/,
    );

    // Same session: no second entrance.
    await page.reload();
    await expect(layer).toBeAttached({ timeout: 30_000 });
    await expect(layer).toHaveAttribute("data-entrance", "skipped");
    await expect(layer.locator(".lk-traveler-roller")).toHaveCSS("transform", "none");
  });

  test("skips the entrance when the page is already past the hero", async ({ page }) => {
    // The fragment scrolls the page down while it loads, before he mounts.
    await page.goto("/#closing");
    const layer = page.locator("[data-lukas-traveler]");
    await expect(layer).toHaveAttribute("data-entrance", "skipped", { timeout: 30_000 });
    await expect(layer).toHaveAttribute("data-mood", "celebrating");
  });

  test("is worried in how it works and celebrates next to the final call to action", async ({
    page,
  }) => {
    const errors = collectErrors(page);
    await page.addInitScript(() => sessionStorage.setItem("lukas:entrance", "seen"));
    await page.goto("/");
    const layer = page.locator("[data-lukas-traveler]");
    await expect(layer).toBeVisible({ timeout: 30_000 });

    await scrollToSpot(page, "how");
    await expect(layer).toHaveAttribute("data-spot", "how");
    await expect(layer).toHaveAttribute("data-mood", "worried");
    await expect.poll(() => activeSheet(page)).toContain("/lukas/worried.webp");
    await expect
      .poll(() => centerDistance(page, "[data-lukas-spot='how']", "[data-lukas-traveler]"))
      .toBeLessThan(8);

    await page.evaluate(() =>
      window.scrollTo({ top: document.documentElement.scrollHeight, behavior: "instant" }),
    );
    await expect(layer).toHaveAttribute("data-spot", "closing");
    await expect(layer).toHaveAttribute("data-mood", "celebrating");
    await expect.poll(() => activeSheet(page)).toContain("/lukas/celebrate.webp");
    const closing = page.locator("[data-lukas-spot='closing']");
    await expect(closing.locator(".lk-lukas")).toBeHidden();
    await expect
      .poll(() => centerDistance(page, "[data-lukas-spot='closing']", "[data-lukas-traveler]"))
      .toBeLessThan(8);

    // Nothing on the page is covered for clicks: the closing button still gets them.
    await page.locator("#closing a.lk-btn").scrollIntoViewIfNeeded();
    expect(await getsThePointer(page, "#closing a.lk-btn")).toBe(true);
    expect(errors).toEqual([]);
  });

  test("never stands over text, at any scroll position", async ({ page }) => {
    await page.addInitScript(() => sessionStorage.setItem("lukas:entrance", "seen"));
    await page.goto("/");
    await expect(page.locator("[data-lukas-traveler]")).toBeVisible({ timeout: 30_000 });
    const overlaps = await page.evaluate(async () => {
      const frame = () => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
      const layer = document.querySelector<HTMLElement>("[data-lukas-traveler]");
      const turn = layer?.firstElementChild as HTMLElement | null;
      if (!layer || !turn) return ["no layer"];
      const texts: { rect: DOMRect; text: string }[] = [];
      const max = document.documentElement.scrollHeight - window.innerHeight;
      const found: string[] = [];
      for (let top = 0; top <= max + 40; top += 40) {
        window.scrollTo({ top, behavior: "instant" });
        await frame();
        const opacity = Number(turn.style.opacity || 1);
        if (opacity < 0.05) continue;
        // His figure inside the square frame (measured on the sheets), narrowed by an edge-on turn.
        const turned = /rotateY\(([-\d.]+)deg\)/.exec(turn.style.transform);
        const cos = turned ? Math.cos((Number(turned[1]) * Math.PI) / 180) : 1;
        const b = layer.getBoundingClientRect();
        const half = b.width * 0.34 * cos;
        const figure = {
          left: b.left + b.width / 2 - half,
          right: b.left + b.width / 2 + half,
          top: b.top + b.height * 0.07,
          bottom: b.top + b.height * 0.94,
        };
        texts.length = 0;
        const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
        while (walker.nextNode()) {
          const node = walker.currentNode;
          if (!node.textContent?.trim() || layer.contains(node)) continue;
          const range = document.createRange();
          range.selectNodeContents(node);
          for (const rect of range.getClientRects()) {
            if (rect.width > 0) texts.push({ rect, text: node.textContent.trim().slice(0, 40) });
          }
        }
        for (const { rect, text } of texts) {
          const hit =
            rect.left < figure.right &&
            rect.right > figure.left &&
            rect.top < figure.bottom &&
            rect.bottom > figure.top;
          if (hit) found.push(`${top}px (${layer.dataset.spot}): ${text}`);
        }
      }
      return [...new Set(found)];
    });
    expect(overlaps).toEqual([]);
  });

  test("causes no layout shift", async ({ page }) => {
    await page.addInitScript(() => {
      (window as unknown as { shift: number }).shift = 0;
      new PerformanceObserver((list) => {
        for (const entry of list.getEntries() as (PerformanceEntry & {
          value: number;
          hadRecentInput: boolean;
        })[]) {
          if (!entry.hadRecentInput) (window as unknown as { shift: number }).shift += entry.value;
        }
      }).observe({ type: "layout-shift", buffered: true });
    });
    await page.goto("/");
    const layer = page.locator("[data-lukas-traveler]");
    await expect(layer).toHaveAttribute("data-entrance", "done", { timeout: 30_000 });
    const shift = await page.evaluate(() => (window as unknown as { shift: number }).shift);
    expect(shift).toBeLessThan(0.01);
  });

  test("never leaves a spot empty when a sheet fails to load", async ({ page }) => {
    await page.route("**/lukas/worried.webp", (route) => route.abort());
    await page.addInitScript(() => sessionStorage.setItem("lukas:entrance", "seen"));
    await page.goto("/");
    await expect(page.locator("[data-lukas-traveler]")).toBeVisible({ timeout: 30_000 });
    await scrollToSpot(page, "how");
    // Give the failed sheet time to fail and the layer time to react.
    await page.waitForTimeout(1500);
    const state = await page.evaluate(async () => {
      const layer = document.querySelector<HTMLElement>("[data-lukas-traveler]");
      if (!layer) {
        const hero = document.querySelector("#hero [data-slot='hero-mascot'] .lk-lukas");
        return {
          steppedAside: true,
          live: document.documentElement.hasAttribute("data-lukas-live"),
          heroVisible: hero ? getComputedStyle(hero).visibility === "visible" : false,
        };
      }
      const sprite = layer.querySelector(".lk-traveler-mood.is-active .lk-lukas-sprite");
      const url = sprite
        ? /url\("?([^")]+)"?\)/.exec(getComputedStyle(sprite).backgroundImage)?.[1]
        : undefined;
      const sheetLoads = await new Promise<boolean>((resolve) => {
        if (!url) return resolve(false);
        const image = new Image();
        image.onload = () => resolve(true);
        image.onerror = () => resolve(false);
        image.src = url;
      });
      return { steppedAside: false, spot: layer.dataset.spot, sheetLoads };
    });
    if (state.steppedAside) {
      // He stepped aside: the prerendered sprites are back.
      expect(state).toEqual({ steppedAside: true, live: false, heroVisible: true });
    } else {
      // He stands on the spot, showing a sheet that actually loaded (the mood he held).
      expect(state).toEqual({ steppedAside: false, spot: "how", sheetLoads: true });
    }
  });

  test("steps aside when reduced motion is switched on while the page is open", async ({
    page,
  }) => {
    await page.addInitScript(() => sessionStorage.setItem("lukas:entrance", "seen"));
    await page.goto("/");
    await expect(page.locator("[data-lukas-traveler]")).toBeVisible({ timeout: 30_000 });
    await page.emulateMedia({ reducedMotion: "reduce" });
    await expect(page.locator("[data-lukas-traveler]")).toHaveCount(0);
    await expect(page.locator("html")).not.toHaveAttribute("data-lukas-live", /.*/);
    const sprite = page.locator("#hero [data-slot='hero-mascot'] .lk-lukas-sprite");
    await expect(sprite).toBeVisible();
    expect(await sprite.evaluate((el) => el.getAnimations().length)).toBe(0);
  });

  test("keeps the still image under reduced motion", async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.goto("/");
    await settle(page);
    await expect(page.locator("[data-lukas-traveler]")).toHaveCount(0);
    await expect(page.locator("canvas")).toHaveCount(0);
    for (const spot of ["#hero [data-slot='hero-mascot']", "[data-lukas-spot='closing']"]) {
      const sprite = page.locator(`${spot} .lk-lukas-sprite`);
      await expect(sprite).toBeVisible();
      expect(await sprite.evaluate((el) => el.getAnimations().length)).toBe(0);
    }
  });
});

interface ManifestChunk {
  file: string;
  src?: string;
  isEntry?: boolean;
  imports?: string[];
  dynamicImports?: string[];
}

test.describe("JavaScript budget", () => {
  test("the initial JavaScript of / stays under 300 KB gzipped, with no three.js anywhere", async ({
    request,
  }, testInfo) => {
    // Vite's manifest is moved out of what ships (react-router.config.ts).
    expect(existsSync(`${CLIENT}.vite`)).toBe(false);
    const manifest = JSON.parse(readFileSync(`${BUILD}vite-manifest.json`, "utf8")) as Record<
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

    // The 3D experiment is never built into the site: no chunk at all carries three.js.
    const chunks = readdirSync(`${CLIENT}assets`).filter((file) => file.endsWith(".js"));
    const withThree = chunks.filter((file) =>
      readFileSync(`${CLIENT}assets/${file}`, "utf8").includes(THREE_SIGNATURE),
    );
    expect(withThree).toEqual([]);
    for (const chunk of Object.values(manifest)) {
      expect(chunk.src ?? "").not.toMatch(/node_modules\/(three|@react-three)\/|\/experimental\//);
    }

    const inline = [...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)]
      .map((m) => m[1] ?? "")
      .join("\n");
    const gzip = (text: string | Buffer) => gzipSync(text, { level: 9 }).length;
    const initialBytes =
      [...initial].reduce((sum, file) => sum + gzip(readFileSync(`${CLIENT}${file}`)), 0) +
      gzip(inline);
    testInfo.annotations.push({
      type: "js-budget",
      description: `initial ${(initialBytes / 1024).toFixed(1)} KB gz (${initial.size} files); ${chunks.length} chunks, none with three.js`,
    });
    console.log(testInfo.annotations.at(-1)?.description);
    expect(initialBytes).toBeLessThan(BUDGET_GZIP);
  });
});
