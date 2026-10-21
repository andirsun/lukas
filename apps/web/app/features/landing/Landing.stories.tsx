import type { Meta, StoryObj } from "@storybook/react-vite";
import { MemoryRouter } from "react-router";
import { expect, userEvent, within } from "storybook/test";
import { expectEdge, expectFocusRing, expectTarget } from "../../../.storybook/story-utils.ts";
import { Faq } from "./Faq.tsx";
import { Footer } from "./Footer.tsx";
import { Hero } from "./Hero.tsx";
import { HowItWorks } from "./HowItWorks.tsx";
import { Landing } from "./Landing.tsx";
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
    const ctas = canvas.getAllByRole("link", { name: "Empieza gratis" });
    await expect(ctas.map((link) => link.getAttribute("href"))).toEqual([
      "/sign-in?lang=es",
      "/sign-in?lang=es",
    ]);
    await expect(canvas.getByRole("link", { name: "Entrar" })).toHaveAttribute(
      "href",
      "/sign-in?lang=es",
    );
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
    await expect(canvas.getAllByRole("link", { name: "Start free" })[0]).toHaveAttribute(
      "href",
      "/sign-in?lang=en",
    );
  },
};

/** Hero: crossed-out questions, the headline, one primary action on its edge, Lukas waving. */
export const HeroSection: Story = {
  render: () => <Hero />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const questions = canvasElement.querySelectorAll(".lk-landing-questions s");
    await expect([...questions].map((q) => q.textContent)).toEqual([
      "¿En qué se me va la plata?",
      "¿Cuánto me cuesta vivir?",
    ]);
    await expect(canvas.getByText("Tu presupuesto, tu mejor amigo.")).toBeVisible();
    const cta = canvas.getByRole("link", { name: "Empieza gratis" });
    await expectEdge(cta, 6);
    await expectTarget(cta);
    await userEvent.tab();
    await expectFocusRing(cta);
    const mascot = canvas.getByRole("img", { name: /Lukas/ });
    await expect(mascot).toHaveAttribute("data-slot", "hero-mascot");
    await expect(mascot.querySelector(".lk-lukas")).toHaveAttribute("aria-hidden", "true");
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

/** Web is live; Android and the AI assistants are coming soon. */
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
      "Bring your Budge history",
    ]);
    for (const demo of canvasElement.querySelectorAll(".lk-landing-demo")) {
      await expect(demo).toHaveAttribute("aria-hidden", "true");
    }
    await expect(canvasElement).toHaveTextContent("€46.33 left");
    await expect(canvasElement).toHaveTextContent("1,248 transactions ready");
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
    await expect(english).toHaveAttribute("aria-current", "page");
    const spanish = canvas.getByRole("link", { name: "Español" });
    await expect(spanish).toHaveAttribute("href", "/");
    await expect(spanish).toHaveAttribute("hreflang", "es");
    await expect(canvas.getByRole("link", { name: "Privacy" })).toHaveAttribute("href", "#privacy");
    for (const link of canvas.getAllByRole("link")) await expectTarget(link);
    await expect(canvasElement).toHaveTextContent("© 2026 Lukas");
  },
};
