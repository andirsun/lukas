/**
 * What the web's insights charts draw, as numbers (apps/mobile/test/insights/recharts_geometry.json):
 * the donut's sector paths and the trend's bars, grid, axis labels and budget line, read from the
 * SVG Recharts makes in the static Storybook for the insights stories. The app draws the same charts
 * with its own code (apps/mobile/lib/insights/chart_geometry.dart, a port of what Recharts computes),
 * and its tests check that the same data gives the same arcs, points and labels.
 *
 *   pnpm --filter @lukas/web parity:insights-geometry
 */
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { pathToFileURL } from "node:url";
import { chromium } from "playwright";
import {
  buildStorybook,
  openStory,
  PARITY_DIR,
  phoneContext,
  serveStorybook,
} from "./parity-storybook.ts";

/** A story, and the period button the person presses first (the trend's span), if any. */
const CASES = [
  { name: "donut-expenses", storyId: "insights-insights--donut-by-category" },
  { name: "donut-income", storyId: "insights-insights--donut-income" },
  { name: "donut-pending", storyId: "insights-insights--donut-pending" },
  { name: "trend-1-month", storyId: "insights-insights--trend-scrolled", span: "1 mes" },
  { name: "trend-3-months", storyId: "insights-insights--trend-scrolled", span: "3 meses" },
  { name: "trend-6-months", storyId: "insights-insights--trend-scrolled" },
  { name: "trend-year", storyId: "insights-insights--trend-year-scrolled" },
  { name: "trend-budget-gaps", storyId: "insights-insights--trend-gaps-scrolled" },
] as const;

async function main() {
  buildStorybook();
  const server = await serveStorybook();
  const browser = await chromium.launch();
  try {
    const out: Record<string, unknown> = {};
    for (const entry of CASES) {
      const context = await phoneContext(browser);
      const { page } = await openStory(context, server.base, {
        id: entry.name,
        storyId: entry.storyId,
        theme: "night",
        appTest: "unused_test.dart",
      });
      const span = "span" in entry ? entry.span : undefined;
      if (span) await page.getByRole("tab", { name: span }).click();
      await page.waitForTimeout(2500);
      // tsx wraps the named helpers below in `__name`, which the page does not have.
      await page.evaluate("globalThis.__name = (target) => target");
      out[entry.name] = await page.evaluate(() => {
        const attr = (el: Element, name: string) => el.getAttribute(name);
        const rects = (cls: string) =>
          [...document.querySelectorAll(`.${cls} .recharts-rectangle`)].map((r) => ({
            d: attr(r, "d"),
          }));
        const trend = document.querySelector(".lk-trend");
        const donut = document.querySelector(".lk-donut");
        return {
          donut: donut && {
            size: Number(attr(donut, "width")),
            sectors: [...document.querySelectorAll(".recharts-pie-sector path")].map((p) => ({
              d: attr(p, "d"),
              fill: attr(p, "fill"),
            })),
          },
          trend: trend && {
            width: Number(attr(trend, "width")),
            height: Number(attr(trend, "height")),
            income: rects("lk-trend-income"),
            expenses: rects("lk-trend-expenses"),
            grid: [...document.querySelectorAll(".lk-trend .recharts-cartesian-grid line")].map(
              (l) => ({
                y: Number(attr(l, "y1")),
                x1: Number(attr(l, "x1")),
                x2: Number(attr(l, "x2")),
              }),
            ),
            xTicks: [...document.querySelectorAll(".recharts-xAxis-tick-labels text")].map((t) => ({
              text: t.textContent,
              x: Number(attr(t, "x")),
              y: Number(attr(t, "y")),
            })),
            yTicks: [...document.querySelectorAll(".recharts-yAxis-tick-labels text")].map((t) => ({
              text: t.textContent,
              x: Number(attr(t, "x")),
              y: Number(attr(t, "y")),
            })),
            budget: document.querySelector(".lk-trend-budget path")?.getAttribute("d") ?? null,
            dots: [...document.querySelectorAll(".lk-trend-budget-dot")].map((c) => ({
              cx: Number(attr(c, "cx")),
              cy: Number(attr(c, "cy")),
            })),
          },
        };
      });
      await context.close();
      console.log(entry.name);
    }
    const file = join(PARITY_DIR, "..", "insights", "recharts_geometry.json");
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, `${JSON.stringify(out, null, 2)}\n`);
  } finally {
    await browser.close();
    await server.close();
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
