import { addMonths, monthOf } from "@lukas/core";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { expectTarget } from "../../../.storybook/story-utils.ts";
import { HomeStage, STORY_TODAY } from "../home/story-harness.tsx";
import { monthLabel } from "./insights-model.ts";

/**
 * Insights (spec §2.7) against the fake API: the October 2026 fixture (packages/core: 2237,08 €
 * spent, Casa 1329,78 € of it, 6.200 € of salary) in this month and the six before it, with the
 * rent and Spotify as recurrences. The donut by category (expenses or income, paid or pending),
 * the month-by-month trend, and "¿Cuánto me cuesta vivir?"; each chart with its table for screen
 * readers, and text (never a blank chart) when there is nothing to show.
 */

interface Spies {
  onRequest(line: string, headers: Record<string, string>): void;
}

const meta = {
  title: "Insights/Insights",
  args: { onRequest: fn() },
  parameters: {
    viewport: {
      options: {
        phone: { name: "Phone", styles: { width: "390px", height: "844px" }, type: "mobile" },
        desktop: { name: "Desktop", styles: { width: "1280px", height: "800px" }, type: "desktop" },
      },
    },
  },
  globals: { viewport: { value: "phone", isRotated: false } },
} satisfies Meta<Spies>;

export default meta;
type Story = StoryObj<Spies>;
type Canvas = ReturnType<typeof within>;

const MONTH = monthOf(STORY_TODAY);
/** A month mid-sentence, as the page writes it: `octubre`, `diciembre de 2025`. */
const inSentence = (back: number) => monthLabel(addMonths(MONTH, -back), MONTH, "es");
/** A month starting a table row: `Octubre`, `Diciembre de 2025`. */
const rowName = (back: number) => {
  const name = inSentence(back);
  return name.charAt(0).toUpperCase() + name.slice(1);
};
/**
 * Text content is compared with its whitespace collapsed: the NBSP before € and % reads as a
 * space (`toHaveTextContent` does it; `bodyRows` does it too).
 */
const NBSP = " ";
const eur = (text: string) => `${text}${NBSP}€`;
const pct = (text: string) => `${text}${NBSP}%`;

const october = (args: Spies) => (
  <HomeStage onRequest={args.onRequest} data="october" path="/app/insights" />
);

/**
 * Waits until every entrance animation (cards rising, legend rows sliding in) has ended, so
 * visibility and the a11y contrast checks never measure something mid-fade.
 */
const settled = (root: HTMLElement) =>
  waitFor(
    () => {
      expect(root.querySelector("[aria-busy='true']")).toBeNull();
      const moving = root.querySelectorAll<HTMLElement>(
        "section, li, .lk-insight-body, [style*='opacity']",
      );
      for (const el of [root, ...moving]) {
        expect(getComputedStyle(el).opacity).toBe("1");
      }
    },
    { timeout: 8000 },
  );

/** A play function that, once done, also waits for the screen to settle (for the a11y checks). */
function settledAfter<Context extends { canvasElement: HTMLElement }>(
  play: (context: Context) => Promise<void>,
) {
  return async (context: Context) => {
    await play(context);
    await settled(context.canvasElement);
  };
}

/** A section of the screen, by its heading, once it has risen into place. */
async function region(canvas: Canvas, name: string) {
  const found = await canvas.findByRole("region", { name }, { timeout: 4000 });
  await settled(found);
  return found;
}

/** The rows of a table (header row left out), each as its cells' text. */
function bodyRows(table: HTMLElement): string[][] {
  return [...table.querySelectorAll("tbody tr")].map((row) =>
    [...row.querySelectorAll("th, td")].map((cell) =>
      (cell.textContent ?? "").replace(/\s+/g, " ").trim(),
    ),
  );
}

async function tableIn(scope: HTMLElement, name: string | RegExp) {
  return within(scope).findByRole("table", { name }, { timeout: 4000 });
}

/** The donut is drawn: one sector per category, once the chart's code has loaded. */
const sectorsIn = (scope: HTMLElement, count: number) =>
  waitFor(() => expect(scope.querySelectorAll(".recharts-pie-sector")).toHaveLength(count), {
    timeout: 8000,
  });

// -- Donut ----------------------------------------------------------------------------------------

/**
 * This month's spending by category: Casa first with 59,4 % (1329,78 € of 2237,08 €), seven
 * sectors (Transporte spent nothing), the legend in the same order, and the table for screen
 * readers saying the same. Lukitas says what took the biggest bite.
 */
export const DonutByCategory: Story = {
  render: october,
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(
      await canvas.findByRole("heading", { level: 1, name: "Análisis" }, { timeout: 4000 }),
    ).toBeVisible();
    const donut = await region(canvas, "Por categoría");
    const table = await tableIn(donut, `Gastos por categoría en ${inSentence(0)}`);
    const rows = bodyRows(table);
    await expect(rows[0]).toEqual(["Casa", pct("59,4"), eur("1329,78")]);
    await expect(rows).toHaveLength(7);
    await expect(rows.map((r) => r[0])).not.toContain("Transporte");
    await expect(table.querySelector("tfoot")).toHaveTextContent(`Total${eur("2237,08")}`);

    await sectorsIn(donut, 7);
    const legend = within(donut).getByTestId("donut-legend");
    const first = legend.querySelector("li");
    await expect(first).toHaveTextContent("Casa");
    await expect(first).toHaveTextContent(pct("59,4"));
    await expect(first).toHaveTextContent(eur("1329,78"));
    await expect(within(donut).getByTestId("donut-total")).toHaveTextContent(eur("2237,08"));

    await expect(
      canvas.getByText(
        `Casa fue lo que más lukas se llevó en ${inSentence(0)}: ${eur("1329,78")}.`,
      ),
    ).toBeVisible();
  }),
};

/** "Ingresos" shows where the money came from: all of it from Salário. */
export const DonutIncome: Story = {
  render: october,
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const donut = await region(canvas, "Por categoría");
    await tableIn(donut, /^Gastos por categoría/);
    const income = within(donut).getByRole("tab", { name: "Ingresos" });
    await expectTarget(income);
    await userEvent.click(income);
    const table = await tableIn(donut, /^Ingresos por categoría/);
    await waitFor(() => expect(bodyRows(table)).toEqual([["Salário", pct("100"), eur("6200,00")]]));
    await sectorsIn(donut, 1);
    await expect(within(donut).getByTestId("donut-total")).toHaveTextContent(eur("6200,00"));
  }),
};

/** "Pendientes" keeps only what is still to pay: this month's subscriptions. */
export const DonutPending: Story = {
  render: october,
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const donut = await region(canvas, "Por categoría");
    await tableIn(donut, /^Gastos por categoría/);
    await userEvent.click(within(donut).getByRole("tab", { name: "Pendientes" }));
    const table = await tableIn(donut, /^Gastos pendientes por categoría/);
    await waitFor(() =>
      expect(bodyRows(table)).toEqual([["suscripciones", pct("100"), eur("36,89")]]),
    );
    // Paid ones: the rest, without the subscriptions.
    await userEvent.click(within(donut).getByRole("tab", { name: "Pagados" }));
    const paid = await tableIn(donut, /^Gastos pagados por categoría/);
    await waitFor(() => expect(bodyRows(paid)[0]?.[0]).toBe("Casa"));
    await expect(bodyRows(paid).map((r) => r[0])).not.toContain("suscripciones");
  }),
};

/** A range: the last three months add up (3 × 2237,08 €), and Casa keeps its share. */
export const DonutRange: Story = {
  render: october,
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await region(canvas, "Por categoría");
    await userEvent.click(canvas.getByRole("tab", { name: "3 meses" }));
    const donut = await region(canvas, "Por categoría");
    const table = await tableIn(
      donut,
      `Gastos por categoría de ${inSentence(2)} a ${inSentence(0)}`,
    );
    await waitFor(() => expect(bodyRows(table)[0]).toEqual(["Casa", pct("59,4"), eur("3989,34")]));
    await expect(within(donut).getByTestId("donut-total")).toHaveTextContent(eur("6711,24"));
    // Going back a month moves the whole range.
    await userEvent.click(canvas.getByRole("button", { name: "Mes anterior" }));
    await tableIn(donut, `Gastos por categoría de ${inSentence(3)} a ${inSentence(1)}`);
  }),
};

// -- Trend ----------------------------------------------------------------------------------------

/** The trend covers the span on screen: these stories look at six months. */
async function showSixMonths(canvas: ReturnType<typeof within>) {
  await userEvent.click(await canvas.findByRole("tab", { name: "6 meses" }));
}

/** The trend covers the same months as the donut: one month by default, three after "3 meses". */
export const TrendFollowsSpan: Story = {
  render: october,
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const trend = await region(canvas, "Mes a mes");
    await waitFor(() =>
      expect(bodyRows(within(trend).getByRole("table")).map((r) => r[0])).toEqual([rowName(0)]),
    );
    await userEvent.click(canvas.getByRole("tab", { name: "3 meses" }));
    await waitFor(() =>
      expect(bodyRows(within(trend).getByRole("table")).map((r) => r[0])).toEqual([
        rowName(2),
        rowName(1),
        rowName(0),
      ]),
    );
  }),
};

/** Six months ("6 meses"), one row each in the table: income, expenses and the budget. */
export const Trend: Story = {
  render: october,
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await showSixMonths(canvas);
    const trend = await region(canvas, "Mes a mes");
    const table = await tableIn(trend, /^Ingresos, gastos y presupuesto/);
    const rows = bodyRows(table);
    await expect(rows).toHaveLength(6);
    await expect(rows[5]).toEqual([rowName(0), eur("6200,00"), eur("2237,08"), eur("2800,00")]);
    await expect(rows[0]?.[0]).toBe(rowName(5));
    // Bars for income and expenses in every month, and the budget line.
    await waitFor(
      () => {
        expect(trend.querySelectorAll(".lk-trend-income .recharts-rectangle")).toHaveLength(6);
        expect(trend.querySelectorAll(".lk-trend-expenses .recharts-rectangle")).toHaveLength(6);
        expect(trend.querySelector(".lk-trend-budget path")).not.toBeNull();
      },
      { timeout: 8000 },
    );
    // A scale in compact amounts: `0`, `2 mil`, `4 mil`…
    const ticks = [...trend.querySelectorAll(".lk-trend-y-tick")]
      .map((tick) => (tick.textContent ?? "").replace(/\s+/g, " "))
      .filter(Boolean);
    await expect(ticks.length).toBeGreaterThanOrEqual(3);
    await expect(ticks.some((tick) => /^\d+(,\d)? mil$/.test(tick))).toBe(true);
  }),
};

/**
 * The selected month's figures are written under the chart, the latest month first; the arrows
 * beside them step through the months from the keyboard (the band behind the bars follows).
 */
export const TrendFromKeyboard: Story = {
  render: october,
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await showSixMonths(canvas);
    const trend = await region(canvas, "Mes a mes");
    const readout = await within(trend).findByTestId("trend-readout", {}, { timeout: 4000 });
    await expect(readout).toHaveTextContent(rowName(0));
    await expect(readout).toHaveTextContent(`Ingresos ${eur("6200,00")}`);
    await expect(readout).toHaveTextContent(`Gastos ${eur("2237,08")}`);
    await expect(readout).toHaveTextContent(`Presupuesto ${eur("2800,00")}`);
    const next = within(trend).getByRole("button", { name: "Ver el mes siguiente en el gráfico" });
    const previous = within(trend).getByRole("button", {
      name: "Ver el mes anterior en el gráfico",
    });
    await expect(next).toBeDisabled();
    await expectTarget(previous);
    const band = within(trend).getByTestId("trend-selected");
    const before = band.style.left;

    previous.focus();
    await userEvent.keyboard("{Enter}");
    await expect(readout).toHaveTextContent(rowName(1));
    await expect(band.style.left).not.toBe(before);
    await expect(next).toBeEnabled();
    await userEvent.keyboard("{Enter}");
    await expect(readout).toHaveTextContent(rowName(2));
  }),
};

/**
 * Months without a budget leave a gap in the budget line (a dot per month that has one), and say
 * "Sin presupuesto" instead of 0: here the budgets start two months ago.
 */
export const TrendBudgetGaps: Story = {
  render: (args) => (
    <HomeStage onRequest={args.onRequest} data="october" budgetsSince={2} path="/app/insights" />
  ),
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await showSixMonths(canvas);
    const trend = await region(canvas, "Mes a mes");
    const rows = bodyRows(await tableIn(trend, /^Ingresos, gastos y presupuesto/));
    await expect(rows.map((r) => r[3])).toEqual([
      "Sin presupuesto",
      "Sin presupuesto",
      "Sin presupuesto",
      eur("2800,00"),
      eur("2800,00"),
      eur("2800,00"),
    ]);
    await waitFor(() => expect(trend.querySelectorAll(".lk-trend-budget-dot")).toHaveLength(3), {
      timeout: 8000,
    });
    await userEvent.click(
      within(trend).getByRole("button", { name: /mes anterior en el gráfico/ }),
    );
    await userEvent.click(
      within(trend).getByRole("button", { name: /mes anterior en el gráfico/ }),
    );
    await userEvent.click(
      within(trend).getByRole("button", { name: /mes anterior en el gráfico/ }),
    );
    await expect(within(trend).getByTestId("trend-readout")).toHaveTextContent(
      "Presupuesto Sin presupuesto",
    );
  }),
};

/**
 * While another answer loads, the figures on screen keep their own labels (never the new ones)
 * and dim, and the card says it is busy; Lukitas keeps his line until he has the new month's
 * figures. The toggles stay bright.
 */
export const StaleWhileLoading: Story = {
  render: (args) => (
    <HomeStage onRequest={args.onRequest} data="october" reportDelayMs={900} path="/app/insights" />
  ),
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const donut = await region(canvas, "Por categoría");
    await tableIn(donut, `Gastos por categoría en ${inSentence(0)}`);
    await settled(canvasElement);
    const figure = donut.querySelector("figure") as HTMLElement;

    await userEvent.click(within(donut).getByRole("tab", { name: "Ingresos" }));
    await expect(donut).toHaveAttribute("aria-busy", "true");
    // Still the spending, said as spending.
    await expect(within(donut).getByRole("table")).toHaveAccessibleName(
      `Gastos por categoría en ${inSentence(0)}`,
    );
    await expect(figure).toHaveTextContent("Gastado");
    await expect(within(donut).getByTestId("donut-total")).toHaveTextContent(eur("2237,08"));
    await waitFor(() =>
      expect(Number(getComputedStyle(figure.parentElement as HTMLElement).opacity)).toBeLessThan(
        0.9,
      ),
    );
    // The toggles are not dimmed.
    await expect(
      getComputedStyle(within(donut).getByRole("tablist", { name: "Qué mostrar" })).opacity,
    ).toBe("1");
    await tableIn(donut, `Ingresos por categoría en ${inSentence(0)}`);
    await waitFor(() => expect(donut).not.toHaveAttribute("aria-busy"));
    await expect(figure).toHaveTextContent("Recibido");

    // Lukitas: the old month's line stays whole until the earlier month's answer lands.
    const said = `Casa fue lo que más lukas se llevó en ${inSentence(0)}: ${eur("1329,78")}.`;
    const bubble = canvas.getByText(said);
    await userEvent.click(canvas.getByRole("button", { name: "Mes anterior" }));
    await expect(bubble).toHaveTextContent(said);
    await expect(bubble.closest("[aria-busy]")).toHaveAttribute("aria-busy", "true");
    await expect(
      await canvas.findByText(
        `Casa fue lo que más lukas se llevó en ${inSentence(1)}: ${eur("1329,78")}.`,
        {},
        { timeout: 4000 },
      ),
    ).toBeVisible();
  }),
};

// -- Cost of living -------------------------------------------------------------------------------

/**
 * "¿Cuánto me cuesta vivir?": the average of the last six complete months, 2237,08 € a month,
 * split into fixed (Casa and suscripciones, which have recurrences: 1366,67 €) and variable
 * (870,41 €), and per category.
 */
export const CostOfLiving: Story = {
  render: october,
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const living = await region(canvas, "¿Cuánto me cuesta vivir?");
    await waitFor(() => expect(living).toHaveTextContent(`${eur("2237,08")} al mes`), {
      timeout: 4000,
    });
    await expect(living).toHaveTextContent("tus últimos 6 meses completos");
    const split = within(living).getByTestId("living-split");
    await expect(split).toHaveTextContent(`Fijos${eur("1366,67")}`);
    await expect(split).toHaveTextContent(`Variables${eur("870,41")}`);
    const table = await tableIn(living, "Promedio mensual por categoría");
    const rows = bodyRows(table);
    await expect(rows[0]).toEqual(["Casa", "Fijo", eur("1329,78")]);
    await expect(rows).toContainEqual(["suscripciones", "Fijo", eur("36,89")]);
    await expect(rows).toContainEqual(["Ocio", "Variable", eur("262,80")]);
    const foot = table.querySelector("tfoot");
    await expect(foot).toHaveTextContent(`Fijos${eur("1366,67")}`);
    await expect(foot).toHaveTextContent(`Variables${eur("870,41")}`);
    await expect(foot).toHaveTextContent(`Total${eur("2237,08")}`);
  }),
};

// -- Empty ----------------------------------------------------------------------------------------

/**
 * No transactions yet: every section says so in words (no blank charts), and Lukitas says what
 * will show up here.
 */
export const Empty: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} data="empty" path="/app/insights" />,
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const donut = await region(canvas, "Por categoría");
    await expect(
      await within(donut).findByText(`No hay gastos en ${inSentence(0)}.`),
    ).toBeVisible();
    const trend = await region(canvas, "Mes a mes");
    await expect(
      await within(trend).findByText(`Aún no hay movimientos en ${inSentence(0)}.`),
    ).toBeVisible();
    const living = await region(canvas, "¿Cuánto me cuesta vivir?");
    await expect(
      await within(living).findByText(/^Necesito al menos un mes completo con gastos/),
    ).toBeVisible();
    await expect(
      canvas.getByText(
        `No veo gastos en ${inSentence(0)}. Cuando los anotes, aquí te muestro en qué se van tus lukas.`,
      ),
    ).toBeVisible();
    // Nothing drawn, and no tables of nothing.
    await expect(canvasElement.querySelector(".recharts-surface")).toBeNull();
    await expect(canvas.queryByRole("table")).toBeNull();
  }),
};

// -- Navigation, themes, sizes --------------------------------------------------------------------

/** Análisis is a real tab now: from home, the bottom bar opens it and marks it current. */
export const FromBottomBar: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} data="october" />,
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await canvas.findAllByRole("navigation", { name: "Navegación principal" }, { timeout: 4000 });
    const bar = within(canvasElement.querySelector(".lk-tabbar") as HTMLElement);
    await expect(bar.queryByText("Pronto")).toBeNull();
    await userEvent.click(bar.getByRole("link", { name: "Análisis" }));
    await expect(
      await canvas.findByRole("heading", { level: 1, name: "Análisis" }, { timeout: 4000 }),
    ).toBeVisible();
    await expect(bar.getByRole("link", { name: "Análisis" })).toHaveAttribute(
      "aria-current",
      "page",
    );
  }),
};

/** Day theme: the same page, with the a11y checks (contrast included) in the light colors. */
export const Day: Story = {
  render: october,
  globals: { theme: "day" },
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await sectorsIn(await region(canvas, "Por categoría"), 7);
    await region(canvas, "¿Cuánto me cuesta vivir?");
  }),
};

/**
 * Desktop: the sidebar's Análisis is a link (no "Pronto"); the donut takes the left column, the
 * trend and what living costs stack on the right.
 */
export const Desktop: Story = {
  render: october,
  globals: { viewport: { value: "desktop", isRotated: false } },
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const donut = await region(canvas, "Por categoría");
    const trend = await region(canvas, "Mes a mes");
    const living = await region(canvas, "¿Cuánto me cuesta vivir?");
    await sectorsIn(donut, 7);
    const [a, b, c] = [donut, trend, living].map((el) => el.getBoundingClientRect());
    await expect(Math.abs((a?.top ?? 0) - (b?.top ?? 0))).toBeLessThan(2);
    await expect(b?.left ?? 0).toBeGreaterThan(a?.right ?? 0);
    // What living costs sits under the trend, in the right column.
    await expect(c?.top ?? 0).toBeGreaterThan(b?.bottom ?? 0);
    await expect(Math.abs((c?.left ?? 0) - (b?.left ?? 0))).toBeLessThan(2);
    const sidebar = canvasElement.querySelector("nav.w-56") as HTMLElement;
    const link = within(sidebar).getByRole("link", { name: "Análisis" });
    await expect(link).toHaveAttribute("aria-current", "page");
    await expect(link).not.toHaveTextContent("Pronto");
  }),
};

/** English: the same figures in English formats. */
export const English: Story = {
  render: october,
  globals: { locale: "en" },
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const donut = await region(canvas, "By category");
    const table = await tableIn(donut, /^Spending by category in /);
    await expect(bodyRows(table)[0]).toEqual(["Casa", "59.4%", "€1,329.78"]);
    const trend = await region(canvas, "Month by month");
    await waitFor(
      () => {
        const ticks = [...trend.querySelectorAll(".lk-trend-y-tick")].map(
          (tick) => tick.textContent ?? "",
        );
        expect(ticks.some((tick) => /^\d+(\.\d)?k$/.test(tick))).toBe(true);
      },
      { timeout: 8000 },
    );
    await region(canvas, "How much does it cost me to live?");
  }),
};

/** Reduced motion: the charts are drawn at once, with no growing or rising. */
export const ReducedMotion: Story = {
  render: october,
  parameters: { reducedMotion: true },
  play: settledAfter(async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const donut = await region(canvas, "Por categoría");
    await sectorsIn(donut, 7);
    await expect(donut.querySelector("[data-animated]")?.getAttribute("data-animated")).toBe(
      "false",
    );
  }),
};
