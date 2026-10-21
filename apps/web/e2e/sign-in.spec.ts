import { expect, test } from "@playwright/test";
import {
  clientIp,
  freshEmail,
  readSignInMail,
  requestCode,
  sessionUser,
  spendCode,
} from "./helpers.ts";

/**
 * Passwordless sign-in against the dev stack: the code from the email, the magic link opened in
 * another browser (no pending state there), and a used link that offers a new code.
 *
 * Each browser gets its own client address (see `clientIp`): the API's per-address sign-in limits
 * would otherwise be shared by every test and every run.
 */

// A fixture, not a value: a new address for every test, not one per worker.
test.use({
  extraHTTPHeaders: async ({ extraHTTPHeaders }, use) =>
    use({ ...extraHTTPHeaders, "x-forwarded-for": clientIp() }),
});

test("the emailed code signs a new user in, and the magic link signs them in elsewhere", async ({
  page,
  browser,
}) => {
  const email = freshEmail("code");

  // Came from the English landing: the page speaks English, and so will the new profile.
  await page.goto("/sign-in?lang=en");
  await expect(page.getByRole("heading", { level: 1, name: "Sign in to Lukitas" })).toBeVisible();
  await page.getByRole("textbox", { name: "Your email" }).fill(email);
  await page.getByRole("button", { name: "Send code" }).click();
  await expect(page.getByRole("heading", { level: 1, name: "Check your email" })).toBeVisible();

  // The email is in the language of the page that asked for it, and so is its link.
  const first = await readSignInMail(email);
  expect(first.subject).toMatch(/^Your Lukitas code: \d{6}$/);
  expect(new URL(first.link).searchParams.get("lang")).toBe("en");
  const firstBox = page.getByRole("textbox", { name: "Digit 1 of 6" });
  await expect(firstBox).toBeFocused();

  // A wrong code is refused, and the boxes are ready for another try.
  await page.keyboard.type(first.code === "000000" ? "111111" : "000000");
  await expect(page.getByRole("main").getByRole("alert")).toHaveText(
    "That code isn't right. Check it and try again.",
  );
  await expect(firstBox).toBeFocused();

  await page.keyboard.type(first.code);
  await expect(page).toHaveURL(/\/welcome$/);

  const user = await sessionUser(page);
  expect(user?.email).toBe(email);
  const me = await page.request.get("/api/v1/me");
  expect(await me.json()).toMatchObject({ email, locale: "en", onboardingCompletedAt: null });

  // Signed in: the sign-in page sends them on.
  await page.goto("/sign-in");
  await expect(page).toHaveURL(/\/welcome$/);

  // A new code for the same address (now in their profile's English), and its magic link
  // opened in another browser, which keeps the language and `next`.
  await requestCode(email, { next: "/app/insights" });
  const second = await readSignInMail(email, { skip: [first.id] });
  expect(second.subject).toMatch(/^Your Lukitas code/);
  const secondLink = new URL(second.link);
  expect(secondLink.pathname).toBe("/auth/verify");
  expect(secondLink.searchParams.get("lang")).toBe("en");
  expect(secondLink.searchParams.get("next")).toBe("/app/insights");

  const elsewhere = await browser.newContext({
    extraHTTPHeaders: { "x-forwarded-for": clientIp() },
  });
  try {
    const other = await elsewhere.newPage();
    expect(await sessionUser(other)).toBeNull();
    await other.goto(second.link);
    // It asks before spending the code, and the code has already left the address bar.
    await expect(
      other.getByRole("heading", { level: 1, name: `Continue as ${email}` }),
    ).toBeVisible();
    await expect(other).toHaveURL(/\/auth\/verify\?lang=en$/);
    await expect(other.locator('meta[name="referrer"]')).toHaveAttribute("content", "no-referrer");
    await other.getByRole("button", { name: "Continue" }).click();
    await expect(other).toHaveURL(/\/welcome$/);
    expect((await sessionUser(other))?.id).toBe(user?.id);
  } finally {
    await elsewhere.close();
  }

  // The first browser is still signed in as the same user.
  expect((await sessionUser(page))?.id).toBe(user?.id);
});

test("a used magic link says so and sends a new code", async ({ page }) => {
  const email = freshEmail("link");
  await requestCode(email);
  const mail = await readSignInMail(email);
  await spendCode(email, mail.code);

  await page.goto(mail.link);
  await page.getByRole("button", { name: "Continuar" }).click();
  await expect(page.getByRole("main").getByRole("alert")).toHaveText(
    "Este código ya no sirve: venció o ya se usó. Pide uno nuevo.",
  );
  expect(await sessionUser(page)).toBeNull();

  await page.getByRole("button", { name: "Enviar un código nuevo" }).click();
  await expect(page.getByRole("heading", { level: 1, name: "Revisa tu correo" })).toBeVisible();
  await expect(page).toHaveURL(/\/sign-in\?lang=es$/);

  const fresh = await readSignInMail(email, { skip: [mail.id] });
  await page.getByRole("textbox", { name: "Dígito 1 de 6" }).fill(fresh.code);
  await expect(page).toHaveURL(/\/welcome$/);
  expect((await sessionUser(page))?.email).toBe(email);
});

test("opening the magic link spends nothing until Continue", async ({ page, browser, request }) => {
  const email = freshEmail("scan");
  await requestCode(email, { locale: "es" });
  const mail = await readSignInMail(email);

  // A mail scanner: a plain GET, then a browser that runs the page and looks around.
  expect((await request.get(mail.link)).ok()).toBe(true);
  const scanner = await browser.newContext({
    extraHTTPHeaders: { "x-forwarded-for": clientIp() },
  });
  try {
    const scan = await scanner.newPage();
    await scan.goto(mail.link);
    await expect(scan.getByRole("button", { name: "Continuar" })).toBeVisible();
    await scan.waitForTimeout(500);
    expect(await sessionUser(scan)).toBeNull();
  } finally {
    await scanner.close();
  }

  // Its owner taps Continue later: the code still works.
  await page.goto(mail.link);
  await expect(
    page.getByRole("heading", { level: 1, name: `Continuar como ${email}` }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Continuar" }).click();
  await expect(page).toHaveURL(/\/welcome$/);
  expect((await sessionUser(page))?.email).toBe(email);
});
