import type { ReactNode, Ref } from "react";
import { Link } from "react-router";
import { useTranslations } from "use-intl";
import { Lukas, type LukasMood } from "../../lukas/Lukas.tsx";
import { ThemeToggle } from "../../ui/ThemeToggle.tsx";

/** Lukitas' size on the sign-in screens: friendly, never crowding the form. */
const MASCOT_PX = 96;

/**
 * The frame of the sign-in screens (`/sign-in`, `/auth/verify`): the wordmark (home) and the
 * day/night switch on top, then one column with Lukitas above the content. On a phone the column
 * sits on the background, so the code boxes get the whole width; from `sm` up it is a raised card.
 */
export function SignInScreen({
  mood = "happy",
  children,
}: {
  mood?: LukasMood;
  children: ReactNode;
}) {
  const t = useTranslations("sign_in");
  return (
    <div className="lk-screen flex min-h-dvh flex-col">
      <header className="mx-auto flex w-full max-w-[480px] items-center justify-between px-(--space-4) py-(--space-3)">
        <Link
          to="/"
          aria-label={t("home")}
          className="lk-logo inline-flex min-h-11 items-center rounded-sm no-underline focus-visible:outline-3 focus-visible:outline-focus focus-visible:outline-offset-2"
        >
          Lukitas
        </Link>
        <ThemeToggle />
      </header>
      <main className="flex flex-1 flex-col items-center px-(--space-4) pb-(--space-6)">
        <div className="flex w-full max-w-[420px] flex-col items-center gap-(--space-4) sm:mt-(--space-5) sm:rounded-xl sm:border-2 sm:border-stroke sm:bg-surface sm:p-(--space-6) sm:shadow-edge-md">
          <Lukas mood={mood} size={MASCOT_PX} />
          {children}
        </div>
      </main>
    </div>
  );
}

/**
 * The screen's title: display face, centered. A screen that opens by itself (not from a tap on a
 * link) takes the focus to it with `focusable` and a `ref`, so a screen reader starts there.
 */
export function ScreenTitle({
  children,
  ref,
  focusable = false,
}: {
  children: ReactNode;
  ref?: Ref<HTMLHeadingElement>;
  focusable?: boolean;
}) {
  return (
    <h1
      ref={ref}
      tabIndex={focusable ? -1 : undefined}
      className="text-center font-display text-[28px] leading-tight font-bold text-ink outline-none"
    >
      {children}
    </h1>
  );
}

/** An error under the control it is about; `role="alert"` so it is read out when it appears. */
export function FieldError({ id, children }: { id: string; children: ReactNode }) {
  return (
    <p id={id} role="alert" className="text-[15px] text-over">
      {children}
    </p>
  );
}
