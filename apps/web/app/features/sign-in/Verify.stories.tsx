import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { expectTarget } from "../../../.storybook/story-utils.ts";
import { fail, fakeAuth, GOOD_CODE, ONBOARDED_USER, SignInStage } from "./story-harness.tsx";

/** The magic link as the API writes it: email, code, the email's language, and `next` if any. */
const LINK = `/auth/verify?email=ana%40example.com&code=${GOOD_CODE}&lang=es`;

const meta = {
  title: "Sign-in/Verify",
  component: SignInStage,
  args: { auth: fakeAuth(), initialEntry: LINK },
} satisfies Meta<typeof SignInStage>;

export default meta;
type Story = StoryObj<typeof meta>;

const currentPage = (canvas: ReturnType<typeof within>) =>
  canvas.getByRole("status", { name: "Current page" });

const expired = (auth = fakeAuth()) => ({
  ...auth,
  verifyCode: fn(async () => fail({ code: "OTP_EXPIRED", status: 400 })),
});

const tapContinue = async (canvas: ReturnType<typeof within>) => {
  const button = await canvas.findByRole("button", { name: "Continuar" });
  await userEvent.click(button);
};

/**
 * Opening the link spends nothing: it shows which account is about to sign in and waits for a
 * tap. A mail scanner that opens (and even runs) the page leaves the code for its owner.
 */
export const AsksFirst: Story = {
  args: { auth: fakeAuth() },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(
      canvas.getByRole("heading", { level: 1, name: "Continuar como ana@example.com" }),
    ).toBeVisible();
    await expect(canvas.getByRole("img", { name: "Lukitas, contento" })).toBeVisible();
    const button = canvas.getByRole("button", { name: "Continuar" });
    await expectTarget(button);
    const notMe = canvas.getByRole("link", { name: "No soy yo" });
    await expect(notMe).toHaveAttribute("href", "/sign-in?lang=es");
    await expectTarget(notMe);
    // Some time passes, as for a scanner rendering the page: still nothing spent.
    await new Promise((resolve) => setTimeout(resolve, 300));
    await expect(args.auth.verifyCode).not.toHaveBeenCalled();
  },
};

/** A phone's Chrome, as the user agent of an Android browser. */
const ANDROID_CHROME =
  "Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36";

/** The link of a sign-in started in the Android app, as the API writes it. */
const APP_SEARCH = `?email=ana%40example.com&code=${GOOD_CODE}&lang=es&from=app`;

/**
 * The sign-in was started in the Android app and the link opened in a browser (a mail app's own,
 * say) that never asked Android for the app: the page offers the app, with an `intent://` link to
 * this same address, or the web. It spends nothing until the person picks the web.
 */
export const OffersTheApp: Story = {
  args: {
    auth: fakeAuth(),
    initialEntry: `/auth/verify${APP_SEARCH}`,
    userAgent: ANDROID_CHROME,
  },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(
      canvas.getByRole("heading", { level: 1, name: "Continuar como ana@example.com" }),
    ).toBeVisible();
    const open = canvas.getByRole("link", { name: "Abrir en Lukitas" });
    await expectTarget(open);
    const { origin, host } = window.location;
    await expect(open).toHaveAttribute(
      "href",
      `intent://${host}/auth/verify${APP_SEARCH}` +
        "#Intent;scheme=https;package=com.andersonlaverde.lukitas;" +
        `S.browser_fallback_url=${encodeURIComponent(
          `${origin}/auth/verify?email=ana%40example.com&code=${GOOD_CODE}&lang=es`,
        )};end`,
    );
    await expectTarget(canvas.getByRole("button", { name: "Seguir en la web" }));
    await expect(canvas.queryByRole("button", { name: "Continuar" })).toBeNull();
    await expect(canvas.getByRole("link", { name: "No soy yo" })).toBeVisible();
    // Some time passes, as for a scanner or a slow tap: still nothing spent.
    await new Promise((resolve) => setTimeout(resolve, 300));
    await expect(args.auth.verifyCode).not.toHaveBeenCalled();
  },
};

/** "Seguir en la web" spends the code on the web, as the plain page does. */
export const FollowsOnTheWeb: Story = {
  args: { ...OffersTheApp.args, auth: fakeAuth() },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Seguir en la web" }));
    await waitFor(() => expect(currentPage(canvas)).toHaveTextContent("/welcome"));
    await expect(args.auth.verifyCode).toHaveBeenCalledTimes(1);
    await expect(args.auth.verifyCode).toHaveBeenCalledWith("ana@example.com", GOOD_CODE);
  },
};

/** The same offer in English. */
export const OffersTheAppInEnglish: Story = {
  args: {
    ...OffersTheApp.args,
    auth: fakeAuth(),
    initialEntry: `/auth/verify${APP_SEARCH.replace("lang=es", "lang=en")}`,
  },
  globals: { locale: "en" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("link", { name: "Open in Lukitas" })).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Stay on the web" })).toBeVisible();
    await expect(args.auth.verifyCode).not.toHaveBeenCalled();
  },
};

/** `from=app` in a browser that is not Android's: the page is the plain one. */
export const FromAppOffAndroid: Story = {
  args: {
    auth: fakeAuth(),
    initialEntry: `/auth/verify${APP_SEARCH}`,
    userAgent:
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("button", { name: "Continuar" })).toBeVisible();
    await expect(canvas.queryByRole("link", { name: "Abrir en Lukitas" })).toBeNull();
    await expect(canvas.queryByRole("button", { name: "Seguir en la web" })).toBeNull();
  },
};

/** An Android browser without `from=app` (a link from the web): the plain page. */
export const AndroidWithoutMarker: Story = {
  args: { auth: fakeAuth(), userAgent: ANDROID_CHROME },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("button", { name: "Continuar" })).toBeVisible();
    await expect(canvas.queryByRole("link", { name: "Abrir en Lukitas" })).toBeNull();
  },
};

/** One tap signs in with the email and code from the link, then on to onboarding. */
export const SignsIn: Story = {
  args: { auth: fakeAuth() },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await tapContinue(canvas);
    await waitFor(() => expect(currentPage(canvas)).toHaveTextContent("/welcome"));
    await expect(args.auth.verifyCode).toHaveBeenCalledTimes(1);
    await expect(args.auth.verifyCode).toHaveBeenCalledWith("ana@example.com", GOOD_CODE);
  },
};

/** The link's `next` survives the email round trip: an onboarded user goes back there. */
export const KeepsNext: Story = {
  args: {
    auth: fakeAuth({ user: ONBOARDED_USER }),
    profileUser: ONBOARDED_USER,
    initialEntry: `${LINK}&next=%2Fapp%2Finsights`,
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await tapContinue(canvas);
    await waitFor(() => expect(currentPage(canvas)).toHaveTextContent("/app/insights"));
  },
};

/** The link's language becomes a new user's profile language. */
export const NewUserInEnglish: Story = {
  args: {
    auth: fakeAuth(),
    initialEntry: `/auth/verify?email=ana%40example.com&code=${GOOD_CODE}&lang=en`,
    onPatchMe: fn(),
  },
  globals: { locale: "en" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(
      canvas.getByRole("heading", { level: 1, name: "Continue as ana@example.com" }),
    ).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Continue" }));
    await waitFor(() => expect(currentPage(canvas)).toHaveTextContent("/welcome"));
    await expect(args.onPatchMe).toHaveBeenCalledWith({ locale: "en" });
  },
};

/** While the code is checked: the button says so and can't be pressed twice. */
export const Checking: Story = {
  args: { auth: fakeAuth({ verifyCode: fn(() => new Promise<never>(() => {})) }) },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await tapContinue(canvas);
    await expect(await canvas.findByRole("button", { name: "Entrando…" })).toBeDisabled();
  },
};

/** A rejected code (expired, or already used): the friendly message and "send a new code". */
export const Expired: Story = {
  args: { auth: expired() },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await tapContinue(canvas);
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "Este código ya no sirve: venció o ya se usó. Pide uno nuevo.",
    );
    const again = canvas.getByRole("button", { name: "Enviar un código nuevo" });
    await expectTarget(again);
    await userEvent.click(again);
    await expect(args.auth.sendCode).toHaveBeenCalledWith("ana@example.com", {
      locale: "es",
      next: null,
    });
    // The new code is typed on the sign-in page, already at the code step.
    await expect(
      await canvas.findByRole("heading", { level: 1, name: "Revisa tu correo" }),
    ).toBeVisible();
    await expect(currentPage(canvas)).toHaveTextContent("/sign-in");
  },
};

/** The same, by day and in English. */
export const ExpiredDay: Story = {
  args: { auth: expired(), initialEntry: LINK.replace("lang=es", "lang=en") },
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Continue" }));
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "This code no longer works: it expired or was already used. Ask for a new one.",
    );
    await expect(canvas.getByRole("button", { name: "Send a new code" })).toBeVisible();
  },
};

/** A link without its email or code can't sign in; "send a new code" starts over at the email step. */
export const IncompleteLink: Story = {
  args: { auth: fakeAuth(), initialEntry: "/auth/verify?code=123456&lang=es" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "Este código ya no sirve: venció o ya se usó. Pide uno nuevo.",
    );
    await expect(canvas.queryByRole("button", { name: "Continuar" })).toBeNull();
    await userEvent.click(canvas.getByRole("button", { name: "Enviar un código nuevo" }));
    await expect(args.auth.verifyCode).not.toHaveBeenCalled();
    await expect(args.auth.sendCode).not.toHaveBeenCalled();
    await expect(canvas.getByRole("textbox", { name: "Tu correo" })).toBeVisible();
  },
};

/** The first check finds no connection; the next one works. */
const offlineOnce = fn(async (email: string, code: string) =>
  offlineOnce.mock.calls.length === 1 ? fail({ status: 0 }) : fakeAuth().verifyCode(email, code),
);

/** No connection: say so, and offer to try the same link again. */
export const Offline: Story = {
  args: { auth: fakeAuth({ verifyCode: offlineOnce }) },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await tapContinue(canvas);
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "Sin conexión. Revisa tu internet e inténtalo de nuevo.",
    );
    await userEvent.click(canvas.getByRole("button", { name: "Reintentar" }));
    await waitFor(() => expect(currentPage(canvas)).toHaveTextContent("/welcome"));
    await expect(args.auth.verifyCode).toHaveBeenCalledTimes(2);
  },
};

/** The first check hits the sign-in rate limit (retry after 2 s); the next one works. */
const rateLimitedOnce = fn(async (email: string, code: string) =>
  rateLimitedOnce.mock.calls.length === 1
    ? fail({ status: 429, retryAfter: 2 })
    : fakeAuth().verifyCode(email, code),
);

/**
 * Rate limited: the link's code is still good, so the page counts down the server's wait and
 * then offers to retry (no new email needed).
 */
export const RateLimited: Story = {
  args: { auth: fakeAuth({ verifyCode: rateLimitedOnce }) },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await tapContinue(canvas);
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "Demasiados intentos seguidos. Espera unos segundos e inténtalo otra vez.",
    );
    await expect(canvas.getByRole("button", { name: /^Reintentar en \d s$/ })).toBeDisabled();
    const retry = await canvas.findByRole("button", { name: "Reintentar" }, { timeout: 5000 });
    await userEvent.click(retry);
    await waitFor(() => expect(currentPage(canvas)).toHaveTextContent("/welcome"));
    await expect(args.auth.verifyCode).toHaveBeenCalledTimes(2);
    await expect(args.auth.sendCode).not.toHaveBeenCalled();
  },
};
