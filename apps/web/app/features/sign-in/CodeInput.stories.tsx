import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { expectFocusRing } from "../../../.storybook/story-utils.ts";
import { CodeInput } from "./CodeInput.tsx";

function CodeInputHarness({
  onComplete,
  invalid = false,
}: {
  onComplete: (code: string) => void;
  invalid?: boolean;
}) {
  const [value, setValue] = useState("");
  return (
    <div className="max-w-[360px]">
      <CodeInput
        value={value}
        onChange={setValue}
        onComplete={onComplete}
        invalid={invalid}
        autoFocus
      />
      <output aria-label="Typed code">{value}</output>
    </div>
  );
}

const meta = {
  title: "Sign-in/CodeInput",
  component: CodeInputHarness,
  args: { onComplete: fn() },
} satisfies Meta<typeof CodeInputHarness>;

export default meta;
type Story = StoryObj<typeof meta>;

const boxes = (canvas: ReturnType<typeof within>) =>
  canvas.getAllByRole("textbox", { name: /^Dígito \d de 6$/ });

/** Six labelled boxes in a named group; typing moves along and the last digit completes the code. */
export const Typing: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const inputs = boxes(canvas);
    await expect(inputs).toHaveLength(6);
    await expect(inputs[0]).toHaveAttribute("autocomplete", "one-time-code");
    for (const input of inputs.slice(1)) await expect(input).toHaveAttribute("autocomplete", "off");
    await waitFor(() => expect(inputs[0]).toHaveFocus());
    await expectFocusRing(inputs[0] as HTMLElement);
    await userEvent.keyboard("12");
    await expect(inputs[2]).toHaveFocus();
    await expect(args.onComplete).not.toHaveBeenCalled();
    await userEvent.keyboard("3456");
    await expect(canvas.getByRole("status", { name: "Typed code" })).toHaveTextContent("123456");
    await expect(args.onComplete).toHaveBeenCalledWith("123456");
  },
};

/** Backspace on an empty box steps back and clears the digit there; letters are ignored. */
export const Backspace: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const inputs = boxes(canvas);
    await waitFor(() => expect(inputs[0]).toHaveFocus());
    await userEvent.keyboard("1a2");
    await expect(canvas.getByRole("status", { name: "Typed code" })).toHaveTextContent("12");
    await expect(inputs[2]).toHaveFocus();
    await userEvent.keyboard("{Backspace}");
    await expect(inputs[1]).toHaveFocus();
    await expect(inputs[1]).toHaveValue("");
    await userEvent.keyboard("{Backspace}");
    await expect(inputs[0]).toHaveFocus();
    await expect(inputs[0]).toHaveValue("");
    await expect(canvas.getByRole("status", { name: "Typed code" })).toHaveTextContent("");
  },
};

/** Pasting (or the phone's autofill) a whole code fills every box and completes it. */
export const Paste: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const inputs = boxes(canvas);
    await waitFor(() => expect(inputs[0]).toHaveFocus());
    await userEvent.paste("Code: 987-654");
    await expect(inputs.map((input: HTMLElement) => (input as HTMLInputElement).value)).toEqual([
      "9",
      "8",
      "7",
      "6",
      "5",
      "4",
    ]);
    await expect(args.onComplete).toHaveBeenCalledWith("987654");
  },
};

/** Marked invalid (after a wrong code) in both themes: the boxes carry aria-invalid. */
export const Invalid: Story = {
  args: { invalid: true },
  globals: { theme: "day" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    for (const input of boxes(canvas)) await expect(input).toHaveAttribute("aria-invalid", "true");
  },
};
