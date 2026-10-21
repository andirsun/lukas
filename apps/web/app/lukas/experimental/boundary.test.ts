import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const APP = fileURLToPath(new URL("../../", import.meta.url));

function sources(dir: string): string[] {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) return sources(path);
    return /\.(ts|tsx)$/.test(name) ? [path] : [];
  });
}

/** Static imports, re-exports and dynamic imports whose specifier goes through `experimental/`. */
const EXPERIMENTAL = /(?:from\s*|import\s*\(\s*|import\s+)["'][^"']*\/experimental\/[^"']*["']/;

describe("the 3D Lukas experiment", () => {
  it("is never imported by the app's features or routes", () => {
    const files = ["features", "routes"].flatMap((dir) => sources(join(APP, dir)));
    expect(files.length).toBeGreaterThan(0);
    const offenders = files
      .filter((file) => EXPERIMENTAL.test(readFileSync(file, "utf8")))
      .map((file) => relative(APP, file));
    expect(offenders).toEqual([]);
  });
});
