import {
  type ClipboardEvent,
  type KeyboardEvent,
  type Ref,
  useId,
  useImperativeHandle,
  useRef,
} from "react";
import { useTranslations } from "use-intl";
import { cx } from "../../ui/cx.ts";

export const CODE_LENGTH = 6;

export interface CodeInputHandle {
  /** Focuses box `index`, by default the first empty one. */
  focus(index?: number): void;
}

export interface CodeInputProps {
  /** The digits typed so far, left to right with no gaps (at most 6). */
  value: string;
  onChange(value: string): void;
  /** Called when a change makes the code 6 digits long. */
  onComplete(code: string): void;
  invalid?: boolean;
  /** Typing is ignored (e.g. while the code is being checked); the boxes stay focusable. */
  readOnly?: boolean;
  autoFocus?: boolean;
  /** Id of the text that explains an error. */
  describedBy?: string | undefined;
  ref?: Ref<CodeInputHandle>;
}

const digitsOf = (text: string) => text.replace(/\D/g, "");

/**
 * The 6-digit sign-in code as six boxes. Typing moves to the next box, Backspace on an empty box
 * steps back and clears the digit there, the arrows move between boxes. Pasting a code (or the
 * phone offering it from the email: `autocomplete="one-time-code"` on the first box) fills every
 * box. Screen readers hear a group "6-digit code" with "Digit 1 of 6" and so on.
 *
 * The value is one string, filled left to right: a box after the first empty one can't be reached,
 * so the code never has gaps.
 */
export function CodeInput({
  value,
  onChange,
  onComplete,
  invalid = false,
  readOnly = false,
  autoFocus = false,
  describedBy,
  ref,
}: CodeInputProps) {
  const t = useTranslations("sign_in");
  const labelId = useId();
  const boxes = useRef<(HTMLInputElement | null)[]>([]);
  // The code as of the last change, ahead of the re-render: moving focus happens in the same event
  // as the change, and the focused box must already see the new length.
  const latest = useRef(value);
  latest.current = value;

  const focusBox = (index: number) => {
    const box = boxes.current[Math.max(0, Math.min(index, CODE_LENGTH - 1))];
    box?.focus();
    box?.select();
  };

  useImperativeHandle(
    ref,
    () => ({ focus: (index = latest.current.length) => focusBox(index) }),
    [],
  );

  const commit = (next: string, focusIndex: number) => {
    const code = digitsOf(next).slice(0, CODE_LENGTH);
    if (code !== latest.current) {
      latest.current = code;
      onChange(code);
      if (code.length === CODE_LENGTH) onComplete(code);
    }
    focusBox(focusIndex);
  };

  /** Digits typed, pasted or autofilled into box `index`: they replace the code from there on. */
  const fill = (index: number, digits: string) => {
    const value = latest.current;
    const at = Math.min(index, value.length);
    if (digits.length === 1) {
      commit(value.slice(0, at) + digits + value.slice(at + 1), at + 1);
    } else {
      const next = (value.slice(0, at) + digits).slice(0, CODE_LENGTH);
      commit(next, next.length);
    }
  };

  const remove = (index: number) =>
    commit(latest.current.slice(0, index) + latest.current.slice(index + 1), index);

  const onKeyDown = (index: number) => (event: KeyboardEvent<HTMLInputElement>) => {
    if (readOnly) return;
    const value = latest.current;
    if (event.key === "Backspace" && index >= value.length && index > 0) {
      event.preventDefault();
      remove(index - 1);
    } else if (event.key === "ArrowLeft" && index > 0) {
      event.preventDefault();
      focusBox(index - 1);
    } else if (event.key === "ArrowRight" && index < value.length) {
      event.preventDefault();
      focusBox(index + 1);
    }
  };

  const onPaste = (index: number) => (event: ClipboardEvent<HTMLInputElement>) => {
    event.preventDefault();
    if (readOnly) return;
    const digits = digitsOf(event.clipboardData.getData("text"));
    if (digits) fill(index, digits);
  };

  return (
    <div className="flex w-full flex-col gap-(--space-2)">
      <span id={labelId} className="text-sm text-ink-muted">
        {t("code_label")}
      </span>
      <div
        role="group"
        aria-labelledby={labelId}
        className="flex w-full justify-center gap-(--space-1) min-[360px]:gap-(--space-2)"
      >
        {Array.from({ length: CODE_LENGTH }, (_, index) => (
          <input
            // The boxes never reorder: their position is their identity.
            key={index}
            ref={(element) => {
              boxes.current[index] = element;
            }}
            type="text"
            inputMode="numeric"
            autoComplete={index === 0 ? "one-time-code" : "off"}
            // Only the first box: the code step exists to type this code, and it starts there.
            autoFocus={autoFocus && index === 0}
            aria-label={t("digit_label", { index: index + 1 })}
            aria-invalid={invalid || undefined}
            aria-describedby={describedBy}
            readOnly={readOnly}
            value={value[index] ?? ""}
            className={cx("lk-code-box", invalid && "is-invalid")}
            onFocus={(event) => {
              // No gaps: a box past the first empty one sends focus back to it.
              if (index > latest.current.length) focusBox(latest.current.length);
              else event.currentTarget.select();
            }}
            onChange={(event) => {
              if (readOnly) return;
              const digits = digitsOf(event.target.value);
              const old = latest.current[index];
              // Typed next to the digit already there (not over it): keep only the new one.
              if (old && digits.length === 2 && digits.includes(old)) {
                fill(index, digits[0] === old ? digits.slice(1) : digits.slice(0, 1));
              } else if (digits) fill(index, digits);
              else if (index < latest.current.length) remove(index);
            }}
            onKeyDown={onKeyDown(index)}
            onPaste={onPaste(index)}
          />
        ))}
      </div>
    </div>
  );
}
