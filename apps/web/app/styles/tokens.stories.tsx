import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect } from "storybook/test";

const COLORS = ["bg", "surface", "surface-row", "surface-sunken", "brand", "good", "near", "over"];

function Tokens() {
  return (
    <div className="lk-screen lk-pad min-h-dvh">
      <span className="lk-logo">Lukas</span>
      <ul className="lk-row-flex m-0 list-none p-0">
        {COLORS.map((name) => (
          <li key={name} className="lk-rowcard">
            <span className="lk-tile" style={{ background: `var(--${name})` }} />
            <code className="lk-status">--{name}</code>
          </li>
        ))}
      </ul>
    </div>
  );
}

const meta = {
  title: "Foundations/Tokens",
  component: Tokens,
} satisfies Meta<typeof Tokens>;

export default meta;

/** Smoke test: the generated tokens and the lk- component layer load in Storybook. */
export const Night: StoryObj<typeof meta> = {
  play: async () => {
    const styles = getComputedStyle(document.documentElement);
    await expect(styles.getPropertyValue("--brand").trim()).toBe("#7c4dff");
    await expect(styles.getPropertyValue("--space-4").trim()).toBe("16px");
    // tokens.css (unlayered) wins over Tailwind's same-named @theme entries.
    await expect(styles.getPropertyValue("--radius-xl").trim()).toBe("24px");
  },
};
