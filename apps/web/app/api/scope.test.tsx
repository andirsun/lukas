import { type QueryClient, useQueryClient } from "@tanstack/react-query";
import { renderToString } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";
import { ApiProvider, type ApiProviderProps, useApi, useApiMode } from "./ApiProvider.tsx";
import { createApiScope } from "./scope.ts";

const json = (body: unknown) =>
  new Response(JSON.stringify(body), { headers: { "content-type": "application/json" } });

describe("createApiScope", () => {
  it("gives each scope its own cache", () => {
    const demo = createApiScope({ mode: "demo", fetch: vi.fn() });
    const live = createApiScope({ mode: "live" });
    demo.queryClient.setQueryData(["me"], { email: "valentina@demo" });
    expect(demo.queryClient).not.toBe(live.queryClient);
    expect(live.queryClient.getQueryData(["me"])).toBeUndefined();
  });

  it("uses the injected fetch for the client, in demo mode", async () => {
    const fetch = vi.fn<typeof globalThis.fetch>(async () => json([]));
    const scope = createApiScope({ mode: "demo", fetch, baseUrl: "http://localhost/api" });
    await scope.client.GET("/v1/recurrences");
    expect(fetch).toHaveBeenCalledOnce();
  });

  it("clearSession empties the cache, so the next user never sees the last one's data", () => {
    const scope = createApiScope({ mode: "live" });
    scope.queryClient.setQueryData(["me"], { email: "ana@example.com" });
    scope.queryClient.setQueryData(["summary", "2026-10"], { spent: 1 });
    scope.clearSession();
    expect(scope.queryClient.getQueryData(["me"])).toBeUndefined();
    expect(scope.queryClient.getQueryData(["summary", "2026-10"])).toBeUndefined();
  });
});

/** Renders `<ApiProvider>` on the server and returns what the hooks gave a child during render. */
function render(props: Omit<ApiProviderProps, "children"> = {}) {
  const seen: { client?: ReturnType<typeof useApi>; mode?: string; queryClient?: QueryClient } = {};
  function Probe() {
    seen.client = useApi();
    seen.mode = useApiMode();
    seen.queryClient = useQueryClient();
    return null;
  }
  renderToString(
    <ApiProvider {...props}>
      <Probe />
    </ApiProvider>,
  );
  return seen;
}

describe("ApiProvider", () => {
  it("is live by default", () => {
    expect(render().mode).toBe("live");
  });

  it("gives screens a client bound to the injected fetch in demo mode", async () => {
    const fetch = vi.fn<typeof globalThis.fetch>(async () => json({ email: "valentina@demo" }));
    const seen = render({ mode: "demo", fetch, baseUrl: "http://localhost/api" });
    expect(seen.mode).toBe("demo");
    await seen.client?.GET("/v1/me");
    expect(fetch).toHaveBeenCalledOnce();
  });

  it("has a fresh cache for each mode", () => {
    const demo = render({ mode: "demo", fetch: vi.fn() });
    demo.queryClient?.setQueryData(["me"], { email: "valentina@demo" });
    const live = render({ mode: "live" });
    expect(live.queryClient).not.toBe(demo.queryClient);
    expect(live.queryClient?.getQueryData(["me"])).toBeUndefined();
  });
});
