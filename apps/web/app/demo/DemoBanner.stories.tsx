import type { Meta, StoryObj } from "@storybook/react-vite";
import { MemoryRouter } from "react-router";
import { expect, userEvent, within } from "storybook/test";
import { expectEdge, expectFocusRing, expectTarget } from "../../.storybook/story-utils.ts";
import { DemoBanner } from "./DemoBanner.tsx";

const meta = {
  title: "Demo/DemoBanner",
  component: DemoBanner,
  decorators: [
    (Story) => (
      <MemoryRouter initialEntries={["/demo"]}>
        <div className="lk-screen min-h-[240px]">
          <Story />
          <p className="p-(--space-4) text-ink">Inicio de Valentina…</p>
        </div>
      </MemoryRouter>
    ),
  ],
} satisfies Meta<typeof DemoBanner>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The notice by night, in Spanish: invented data, wiped on reload, and "Crear mi cuenta". */
export const Night: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const banner = canvas.getByRole("complementary", { name: "Demo" });
    await expect(banner).toHaveTextContent(
      "Estás en el demo: los datos son inventados y se borran al recargar.",
    );
    await expect(getComputedStyle(banner).position).toBe("sticky");
    const cta = within(banner).getByRole("link", { name: "Crear mi cuenta" });
    await expect(cta).toHaveAttribute("href", "/sign-in?lang=es");
    await expect(cta).toHaveClass("lk-btn-primary");
    await expectEdge(cta, 6);
    await expectTarget(cta);
    await userEvent.tab();
    await expectFocusRing(cta);
  },
};

/** By day, in English: sign-in keeps the visitor's language. */
export const DayEnglish: Story = {
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const banner = within(canvasElement).getByRole("complementary", { name: "Demo" });
    await expect(banner).toHaveTextContent(
      "You're in the demo: the data is made up and goes away when you reload.",
    );
    await expect(within(banner).getByRole("link", { name: "Create my account" })).toHaveAttribute(
      "href",
      "/sign-in?lang=en",
    );
  },
};

/** On a 320px phone the button wraps under the sentence; nothing overflows. */
export const NarrowPhone: Story = {
  decorators: [
    (Story) => (
      <div style={{ width: 320 }}>
        <Story />
      </div>
    ),
  ],
  play: async ({ canvasElement }) => {
    const banner = within(canvasElement).getByRole("complementary", { name: "Demo" });
    await expect(banner.scrollWidth).toBeLessThanOrEqual(banner.clientWidth);
    const cta = within(banner).getByRole("link", { name: "Crear mi cuenta" });
    const text = within(banner).getByText(/Estás en el demo/);
    await expect(cta.getBoundingClientRect().top).toBeGreaterThan(text.getBoundingClientRect().top);
  },
};
