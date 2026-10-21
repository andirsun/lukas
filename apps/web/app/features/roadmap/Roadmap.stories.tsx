import type { Meta, StoryObj } from "@storybook/react-vite";
import { MemoryRouter } from "react-router";
import { expect, within } from "storybook/test";
import { expectTarget } from "../../../.storybook/story-utils.ts";
import { Roadmap } from "./Roadmap.tsx";
import { WhatsNext } from "./WhatsNext.tsx";

const meta = {
  title: "Roadmap/Roadmap",
  component: Roadmap,
  parameters: { layout: "fullscreen" },
  decorators: [
    (Story) => (
      <MemoryRouter>
        <Story />
      </MemoryRouter>
    ),
  ],
} satisfies Meta<typeof Roadmap>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The page in Spanish, night theme: a column per status that has items ("Ya está" is empty). */
export const Page: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading", { level: 1 })).toHaveTextContent("Lo que viene");
    await expect(canvas.getByText(/Puede cambiar con el tiempo/)).toBeVisible();
    const columns = canvas.getAllByRole("heading", { level: 2 });
    await expect(columns.map((heading) => heading.textContent)).toEqual([
      "En construcción",
      "Próximo",
      "Más adelante",
    ]);
    await expect(canvas.queryByText("Ya está")).toBeNull();
    await expect(canvas.getByRole("heading", { name: "Conecta tu IA" })).toBeVisible();
  },
};

/** The page in English, day theme. */
export const PageDayEnglish: Story = {
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading", { level: 1 })).toHaveTextContent("What's next");
    await expect(canvas.getByRole("heading", { name: "Being built" })).toBeVisible();
    await expect(canvas.getByRole("heading", { name: "iPhone app" })).toBeVisible();
  },
};

/** The landing's section: three cards and a button to the roadmap. */
export const WhatsNextSection: Story = {
  render: () => <WhatsNext />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getAllByRole("listitem")).toHaveLength(3);
    const button = canvas.getByRole("link", { name: "Ver el roadmap" });
    await expect(button).toHaveAttribute("href", "/roadmap");
    await expectTarget(button);
  },
};

/** The landing's section in English. */
export const WhatsNextEnglish: Story = {
  render: () => <WhatsNext />,
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("link", { name: "See the roadmap" })).toHaveAttribute(
      "href",
      "/en/roadmap",
    );
  },
};
