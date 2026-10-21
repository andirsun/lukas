import { describe, expect, test } from "vitest";
import { signInEmail } from "../src/emails/sign-in.ts";

const input = { code: "123456", link: "https://example.test/auth/verify?code=123456" };

describe("sign-in email", () => {
  test("Spanish: Lukitas in the subject and the body", () => {
    const mail = signInEmail({ ...input, locale: "es" });
    expect(mail.subject).toBe("Tu código de Lukitas: 123456");
    expect(mail.text).toContain("Usa este código para entrar a Lukitas:");
    expect(mail.html).toContain("Usa este código para entrar a Lukitas:");
  });

  test("English: Lukitas in the subject and the body", () => {
    const mail = signInEmail({ ...input, locale: "en" });
    expect(mail.subject).toBe("Your Lukitas code: 123456");
    expect(mail.text).toContain("Use this code to sign in to Lukitas:");
    expect(mail.html).toContain("Use this code to sign in to Lukitas:");
  });

  test("neither language names the product Lukas", () => {
    for (const locale of ["es", "en"] as const) {
      const mail = signInEmail({ ...input, locale });
      expect(`${mail.subject}\n${mail.text}\n${mail.html}`).not.toMatch(/\bLukas\b/);
    }
  });
});
