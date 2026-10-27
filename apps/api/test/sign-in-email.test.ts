import { describe, expect, test } from "vitest";
import { claimEmail, signInEmail } from "../src/emails/sign-in.ts";

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
    for (const locale of ["es", "en", "it", "pt"] as const) {
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

  test("Italian: subject, preheader, heading, button, expiry (singular too), ignore note, footer", () => {
    const mail = signInEmail({ ...input, locale: "it" });
    expect(mail.subject).toBe("Il tuo codice Lukitas: 123456");
    expect(mail.html).toContain("Il tuo codice per entrare in Lukitas: 123456");
    expect(mail.html).toContain('lang="it"');
    const text = visibleText(mail.html);
    expect(text).toContain("Ciao! Questo è il tuo codice per entrare");
    expect(text).toContain("ENTRA IN LUKITAS");
    expect(text).toContain("Il codice e il link scadono tra 10 minuti.");
    expect(text).toContain(
      "Se non hai chiesto questa email, ignorala: nessuno può entrare senza questo codice.",
    );
    expect(text).toContain("Lukitas · gratis e open source");
    expect(signInEmail({ ...input, locale: "it", expiresInMinutes: 1 }).text).toContain(
      "scadono tra 1 minuto.",
    );
    // Not Spanish, not English.
    expect(text).not.toMatch(/Tu código|Your Lukitas|ENTRAR A/);
  });

  test("European Portuguese: the tu form, ligação and not link, no Brazilian words", () => {
    const mail = signInEmail({ ...input, locale: "pt" });
    expect(mail.subject).toBe("O teu código Lukitas: 123456");
    expect(mail.html).toContain("Código para entrares em Lukitas: 123456");
    expect(mail.html).toContain('lang="pt"');
    const text = visibleText(mail.html);
    expect(text).toContain("Olá! Este é o teu código para entrar");
    expect(text).toContain("ENTRAR EM LUKITAS");
    expect(text).toContain("O código e a ligação expiram dentro de 10 minutos.");
    expect(text).toContain(
      "Se não pediste este email, ignora-o: ninguém consegue entrar sem este código.",
    );
    expect(text).toContain("Lukitas · grátis e de código aberto");
    expect(signInEmail({ ...input, locale: "pt", expiresInMinutes: 1 }).text).toContain(
      "dentro de 1 minuto.",
    );
    expect(text).not.toMatch(
      /Tu código|Your Lukitas|ENTRAR A|(?<![\p{L}])(você|seu código|celular|ônibus)(?![\p{L}])/iu,
    );
  });

  test("the Brazilian-word guard sees accented words (você, ônibus)", () => {
    const guard = /(?<![\p{L}])(você|seu código|celular|ônibus)(?![\p{L}])/iu;
    expect("Olá, você").toMatch(guard);
    expect("apanha o ônibus").toMatch(guard);
    expect("o teu código").not.toMatch(guard);
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

  test("no language names the product Lukas, or calls it a game", () => {
    for (const locale of ["es", "en", "it", "pt"] as const) {
      const mail = signInEmail({ ...input, locale });
      const all = `${mail.subject}\n${mail.text}\n${visibleText(mail.html)}`;
      expect(all).not.toMatch(/\bLukas\b/);
      expect(all).not.toMatch(/\b(game|juego|gioco|jogo)\b/i);
    }
  });
});

describe("claim email (a guest saves their progress)", () => {
  const claim = { code: "123456", webUrl: WEB_URL, expiresInMinutes: 10 };

  test("Spanish: the save-progress subject and heading, the code, the expiry, no link", () => {
    const mail = claimEmail({ ...claim, locale: "es" });
    expect(mail.subject).toBe("Tu código para guardar tu progreso: 123456");
    const text = visibleText(mail.html);
    expect(text).toContain("Tu código para guardar tu progreso");
    expect(text).toContain("123456");
    expect(text).toContain("El código vence en 10 minutos.");
    expect(text).not.toContain("ENTRAR A LUKITAS");
    expect(text).not.toContain("enlace");
    expect(mail.html).toContain('lang="es"');
    expect(mail.html).not.toContain("/auth/verify");
  });

  test("English: the save-progress subject and heading, the code, the expiry, no link", () => {
    const mail = claimEmail({ ...claim, locale: "en" });
    expect(mail.subject).toBe("Your code to save your progress: 123456");
    const text = visibleText(mail.html);
    expect(text).toContain("Your code to save your progress");
    expect(text).toContain("The code expires in 10 minutes.");
    expect(text).not.toContain("SIGN IN TO LUKITAS");
    expect(text).not.toMatch(/\blink\b/i);
  });

  test("Italian: the save-progress subject and heading, the code, the expiry, no link", () => {
    const mail = claimEmail({ ...claim, locale: "it" });
    expect(mail.subject).toBe("Il tuo codice per salvare i tuoi progressi: 123456");
    const text = visibleText(mail.html);
    expect(text).toContain("Il tuo codice per salvare i tuoi progressi");
    expect(text).toContain("Scrivilo in Lukitas per salvare i tuoi progressi con questa email.");
    expect(text).toContain("Il codice scade tra 10 minuti.");
    expect(text).not.toContain("ENTRA IN LUKITAS");
    expect(text).not.toMatch(/\blink\b|pulsante/i);
    expect(mail.html).toContain('lang="it"');
  });

  test("European Portuguese: the save-progress subject and heading, the code, the expiry, no link", () => {
    const mail = claimEmail({ ...claim, locale: "pt" });
    expect(mail.subject).toBe("O teu código para guardares o teu progresso: 123456");
    const text = visibleText(mail.html);
    expect(text).toContain("O teu código para guardares o teu progresso");
    expect(text).toContain("Escreve-o em Lukitas para guardar o teu progresso com este email.");
    expect(text).toContain("O código expira dentro de 10 minutos.");
    expect(text).not.toContain("ENTRAR EM LUKITAS");
    expect(text).not.toMatch(/\bligação\b|\blink\b|botão/i);
    expect(mail.html).toContain('lang="pt"');
  });

  test("the text part has the code and the web URL, and no other link", () => {
    for (const locale of ["es", "en", "it", "pt"] as const) {
      const mail = claimEmail({ ...claim, locale });
      expect(mail.text).toContain("123456");
      expect(mail.text.match(/https?:\/\/\S+/g)).toEqual([WEB_URL]);
    }
  });

  test("the same layout as sign-in: the mascot, the brand palette, email-safe HTML", () => {
    const { html } = claimEmail({ ...claim, locale: "es" });
    expect(html).toContain(`src="${WEB_URL}/email/lukitas-wave.png"`);
    expect(html).toContain("#f7f4ff");
    expect(html).toContain('role="presentation"');
    expect(html).not.toMatch(/<script/i);
  });
});
