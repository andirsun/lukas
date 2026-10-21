import { expect, type Page, request } from "@playwright/test";

/**
 * Helpers for app flows against the dev stack (`docker compose up`: API, Postgres, Mailpit):
 * fresh addresses, reading the sign-in email from Mailpit, and signing a new user in.
 */

const MAILPIT = process.env.MAILPIT_URL ?? "http://localhost:8025";
/** The API itself (not through the web's proxy), for set-up calls that are not under test. */
const API = process.env.E2E_API_URL ?? "http://localhost:3000";
const WEB = "http://localhost:5173";

const rand = (n: number) => Math.floor(Math.random() * n);

/**
 * A made-up client address (from 198.18.0.0/15, reserved for testing) for a browser context's
 * `X-Forwarded-For`. The API limits sign-in per address (3 sign-ins per 10 s, 5 codes per
 * 10 min), and every browser on this machine would otherwise be 127.0.0.1. The dev stack trusts
 * Vite's proxy (TRUSTED_PROXIES in .env), so the address the browser sends is the one counted.
 */
export function clientIp(): string {
  return `198.${18 + rand(2)}.${rand(256)}.${1 + rand(254)}`;
}

/** A new address per call, so each test is a new user with its own email throttle. */
export function freshEmail(label = "e2e"): string {
  const nonce = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;
  return `${label}-${nonce}@lukas.test`;
}

interface MailSummary {
  ID: string;
  Created: string;
  Subject: string;
  To: { Address: string }[];
}

export interface SignInMail {
  id: string;
  code: string;
  /** The magic link: `${WEB_URL}/auth/verify?email=…&code=…`. */
  link: string;
  subject: string;
}

async function mailsTo(email: string): Promise<MailSummary[]> {
  const response = await fetch(`${MAILPIT}/api/v1/messages?limit=200`);
  if (!response.ok) throw new Error(`Mailpit: ${response.status}`);
  const { messages } = (await response.json()) as { messages: MailSummary[] };
  return messages.filter((m) => m.To.some((to) => to.Address.toLowerCase() === email));
}

/**
 * The newest sign-in email to `email`, waiting for it to arrive. `skip` ignores emails already
 * read (by id), so a second code is never confused with the first.
 */
export async function readSignInMail(
  email: string,
  { skip = [] as string[], timeoutMs = 15_000 } = {},
): Promise<SignInMail> {
  let found: MailSummary | undefined;
  await expect
    .poll(
      async () => {
        found = (await mailsTo(email.toLowerCase())).find((m) => !skip.includes(m.ID));
        return found !== undefined;
      },
      { timeout: timeoutMs, message: `a sign-in email to ${email}` },
    )
    .toBe(true);
  const summary = found as MailSummary;
  const response = await fetch(`${MAILPIT}/api/v1/message/${summary.ID}`);
  const { Text } = (await response.json()) as { Text: string };
  const code = /\b(\d{6})\b/.exec(summary.Subject)?.[1];
  const link = /https?:\/\/\S+\/auth\/verify\?\S+/.exec(Text)?.[0];
  if (!code || !link) throw new Error(`No code or link in "${summary.Subject}"`);
  return { id: summary.ID, code, link, subject: summary.Subject };
}

/** A client for the API itself, as a new client address. */
const apiClient = () =>
  request.newContext({
    baseURL: API,
    extraHTTPHeaders: { origin: WEB, "x-forwarded-for": clientIp() },
  });

/**
 * Asks the API for a sign-in code without going through a page, for set-up steps that are not
 * what the test checks.
 */
export async function requestCode(
  email: string,
  hints: { locale?: "es" | "en"; next?: string } = {},
): Promise<void> {
  const api = await apiClient();
  const response = await api.post("/api/auth/email-otp/send-verification-otp", {
    data: { email, type: "sign-in" },
    headers: {
      ...(hints.locale ? { "x-lukas-locale": hints.locale } : {}),
      ...(hints.next ? { "x-lukas-next": hints.next } : {}),
    },
  });
  expect(response.status(), await response.text()).toBe(200);
  await api.dispose();
}

/** Signs in with a code through the API, using it up (as if typed elsewhere). */
export async function spendCode(email: string, code: string): Promise<void> {
  const api = await apiClient();
  const response = await api.post("/api/auth/sign-in/email-otp", { data: { email, otp: code } });
  expect(response.status(), await response.text()).toBe(200);
  await api.dispose();
}

/** The signed-in user of a page's browser context, from Better Auth's session endpoint. */
export async function sessionUser(page: Page): Promise<{ id: string; email: string } | null> {
  const response = await page.request.get("/api/auth/get-session");
  expect(response.ok()).toBe(true);
  const body = (await response.json()) as { user: { id: string; email: string } } | null;
  return body?.user ?? null;
}

/** Signs a brand-new user in through the sign-in page; returns their email. Lands on /welcome. */
export async function signUpNewUser(page: Page, { lang = "es" as "es" | "en" } = {}) {
  const email = freshEmail();
  await page.goto(`/sign-in?lang=${lang}`);
  await page.getByRole("textbox", { name: lang === "en" ? "Your email" : "Tu correo" }).fill(email);
  await page.getByRole("button", { name: lang === "en" ? "Send code" : "Enviar código" }).click();
  const mail = await readSignInMail(email);
  await page
    .getByRole("textbox", { name: lang === "en" ? "Digit 1 of 6" : "Dígito 1 de 6" })
    .fill(mail.code);
  await expect(page).toHaveURL(/\/welcome$/);
  return email;
}
