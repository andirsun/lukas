import { emailThrottle, user } from "@lukas/db";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { isSignInAllowed } from "../src/auth.ts";
import { codeFrom, createTestApp, type TestApp } from "./harness.ts";

describe("isSignInAllowed", () => {
  test("with no allowlist, anyone may sign in (development, tests)", () => {
    expect(isSignInAllowed({}, "anyone@lukas.test")).toBe(true);
    expect(isSignInAllowed({ SIGN_IN_ALLOWLIST: undefined }, "anyone@lukas.test")).toBe(true);
  });

  test("with an allowlist, only listed addresses, ignoring case and spaces", () => {
    const config = { SIGN_IN_ALLOWLIST: ["founder@lukas.test"] };
    expect(isSignInAllowed(config, "founder@lukas.test")).toBe(true);
    expect(isSignInAllowed(config, "  Founder@Lukas.TEST ")).toBe(true);
    expect(isSignInAllowed(config, "stranger@lukas.test")).toBe(false);
    expect(isSignInAllowed(config, "founder@lukas.test.evil.example")).toBe(false);
    expect(isSignInAllowed(config, "")).toBe(false);
  });
});

describe("sign-in allowlist", () => {
  let t: TestApp;
  beforeAll(async () => {
    t = await createTestApp({ SIGN_IN_ALLOWLIST: ["founder@lukas.test"] });
  });
  afterAll(() => t?.stop());

  const sendCode = (email: string) =>
    t.request("POST", "/auth/email-otp/send-verification-otp", {
      body: { email, type: "sign-in" },
    });

  test("an address outside the list gets sign_in_not_allowed and no email", async () => {
    const res = await sendCode("stranger@lukas.test");
    expect(res.status).toBe(403);
    expect(await res.json()).toMatchObject({ code: "sign_in_not_allowed" });
    expect(t.mailer.sent).toHaveLength(0);
  });

  test("nothing is stored for a refused address: no throttle row, no user", async () => {
    await sendCode("stranger2@lukas.test");
    const throttle = await t.admin.select().from(emailThrottle);
    expect(throttle.map((row) => row.email)).not.toContain("stranger2@lukas.test");
    const users = await t.admin.select().from(user);
    expect(users).toHaveLength(0);
  });

  test("a listed address gets its code, whatever the case, and can sign in", async () => {
    const res = await sendCode("Founder@Lukas.Test");
    expect(res.status).toBe(200);
    const mail = t.mailer.sent.at(-1);
    expect(mail).toBeDefined();
    const signedIn = await t.request("POST", "/auth/sign-in/email-otp", {
      body: { email: "Founder@Lukas.Test", otp: codeFrom(mail?.subject ?? "") },
    });
    expect(signedIn.status).toBe(200);
  });

  test("a signed-in listed user keeps working after the list is applied (sessions are unaffected)", async () => {
    const { headers } = await t.signIn("founder@lukas.test");
    const me = await t.request("GET", "/v1/me", { headers });
    expect(me.status).toBe(200);
  });
});
