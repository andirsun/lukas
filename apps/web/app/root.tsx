import { QueryClientProvider } from "@tanstack/react-query";
import { type ReactNode, useState } from "react";
import { Links, Meta, Outlet, Scripts, ScrollRestoration } from "react-router";
import { ApiProvider } from "./api/ApiProvider.tsx";
import { createQueryClient } from "./api/query-client.ts";
import { IntlProvider, useLocale } from "./i18n/IntlProvider.tsx";
import { ThemeProvider } from "./theme/ThemeProvider.tsx";
import { THEME_BOOTSTRAP_SCRIPT } from "./theme/theme-bootstrap.ts";
import { ToastProvider } from "./ui/Toast.tsx";
import "./styles/fonts.ts";
import "./styles/app.css";

function Document({ children }: { children: ReactNode }) {
  const { locale } = useLocale();
  return (
    // data-theme is set by the bootstrap script before paint, so React must not reset it.
    <html lang={locale} suppressHydrationWarning>
      <head>
        {/* Runs before the stylesheet and <body>, so the stored theme never flashes. (React 19 hoists meta/title/link above it, so it is not literally first.) */}
        <script dangerouslySetInnerHTML={{ __html: THEME_BOOTSTRAP_SCRIPT }} />
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <Meta />
        <Links />
      </head>
      <body>
        {children}
        <ScrollRestoration />
        <Scripts />
      </body>
    </html>
  );
}

export function Layout({ children }: { children: ReactNode }) {
  return (
    <IntlProvider>
      <ThemeProvider>
        <Document>{children}</Document>
      </ThemeProvider>
    </IntlProvider>
  );
}

export default function App() {
  // One cache per visitor; created in state so prerendering never shares one across pages.
  const [queryClient] = useState(createQueryClient);
  return (
    <QueryClientProvider client={queryClient}>
      <ApiProvider>
        <ToastProvider>
          <Outlet />
        </ToastProvider>
      </ApiProvider>
    </QueryClientProvider>
  );
}
