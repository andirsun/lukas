import AxeBuilder from "@axe-core/playwright";
import { expect, type Page, test } from "@playwright/test";

/**
 * The landing page as shipped: prerendered HTML served statically (playwright.built.config.ts,
 * `pnpm e2e:landing`), read with JavaScript off unless a test turns it on. Everything a visitor or
 * a crawler needs must already be in the HTML.
 */

const ORIGIN = "https://lukas.app";
const GITHUB = "https://github.com/andirsun/lukas";

const LOCALES = [
  {
    locale: "es",
    path: "/",
    headline: "Tus lukas, por fin claras.",
    highlight: "lukas",
    annotation: "¡Gratis, y siempre lo será!",
    lead: "Lukas es tu presupuesto, y te va a dar gusto cuidarlo.",
    description: "Anota un gasto en segundos y mira en qué se va cada luka.",
    perks: "Gratis para siempre · Código abierto · Sin contraseñas",
    openSourcePerk: "Código abierto",
    removedQuestions: ["¿En qué se me va la plata?", "¿Cuánto me cuesta vivir?"],
    cta: "Empieza ahora",
    demoCta: "Pruébalo sin cuenta",
    webCta: "Empezar",
    soon: "Pronto",
    ways: ["En la web", "App para Android y iOS", "Con tu IA"],
    importStep: "Trae tu historial",
    importQuestion: "¿Puedo traer mi historial de otras apps?",
    freeQuestion: "¿Es gratis?",
    freeAnswer: "Sí, y lo será siempre.",
    openSource: { title: "Código abierto", cta: "Ver el código en GitHub" },
    metaDescription: [/Gratis para siempre/, /código abierto/],
    banned: [/mejor amigo/i, /\bjueg(o|a)\b/i, /Empieza gratis/i],
    // Privacy copy claims only what Lukas does today: no "can't leak", no end-to-end encryption,
    // no encryption at rest.
    overclaims: [/se pueda filtrar/i, /extremo a extremo/i, /no podemos ver/i, /en reposo/i],
    privacyAnswer:
      "Tus datos viajan cifrados y nunca los vendemos ni los compartimos con anunciantes.",
    faq: "Preguntas frecuentes",
    privacy: "Privacidad",
    other: { name: "English", path: "/en" },
    titlePart: "Tus lukas, por fin claras",
  },
  {
    locale: "en",
    path: "/en",
    headline: "Your money, finally clear.",
    highlight: "money",
    annotation: "Free, and it always will be!",
    lead: "Lukas is your budget, and you'll actually enjoy looking after it.",
    description: "Log an expense in seconds and see where every buck goes.",
    perks: "Free forever · Open source · No passwords",
    openSourcePerk: "Open source",
    removedQuestions: ["Where does all my money go?", "How much does living cost me?"],
    cta: "Get started",
    demoCta: "Try it without an account",
    webCta: "Start",
    soon: "Soon",
    ways: ["On the web", "Android & iOS app", "With your AI"],
    importStep: "Bring your history",
    importQuestion: "Can I bring my history from other apps?",
    freeQuestion: "Is it free?",
    freeAnswer: "Yes, and it always will be.",
    openSource: { title: "Open source", cta: "View the code on GitHub" },
    metaDescription: [/Free forever/, /open source/],
    banned: [/best friend/i, /\bgames?\b/i, /Start free/i],
    overclaims: [/nothing to leak/i, /end-to-end/i, /can(no|')t see/i, /at rest/i],
    privacyAnswer:
      "Your data travels encrypted, and we never sell it or share it with advertisers.",
    faq: "Frequently asked questions",
    privacy: "Privacy",
    other: { name: "Español", path: "/" },
    titlePart: "Your money, finally clear",
  },
] as const;

type Rgba = { rgb: [number, number, number]; alpha: number };

/** A computed color: `rgb(…)`, `rgba(…)` or `color(srgb r g b / a)` (what `color-mix` gives). */
function parseColor(color: string): Rgba {
  const numbers = (color.match(/[\d.]+/g) ?? []).map(Number);
  const srgb = color.startsWith("color(srgb");
  const [r = 0, g = 0, b = 0, alpha = 1] = numbers;
  const scale = srgb ? 255 : 1;
  return { rgb: [r * scale, g * scale, b * scale], alpha };
}

/** `top` painted over the opaque `bottom`. */
function over(top: Rgba, bottom: Rgba): Rgba {
  const rgb = top.rgb.map((c, i) => c * top.alpha + (bottom.rgb[i] ?? 0) * (1 - top.alpha));
  return { rgb: rgb as [number, number, number], alpha: 1 };
}

/** WCAG contrast ratio of two opaque colors. */
function contrast(a: Rgba, b: Rgba): number {
  const luminance = ({ rgb }: Rgba) => {
    const [r, g, b] = rgb.map((channel) => {
      const c = channel / 255;
      return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
    }) as [number, number, number];
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x) as [number, number];
  return (hi + 0.05) / (lo + 0.05);
}

/**
 * Contrast in the hero, which axe can't measure there (the page background is a gradient, so it
 * reports the hero's text as "incomplete"): the highlighted word is dark ink on solid gold, and
 * the handwritten note is ink on a translucent stroke, checked over both ends of the gradient
 * (`bg-glow` and `bg`). AA for normal text in both cases.
 */
async function expectHeroContrast(page: Page) {
  const colors = await page.locator("#hero").evaluate((hero) => {
    const read = (selector: string) => {
      const style = getComputedStyle(hero.querySelector(selector) as Element);
      return { color: style.color, background: style.backgroundColor };
    };
    const token = (name: string) => {
      const probe = document.createElement("span");
      probe.style.color = `var(${name})`;
      hero.append(probe);
      const value = getComputedStyle(probe).color;
      probe.remove();
      return value;
    };
    return {
      marker: read("h1 .lk-landing-marker"),
      note: read(".lk-landing-annotation"),
      page: [token("--bg"), token("--bg-glow")],
    };
  });
  const marker = parseColor(colors.marker.background);
  expect(marker.alpha).toBe(1);
  expect(contrast(parseColor(colors.marker.color), marker)).toBeGreaterThanOrEqual(4.5);

  const stroke = parseColor(colors.note.background);
  expect(stroke.alpha).toBeGreaterThan(0);
  for (const page of colors.page) {
    const background = over(stroke, parseColor(page));
    expect(contrast(parseColor(colors.note.color), background)).toBeGreaterThanOrEqual(4.5);
  }
}

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
      // React escapes apostrophes in text ("you'll" → "you&#x27;ll").
      const html = (await (await request.get(l.path)).text()).replaceAll("&#x27;", "'");
      expect(html).toContain(l.annotation);
      expect(html).toContain(l.lead);
      expect(html).toContain(`<html lang="${l.locale}"`);

      await page.goto(l.path);
      await expect(page.getByRole("heading", { level: 1 })).toHaveText(l.headline);
      await expect(page).toHaveTitle(new RegExp(l.titlePart));
    });

    test("the hero is simple: no crossed-out questions, the note comes first", async ({
      page,
      request,
    }) => {
      // The old crossed-out questions are gone, from the copy and from the markup.
      const html = (await (await request.get(l.path)).text()).replaceAll("&#x27;", "'");
      for (const question of l.removedQuestions) expect(html).not.toContain(question);
      await page.goto(l.path);
      const hero = page.locator("#hero");
      await expect(hero.locator("s")).toHaveCount(0);
      // Annotation → headline → description → actions.
      expect(
        await hero
          .locator(".lk-landing-hero-text > *")
          .evaluateAll((nodes) => nodes.map((node) => node.className)),
      ).toEqual([
        "lk-landing-annotation",
        "lk-landing-headline",
        "lk-landing-description",
        "lk-landing-cta",
      ]);
    });

    test("the hero: a handwritten note, the highlighted word, the lead and the perks", async ({
      page,
    }) => {
      await page.goto(l.path);
      const hero = page.locator("#hero");
      const headline = hero.getByRole("heading", { level: 1 });
      await expect(headline.locator(".lk-landing-marker")).toHaveText(l.highlight);

      // Real text in the handwritten face, above the headline.
      const note = hero.getByText(l.annotation, { exact: true });
      await expect(note).toBeVisible();
      await expect(note).toHaveCSS("font-family", /Caveat/);
      const noteBox = await note.boundingBox();
      const headlineBox = await headline.boundingBox();
      expect((noteBox?.y ?? 0) + (noteBox?.height ?? 0) / 2).toBeLessThan(headlineBox?.y ?? 0);

      const description = hero.locator(".lk-landing-description");
      await expect(description).toHaveText(`${l.lead} ${l.description}`);
      await expect(description.locator(".lk-landing-lead")).toHaveText(l.lead);

      await expect(hero.locator(".lk-landing-perks")).toHaveText(l.perks);
      const github = hero.getByRole("link", { name: l.openSourcePerk });
      await expect(github).toHaveAttribute("href", GITHUB);
      await expect(github).toHaveAttribute("target", "_blank");
      await expect(github).toHaveAttribute("rel", "noopener");

      // The demo (Task 18a) is not built yet: no link to it.
      await expect(page.getByRole("link", { name: l.demoCta })).toHaveCount(0);
    });

    test("says nothing about games, best friends or paying later", async ({ page, request }) => {
      const html = await (await request.get(l.path)).text();
      const withoutScripts = html.replace(/<script[\s\S]*?<\/script>/g, "");
      await page.goto(l.path);
      const text = await page.locator("body").evaluate((body) => body.textContent ?? "");
      for (const pattern of l.banned) {
        expect(withoutScripts).not.toMatch(pattern);
        expect(text).not.toMatch(pattern);
      }
    });

    test("privacy copy promises only what Lukas does today", async ({ page, request }) => {
      // React escapes apostrophes in text ("can't" → "can&#x27;t"): decode before matching.
      const html = (await (await request.get(l.path)).text()).replaceAll("&#x27;", "'");
      const withoutScripts = html.replace(/<script[\s\S]*?<\/script>/g, "");
      await page.goto(l.path);
      const text = await page.locator("body").evaluate((body) => body.textContent ?? "");
      for (const pattern of l.overclaims) {
        expect(withoutScripts).not.toMatch(pattern);
        expect(text).not.toMatch(pattern);
      }
      await expect(page.locator("#privacy")).toContainText(l.privacyAnswer);
    });

    test("has its SEO tags: description, Open Graph, canonical and hreflang", async ({ page }) => {
      await page.goto(l.path);
      const head = page.locator("head");
      const self = `${ORIGIN}${l.path === "/" ? "/" : l.path}`;
      const description = head.locator('meta[name="description"]');
      await expect(description).toHaveAttribute("content", /.{60,}/);
      for (const pattern of l.metaDescription) {
        await expect(description).toHaveAttribute("content", pattern);
      }
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

    test("one primary action: get started → sign-in in this language", async ({ page }) => {
      await page.goto(l.path);
      const hero = page.locator("#hero");
      const cta = hero.getByRole("link", { name: l.cta });
      await expect(cta).toHaveAttribute("href", `/sign-in?lang=${l.locale}`);
      await expect(cta).toHaveClass(/lk-btn-primary/);
      const box = await cta.boundingBox();
      expect(box?.height).toBeGreaterThanOrEqual(44);
    });

    test("use it your way: web is live, Android & iOS and AI are coming soon", async ({ page }) => {
      await page.goto(l.path);
      const [web, mobile, ai] = l.ways.map((name) =>
        page.getByRole("listitem").filter({ has: page.getByRole("heading", { name }) }),
      ) as [ReturnType<Page["locator"]>, ReturnType<Page["locator"]>, ReturnType<Page["locator"]>];
      await expect(web.getByRole("link", { name: l.webCta, exact: true })).toHaveAttribute(
        "href",
        `/sign-in?lang=${l.locale}`,
      );
      await expect(web.getByText(l.soon, { exact: true })).toHaveCount(0);
      for (const card of [mobile, ai]) {
        await expect(card.getByText(l.soon, { exact: true })).toBeVisible();
        await expect(card.getByRole("link")).toHaveCount(0);
      }
      await expect(ai).toContainText("Claude");
      await expect(ai).toContainText("ChatGPT");
    });

    test("imports come from other apps: Budge today, Buddy soon", async ({ page }) => {
      await page.goto(l.path);
      const step = page
        .locator("#how")
        .getByRole("listitem")
        .filter({ has: page.getByRole("heading", { name: l.importStep }) });
      await expect(step).toContainText("Budge");
      await expect(step).toContainText("Buddy");
      const answer = page
        .locator("#faq details")
        .filter({ has: page.getByText(l.importQuestion, { exact: true }) });
      await expect(answer).toContainText("Budge");
      await expect(answer).toContainText("Buddy");
    });

    test("free forever and open source: the FAQ and the section link to the code", async ({
      page,
    }) => {
      await page.goto(l.path);
      const free = page
        .locator("#faq details")
        .filter({ has: page.getByText(l.freeQuestion, { exact: true }) });
      await free.locator("summary").click();
      await expect(free).toContainText(l.freeAnswer);
      await expect(free.getByRole("link", { name: "GitHub" })).toHaveAttribute("href", GITHUB);

      const section = page.locator("#open-source");
      await expect(section.getByRole("heading", { level: 2 })).toHaveText(l.openSource.title);
      await expect(section).toContainText("AGPL-3.0");
      const code = section.getByRole("link", { name: l.openSource.cta });
      await expect(code).toHaveAttribute("href", GITHUB);
      await expect(code).toHaveAttribute("target", "_blank");
      await expect(code).toHaveAttribute("rel", "noopener");
      // Right before the FAQ.
      expect(await section.evaluate((el) => el.nextElementSibling?.id)).toBe("faq");
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
        await expectHeroContrast(page);
      });
    });

    test("fits the viewport and keeps every target at 44px", async ({ page }) => {
      await page.goto(l.path);
      // `.lk-landing` clips horizontal overflow, so the document never scrolls sideways: check
      // every rendered element instead, so content that would be cut off fails here. Nothing on
      // the page is meant to be clipped (no exceptions).
      const overflowing = await page.evaluate(() => {
        const width = document.documentElement.clientWidth;
        return [...document.querySelectorAll(".lk-landing *")]
          .filter((el) => {
            const box = el.getBoundingClientRect();
            if (box.width === 0 && box.height === 0) return false;
            return box.left < -0.5 || box.right > width + 0.5;
          })
          .map(
            (el) => `${el.tagName.toLowerCase()}.${el.className} "${el.textContent?.slice(0, 30)}"`,
          );
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
      await expectHeroContrast(page);
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
