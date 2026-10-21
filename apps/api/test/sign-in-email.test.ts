import { describe, expect, test } from "vitest";
import { signInEmail } from "../src/emails/sign-in.ts";

const WEB_URL = "https://lukitas.example";
const link = `${WEB_URL}/auth/verify?email=a%40lukas.test&code=123456&lang=es&next=%2Fapp%2Finsights`;
const input = { code: "123456", link, webUrl: WEB_URL, expiresInMinutes: 10 };

/** The visible text of the HTML: no tags, no style, no hidden preheader. */
const visibleText = (html: string) =>
  html
    .replace(/<style[\s\S]*?<\/style>/g, "")
    .replace(/<!--[\s\S]*?-->/g, "")
    .replace(/<div[^>]*display:none[\s\S]*?<\/div>/g, "")
    .replace(/<[^>]+>/g, " ")
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ");

describe("sign-in email", () => {
  test("Spanish: subject, preheader, heading, code, button, expiry, ignore note, footer", () => {
    const mail = signInEmail({ ...input, locale: "es" });
    expect(mail.subject).toBe("Tu código de Lukitas: 123456");
    expect(mail.html).toContain("Tu código para entrar a Lukitas: 123456");
    const text = visibleText(mail.html);
    expect(text).toContain("¡Hola! Este es tu código para entrar");
    expect(text).toContain("123456");
    expect(text).toContain("ENTRAR A LUKITAS");
    expect(text).toContain("El código y el enlace vencen en 10 minutos.");
    expect(text).toContain(
      "Si no pediste este correo, ignóralo: nadie puede entrar sin este código.",
    );
    expect(text).toContain("Lukitas · gratis y de código abierto");
    expect(mail.html).toContain('lang="es"');
  });

  test("English: subject, preheader, heading, code, button, expiry, ignore note, footer", () => {
    const mail = signInEmail({ ...input, locale: "en", expiresInMinutes: 15 });
    expect(mail.subject).toBe("Your Lukitas code: 123456");
    expect(mail.html).toContain("Your Lukitas sign-in code: 123456");
    const text = visibleText(mail.html);
    expect(text).toContain("Hi! Here is your sign-in code");
    expect(text).toContain("SIGN IN TO LUKITAS");
    expect(text).toContain("The code and the link expire in 15 minutes.");
    expect(text).toContain(
      "If you didn't ask for this email, ignore it: nobody can sign in without this code.",
    );
    expect(text).toContain("Lukitas · free and open source");
    expect(mail.html).toContain('lang="en"');
  });

  test("the expiry is the one passed in, singular for one minute", () => {
    expect(signInEmail({ ...input, locale: "es", expiresInMinutes: 5 }).text).toContain(
      "vencen en 5 minutos.",
    );
    expect(signInEmail({ ...input, locale: "es", expiresInMinutes: 1 }).text).toContain(
      "vencen en 1 minuto.",
    );
    expect(signInEmail({ ...input, locale: "en", expiresInMinutes: 1 }).text).toContain(
      "expire in 1 minute.",
    );
  });

  test("the button, and the link behind it, are the magic link as given", () => {
    const mail = signInEmail({ ...input, locale: "es" });
    const escaped = link.replace(/&/g, "&amp;");
    expect(mail.html).toContain(`href="${escaped}"`);
    expect(
      mail.html.match(new RegExp(`href="${escaped.replace(/[?]/g, "\\?")}"`, "g"))?.length,
    ).toBeGreaterThanOrEqual(2);
  });

  test("the text part has the same content, with the raw link on its own line", () => {
    for (const locale of ["es", "en"] as const) {
      const mail = signInEmail({ ...input, locale });
      expect(mail.text.split("\n")).toContain(link);
      expect(mail.text).toContain("123456");
      expect(mail.text).toContain("10 ");
      expect(mail.text).toContain(WEB_URL);
    }
    expect(signInEmail({ ...input, locale: "es" }).text).toContain(
      "¡Hola! Este es tu código para entrar",
    );
    expect(signInEmail({ ...input, locale: "es" }).text).toContain(
      "Lukitas · gratis y de código abierto",
    );
  });

  test("the text part gives the magic link before any other URL", () => {
    // Callers (and the e2e helpers) take the first URL in the text as the magic link.
    const mail = signInEmail({ ...input, locale: "es" });
    expect(/https?:\/\/\S+/.exec(mail.text)?.[0]).toBe(link);
  });

  test("Lukitas waves at the top: the image URL is built from WEB_URL, with size and alt", () => {
    const mail = signInEmail({ ...input, locale: "es" });
    const img = /<img[^>]*lukitas-wave\.png[^>]*>/.exec(mail.html)?.[0] ?? "";
    expect(img).toContain(`src="${WEB_URL}/email/lukitas-wave.png"`);
    expect(img).toContain('width="160"');
    expect(img).toContain('height="160"');
    expect(img).toMatch(/alt="[^"]+"/);
    // The first thing in the card area, before the heading.
    expect(mail.html.indexOf("lukitas-wave.png")).toBeLessThan(mail.html.indexOf("¡Hola!"));
  });

  test("a trailing slash on WEB_URL does not double up in the image or footer URLs", () => {
    const mail = signInEmail({ ...input, webUrl: `${WEB_URL}/`, locale: "en" });
    expect(mail.html).toContain(`src="${WEB_URL}/email/lukitas-wave.png"`);
    expect(mail.html).toContain(`href="${WEB_URL}"`);
  });

  test("the HTML is email-safe: tables, inline styles, no scripts, no external CSS or fonts", () => {
    const { html } = signInEmail({ ...input, locale: "es" });
    expect(html).toMatch(/^<!doctype html>/i);
    expect(html).toContain('role="presentation"');
    expect(html).toMatch(/max-width:\s*600px/);
    expect(html).not.toMatch(/<script/i);
    expect(html).not.toMatch(/<link[^>]+stylesheet/i);
    expect(html).not.toMatch(/@import|@font-face/i);
    expect(html).toMatch(/font-family:[^;"]*Fredoka[^;"]*Arial/);
    expect(html).toContain("#f7f4ff");
  });

  test("a hidden preheader comes first in the body", () => {
    const { html } = signInEmail({ ...input, locale: "es" });
    const body = html.slice(html.indexOf("<body"));
    const hidden = body.search(/display:none/);
    expect(hidden).toBeGreaterThan(-1);
    expect(hidden).toBeLessThan(body.indexOf("¡Hola!"));
  });

  test("escapes a malicious next in the HTML (and keeps it as given in the text)", () => {
    const evil = `${WEB_URL}/auth/verify?code=1&next=${encodeURIComponent('"><script>alert(1)</script>')}`;
    const raw = `${WEB_URL}/auth/verify?code=1&next="><script>alert(1)</script>`;
    for (const url of [evil, raw]) {
      const mail = signInEmail({ ...input, link: url, locale: "es" });
      expect(mail.html).not.toContain("<script");
      expect(mail.html).not.toContain('"><script');
    }
    const mail = signInEmail({ ...input, link: raw, locale: "es" });
    expect(mail.html).toContain("&quot;&gt;&lt;script&gt;");
    expect(mail.text).toContain(raw);
  });

  test("escapes the code, the web URL and the expiry in the HTML", () => {
    const mail = signInEmail({
      code: '<b>"&</b>',
      link,
      webUrl: 'https://x.test/"><img src=x onerror=alert(1)>',
      expiresInMinutes: 10,
      locale: "en",
    });
    expect(mail.html).not.toContain("<b>");
    expect(mail.html).not.toMatch(/<img src=x/);
    expect(mail.html).toContain("&lt;b&gt;&quot;&amp;&lt;/b&gt;");
  });

  test("neither language names the product Lukas, or calls it a game", () => {
    for (const locale of ["es", "en"] as const) {
      const mail = signInEmail({ ...input, locale });
      const all = `${mail.subject}\n${mail.text}\n${visibleText(mail.html)}`;
      expect(all).not.toMatch(/\bLukas\b/);
      expect(all).not.toMatch(/\b(game|juego)\b/i);
    }
  });
});
