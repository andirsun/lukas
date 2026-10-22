import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { readBuildEnv, resolveBuildMode } from "./build-env.ts";

let root: string;

beforeEach(() => {
  root = mkdtempSync(join(tmpdir(), "lukas-build-env-"));
  vi.stubEnv("VITE_SITE_URL", undefined);
  vi.stubEnv("VITE_LANDING_ONLY", undefined);
  vi.stubEnv("VITE_APP_URL", undefined);
});

afterEach(() => {
  vi.unstubAllEnvs();
  rmSync(root, { recursive: true, force: true });
});

function write(name: string, content: string) {
  mkdirSync(root, { recursive: true });
  writeFileSync(join(root, name), content);
}

describe("readBuildEnv", () => {
  it("is undefined when neither a .env file nor the environment sets the flags", () => {
    expect(readBuildEnv({ root, mode: "production" })).toEqual({
      siteUrl: undefined,
      landingOnly: undefined,
      appUrl: undefined,
    });
  });

  it("reads the flags from a .env file, like Vite does for the app code", () => {
    write(
      ".env",
      "VITE_SITE_URL=https://lukitas.example\nVITE_LANDING_ONLY=true\nVITE_APP_URL=https://app.example\n",
    );
    expect(readBuildEnv({ root, mode: "production" })).toEqual({
      siteUrl: "https://lukitas.example",
      landingOnly: "true",
      appUrl: "https://app.example",
    });
  });

  it("reads them from the real environment too, which wins over the file", () => {
    write(".env", "VITE_SITE_URL=https://from-file.example\n");
    vi.stubEnv("VITE_SITE_URL", "https://from-env.example");
    vi.stubEnv("VITE_LANDING_ONLY", "true");
    vi.stubEnv("VITE_APP_URL", "https://app-from-env.example");
    expect(readBuildEnv({ root, mode: "production" })).toEqual({
      siteUrl: "https://from-env.example",
      landingOnly: "true",
      appUrl: "https://app-from-env.example",
    });
  });

  it("reads the file for the mode: .env.production only in production", () => {
    write(".env", "VITE_SITE_URL=https://base.example\n");
    write(".env.production", "VITE_SITE_URL=https://prod.example\n");
    expect(readBuildEnv({ root, mode: "production" }).siteUrl).toBe("https://prod.example");
    expect(readBuildEnv({ root, mode: "development" }).siteUrl).toBe("https://base.example");
  });

  it("ignores variables without the VITE_ prefix", () => {
    write(".env", "SITE_URL=https://nope.example\nLANDING_ONLY=true\n");
    expect(readBuildEnv({ root, mode: "production" })).toEqual({
      siteUrl: undefined,
      landingOnly: undefined,
      appUrl: undefined,
    });
  });
});

describe("resolveBuildMode", () => {
  it("takes --mode (or -m) from the command line first", () => {
    expect(resolveBuildMode(["node", "react-router", "build", "--mode", "staging"], {})).toBe(
      "staging",
    );
    expect(resolveBuildMode(["node", "react-router", "build", "--mode=staging"], {})).toBe(
      "staging",
    );
    expect(resolveBuildMode(["node", "react-router", "build", "-m", "staging"], {})).toBe(
      "staging",
    );
    expect(
      resolveBuildMode(["node", "react-router", "build", "--mode", "staging"], {
        NODE_ENV: "development",
      }),
    ).toBe("staging");
  });

  it("then NODE_ENV", () => {
    expect(resolveBuildMode(["node", "react-router", "build"], { NODE_ENV: "test" })).toBe("test");
  });

  it("then the command: dev is development, anything else production", () => {
    expect(resolveBuildMode(["node", "react-router", "dev"], {})).toBe("development");
    expect(resolveBuildMode(["node", "react-router", "build"], {})).toBe("production");
    expect(resolveBuildMode(["node", "tsx", "scripts/build-landing.ts"], {})).toBe("production");
  });
});
