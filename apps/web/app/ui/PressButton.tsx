import type { ButtonHTMLAttributes, Ref } from "react";
import { cx } from "./cx.ts";

export type PressButtonProps = {
  variant?: "primary" | "secondary" | "ghost";
  size?: "md" | "sm";
  ref?: Ref<HTMLButtonElement>;
} & ButtonHTMLAttributes<HTMLButtonElement>;

/**
 * The pressable button (`lk-btn`): sits on a solid bottom edge and sinks into it while pressed.
 * One `primary` per view; `secondary` for the alternative, `ghost` to skip or dismiss. Always at
 * least 44px in both directions; `type` defaults to `button` so it never submits by accident.
 */
export function PressButton({
  variant = "primary",
  size = "md",
  type = "button",
  className,
  ...rest
}: PressButtonProps) {
  return (
    <button
      type={type}
      className={cx(
        "lk-btn",
        `lk-btn-${variant}`,
        size === "sm" && "lk-btn-sm",
        "inline-flex min-h-11 min-w-11 items-center justify-center gap-(--space-2)",
        className,
      )}
      {...rest}
    />
  );
}
