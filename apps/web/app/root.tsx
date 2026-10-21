import type { ReactNode } from "react";
import { Links, Meta, Outlet, Scripts, ScrollRestoration, useLocation } from "react-router";
import "./styles/fonts.ts";
import "./styles/app.css";

export function Layout({ children }: { children: ReactNode }) {
  const { pathname } = useLocation();
  const lang = pathname === "/en" || pathname.startsWith("/en/") ? "en" : "es";
  return (
    <html lang={lang}>
      <head>
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

export default function App() {
  return <Outlet />;
}
