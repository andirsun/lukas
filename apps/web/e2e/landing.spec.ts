import AxeBuilder from "@axe-core/playwright";
import { expect, type Page, test } from "@playwright/test";

/**
 * The landing page as shipped: prerendered HTML served statically (`built-*` projects), read with
 * JavaScript off unless a test turns it on. Everything a visitor or a crawler needs must already
 * be in the HTML.
 */

const ORIGIN = "https://lukas.app";

const LOCALES = [
  {
    locale: "es",
    path: "/",
    headline: "Tus lukas, por fin claras.",
    tagline: "Tu presupuesto, tu mejor amigo.",
    questions: ["¿En qué se me va la plata?", "¿Cuánto me cuesta vivir?"],
    cta: "Empieza gratis",
    webCta: "Empezar",
    soon: "Pronto",
    ways: ["En la web", "App Android", "Con tu IA"],
    faq: "Preguntas frecuentes",
    privacy: "Privacidad",
    other: { name: "English", path: "/en" },
    titlePart: "Tus lukas, por fin claras",
  },
  {
    locale: "en",
    path: "/en",
    headline: "Your money, finally clear.",
    tagline: "Your budget, your best friend.",
    questions: ["Where does all my money go?", "How much does living cost me?"],
    cta: "Start free",
    webCta: "Start",
    soon: "Soon",
    ways: ["On the web", "Android app", "With your AI"],
    faq: "Frequently asked questions",
    privacy: "Privacy",
    other: { name: "Español", path: "/" },
    titlePart: "Your money, finally clear",
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

for (const l of LOCALES) {
  test.describe(`landing (${l.locale})`, () => {
    test("the prerendered HTML carries the copy, without JavaScript", async ({ page, request }) => {
      const html = await (await request.get(l.path)).text();
      expect(html).toContain(l.headline);
      expect(html).toContain(l.tagline);
      expect(html).toContain(`<html lang="${l.locale}"`);

      await page.goto(l.path);
      await expect(page.getByRole("heading", { level: 1 })).toHaveText(l.headline);
      await expect(page.getByText(l.tagline, { exact: true })).toBeVisible();
      for (const question of l.questions) {
        // Crossed out: the questions Lukas answers.
        await expect(page.locator("s", { hasText: question })).toBeVisible();
      }
      await expect(page).toHaveTitle(new RegExp(l.titlePart));
    });

    test("has its SEO tags: description, Open Graph, canonical and hreflang", async ({ page }) => {
      await page.goto(l.path);
      const head = page.locator("head");
      const self = `${ORIGIN}${l.path === "/" ? "/" : l.path}`;
      await expect(head.locator('meta[name="description"]')).toHaveAttribute("content", /.{60,}/);
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
      await expect(head.locator('meta[property="og:title"]')).toHaveAttribute(
        "content",
        new RegExp(l.titlePart),
      );
      await expect(head.locator('meta[property="og:description"]')).toHaveAttribute(
        "content",
        /.{60,}/,
      );
      await expect(head.locator('meta[property="og:url"]')).toHaveAttribute("content", self);
      await expect(head.locator('meta[property="og:type"]')).toHaveAttribute("content", "website");
      await expect(head.locator('meta[property="og:image"]')).toHaveAttribute(
        "content",
        `${ORIGIN}/og-${l.locale}.png`,
      );
      await expect(head.locator('meta[name="twitter:card"]')).toHaveAttribute(
        "content",
        "summary_large_image",
      );
    });

    test("one primary action: start free → sign-in in this language", async ({ page }) => {
      await page.goto(l.path);
      const hero = page.locator("#hero");
      const cta = hero.getByRole("link", { name: l.cta });
      await expect(cta).toHaveAttribute("href", `/sign-in?lang=${l.locale}`);
      await expect(cta).toHaveClass(/lk-btn-primary/);
      const box = await cta.boundingBox();
      expect(box?.height).toBeGreaterThanOrEqual(44);
    });

    test("use it your way: web is live, Android and AI are coming soon", async ({ page }) => {
      await page.goto(l.path);
      const [web, android, ai] = l.ways.map((name) =>
        page.getByRole("listitem").filter({ has: page.getByRole("heading", { name }) }),
      ) as [ReturnType<Page["locator"]>, ReturnType<Page["locator"]>, ReturnType<Page["locator"]>];
      await expect(web.getByRole("link", { name: l.webCta, exact: true })).toHaveAttribute(
        "href",
        `/sign-in?lang=${l.locale}`,
      );
      await expect(web.getByText(l.soon, { exact: true })).toHaveCount(0);
      for (const card of [android, ai]) {
        await expect(card.getByText(l.soon, { exact: true })).toBeVisible();
        await expect(card.getByRole("link")).toHaveCount(0);
      }
      await expect(ai).toContainText("Claude");
      await expect(ai).toContainText("ChatGPT");
    });

    test("the FAQ opens without JavaScript", async ({ page }) => {
      await page.goto(l.path);
      const faq = page.locator("#faq");
      await expect(faq.getByRole("heading", { level: 2 })).toHaveText(l.faq);
      const questions = faq.locator("details");
      expect(await questions.count()).toBeGreaterThanOrEqual(6);
      const first = questions.first();
      await expect(first).not.toHaveAttribute("open");
      await first.locator("summary").click();
      await expect(first).toHaveAttribute("open");
      await expect(first.locator("summary + *")).toBeVisible();
    });

    test("the footer switches language on the same page and links to privacy", async ({ page }) => {
      await page.goto(l.path);
      const footer = page.getByRole("contentinfo");
      const switchLink = footer.getByRole("link", { name: l.other.name });
      await expect(switchLink).toHaveAttribute("href", l.other.path);
      await expect(switchLink).toHaveAttribute("hreflang", l.other.path === "/" ? "es" : "en");
      const privacy = footer.getByRole("link", { name: l.privacy });
      await expect(privacy).toHaveAttribute("href", "#privacy");
      // A placeholder anchor until the policy has its page: the FAQ answer about your data,
      // which the browser opens when the link is followed.
      await expect(page.locator("#privacy")).toBeHidden();
      await privacy.click();
      await expect(page.locator("#privacy")).toBeVisible();
      await expect(footer).toContainText("© 2026 Lukas");

      await switchLink.click();
      await expect(page).toHaveURL(new RegExp(`${l.other.path}$`));
      await expect(page.locator("html")).toHaveAttribute("lang", l.locale === "es" ? "en" : "es");
    });

    test.describe(() => {
      // Axe runs asynchronously, so it needs JavaScript: keep it on but block the app's own
      // scripts, which leaves exactly the prerendered page (the inline theme script still picks
      // night from the dark color scheme).
      test.use({ javaScriptEnabled: true, colorScheme: "dark" });

      test("the prerendered page is accessible (axe, night theme)", async ({ page }) => {
        await page.route("**/assets/*.js", (route) => route.abort());
        await page.goto(l.path);
        await expect(page.locator("html")).toHaveAttribute("data-theme", "night");
        await expectNoA11yViolations(page);
      });
    });

    test("fits the viewport and keeps every target at 44px", async ({ page }) => {
      await page.goto(l.path);
      const overflow = await page.evaluate(
        () => document.documentElement.scrollWidth - document.documentElement.clientWidth,
      );
      expect(overflow).toBeLessThanOrEqual(0);
      for (const target of await page.locator("a:visible, button:visible, summary").all()) {
        const box = await target.boundingBox();
        expect(box?.height, await target.innerText()).toBeGreaterThanOrEqual(44);
        expect(box?.width, await target.innerText()).toBeGreaterThanOrEqual(44);
      }
    });

    test("shows Lukas waving, and still under reduced motion", async ({ page }) => {
      await page.goto(l.path);
      const mascot = page.locator("#hero [data-slot='hero-mascot']");
      await expect(mascot).toHaveAttribute("role", "img");
      await expect(mascot).toHaveAttribute("aria-label", /Lukas/);
      const sprite = mascot.locator(".lk-lukas-sprite");
      await expect(sprite).toHaveCSS("background-image", /\/lukas\/wave\.webp/);
      expect(await sprite.evaluate((el) => el.getAnimations().length)).toBeGreaterThan(0);

      await page.emulateMedia({ reducedMotion: "reduce" });
      expect(await sprite.evaluate((el) => el.getAnimations().length)).toBe(0);
    });
  });
}

test.describe("landing with JavaScript", () => {
  test.use({ javaScriptEnabled: true });

  test("hydrates cleanly and keeps the page when switching language", async ({ page }) => {
    const errors: string[] = [];
    page.on("console", (message) => {
      if (message.type() === "error") errors.push(message.text());
    });
    page.on("pageerror", (error) => errors.push(error.message));

    await page.goto("/");
    await page.waitForLoadState("networkidle");
    await expect(page.getByRole("heading", { level: 1 })).toHaveText("Tus lukas, por fin claras.");

    await page.getByRole("contentinfo").getByRole("link", { name: "English" }).click();
    await expect(page).toHaveURL(/\/en$/);
    await expect(page.getByRole("heading", { level: 1 })).toHaveText("Your money, finally clear.");
    await expect(page).toHaveTitle(/Your money, finally clear/);
    await expect(page.locator("html")).toHaveAttribute("lang", "en");
    await expect(page.locator('link[rel="canonical"]')).toHaveAttribute("href", `${ORIGIN}/en`);
    expect(errors).toEqual([]);
  });

  for (const l of LOCALES) {
    test(`is accessible in the day theme (${l.locale})`, async ({ page }) => {
      await page.emulateMedia({ colorScheme: "light" });
      await page.goto(l.path);
      await expect(page.locator("html")).toHaveAttribute("data-theme", "day");
      await expectNoA11yViolations(page);
    });
  }
});

test.describe("static files", () => {
  test("robots.txt, sitemap.xml and the Open Graph images are served", async ({ request }) => {
    const robots = await (await request.get("/robots.txt")).text();
    expect(robots).toContain("Sitemap: https://lukas.app/sitemap.xml");

    const sitemap = await (await request.get("/sitemap.xml")).text();
    expect(sitemap).toContain("<loc>https://lukas.app/</loc>");
    expect(sitemap).toContain("<loc>https://lukas.app/en</loc>");
    expect(sitemap).toContain('hreflang="x-default"');

    for (const locale of ["es", "en"]) {
      const image = await request.get(`/og-${locale}.png`);
      expect(image.headers()["content-type"]).toBe("image/png");
      const bytes = await image.body();
      // PNG IHDR: width and height are big-endian at bytes 16 and 20.
      expect([bytes.readUInt32BE(16), bytes.readUInt32BE(20)]).toEqual([1200, 630]);
    }
  });
});
