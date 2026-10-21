import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { expectTarget } from "../../../.storybook/story-utils.ts";
import { fail, fakeAuth, GOOD_CODE, SignInStage } from "./story-harness.tsx";

const LINK = `/auth/verify?email=ana%40example.com&code=${GOOD_CODE}`;

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

/** The magic link submits the email and code from the URL on its own, then goes to onboarding. */
export const SignsIn: Story = {
  args: { auth: fakeAuth() },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await waitFor(() => expect(currentPage(canvas)).toHaveTextContent("/welcome"));
    await expect(args.auth.verifyCode).toHaveBeenCalledTimes(1);
    await expect(args.auth.verifyCode).toHaveBeenCalledWith("ana@example.com", GOOD_CODE);
  },
};

/** While the code is checked: Lukitas and a polite "signing you in". */
export const Checking: Story = {
  args: { auth: fakeAuth({ verifyCode: fn(() => new Promise<never>(() => {})) }) },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(
      await canvas.findByRole("heading", { level: 1, name: "Entrando a Lukitas…" }),
    ).toBeVisible();
  },
};

/** A rejected code (expired, or already used): the friendly message and "send a new code". */
export const Expired: Story = {
  args: { auth: expired() },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "Este código ya no sirve: venció o ya se usó. Pide uno nuevo.",
    );
    const again = canvas.getByRole("button", { name: "Enviar un código nuevo" });
    await expectTarget(again);
    await userEvent.click(again);
    await expect(args.auth.sendCode).toHaveBeenCalledWith("ana@example.com");
    // The new code is typed on the sign-in page, already at the code step.
    await expect(
      await canvas.findByRole("heading", { level: 1, name: "Revisa tu correo" }),
    ).toBeVisible();
    await expect(currentPage(canvas)).toHaveTextContent("/sign-in");
  },
};

/** The same, by day and in English. */
export const ExpiredDay: Story = {
  args: { auth: expired() },
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "This code no longer works: it expired or was already used. Ask for a new one.",
    );
    await expect(canvas.getByRole("button", { name: "Send a new code" })).toBeVisible();
  },
};

/** A link without its email or code can't sign in; "send a new code" starts over at the email step. */
export const IncompleteLink: Story = {
  args: { auth: fakeAuth(), initialEntry: "/auth/verify?code=123456" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "Este código ya no sirve: venció o ya se usó. Pide uno nuevo.",
    );
    await expect(args.auth.verifyCode).not.toHaveBeenCalled();
    await userEvent.click(canvas.getByRole("button", { name: "Enviar un código nuevo" }));
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
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "Sin conexión. Revisa tu internet e inténtalo de nuevo.",
    );
    await userEvent.click(canvas.getByRole("button", { name: "Reintentar" }));
    await waitFor(() => expect(currentPage(canvas)).toHaveTextContent("/welcome"));
    await expect(args.auth.verifyCode).toHaveBeenCalledTimes(2);
  },
};
