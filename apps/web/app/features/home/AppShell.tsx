import { type ReactNode, useEffect } from "react";
import { useMe } from "../../api/queries.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { BottomBar } from "../../ui/BottomBar.tsx";
import { Sidebar } from "../../ui/Sidebar.tsx";
import {
  TransactionSheetProvider,
  useTransactionSheet,
} from "../add-transaction/TransactionSheetProvider.tsx";

/** Sections linked from the navigation that do not exist yet (Tasks 13–15 add them). */
const SOON_SIDEBAR = ["insights", "recurring", "categories", "settings"] as const;
const SOON_TABS = ["insights"] as const;

function Frame({ children }: { children: ReactNode }) {
  const { openAdd } = useTransactionSheet();
  return (
    <div className="lk-screen lk-app-shell flex min-h-dvh">
      <div className="sticky top-0 hidden h-dvh flex-none lg:flex">
        <Sidebar current="home" onAdd={() => openAdd()} soon={SOON_SIDEBAR} />
      </div>
      <div className="min-w-0 flex-1 pb-[calc(112px+env(safe-area-inset-bottom))] lg:pb-(--space-6)">
        {children}
      </div>
      <div className="fixed inset-x-0 bottom-0 z-30 pb-[env(safe-area-inset-bottom)] lg:hidden">
        <BottomBar current="home" onAdd={() => openAdd()} soon={SOON_TABS} />
      </div>
    </div>
  );
}

/**
 * The frame of the signed-in app (`/app/*`): the bottom bar on phones (Inicio · ＋ · Análisis),
 * the sidebar on wide screens, and the add/edit sheet both open. It waits for the profile (its
 * currency and time zone drive every screen) and speaks the profile's language.
 */
export function AppShell({ children }: { children: ReactNode }) {
  const me = useMe();
  const { locale, setLocale } = useLocale();
  const profileLocale = me.data?.locale;
  useEffect(() => {
    if ((profileLocale === "es" || profileLocale === "en") && profileLocale !== locale) {
      setLocale(profileLocale);
    }
  }, [profileLocale, locale, setLocale]);

  if (me.error && !me.data) throw me.error;
  if (!me.data) return <div className="lk-screen min-h-dvh" aria-busy="true" />;
  return (
    <TransactionSheetProvider currency={me.data.currency} timezone={me.data.timezone}>
      <Frame>{children}</Frame>
    </TransactionSheetProvider>
  );
}
