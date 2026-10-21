import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { LukasBubble } from "./LukasBubble.tsx";

const meta = {
  title: "Lukas/LukasBubble",
  component: LukasBubble,
  decorators: [
    (Story) => (
      <div className="lk-screen max-w-[390px] p-(--space-4)">
        <Story />
      </div>
    ),
  ],
  args: { message: "¡Vas bien! Te quedan 11 días y aún tienes margen.", mood: "happy" },
} satisfies Meta<typeof LukasBubble>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Lukas beside his line. The line is the content; Lukas is decorative next to it. */
export const Happy: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const bubble = canvas.getByText("¡Vas bien! Te quedan 11 días y aún tienes margen.");
    await expect(bubble).toHaveClass("lk-bubble");
    await expect(bubble).toHaveAttribute("aria-live", "polite");
    const lukas = canvasElement.querySelector(".lk-lukas") as HTMLElement;
    await expect(lukas).toHaveAttribute("aria-hidden", "true");
    await expect(lukas).toHaveClass("is-happy");
    await expect(canvas.queryByRole("img")).toBeNull();
  },
};

export const Worried: Story = {
  args: { message: "Ojo: ya te pasaste 20,20 € en Supermercado.", mood: "worried" },
  play: async ({ canvasElement }) => {
    await expect(canvasElement.querySelector(".lk-lukas")).toHaveClass("is-worried");
    await expect(
      within(canvasElement).getByText("Ojo: ya te pasaste 20,20 € en Supermercado."),
    ).toBeVisible();
  },
};

export const CelebratingDay: Story = {
  args: { message: "¡Anotado!", mood: "celebrating" },
  globals: { theme: "day" },
  play: async ({ canvasElement }) => {
    await expect(canvasElement.querySelector(".lk-lukas")).toHaveClass("is-celebrating");
  },
};
