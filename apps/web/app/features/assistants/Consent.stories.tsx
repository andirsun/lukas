import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { MemoryRouter, Route, Routes } from "react-router";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { expectTarget } from "../../../.storybook/story-utils.ts";
import { ApiProvider } from "../../api/ApiProvider.tsx";
import { Consent } from "./Consent.tsx";
import { type ConsentApi, ConsentError } from "./consent-api.ts";
import type { ConsentProblem, PublicClient } from "./consent-model.ts";

/** Ten minutes from the story's start, as Better Auth signs it. */
const EXP = Math.floor(Date.now() / 1000) + 600;

const query = (scope: string, exp = EXP) =>
  `?response_type=code&client_id=${encodeURIComponent("https://claude.ai/oauth/mcp-oauth-client-metadata")}` +
  `&redirect_uri=${encodeURIComponent("https://claude.ai/api/mcp/auth_callback")}` +
  `&scope=${encodeURIComponent(scope)}&state=st&exp=${exp}&sig=s1g`;

const FULL = query("finance:read finance:write offline_access");

const CLAUDE: PublicClient = { name: "Claude", icon: null, domain: "claude.ai" };

interface StageProps {
  search: string;
  guest: boolean;
  client: () => Promise<PublicClient>;
  decide: (accept: boolean, oauthQuery: string) => Promise<string>;
  go: (url: string) => void;
}

/** The consent screen at `/oauth/consent<search>`, with Better Auth and the page load stood in for. */
function ConsentStage({ search, guest, client, decide, go }: StageProps) {
  const [api] = useState<ConsentApi>(() => ({ client: () => client(), decide }));
  return (
    <MemoryRouter initialEntries={[`/oauth/consent${search}`]}>
      <ApiProvider fetch={async () => new Response(null, { status: 404 })}>
        <Routes>
          <Route path="/oauth/consent" element={<Consent api={api} guest={guest} go={go} />} />
        </Routes>
      </ApiProvider>
    </MemoryRouter>
  );
}

const refuse = (problem: ConsentProblem) => async (): Promise<never> => {
  throw new ConsentError(problem);
};

const meta = {
  title: "Assistants/Consent",
  component: ConsentStage,
  args: {
    search: FULL,
    guest: false,
    client: fn(async () => CLAUDE),
    decide: fn<StageProps["decide"]>(async (accept) =>
      accept
        ? "https://claude.ai/api/mcp/auth_callback?code=c0de&state=st"
        : "https://claude.ai/api/mcp/auth_callback?error=access_denied&state=st",
    ),
    go: fn(),
  },
} satisfies Meta<typeof ConsentStage>;

export default meta;
type Story = StoryObj<typeof meta>;

type Canvas = ReturnType<typeof within>;

const title = (canvas: Canvas, name = "Claude quiere acceder a tus finanzas") =>
  canvas.findByRole("heading", { level: 1, name });

/**
 * Who asks, where it comes from (the domain its client_id lives on, in bold), and what it could
 * do, in plain words. The heading has the focus.
 */
export const Request: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const heading = await title(canvas);
    await waitFor(() => expect(heading).toHaveFocus());
    await expect(canvas.getByText("Desde claude.ai")).toBeVisible();
    await expect(
      canvas.getByText("Revisa que sea el sitio de tu asistente. Si no lo reconoces, cancela."),
    ).toBeVisible();
    const permissions = within(canvas.getByRole("list"));
    await expect(permissions.getAllByRole("listitem").map((li) => li.textContent)).toEqual([
      "Ver tus movimientos y reportes",
      "Anotar, cambiar y borrar movimientos, presupuestos y categorías",
      "Seguir conectado hasta que lo desconectes",
    ]);
    await expectTarget(canvas.getByRole("button", { name: "Permitir" }));
    await expectTarget(canvas.getByRole("button", { name: "Cancelar" }));
    await expect(args.client).toHaveBeenCalledTimes(1);
    await expect(args.decide).not.toHaveBeenCalled();
  },
};

/** Read-only: one line, and in English by day (contrast is checked in both themes). */
export const ReadOnlyDayEnglish: Story = {
  args: {
    search: query("finance:read"),
    client: fn(async () => ({ ...CLAUDE, name: "ChatGPT", domain: "chatgpt.com" })),
  },
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await title(canvas, "ChatGPT wants to access your finances");
    await expect(canvas.getByText("From chatgpt.com")).toBeVisible();
    const permissions = within(canvas.getByRole("list"));
    await expect(permissions.getAllByRole("listitem").map((li) => li.textContent)).toEqual([
      "See your entries and reports",
    ]);
    await expect(canvas.getByRole("button", { name: "Allow" })).toBeVisible();
  },
};

/** No domain to show: it says so, in place of the domain. */
export const UnknownDomain: Story = {
  args: { client: fn(async () => ({ name: "MiAsistente", icon: null, domain: null })) },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await title(canvas, "MiAsistente quiere acceder a tus finanzas");
    await expect(
      canvas.getByText("No sabemos de qué sitio viene. Conéctalo solo si tú lo agregaste."),
    ).toBeVisible();
  },
};

/** Permitir posts accept: true with the page's signed query, then follows the returned URL. */
export const Allow: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await title(canvas);
    const allow = canvas.getByRole("button", { name: "Permitir" });
    await userEvent.dblClick(allow);
    await waitFor(() =>
      expect(args.go).toHaveBeenCalledWith(
        "https://claude.ai/api/mcp/auth_callback?code=c0de&state=st",
      ),
    );
    // Two taps, one answer.
    await expect(args.decide).toHaveBeenCalledTimes(1);
    await expect(args.decide).toHaveBeenCalledWith(true, FULL.slice(1));
  },
};

/** Cancelar posts accept: false and goes back to the assistant with its refusal. */
export const Cancel: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await title(canvas);
    await userEvent.click(canvas.getByRole("button", { name: "Cancelar" }));
    await waitFor(() =>
      expect(args.go).toHaveBeenCalledWith(
        "https://claude.ai/api/mcp/auth_callback?error=access_denied&state=st",
      ),
    );
    await expect(args.decide).toHaveBeenCalledWith(false, FULL.slice(1));
  },
};

/** A guest is asked to save their progress, and there is no Permitir; Cancelar still answers. */
export const Guest: Story = {
  args: { guest: true },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await title(canvas);
    await expect(canvas.getByRole("region", { name: "Guarda tu progreso" })).toBeVisible();
    await expect(canvas.queryByRole("button", { name: "Permitir" })).toBeNull();
    await userEvent.click(canvas.getByRole("button", { name: "Cancelar" }));
    await waitFor(() => expect(args.decide).toHaveBeenCalledWith(false, FULL.slice(1)));
  },
};

/** When the API says the session is a guest's after all, Permitir gives way to the same panel. */
export const GuestRefused: Story = {
  args: { decide: fn<StageProps["decide"]>(refuse("guest")) },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await title(canvas);
    await userEvent.click(canvas.getByRole("button", { name: "Permitir" }));
    await expect(await canvas.findByRole("region", { name: "Guarda tu progreso" })).toBeVisible();
    await expect(canvas.queryByRole("button", { name: "Permitir" })).toBeNull();
    await expect(args.go).not.toHaveBeenCalled();
  },
};

/** A link past its ten minutes says to start again from the assistant, without asking anything. */
export const ExpiredOnArrival: Story = {
  args: { search: query("finance:read", Math.floor(Date.now() / 1000) - 60) },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const heading = await title(canvas, "Este enlace ya no sirve");
    await waitFor(() => expect(heading).toHaveFocus());
    await expect(canvas.queryByRole("button", { name: "Permitir" })).toBeNull();
    await expect(args.client).not.toHaveBeenCalled();
  },
};

/** A signature Better Auth refuses (it ran out while the page was open, or was changed). */
export const ExpiredOnAnswer: Story = {
  args: { decide: fn<StageProps["decide"]>(refuse("expired")) },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await title(canvas);
    await userEvent.click(canvas.getByRole("button", { name: "Permitir" }));
    await title(canvas, "Este enlace ya no sirve");
    await expect(
      canvas.getByText(
        "Pasó mucho tiempo o el enlace cambió. Vuelve a tu asistente y empieza a conectar Lukitas otra vez.",
      ),
    ).toBeVisible();
    await expect(args.go).not.toHaveBeenCalled();
  },
};

/** No signature at all: nothing to answer. */
export const Unsigned: Story = {
  args: { search: "?client_id=x&scope=finance%3Aread" },
  play: async ({ canvasElement }) => {
    await title(within(canvasElement), "Este enlace ya no sirve");
  },
};

/** No connection: it says so, and Permitir can be tapped again. */
export const Offline: Story = {
  args: { decide: fn<StageProps["decide"]>(refuse("network")) },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await title(canvas);
    await userEvent.click(canvas.getByRole("button", { name: "Permitir" }));
    await expect(
      await canvas.findByText("Sin conexión. Revisa tu internet e inténtalo de nuevo."),
    ).toHaveAttribute("role", "alert");
    await expect(canvas.getByRole("button", { name: "Permitir" })).toBeEnabled();
    await expect(args.go).not.toHaveBeenCalled();
  },
};

/** The assistant could not be read: the error, and a retry. */
export const ClientFailed: Story = {
  args: { client: fn<StageProps["client"]>(refuse("generic")) },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(
      await canvas.findByText("No pudimos completar la conexión. Inténtalo de nuevo."),
    ).toHaveAttribute("role", "alert");
    await expect(canvas.getByRole("button", { name: "Reintentar" })).toBeVisible();
  },
};
