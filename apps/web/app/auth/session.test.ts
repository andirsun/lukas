import { describe, expect, it } from "vitest";
import { createGuards, DEMO_USER, type GuardDeps, type SessionUser } from "./session.ts";

const user = (onboardingCompletedAt: string | null): SessionUser => ({
  id: "u1",
  email: "ana@example.com",
  onboardingCompletedAt,
});

function guards(session: SessionUser | null, mode: "live" | "demo" = "live") {
  const deps: GuardDeps = { getSession: async () => session, mode: () => mode };
  return createGuards(deps);
}

/** What a guard threw, as a redirect: its status and Location. */
async function redirectOf(run: () => Promise<unknown>) {
  try {
    await run();
  } catch (thrown) {
    if (thrown instanceof Response) {
      return { status: thrown.status, location: thrown.headers.get("Location") };
    }
    throw thrown;
  }
  return null;
}

describe("requireSession", () => {
  it("redirects a visitor without a session to sign-in, remembering the page", async () => {
    const { requireSession } = guards(null);
    expect(await redirectOf(() => requireSession("/app/insights"))).toEqual({
      status: 302,
      location: "/sign-in?next=%2Fapp%2Finsights",
    });
  });

  it("never lets next point off-site", async () => {
    const { requireSession } = guards(null);
    expect(await redirectOf(() => requireSession("https://evil.example"))).toEqual({
      status: 302,
      location: "/sign-in?next=%2Fapp",
    });
  });

  it("returns the user when signed in", async () => {
    const { requireSession } = guards(user(null));
    expect(await requireSession("/app")).toMatchObject({ id: "u1" });
  });

  it("treats the demo as signed in", async () => {
    const { requireSession } = guards(null, "demo");
    expect(await requireSession("/app")).toEqual(DEMO_USER);
  });
});

describe("requireOnboarded", () => {
  it("sends a user who has not finished onboarding to /welcome", async () => {
    const { requireOnboarded } = guards(user(null));
    expect(await redirectOf(() => requireOnboarded())).toEqual({
      status: 302,
      location: "/welcome",
    });
  });

  it("lets an onboarded user through", async () => {
    const { requireOnboarded } = guards(user("2026-10-01T10:00:00.000Z"));
    expect(await requireOnboarded()).toMatchObject({ id: "u1" });
  });

  it("sends a visitor without a session to sign-in", async () => {
    const { requireOnboarded } = guards(null);
    expect(await redirectOf(() => requireOnboarded("/app/insights"))).toEqual({
      status: 302,
      location: "/sign-in?next=%2Fapp%2Finsights",
    });
  });

  it("treats the demo as onboarded", async () => {
    const { requireOnboarded } = guards(null, "demo");
    expect(await requireOnboarded()).toEqual(DEMO_USER);
  });
});

describe("redirectIfSignedIn", () => {
  const request = (url: string) => ({ request: new Request(`http://localhost${url}`) });

  it("lets a signed-out visitor see the page", async () => {
    const { redirectIfSignedIn } = guards(null);
    expect(await redirectIfSignedIn(request("/sign-in"))).toBeNull();
  });

  it("sends an onboarded user to the app", async () => {
    const { redirectIfSignedIn } = guards(user("2026-10-01T10:00:00.000Z"));
    expect(await redirectOf(() => redirectIfSignedIn(request("/sign-in")))).toEqual({
      status: 302,
      location: "/app",
    });
  });

  it("sends a user still onboarding to /welcome", async () => {
    const { redirectIfSignedIn } = guards(user(null));
    expect((await redirectOf(() => redirectIfSignedIn(request("/sign-in"))))?.location).toBe(
      "/welcome",
    );
  });

  it("honours a same-origin next and ignores an off-site one", async () => {
    const { redirectIfSignedIn } = guards(user("2026-10-01T10:00:00.000Z"));
    expect(
      (await redirectOf(() => redirectIfSignedIn(request("/sign-in?next=%2Fapp%2Finsights"))))
        ?.location,
    ).toBe("/app/insights");
    expect(
      (
        await redirectOf(() =>
          redirectIfSignedIn(request("/sign-in?next=https%3A%2F%2Fevil.example")),
        )
      )?.location,
    ).toBe("/app");
  });
});
