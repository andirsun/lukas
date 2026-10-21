import type { Meta, StoryObj } from "@storybook/react-vite";
import { MemoryRouter } from "react-router";
import { expect, userEvent, within } from "storybook/test";
import { expectEdge, expectFocusRing, expectTarget } from "../../../.storybook/story-utils.ts";
import { Faq } from "./Faq.tsx";
import { Footer } from "./Footer.tsx";
import { Hero } from "./Hero.tsx";
import { HowItWorks } from "./HowItWorks.tsx";
import { Landing } from "./Landing.tsx";
import { OpenSource } from "./OpenSource.tsx";
import { UseItYourWay } from "./UseItYourWay.tsx";

const meta = {
  title: "Landing/Landing",
  component: Landing,
  parameters: { layout: "fullscreen" },
  decorators: [
    (Story) => (
      <MemoryRouter>
        <div className="lk-screen lk-landing">
          <Story />
        </div>
      </MemoryRouter>
    ),
  ],
} satisfies Meta<typeof Landing>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The whole page in Spanish, night theme. */
export const Page: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading", { level: 1 })).toHaveTextContent(
      "Tus lukas, por fin claras.",
    );
    const ctas = canvas.getAllByRole("link", { name: "Empieza ahora" });
    await expect(ctas.map((link) => link.getAttribute("href"))).toEqual([
      "/sign-in?lang=es",
      "/sign-in?lang=es",
    ]);
    await expect(canvas.getByRole("link", { name: "Entrar" })).toHaveAttribute(
      "href",
      "/sign-in?lang=es",
    );
    // The day/night switch sits next to "Entrar", in the header.
    await expect(canvas.getByRole("button", { name: "Cambiar a modo día" })).toBeVisible();
  },
};

/** The whole page in English, day theme. */
export const PageDayEnglish: Story = {
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading", { level: 1 })).toHaveTextContent(
      "Your money, finally clear.",
    );
    await expect(canvas.getAllByRole("link", { name: "Get started" })[0]).toHaveAttribute(
      "href",
      "/sign-in?lang=en",
    );
  },
};

/**
 * Hero: the handwritten promise, the headline with "lukas" on the gold marker, one primary action
 * on its edge with the perks (open source links to GitHub), Lukas waving.
 */
export const HeroSection: Story = {
  render: () => <Hero />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvasElement.querySelectorAll("s")).toHaveLength(0);
    await expect(canvas.getByText("¡Gratis, y siempre lo será!")).toBeVisible();
    const headline = canvas.getByRole("heading", { level: 1 });
    await expect(headline).toHaveTextContent("Tus lukas, por fin claras.");
    await expect(headline.querySelector(".lk-landing-marker")).toHaveTextContent("lukas");
    await expect(
      canvas.getByRole("link", { name: "Código abierto (se abre en una pestaña nueva)" }),
    ).toHaveAttribute("href", "https://github.com/andirsun/lukas");
    await expect(canvas.queryByRole("link", { name: "Pruébalo sin cuenta" })).toBeNull();
    const cta = canvas.getByRole("link", { name: "Empieza ahora" });
    await expectEdge(cta, 6);
    await expectTarget(cta);
    await userEvent.tab();
    await expectFocusRing(cta);
    const mascot = canvas.getByRole("img", { name: /Lukitas/ });
    await expect(mascot).toHaveAttribute("data-slot", "hero-mascot");
    await expect(mascot.querySelector(".lk-lukas")).toHaveAttribute("aria-hidden", "true");
  },
};

/** Hero in English by day, with the demo as a second action (the seam Task 18a turns on). */
export const HeroWithDemoDayEnglish: Story = {
  render: () => <Hero secondaryCta />,
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Free, and it always will be!")).toBeVisible();
    const demo = canvas.getByRole("link", { name: "Try it without an account" });
    await expect(demo).toHaveAttribute("href", "/demo");
    await expect(demo).toHaveClass("lk-btn-secondary");
    await expectTarget(demo);
  },
};

/** Hero under reduced motion: Lukas holds still. */
export const HeroReducedMotion: Story = {
  render: () => <Hero />,
  parameters: { reducedMotion: true },
  play: async ({ canvasElement }) => {
    const lukas = canvasElement.querySelector(".lk-lukas") as HTMLElement;
    await expect(lukas.getAnimations({ subtree: true })).toHaveLength(0);
  },
};

/** Web is live; the Android and iOS app and the AI assistants are coming soon. */
export const UseItYourWaySection: Story = {
  render: () => <UseItYourWay />,
  globals: { theme: "day" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getAllByRole("listitem")).toHaveLength(3);
    const start = canvas.getByRole("link", { name: "Empezar" });
    await expect(start).toHaveAttribute("href", "/sign-in?lang=es");
    await expectTarget(start);
    await expect(canvas.getAllByText("Pronto")).toHaveLength(2);
    await expect(canvas.getByText("Claude / ChatGPT")).toBeVisible();
    await expect(canvas.getByRole("heading", { name: "App para Android y iOS" })).toBeVisible();
  },
};

/** Four steps with decorative illustrations, money in the locale's format. */
export const HowItWorksSection: Story = {
  render: () => <HowItWorks />,
  globals: { locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getAllByRole("heading", { level: 3 }).map((h) => h.textContent)).toEqual([
      "Log it in seconds",
      "See where it goes",
      "Budgets that give you a heads-up",
      "Bring your history",
    ]);
    for (const demo of canvasElement.querySelectorAll(".lk-landing-demo")) {
      await expect(demo).toHaveAttribute("aria-hidden", "true");
    }
    await expect(canvasElement).toHaveTextContent("€46.33 left");
    await expect(canvasElement).toHaveTextContent("1,248 transactions ready");
    await expect(canvasElement).toHaveTextContent("Budge today, Buddy and others soon.");
  },
};

/** Open source: the code icon, one short paragraph and the repository, in a new tab. */
export const OpenSourceSection: Story = {
  render: () => <OpenSource />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading", { level: 2 })).toHaveTextContent("Código abierto");
    await expect(canvasElement).toHaveTextContent("AGPL-3.0");
    const code = canvas.getByRole("link", {
      name: "Ver el código en GitHub (se abre en una pestaña nueva)",
    });
    await expect(code).toHaveAttribute("href", "https://github.com/andirsun/lukas");
    await expect(code).toHaveAttribute("target", "_blank");
    await expectEdge(code, 3);
    await expectTarget(code);
  },
};

/** Questions open in place; each summary is a 44px pressable card with the focus ring. */
export const FaqSection: Story = {
  render: () => <Faq />,
  play: async ({ canvasElement }) => {
    const summaries = [...canvasElement.querySelectorAll("summary")];
    await expect(summaries).toHaveLength(6);
    const first = summaries[0] as HTMLElement;
    await expectTarget(first);
    await userEvent.click(first);
    await expect(first.parentElement).toHaveAttribute("open");
    await expect(canvasElement.querySelector("#privacy")).not.toBeNull();
    await userEvent.tab();
    await expectFocusRing(summaries[1] as HTMLElement);
  },
};

/** Language switch (current language marked), privacy link, copyright. */
export const FooterSection: Story = {
  render: () => <Footer />,
  globals: { locale: "en", theme: "day" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const english = canvas.getByRole("link", { name: "English" });
    await expect(english).toHaveAttribute("aria-current", "true");
    const spanish = canvas.getByRole("link", { name: "Español" });
    await expect(spanish).toHaveAttribute("href", "/");
    await expect(spanish).toHaveAttribute("hreflang", "es");
    await expect(canvas.getByRole("link", { name: "Privacy" })).toHaveAttribute("href", "#privacy");
    for (const link of canvas.getAllByRole("link")) await expectTarget(link);
    await expect(canvasElement).toHaveTextContent("© 2026 Lukitas");
  },
};
