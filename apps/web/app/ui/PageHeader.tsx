import type { ReactNode } from "react";
import { Link } from "react-router";

export interface PageHeaderProps {
  /** Where "back" goes, and how it reads (the accessible name contains the visible text). */
  back: { to: string; label: string; short: string };
  /** Beside the back link: the month picker, say. */
  aside?: ReactNode;
}

/**
 * The top of a screen inside the app that is not home: a back link (‹ Inicio) and, beside it,
 * what the screen browses by. Under 400px the aside gets its own row, like home's month.
 */
export function PageHeader({ back, aside }: PageHeaderProps) {
  return (
    <header className="flex flex-wrap items-center justify-between gap-x-(--space-2) gap-y-(--space-1)">
      <Link
        to={back.to}
        aria-label={back.label}
        className="lk-btn lk-btn-ghost lk-btn-sm inline-flex min-h-11 min-w-11 items-center gap-(--space-1) no-underline"
      >
        <span aria-hidden="true">‹</span>
        {back.short}
      </Link>
      {aside && (
        <div className="order-last flex w-full justify-center min-[400px]:order-none min-[400px]:w-auto">
          {aside}
        </div>
      )}
    </header>
  );
}
