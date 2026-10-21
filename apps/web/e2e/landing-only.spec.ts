import { existsSync, readdirSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import AxeBuilder from "@axe-core/playwright";
import { expect, type Page, test } from "@playwright/test";

/**
 * The landing-only release build (`pnpm e2e:landing-only`): the same prerendered landing, built
 * with VITE_LANDING_ONLY=true and a configured origin, served the way Cloudflare Pages serves it
 * (unknown paths get 404.html). Nothing in it may lead to the app, which does not exist yet.
 */

const ORIGIN = process.env.VITE_SITE_URL ?? "https://landing-only.example.test";
const GITHUB = "https://github.com/andirsun/lukas";
const CLIENT = fileURLToPath(new URL("../build/client/", import.meta.url));
/** Anything that would lead to the app: sign-in, the app itself, the welcome flow. */
const APP_PATH = /(^|\/)(sign-in|app|welcome)(\/|\?|#|$)/;

const LOCALES = [
  {
    locale: "es",
    path: "/",
    cta: "Muy pronto · Síguelo en GitHub",
    navCta: "Muy pronto",
    soon: "Pronto",
    webTitle: "En la web",
    ways: ["En la web", "App para Android y iOS", "Con tu IA"],
    closingTitle: "Cuando quieras, arrancamos.",
    closingBody:
      "Lukas está en construcción, en abierto. Mira cómo avanza en GitHub y prueba la app en cuanto abra.",
    oldClosing: /Crea tu cuenta/,
    oldCtas: ["Empieza ahora", "Entrar", "Empezar"],
    banned: [/\bjueg(o|a)\b/i],
    toggleToDay: "Cambiar a modo día",
  },
  {
    locale: "en",
    path: "/en",
    cta: "Coming soon · Follow on GitHub",
    navCta: "Coming soon",
    soon: "Soon",
    webTitle: "On the web",
    ways: ["On the web", "Android & iOS app", "With your AI"],
    closingTitle: "Ready when you are.",
    closingBody:
      "Lukas is being built in the open. Follow its progress on GitHub and try the app as soon as it opens.",
    oldClosing: /Create your account/,
    oldCtas: ["Get started", "Sign in", "Start"],
    banned: [/\bgames?\b/i],
    toggleToDay: "Switch to day mode",
  },
] as const;

/** Axe with the WCAG A/AA rule sets (2.0 to 2.2) plus best practices. */
async function expectNoA11yViolations(page: Page) {
  const results = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa", "best-practice"])
    .analyze();
  expect(
    results.violations.map((v) => ({ id: v.id, nodes: v.nodes.map((n) => n.target.join(" ")) })),
  ).toEqual([]);
}

/** Every rendered element that sticks out of the viewport, and every target under 44px. */
async function expectFitsTheViewport(page: Page) {
  const overflowing = await page.evaluate(() => {
    const width = document.documentElement.clientWidth;
    return [...document.querySelectorAll(".lk-landing *")]
      .filter((el) => {
        const box = el.getBoundingClientRect();
        if (box.width === 0 && box.height === 0) return false;
        return box.left < -0.5 || box.right > width + 0.5;
      })
      .map((el) => `${el.tagName.toLowerCase()}.${el.className} "${el.textContent?.slice(0, 30)}"`);
  });
  expect(overflowing).toEqual([]);
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth - document.documentElement.clientWidth,
    ),
  ).toBeLessThanOrEqual(0);
  for (const target of await page.locator("a:visible, button:visible, summary").all()) {
    const box = await target.boundingBox();
    expect(box?.height, await target.innerText()).toBeGreaterThanOrEqual(44);
    expect(box?.width, await target.innerText()).toBeGreaterThanOrEqual(44);
  }
}

/** The target of a link that is meant to leave for GitHub, in a new tab. */
async function expectGithubLink(link: ReturnType<Page["locator"]>) {
  await expect(link).toHaveAttribute("href", GITHUB);
  await expect(link).toHaveAttribute("target", "_blank");
  await expect(link).toHaveAttribute("rel", "noopener");
}

for (const l of LOCALES) {
  test.describe(`landing-only (${l.locale})`, () => {
    test("the calls to action are one coming-soon link to GitHub, hero and closing", async ({
      page,
    }) => {
      await page.goto(l.path);
      const hero = page.locator("#hero").getByRole("link", { name: l.cta, exact: true });
      await expectGithubLink(hero);
      await expect(hero).toHaveClass(/lk-btn-primary/);
      expect((await hero.boundingBox())?.height).toBeGreaterThanOrEqual(44);

      const closing = page.locator("#closing").getByRole("link", { name: l.cta, exact: true });
      await expectGithubLink(closing);
      await expect(closing).toHaveClass(/lk-btn-primary/);
    });

    test("the header's sign-in is a short coming-soon link to GitHub, beside the day/night switch", async ({
      page,
    }) => {
      await page.goto(l.path);
      const nav = page.getByRole("banner").getByRole("navigation");
      const link = nav.getByRole("link", { name: l.navCta, exact: true });
      await expectGithubLink(link);
      await expect(link).toHaveClass(/lk-btn-secondary/);
      await expect(nav.getByRole("button", { name: l.toggleToDay })).toBeVisible();
    });

    test("none of the old calls to action is left", async ({ page }) => {
      await page.goto(l.path);
      for (const name of l.oldCtas) {
        await expect(page.getByRole("link", { name, exact: true })).toHaveCount(0);
      }
    });

    test("the web card is a coming-soon badge, like the other cards, with no link", async ({
      page,
    }) => {
      await page.goto(l.path);
      for (const name of l.ways) {
        const card = page
          .locator("#ways")
          .getByRole("listitem")
          .filter({ has: page.getByRole("heading", { name }) });
        await expect(card.getByText(l.soon, { exact: true })).toBeVisible();
        await expect(card.getByRole("link")).toHaveCount(0);
      }
    });

    test("no link leads to /sign-in, /app or /welcome", async ({ page, request }) => {
      await page.goto(l.path);
      const hrefs = await page
        .locator("a[href]")
        .evaluateAll((nodes) => nodes.map((node) => node.getAttribute("href") ?? ""));
      expect(hrefs.length).toBeGreaterThan(5);
      expect(hrefs.filter((href) => APP_PATH.test(new URL(href, "http://x").pathname))).toEqual([]);
      const html = await (await request.get(l.path)).text();
      expect(html).not.toMatch(/href="[^"]*\/(sign-in|app|welcome)(["/?#])/);
    });

    test("the closing section tells the truth about the app, and keeps Lukas's spot", async ({
      page,
      request,
    }) => {
      await page.goto(l.path);
      const closing = page.locator("#closing");
      await expect(closing.getByRole("heading", { level: 2 })).toHaveText(l.closingTitle);
      await expect(closing.locator("p")).toHaveText(l.closingBody);
      expect(await closing.innerText()).not.toMatch(l.oldClosing);
      const html = (await (await request.get(l.path)).text()).replaceAll("&#x27;", "'");
      expect(html).not.toMatch(l.oldClosing);

      const spot = closing.locator("[data-lukas-spot='closing']");
      await expect(spot).toHaveAttribute("data-lukas-mood", "celebrating");
      await expect(spot).toHaveAttribute("data-lukas-pose", "celebrate");
      await expect(spot.locator(".lk-lukas")).toHaveCount(1);
    });

    test("is still free, open source and not a game", async ({ page }) => {
      await page.goto(l.path);
      const text = await page.locator("body").evaluate((body) => body.textContent ?? "");
      for (const pattern of l.banned) expect(text).not.toMatch(pattern);
      await expect(page.locator("#open-source").getByRole("link")).toHaveAttribute("href", GITHUB);
    });

    test("canonical, hreflang and Open Graph use the configured origin", async ({ page }) => {
      await page.goto(l.path);
      const head = page.locator("head");
      const self = `${ORIGIN}${l.path}`;
      await expect(head.locator('link[rel="canonical"]')).toHaveAttribute("href", self);
      await expect(head.locator('link[rel="alternate"][hreflang="es"]')).toHaveAttribute(
        "href",
        `${ORIGIN}/`,
      );
      await expect(head.locator('link[rel="alternate"][hreflang="en"]')).toHaveAttribute(
        "href",
        `${ORIGIN}/en`,
      );
      await expect(head.locator('link[rel="alternate"][hreflang="x-default"]')).toHaveAttribute(
        "href",
        `${ORIGIN}/`,
      );
      await expect(head.locator('meta[property="og:url"]')).toHaveAttribute("content", self);
      await expect(head.locator('meta[property="og:image"]')).toHaveAttribute(
        "content",
        `${ORIGIN}/og-${l.locale}.png`,
      );
    });

    test("fits the viewport and keeps every target at 44px", async ({ page }) => {
      await page.goto(l.path);
      await expectFitsTheViewport(page);
    });

    test.describe("at 320px", () => {
      test.use({ viewport: { width: 320, height: 700 } });

      test("the long coming-soon labels wrap instead of overflowing", async ({ page }) => {
        await page.goto(l.path);
        await expectFitsTheViewport(page);
      });
    });

    test.describe(() => {
      // Axe needs JavaScript: keep it on but block the app's own scripts, which leaves exactly
      // the prerendered page.
      test.use({ javaScriptEnabled: true, colorScheme: "dark" });

      test("the prerendered page is accessible (axe, night theme)", async ({ page }) => {
        await page.route("**/assets/*.js", (route) => route.abort());
        await page.goto(l.path);
        await expect(page.locator("html")).toHaveAttribute("data-theme", "night");
        await expectNoA11yViolations(page);
      });
    });

    test.describe("with JavaScript", () => {
      test.use({ javaScriptEnabled: true });

      test("is accessible in the day theme and keeps its links after hydrating", async ({
        page,
      }) => {
        const errors: string[] = [];
        page.on("console", (message) => {
          if (message.type() === "error") errors.push(message.text());
        });
        page.on("pageerror", (error) => errors.push(error.message));
        await page.addInitScript(() => localStorage.setItem("lukas.theme", "day"));
        await page.goto(l.path);
        await page.waitForLoadState("networkidle");
        await expect(page.locator("html")).toHaveAttribute("data-theme", "day");
        await expectNoA11yViolations(page);
        await expectGithubLink(
          page.locator("#hero").getByRole("link", { name: l.cta, exact: true }),
        );
        await expectGithubLink(
          page.locator("#closing").getByRole("link", { name: l.cta, exact: true }),
        );
        expect(errors).toEqual([]);
      });
    });
  });
}

test.describe("landing-only build output", () => {
  test("ships only the landing, a 404 page and the static files", () => {
    expect(readdirSync(CLIENT).sort()).toEqual(
      [
        "404.html",
        "_headers",
        "assets",
        "en",
        "index.html",
        "lukas",
        "og-en.png",
        "og-es.png",
        "robots.txt",
        "sitemap.xml",
      ].sort(),
    );
    expect(readdirSync(`${CLIENT}en`)).toEqual(["index.html"]);
    expect(existsSync(`${CLIENT}__spa-fallback.html`)).toBe(false);
  });

  test("sitemap.xml and robots.txt are generated from the origin", async ({ request }) => {
    const robots = await (await request.get("/robots.txt")).text();
    expect(robots).toContain(`Sitemap: ${ORIGIN}/sitemap.xml`);
    expect(robots).not.toContain("lukas.app");
    expect(robots).not.toContain("Disallow");
    const sitemap = await (await request.get("/sitemap.xml")).text();
    expect(sitemap).toContain(`<loc>${ORIGIN}/</loc>`);
    expect(sitemap).toContain(`<loc>${ORIGIN}/en</loc>`);
    expect(sitemap).not.toContain("lukas.app");
  });

  test("_headers caches assets for good, HTML briefly, and sets the security headers", () => {
    const headers = readFileSync(`${CLIENT}_headers`, "utf8");
    expect(headers).toMatch(/\/assets\/\*\s+Cache-Control: public, max-age=31536000, immutable/);
    expect(headers).toMatch(/X-Content-Type-Options: nosniff/);
    expect(headers).toMatch(/Referrer-Policy: strict-origin-when-cross-origin/);
    expect(headers).toMatch(/Permissions-Policy: .*camera=\(\)/);
  });

  for (const path of ["/some/unknown/page", "/sign-in", "/app", "/welcome", "/en/nope"]) {
    test(`${path} gets the 404 page, not the app`, async ({ request, page }) => {
      const response = await request.get(path);
      expect(response.status()).toBe(404);
      expect(await response.text()).toContain("<title>");
      await page.goto(path);
      await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
    });
  }

  test("the 404 page speaks both languages and links home in each", async ({ page }) => {
    await page.goto("/nowhere");
    await expect(page.getByRole("heading", { level: 1 })).toHaveText("Esta página no existe");
    await expect(page.getByRole("heading", { level: 2 })).toHaveText("This page doesn't exist");
    const es = page.getByRole("link", { name: "Volver al inicio" });
    await expect(es).toHaveAttribute("href", "/");
    await expect(es).toHaveClass(/lk-btn-primary/);
    const en = page.getByRole("link", { name: "Back to home" });
    await expect(en).toHaveAttribute("href", "/en");
    await expect(page.locator('meta[name="robots"]')).toHaveAttribute("content", "noindex");
    await expect(page.locator('link[rel="canonical"]')).toHaveCount(0);
    expect(
      await page
        .locator("a[href]")
        .evaluateAll((nodes) => nodes.map((node) => node.getAttribute("href") ?? "")),
    ).not.toContainEqual(expect.stringMatching(APP_PATH));
    // The landing look: the same stylesheet, the night theme and the logo.
    await expect(page.locator(".lk-landing")).toHaveCount(1);
    await expect(page.locator(".lk-logo").first()).toHaveText("Lukas");
  });

  test.describe("the 404 page with JavaScript", () => {
    test.use({ javaScriptEnabled: true });

    test("hydrates cleanly and is accessible, night and day", async ({ page }) => {
      const errors: string[] = [];
      page.on("console", (message) => {
        // The page itself is a 404 response: the browser logs that, not a fault of the page.
        const isThePage = message.location().url.endsWith("/missing");
        if (message.type() === "error" && !isThePage) errors.push(message.text());
      });
      page.on("pageerror", (error) => errors.push(error.message));
      await page.goto("/missing");
      await page.waitForLoadState("networkidle");
      await expect(page.locator("html")).toHaveAttribute("data-theme", "night");
      await expectNoA11yViolations(page);
      await page.getByRole("banner").getByRole("button", { name: "Cambiar a modo día" }).click();
      await expect(page.locator("html")).toHaveAttribute("data-theme", "day");
      await expectNoA11yViolations(page);
      expect(errors).toEqual([]);
    });
  });
});
