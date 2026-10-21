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
    lead: "Lukitas es tu presupuesto, y te va a dar gusto cuidarlo.",
    description: "Anota un gasto en segundos y mira en qué se va cada luka.",
    newTab: "(se abre en una pestaña nueva)",
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
    // Privacy copy claims only what Lukitas does today: no "can't leak", no end-to-end encryption,
    // no encryption at rest.
    overclaims: [/se pueda filtrar/i, /extremo a extremo/i, /no podemos ver/i, /en reposo/i],
    privacyAnswer:
      "Tus datos viajan cifrados y nunca los vendemos ni los compartimos con anunciantes.",
    faq: "Preguntas frecuentes",
    privacy: "Privacidad",
    signIn: "Entrar",
    toggleToDay: "Cambiar a modo día",
    toggleToNight: "Cambiar a modo noche",
    other: { name: "English", path: "/en" },
    titlePart: "Tus lukas, por fin claras",
  },
  {
    locale: "en",
    path: "/en",
    headline: "Your money, finally clear.",
    highlight: "money",
    annotation: "Free, and it always will be!",
    lead: "Lukitas is your budget, and you'll actually enjoy looking after it.",
    description: "Log an expense in seconds and see where every buck goes.",
    newTab: "(opens in a new tab)",
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
    signIn: "Sign in",
    toggleToDay: "Switch to day mode",
    toggleToNight: "Switch to night mode",
    other: { name: "Español", path: "/" },
    titlePart: "Your money, finally clear",
  },
] as const;

/** The roadmap page and the landing's what's-next section, per language. */
const ROADMAP = {
  es: {
    path: "/roadmap",
    otherPath: "/en/roadmap",
    title: "Lo que viene",
    titlePart: "Lo que viene",
    intro: "Esto es lo que tenemos planeado. Puede cambiar con el tiempo.",
    columns: [
      {
        label: "En construcción",
        items: ["App web", "Importa tu historial de Budge", "Pruébalo sin cuenta"],
      },
      {
        label: "Próximo",
        items: ["Android: widget con micrófono", "Varios gastos en una frase", "Conecta tu IA"],
      },
      {
        label: "Más adelante",
        items: [
          "App para iPhone",
          "Captura automática de las alertas de tu banco",
          "Importa desde Buddy y otras apps",
        ],
      },
    ],
    emptyLabel: "Ya está",
    landingItems: ["Android: widget con micrófono", "Varios gastos en una frase", "Conecta tu IA"],
    cta: "Ver el roadmap",
    navLink: "Lo que viene",
    description: /Lo que tenemos planeado para Lukitas/,
    logo: "Lukitas, inicio",
  },
  en: {
    path: "/en/roadmap",
    otherPath: "/roadmap",
    title: "What's next",
    titlePart: "What's next",
    intro: "This is what we have planned. It may change over time.",
    columns: [
      {
        label: "Being built",
        items: ["Web app", "Import your history from Budge", "Try it without an account"],
      },
      {
        label: "Next",
        items: [
          "Android: widget with a microphone",
          "Several expenses in one sentence",
          "Connect your AI",
        ],
      },
      {
        label: "Later",
        items: [
          "iPhone app",
          "Automatic capture of your bank's alerts",
          "Import from Buddy and other apps",
        ],
      },
    ],
    emptyLabel: "Live",
    landingItems: [
      "Android: widget with a microphone",
      "Several expenses in one sentence",
      "Connect your AI",
    ],
    cta: "See the roadmap",
    navLink: "What's next",
    description: /What we have planned for Lukitas/,
    logo: "Lukitas, home",
  },
} as const;

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

/**
 * Nothing sticks out of the viewport and every target is at least 44px. `.lk-landing` clips
 * horizontal overflow, so the document never scrolls sideways: check every rendered element
 * instead, so content that would be cut off fails here. Nothing on the page is meant to be
 * clipped (no exceptions).
 */
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

/**
 * The header at one width and theme: the wordmark on one line, the CTA and the ☾ switch on the
 * same row, and nothing sticking out of the viewport.
 */
async function expectHeaderFits(
  page: Page,
  path: string,
  width: number,
  theme: "night" | "day",
  cta: string,
) {
  await page.setViewportSize({ width, height: 800 });
  await page.addInitScript((value) => localStorage.setItem("lukas.theme", value), theme);
  await page.goto(path);
  await expect(page.locator("html")).toHaveAttribute("data-theme", theme);
  const header = page.getByRole("banner");
  const logo = header.locator(".lk-logo");
  const nav = header.getByRole("navigation");
  const link = nav.getByRole("link", { name: cta });
  const toggle = nav.getByRole("button");
  await expect(logo).toBeVisible();
  await expect(link).toBeVisible();
  await expect(toggle).toBeVisible();
  const [logoBox, linkBox, toggleBox] = [
    await logo.boundingBox(),
    await link.boundingBox(),
    await toggle.boundingBox(),
  ];
  // One line of the 28px wordmark, not two.
  expect(logoBox?.height).toBeLessThan(40);
  // One row: the three share a vertical band.
  const rowTop = Math.min(logoBox?.y ?? 0, linkBox?.y ?? 0, toggleBox?.y ?? 0);
  const rowBottom = Math.max(
    (logoBox?.y ?? 0) + (logoBox?.height ?? 0),
    (linkBox?.y ?? 0) + (linkBox?.height ?? 0),
    (toggleBox?.y ?? 0) + (toggleBox?.height ?? 0),
  );
  expect(rowBottom - rowTop).toBeLessThan(80);
  // The wordmark clears the CTA, and the switch ends inside the viewport.
  expect((logoBox?.x ?? 0) + (logoBox?.width ?? 0)).toBeLessThanOrEqual(linkBox?.x ?? 0);
  expect((toggleBox?.x ?? 0) + (toggleBox?.width ?? 0)).toBeLessThanOrEqual(width);
  expect(linkBox?.height).toBeGreaterThanOrEqual(44);
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth - document.documentElement.clientWidth,
    ),
  ).toBeLessThanOrEqual(0);
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

      // The visible text is the perks; the link to GitHub adds a hidden "opens in a new tab".
      await expect(hero.locator(".lk-landing-perks")).toHaveText(
        l.perks.replace(l.openSourcePerk, `${l.openSourcePerk} ${l.newTab}`),
      );
      const github = hero.getByRole("link", { name: l.openSourcePerk });
      await expect(github.locator(".sr-only")).toHaveText(l.newTab);
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

    test("names the product Lukitas everywhere a person or a crawler reads it", async ({
      page,
      request,
    }) => {
      // The product is Lukitas; "Lukas" alone is another app. The slang word "lukas" (money, in
      // lowercase) stays in the Spanish copy, so only the capitalized name is banned.
      await page.goto(l.path);
      const seen = await page.evaluate(() => {
        const attributes = [...document.querySelectorAll("[aria-label], [alt], [title]")].flatMap(
          (element) =>
            ["aria-label", "alt", "title"].map((name) => element.getAttribute(name) ?? ""),
        );
        const meta = [...document.querySelectorAll("head meta[content]")].map(
          (element) => element.getAttribute("content") ?? "",
        );
        const body = document.body.cloneNode(true) as HTMLElement;
        for (const script of body.querySelectorAll("script, style")) script.remove();
        return {
          body: body.textContent ?? "",
          title: document.title,
          attributes,
          meta,
        };
      });
      expect(seen.body).toContain("Lukitas");
      expect(seen.title).toContain("Lukitas");
      const everything = [seen.body, seen.title, ...seen.attributes, ...seen.meta].join("\n");
      expect(everything).not.toMatch(/\bLukas\b/);
      const html = await (await request.get(l.path)).text();
      expect(html.replace(/<script[\s\S]*?<\/script>/g, "")).not.toMatch(/\bLukas\b/);
      await expect(page.locator('meta[property="og:site_name"]')).toHaveAttribute(
        "content",
        "Lukitas",
      );
    });

    test("privacy copy promises only what Lukitas does today", async ({ page, request }) => {
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
      await expect(code.locator(".sr-only")).toHaveText(l.newTab);
      // Then "what's next", and the FAQ after it.
      expect(await section.evaluate((el) => el.nextElementSibling?.id)).toBe("whats-next");
    });

    test("what's next: three planned items and a button to the roadmap", async ({ page }) => {
      const r = ROADMAP[l.locale];
      await page.goto(l.path);
      const section = page.locator("#whats-next");
      await expect(section.getByRole("heading", { level: 2 })).toHaveText(r.title);
      await expect(section).toContainText(r.intro);
      const cards = section.getByRole("listitem");
      await expect(cards).toHaveCount(3);
      for (const [index, title] of r.landingItems.entries()) {
        await expect(cards.nth(index).getByRole("heading", { level: 3 })).toHaveText(title);
      }
      // The same card look as "use it your way".
      await expect(cards.first()).toHaveClass(/lk-landing-card/);
      const button = section.getByRole("link", { name: r.cta });
      await expect(button).toHaveAttribute("href", r.path);
      await expect(button).not.toHaveAttribute("target", /.+/);
      await expect(button).toHaveClass(/lk-btn-secondary/);
      // After "open source", before the FAQ.
      expect(await section.evaluate((el) => el.previousElementSibling?.id)).toBe("open-source");
      expect(await section.evaluate((el) => el.nextElementSibling?.id)).toBe("faq");
      // No call to propose or vote.
      await expect(section.getByRole("link")).toHaveCount(1);
    });

    test("the footer links to the roadmap, and the header does on a wide screen", async ({
      page,
    }) => {
      const r = ROADMAP[l.locale];
      await page.goto(l.path);
      const footerLink = page.getByRole("contentinfo").getByRole("link", { name: r.navLink });
      await expect(footerLink).toHaveAttribute("href", r.path);
      await expect(footerLink).not.toHaveAttribute("aria-current", /.+/);
      // The active language is marked the same way on the landing.
      await expect(
        page
          .getByRole("contentinfo")
          .getByRole("link", { name: l.locale === "es" ? "Español" : "English" }),
      ).toHaveAttribute("aria-current", "true");
      const headerLink = page.getByRole("banner").getByRole("link", { name: r.navLink });
      // The phone header has no room for it (hidden, so not in the accessibility tree); from
      // 900px it sits among the section links.
      if ((page.viewportSize()?.width ?? 0) >= 900) {
        await expect(headerLink).toHaveAttribute("href", r.path);
        await expect(headerLink).toBeVisible();
        const names = await page
          .getByRole("banner")
          .getByRole("navigation")
          .getByRole("link")
          .allInnerTexts();
        expect(names.slice(0, 3)).toEqual([
          l.locale === "es" ? "Cómo funciona" : "How it works",
          r.navLink,
          l.locale === "es" ? "Preguntas" : "Questions",
        ]);
      } else {
        await expect(headerLink).toHaveCount(0);
        await expect(page.locator("header a[href='" + r.path + "']")).toBeHidden();
      }
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
      await expect(footer).toContainText("© 2026 Lukitas");

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

    test.describe(() => {
      // The inline theme script alone (the app's scripts are blocked): with nothing stored the page
      // is night even when the OS prefers light; only a stored "auto" follows the OS.
      test.use({ javaScriptEnabled: true, colorScheme: "light" });

      test("is night by default, even on a light OS", async ({ page }) => {
        await page.route("**/assets/*.js", (route) => route.abort());
        await page.goto(l.path);
        await expect(page.locator("html")).toHaveAttribute("data-theme", "night");
      });

      test("follows the OS when the stored preference is auto", async ({ page }) => {
        await page.route("**/assets/*.js", (route) => route.abort());
        await page.addInitScript(() => localStorage.setItem("lukas.theme", "auto"));
        await page.goto(l.path);
        await expect(page.locator("html")).toHaveAttribute("data-theme", "day");
      });
    });

    test("the header has the day/night switch next to sign-in", async ({ page }) => {
      await page.goto(l.path);
      const nav = page.getByRole("banner").getByRole("navigation");
      const toggle = nav.getByRole("button", { name: l.toggleToDay });
      await expect(toggle).toBeVisible();
      await expect(toggle).not.toHaveAttribute("aria-pressed");
      const signIn = nav.getByRole("link", { name: l.signIn });
      const [toggleBox, signInBox] = [await toggle.boundingBox(), await signIn.boundingBox()];
      expect(toggleBox?.width).toBeGreaterThanOrEqual(44);
      expect(toggleBox?.height).toBeGreaterThanOrEqual(44);
      // Same row, to the right of "Sign in".
      expect(Math.abs((toggleBox?.y ?? 0) - (signInBox?.y ?? 0))).toBeLessThan(24);
      expect(toggleBox?.x).toBeGreaterThan((signInBox?.x ?? 0) + (signInBox?.width ?? 0));
    });

    test.describe(() => {
      test.use({ javaScriptEnabled: true });

      for (const width of [320, 390, 1280]) {
        for (const theme of ["night", "day"] as const) {
          test(`the header fits at ${width}px, ${theme} theme`, async ({ page }) => {
            await expectHeaderFits(page, l.path, width, theme, l.signIn);
          });
        }
      }
    });

    test("fits the viewport and keeps every target at 44px", async ({ page }) => {
      await page.goto(l.path);
      await expectFitsTheViewport(page);
    });

    test("shows Lukas waving, and still under reduced motion", async ({ page }) => {
      await page.goto(l.path);
      const mascot = page.locator("#hero [data-slot='hero-mascot']");
      await expect(mascot).toHaveAttribute("role", "img");
      await expect(mascot).toHaveAttribute("aria-label", /Lukitas/);
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
      // Night is the default: day comes from the stored choice (what the switch saves).
      await page.addInitScript(() => localStorage.setItem("lukas.theme", "day"));
      await page.goto(l.path);
      await expect(page.locator("html")).toHaveAttribute("data-theme", "day");
      await expect(
        page.getByRole("banner").getByRole("button", { name: l.toggleToNight }),
      ).toBeVisible();
      await expectNoA11yViolations(page);
      await expectHeroContrast(page);
    });

    test(`the switch changes the theme and it persists after a reload (${l.locale})`, async ({
      page,
    }) => {
      await page.goto(l.path);
      await page.waitForLoadState("networkidle");
      const html = page.locator("html");
      await expect(html).toHaveAttribute("data-theme", "night");

      const header = page.getByRole("banner");
      await header.getByRole("button", { name: l.toggleToDay }).click();
      await expect(html).toHaveAttribute("data-theme", "day");
      expect(await page.evaluate(() => localStorage.getItem("lukas.theme"))).toBe("day");

      // The bootstrap script applies it before paint; the switch then offers the way back.
      await page.reload();
      await expect(html).toHaveAttribute("data-theme", "day");
      await page.waitForLoadState("networkidle");
      await header.getByRole("button", { name: l.toggleToNight }).click();
      await expect(html).toHaveAttribute("data-theme", "night");
      expect(await page.evaluate(() => localStorage.getItem("lukas.theme"))).toBe("night");
    });
  }
});

for (const l of LOCALES) {
  const r = ROADMAP[l.locale];
  const self = `${ORIGIN}${r.path}`;

  test.describe(`roadmap (${l.locale})`, () => {
    test("the prerendered HTML carries the plan, without JavaScript", async ({ page, request }) => {
      const html = (await (await request.get(r.path)).text()).replaceAll("&#x27;", "'");
      expect(html).toContain(`<html lang="${l.locale}"`);
      expect(html).toContain(r.intro);
      for (const column of r.columns) {
        expect(html).toContain(column.label);
        for (const item of column.items) expect(html).toContain(item);
      }

      await page.goto(r.path);
      await expect(page.getByRole("heading", { level: 1 })).toHaveText(r.title);
      await expect(page.getByRole("main")).toContainText(r.intro);
      await expect(page).toHaveTitle(new RegExp(r.titlePart));
    });

    test("shows a column per status that has items, with its items", async ({ page }) => {
      await page.goto(r.path);
      const main = page.getByRole("main");
      // Only the columns with items render: "done" stays empty for now.
      await expect(main.getByRole("heading", { level: 2 })).toHaveText(
        r.columns.map((column) => column.label),
      );
      await expect(main.getByText(r.emptyLabel, { exact: true })).toHaveCount(0);
      for (const column of r.columns) {
        const section = main.getByRole("region", { name: column.label });
        await expect(section.getByRole("heading", { level: 3 })).toHaveText(column.items);
        await expect(section.getByRole("listitem")).toHaveCount(column.items.length);
        // Each item: a glyph, its title and one line.
        for (const card of await section.getByRole("listitem").all()) {
          expect(await card.locator("p").count()).toBe(1);
          expect(((await card.locator("p").innerText()) ?? "").trim().length).toBeGreaterThan(8);
          await expect(card.locator(".lk-landing-icon")).toHaveAttribute("aria-hidden", "true");
          expect(
            (await card.locator(".lk-landing-icon").innerText()).trim().length,
          ).toBeGreaterThan(0);
        }
      }
    });

    test("is one column on a phone and side by side on a desktop", async ({ page }) => {
      await page.goto(r.path);
      const sections = page.getByRole("main").getByRole("region");
      await expect(sections).toHaveCount(r.columns.length);
      const boxes = await sections.evaluateAll((nodes) =>
        nodes.map((node) => {
          const box = node.getBoundingClientRect();
          return { left: box.left, top: box.top };
        }),
      );
      const wide = (page.viewportSize()?.width ?? 0) >= 900;
      const tops = new Set(boxes.map((box) => Math.round(box.top)));
      const lefts = new Set(boxes.map((box) => Math.round(box.left)));
      if (wide) {
        expect(tops.size).toBe(1);
        expect(lefts.size).toBe(boxes.length);
      } else {
        expect(tops.size).toBe(boxes.length);
        expect(lefts.size).toBe(1);
      }
    });

    test("promises no dates, asks for no proposals or votes and is not a game", async ({
      page,
      request,
    }) => {
      const html = (await (await request.get(r.path)).text()).replaceAll("&#x27;", "'");
      // The page's words as a crawler reads them: no scripts, no tags (asset names have hashes).
      const withoutScripts = html
        .replace(/<script[\s\S]*?<\/script>/g, "")
        .replace(/<[^>]+>/g, " ")
        // The copyright year is the one year on the page.
        .replace(/©\s*\d{4}/, "©");
      await page.goto(r.path);
      const text = await page.getByRole("main").evaluate((main) => main.textContent ?? "");
      const forbidden = [
        ...l.banned,
        /\b(20\d\d|Q[1-4])\b/,
        /discussions/i,
        /\bvot(a|o|e|ar|ing|es)\b/i,
        /\bpropon(e|er|ga)\b|\bpropose\b/i,
      ];
      for (const pattern of forbidden) {
        expect(text).not.toMatch(pattern);
        expect(withoutScripts).not.toMatch(pattern);
      }
      // The only links in the content are the header's and the footer's: none leads out.
      await expect(page.getByRole("main").getByRole("link")).toHaveCount(0);
      expect(
        await page
          .locator("a[href]")
          .evaluateAll((nodes) =>
            nodes
              .map((node) => node.getAttribute("href") ?? "")
              .filter((href) => /github/i.test(href)),
          ),
      ).toEqual([]);
    });

    test("names the product Lukitas in the text, the title and the share tags", async ({
      page,
      request,
    }) => {
      await page.goto(r.path);
      const seen = await page.evaluate(() => {
        const attributes = [...document.querySelectorAll("[aria-label], [alt], [title]")].flatMap(
          (element) =>
            ["aria-label", "alt", "title"].map((name) => element.getAttribute(name) ?? ""),
        );
        const meta = [...document.querySelectorAll("head meta[content]")].map(
          (element) => element.getAttribute("content") ?? "",
        );
        const body = document.body.cloneNode(true) as HTMLElement;
        for (const script of body.querySelectorAll("script, style")) script.remove();
        return { body: body.textContent ?? "", title: document.title, attributes, meta };
      });
      expect(seen.body).toContain("Lukitas");
      expect(seen.title).toContain("Lukitas");
      const everything = [seen.body, seen.title, ...seen.attributes, ...seen.meta].join("\n");
      expect(everything).not.toMatch(/\bLukas\b/);
      const html = await (await request.get(r.path)).text();
      expect(html.replace(/<script[\s\S]*?<\/script>/g, "")).not.toMatch(/\bLukas\b/);
      await expect(page.locator('meta[property="og:site_name"]')).toHaveAttribute(
        "content",
        "Lukitas",
      );
    });

    test("has its own SEO tags: title, description, Open Graph, canonical and hreflang", async ({
      page,
    }) => {
      await page.goto(r.path);
      const head = page.locator("head");
      const description = head.locator('meta[name="description"]');
      await expect(description).toHaveAttribute("content", /.{60,}/);
      await expect(description).toHaveAttribute("content", r.description);
      await expect(head.locator('link[rel="canonical"]')).toHaveAttribute("href", self);
      await expect(head.locator('link[rel="alternate"][hreflang="es"]')).toHaveAttribute(
        "href",
        `${ORIGIN}/roadmap`,
      );
      await expect(head.locator('link[rel="alternate"][hreflang="en"]')).toHaveAttribute(
        "href",
        `${ORIGIN}/en/roadmap`,
      );
      await expect(head.locator('link[rel="alternate"][hreflang="x-default"]')).toHaveAttribute(
        "href",
        `${ORIGIN}/roadmap`,
      );
      await expect(head.locator('meta[property="og:title"]')).toHaveAttribute(
        "content",
        new RegExp(r.titlePart),
      );
      await expect(head.locator('meta[property="og:description"]')).toHaveAttribute(
        "content",
        r.description,
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

    test("has the landing's header and footer: logo home, sign-in, theme switch, language", async ({
      page,
    }) => {
      await page.goto(r.path);
      const header = page.getByRole("banner");
      await expect(header.getByRole("link", { name: r.logo })).toHaveAttribute("href", l.path);
      await expect(header.getByRole("link", { name: l.signIn })).toHaveAttribute(
        "href",
        `/sign-in?lang=${l.locale}`,
      );
      await expect(header.getByRole("button", { name: l.toggleToDay })).toBeVisible();
      if ((page.viewportSize()?.width ?? 0) >= 900) {
        const link = header.getByRole("link", { name: r.navLink });
        await expect(link).toHaveAttribute("aria-current", "page");
        // The section links lead back to the landing's sections.
        await expect(
          header.getByRole("link", { name: l.locale === "es" ? "Cómo funciona" : "How it works" }),
        ).toHaveAttribute("href", `${l.path}#how`);
      }
      const footer = page.getByRole("contentinfo");
      await expect(footer.getByRole("link", { name: r.navLink })).toHaveAttribute(
        "aria-current",
        "page",
      );
      // Only the page link is "current": the active language is marked another way.
      await expect(footer.locator('a[aria-current="page"]')).toHaveCount(1);
      await expect(
        footer.getByRole("link", { name: l.locale === "es" ? "Español" : "English" }),
      ).toHaveAttribute("aria-current", "true");
      await expect(footer.getByRole("link", { name: l.privacy })).toHaveAttribute(
        "href",
        `${l.path}#privacy`,
      );
      await expect(footer).toContainText("© 2026 Lukitas");

      // The language switch keeps the page.
      const switchLink = footer.getByRole("link", { name: l.other.name });
      await expect(switchLink).toHaveAttribute("href", r.otherPath);
      await switchLink.click();
      await expect(page).toHaveURL(new RegExp(`${r.otherPath}$`));
      await expect(page.locator("html")).toHaveAttribute("lang", l.locale === "es" ? "en" : "es");
    });

    test("fits the viewport and keeps every target at 44px", async ({ page }) => {
      await page.goto(r.path);
      await expectFitsTheViewport(page);
    });

    test.describe("at 320px", () => {
      test.use({ viewport: { width: 320, height: 700 } });

      test("nothing overflows", async ({ page }) => {
        await page.goto(r.path);
        await expectFitsTheViewport(page);
      });

      test("the landing's what's-next section does not overflow either", async ({ page }) => {
        await page.goto(l.path);
        await expectFitsTheViewport(page);
      });
    });

    test.describe(() => {
      test.use({ javaScriptEnabled: true, colorScheme: "dark" });

      test("the prerendered page is accessible (axe, night theme)", async ({ page }) => {
        await page.route("**/assets/*.js", (route) => route.abort());
        await page.goto(r.path);
        await expect(page.locator("html")).toHaveAttribute("data-theme", "night");
        await expectNoA11yViolations(page);
      });
    });

    test.describe(() => {
      test.use({ javaScriptEnabled: true });

      test("is accessible in the day theme and hydrates cleanly", async ({ page }) => {
        const errors: string[] = [];
        page.on("console", (message) => {
          if (message.type() === "error") errors.push(message.text());
        });
        page.on("pageerror", (error) => errors.push(error.message));
        await page.addInitScript(() => localStorage.setItem("lukas.theme", "day"));
        await page.goto(r.path);
        await page.waitForLoadState("networkidle");
        await expect(page.locator("html")).toHaveAttribute("data-theme", "day");
        await expectNoA11yViolations(page);
        expect(errors).toEqual([]);
      });

      test("the landing's button opens the roadmap and the logo comes back", async ({ page }) => {
        const errors: string[] = [];
        page.on("pageerror", (error) => errors.push(error.message));
        await page.goto(l.path);
        await page.waitForLoadState("networkidle");
        await page.locator("#whats-next").getByRole("link", { name: r.cta }).click();
        await expect(page).toHaveURL(new RegExp(`${r.path}$`));
        await expect(page.getByRole("heading", { level: 1 })).toHaveText(r.title);
        await expect(page.locator("html")).toHaveAttribute("lang", l.locale);
        await page.getByRole("banner").getByRole("link", { name: r.logo }).click();
        await expect(page).toHaveURL(new RegExp(`${l.path === "/" ? "/" : l.path}$`));
        expect(errors).toEqual([]);
      });
    });
  });
}

test.describe("static files", () => {
  test("robots.txt, sitemap.xml and the Open Graph images are served", async ({ request }) => {
    const robots = await (await request.get("/robots.txt")).text();
    expect(robots).toContain("Sitemap: https://lukas.app/sitemap.xml");
    expect(robots).toContain("Disallow: /app");

    const sitemap = await (await request.get("/sitemap.xml")).text();
    expect(sitemap).toContain("<loc>https://lukas.app/</loc>");
    expect(sitemap).toContain("<loc>https://lukas.app/en</loc>");
    expect(sitemap).toContain('hreflang="x-default"');
    expect(sitemap).toContain("<loc>https://lukas.app/roadmap</loc>");
    expect(sitemap).toContain("<loc>https://lukas.app/en/roadmap</loc>");

    for (const locale of ["es", "en"]) {
      const image = await request.get(`/og-${locale}.png`);
      expect(image.headers()["content-type"]).toBe("image/png");
      const bytes = await image.body();
      // PNG IHDR: width and height are big-endian at bytes 16 and 20.
      expect([bytes.readUInt32BE(16), bytes.readUInt32BE(20)]).toEqual([1200, 630]);
    }
  });
});
