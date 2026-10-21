import type { MetaDescriptor } from "react-router";

export function meta(): MetaDescriptor[] {
  return [{ title: "Lukas" }];
}

/** Placeholder until the landing page lands; proves tokens, fonts and the component layer load. */
export default function HomePlaceholder() {
  return (
    <main className="lk-screen grid min-h-dvh place-items-center">
      <h1 className="lk-logo">Lukas</h1>
    </main>
  );
}
