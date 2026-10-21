import { monthOf, todayIn } from "@lukas/core";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, screen, userEvent, waitFor, within } from "storybook/test";
import { expectTarget } from "../../../.storybook/story-utils.ts";
import { BudgetsStep } from "./BudgetsStep.tsx";
import { CategoriesStep } from "./CategoriesStep.tsx";
import { CurrencyStep } from "./CurrencyStep.tsx";
import { ImportStep } from "./ImportStep.tsx";
import type { ImportState } from "./import-state.ts";
import { SAMPLE_PREVIEW, WelcomeStage } from "./story-harness.tsx";
import { SUGGESTED_CATEGORIES } from "./suggested-categories.ts";
import { WelcomeStep } from "./WelcomeStep.tsx";

/**
 * The onboarding (spec §2.4, revised: optional, short, skippable): each screen on its own (state
 * held by the story), and the whole `/welcome` flow against a fake API (`WelcomeStage`).
 */

/** Spies the stories hand to the steps (Storybook resets them before each story). */
interface Spies {
  onBack(): void;
  onSkip(): void;
  onNext(): void;
  onRequest(line: string): void;
}

const meta = {
  title: "Onboarding/Welcome",
  args: { onBack: fn(), onSkip: fn(), onNext: fn(), onRequest: fn() },
} satisfies Meta<Spies>;

export default meta;
type Story = StoryObj<Spies>;

type Canvas = ReturnType<typeof within>;

const calls = (spy: (line: string) => void) =>
  (spy as unknown as ReturnType<typeof fn>).mock.calls.map((call) => call[0] as string);

const suggested = (key: string) => {
  const found = SUGGESTED_CATEGORIES.find((c) => c.key === key);
  if (!found) throw new Error(key);
  return found;
};
const budgetCategory = (key: string) => {
  const c = suggested(key);
  return { id: key, name: c.names.es, glyph: c.glyph, tint: c.tint };
};

const heading = (canvas: Canvas, name: string) =>
  canvas.findByRole("heading", { level: 1, name }, { timeout: 3000 });

const upload = async (canvas: Canvas) =>
  userEvent.upload(
    await canvas.findByLabelText("Subir archivo de Budge"),
    new File(["Date,Payment\n"], "budge.csv", { type: "text/csv" }),
  );

// -- Welcome ---------------------------------------------------------------------------------------

/** Two ways in: set up in a minute, or straight in. No progress yet. */
export const Welcome: Story = {
  render: (args) => <WelcomeStep onSetup={args.onNext} onDirect={args.onSkip} />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const title = canvas.getByRole("heading", {
      level: 1,
      name: "Te damos la bienvenida a Lukitas",
    });
    await waitFor(() => expect(title).toHaveFocus());
    await expect(canvas.queryByText(/^Paso/)).toBeNull();
    const setup = canvas.getByRole("button", { name: "Configurar en 1 minuto" });
    const direct = canvas.getByRole("button", { name: "Entrar directo" });
    await expectTarget(setup);
    await expectTarget(direct);
    await userEvent.click(setup);
    await expect(args.onNext).toHaveBeenCalled();
    await userEvent.click(direct);
    await expect(args.onSkip).toHaveBeenCalled();
  },
};

// -- Currency --------------------------------------------------------------------------------------

function CurrencyHarness(props: Spies) {
  const [value, setValue] = useState<"COP" | "USD" | "EUR">("COP");
  return (
    <CurrencyStep
      value={value}
      onChange={setValue}
      onBack={props.onBack}
      onSkip={props.onSkip}
      onNext={props.onNext}
    />
  );
}

/** COP, USD and EUR, named in the person's language; Back, SALTAR and SIGUIENTE. */
export const Currency: Story = {
  render: (args) => <CurrencyHarness {...args} />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Paso 1 de 4")).toBeVisible();
    await expect(canvas.getAllByRole("radio")).toHaveLength(3);
    await expect(canvas.getByRole("radio", { name: /Peso colombiano.*COP/i })).toBeChecked();
    await userEvent.click(canvas.getByRole("radio", { name: /Euro.*EUR/i }));
    await expect(canvas.getByRole("radio", { name: /Euro.*EUR/i })).toBeChecked();
    for (const name of ["Atrás", "Saltar", "Siguiente"]) {
      await expectTarget(canvas.getByRole("button", { name }));
    }
    await userEvent.click(canvas.getByRole("button", { name: "Saltar" }));
    await expect(args.onSkip).toHaveBeenCalled();
    await userEvent.click(canvas.getByRole("button", { name: "Siguiente" }));
    await expect(args.onNext).toHaveBeenCalled();
    await userEvent.click(canvas.getByRole("button", { name: "Atrás" }));
    await expect(args.onBack).toHaveBeenCalled();
  },
};

// -- Categories ------------------------------------------------------------------------------------

function CategoriesHarness({ onNext }: { onNext(): void }) {
  const [selected, setSelected] = useState(() => new Set(SUGGESTED_CATEGORIES.map((c) => c.key)));
  return (
    <CategoriesStep
      selected={selected}
      onToggle={(key) =>
        setSelected((current) => {
          const next = new Set(current);
          if (next.has(key)) next.delete(key);
          else next.add(key);
          return next;
        })
      }
      custom={[{ id: "own-1", name: "Mascotas", glyph: "🐶", kind: "expense" }]}
      onCreate={async () => {}}
      errorText={() => ""}
      onBack={() => {}}
      onSkip={() => {}}
      onNext={onNext}
    />
  );
}

/** The suggestions come pre-selected; tapping one deselects it; nothing is required to go on. */
export const CategoriesPreselected: Story = {
  render: (args) => <CategoriesHarness onNext={args.onNext} />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Paso 2 de 4")).toBeVisible();
    for (const c of SUGGESTED_CATEGORIES) {
      await expect(canvas.getByRole("button", { name: c.names.es })).toHaveAttribute(
        "aria-pressed",
        "true",
      );
    }
    await expect(canvas.getByRole("button", { name: "Mascotas" })).toHaveAttribute(
      "aria-pressed",
      "false",
    );
    const groceries = canvas.getByRole("button", { name: "Supermercado" });
    await expectTarget(groceries);
    await userEvent.click(groceries);
    await expect(groceries).toHaveAttribute("aria-pressed", "false");
    // Every spending category off: SIGUIENTE still works (no step forces input).
    for (const c of SUGGESTED_CATEGORIES.filter((s) => s.kind === "expense")) {
      const chip = canvas.getByRole("button", { name: c.names.es });
      if (chip.getAttribute("aria-pressed") === "true") await userEvent.click(chip);
    }
    await userEvent.click(canvas.getByRole("button", { name: "Siguiente" }));
    await expect(args.onNext).toHaveBeenCalled();
    await expect(canvas.getByRole("button", { name: "Agregar categoría" })).toBeVisible();
  },
};

/** English and day theme: spending and income apart. */
export const CategoriesInEnglish: Story = {
  globals: { locale: "en", theme: "day" },
  render: (args) => <CategoriesHarness onNext={args.onNext} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(
      canvas.getByRole("heading", { level: 1, name: "Where does your money go?" }),
    ).toBeVisible();
    const spending = canvas.getByRole("group", { name: "Spending" });
    await expect(within(spending).getAllByRole("button")).toHaveLength(8);
    const income = canvas.getByRole("group", { name: "Income" });
    await expect(within(income).getByRole("button", { name: "Salary" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
    await expect(canvas.getByRole("button", { name: "Next" })).toBeEnabled();
    await expect(canvas.getByRole("button", { name: "Skip" })).toBeEnabled();
  },
};

// -- Import ----------------------------------------------------------------------------------------

function ImportHarness({
  state: initial,
  currency = "EUR",
  prefillBasis,
}: {
  state: ImportState;
  currency?: string;
  prefillBasis?: string;
}) {
  const [state, setState] = useState(initial);
  return (
    <ImportStep
      state={state}
      currency={currency}
      onSource={(source) => setState({ phase: source ? "idle" : "sources" })}
      onFile={() => {}}
      onConfirm={() => {}}
      onDiscard={() => {}}
      prefillBasis={prefillBasis ?? null}
      onBack={() => {}}
      onSkip={() => {}}
      onNext={() => {}}
    />
  );
}

/** "¿Traes tu historial?": Budge opens; Excel/CSV, Buddy and other apps are "Pronto". */
export const ImportSources: Story = {
  render: () => <ImportHarness state={{ phase: "sources" }} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Paso 3 de 4")).toBeVisible();
    await expect(
      canvas.getByRole("heading", { level: 1, name: "¿Traes tu historial?" }),
    ).toBeVisible();
    const list = canvas.getByRole("region", { name: "Desde dónde" });
    for (const name of ["Excel, Google Sheets o CSV", "Buddy", "Otras apps"]) {
      const row = within(list).getByText(name).closest("li") as HTMLElement;
      await expect(row).toHaveTextContent("Pronto");
      await expect(within(row).queryByRole("button")).toBeNull();
    }
    await expect(canvas.getByRole("button", { name: "Siguiente" })).toBeEnabled();
    await expect(canvas.getByRole("button", { name: "Saltar" })).toBeEnabled();
    const budge = within(list).getByRole("button", { name: "Budge" });
    await expectTarget(budge);
    await userEvent.click(budge);
    // The how-to takes focus, with the steps and the picker.
    const howTo = canvas.getByRole("heading", { name: "Exporta tus movimientos de Budge" });
    await waitFor(() => expect(howTo).toHaveFocus());
    await expect(canvas.getAllByRole("listitem")).toHaveLength(3);
    await expect(canvas.getByText(/abre Ajustes y busca la opción para exportar/)).toBeVisible();
    const input = canvas.getByLabelText("Subir archivo de Budge");
    await expect(input).toHaveAttribute("type", "file");
    await expect(input).toHaveAttribute("accept", ".csv,text/csv");
    await userEvent.click(canvas.getByRole("button", { name: "Elegir otra fuente" }));
    await waitFor(() => expect(canvas.getByRole("heading", { name: "Desde dónde" })).toHaveFocus());
  },
};

/** The preview: transactions, duplicates, rejected rows (with their lines), new categories. */
export const ImportPreview: Story = {
  render: () => (
    <ImportHarness
      state={{
        phase: "preview",
        fileName: "budge.csv",
        preview: SAMPLE_PREVIEW,
        currencyNote: null,
        confirming: false,
      }}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const region = canvas.getByRole("region", { name: "Esto es lo que vamos a importar" });
    const stats = within(region);
    const value = (term: string) =>
      stats.getByText(term, { selector: "dt" }).nextElementSibling?.textContent;
    await expect(value("Movimientos")).toBe("22");
    await expect(value("Repetidos (ya los tienes)")).toBe("3");
    await expect(value("Filas con problemas")).toBe("1");
    await expect(stats.getByText("Archivo: budge.csv")).toBeVisible();
    await expect(stats.getByText("Del 1 sept 2026 al 30 oct 2026")).toBeVisible();
    await expect(stats.getByText(/Investimento/)).toBeVisible();
    await userEvent.click(stats.getByText("Ver las filas con problemas"));
    await expect(stats.getByText("Línea 19: fecha no válida")).toBeVisible();
    // 22 rows, 3 of them already there: 19 to import. SALTAR stays.
    await expect(canvas.getByRole("button", { name: "Importar 19 movimientos" })).toBeEnabled();
    await expect(canvas.getByRole("button", { name: "Saltar" })).toBeEnabled();
    await expect(canvas.getByRole("button", { name: "Usar otro archivo" })).toBeVisible();
  },
};

/** A file with many bad rows: the list shows 20 and says how many more. */
export const ImportManyRejected: Story = {
  render: () => (
    <ImportHarness
      state={{
        phase: "preview",
        fileName: "budge.csv",
        preview: {
          ...SAMPLE_PREVIEW,
          stats: {
            ...SAMPLE_PREVIEW.stats,
            rejected: Array.from({ length: 45 }, (_, i) => ({
              line: 7 + i,
              reason: "currency_mismatch",
            })),
          },
        },
        currencyNote: null,
        confirming: false,
      }}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByText("Ver las filas con problemas"));
    const list = canvas.getByRole("list", { name: "Filas con problemas" });
    await expect(within(list).getAllByRole("listitem")).toHaveLength(20);
    await expect(canvas.getByText("y 25 más")).toBeVisible();
  },
};

/** The file's currency won: one line says the account switched to it. */
export const ImportSwitchedCurrency: Story = {
  render: () => (
    <ImportHarness
      state={{
        phase: "preview",
        fileName: "budge.csv",
        preview: SAMPLE_PREVIEW,
        currencyNote: { kind: "switched", file: "EUR", account: "COP" },
        confirming: false,
      }}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(
      canvas.getByText("Tu archivo está en EUR, así que tu cuenta ahora usa EUR."),
    ).toBeVisible();
  },
};

/** Imported, with budgets prefilled from the recent months. */
export const Imported: Story = {
  render: () => (
    <ImportHarness
      prefillBasis="Basado en lo que gastaste en tus últimos 3 meses"
      state={{
        phase: "imported",
        result: {
          ...SAMPLE_PREVIEW,
          status: "confirmed",
          stats: { ...SAMPLE_PREVIEW.stats, inserted: 19 },
        },
        prefilled: true,
        currencyNote: null,
      }}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading", { name: "Importamos 19 movimientos." })).toBeVisible();
    await expect(
      canvas.getByText("Llenamos tus presupuestos con lo que gastas en promedio cada mes."),
    ).toBeVisible();
    await expect(
      canvas.getByText("Basado en lo que gastaste en tus últimos 3 meses"),
    ).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Siguiente" })).toBeEnabled();
    // Done importing: nothing left to skip.
    await expect(canvas.queryByRole("button", { name: "Saltar" })).toBeNull();
  },
};

// -- Budgets (last) --------------------------------------------------------------------------------

function BudgetsHarness({ currency, empty = false }: { currency: string; empty?: boolean }) {
  const categories = empty ? [] : ["groceries", "eating_out", "home"].map(budgetCategory);
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  return (
    <BudgetsStep
      categories={categories}
      drafts={drafts}
      onChange={(id, text) => setDrafts((current) => ({ ...current, [id]: text }))}
      currency={currency}
      onBack={() => {}}
      onSkip={() => {}}
      onNext={() => {}}
    />
  );
}

/** One field per chosen spending category; the total is "what you can spend per month". */
export const BudgetsRunningTotal: Story = {
  render: () => <BudgetsHarness currency="EUR" />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Paso 4 de 4")).toBeVisible();
    const total = canvas.getByRole("status");
    await expect(total).toHaveTextContent("Lo que puedes gastar al mes");
    await expect(total).toHaveTextContent("0,00 €");
    await userEvent.type(
      canvas.getByRole("textbox", { name: "Presupuesto de Supermercado" }),
      "300",
    );
    await expect(total).toHaveTextContent("300,00 €");
    await userEvent.type(
      canvas.getByRole("textbox", { name: "Presupuesto de Restaurante" }),
      "120,50",
    );
    await expect(total).toHaveTextContent("420,50 €");
    await userEvent.type(canvas.getByRole("textbox", { name: "Presupuesto de Casa" }), "600");
    await expect(total).toHaveTextContent("1020,50 €");

    // Not a number: the field says so, the total ignores it, SIGUIENTE waits, SALTAR doesn't.
    const home = canvas.getByRole("textbox", { name: "Presupuesto de Casa" });
    await userEvent.type(home, "x");
    await expect(home).toHaveAttribute("aria-invalid", "true");
    await expect(canvas.getByText("Escribe solo el número, como 300.")).toBeVisible();
    await expect(total).toHaveTextContent("420,50 €");
    await expect(canvas.getByRole("button", { name: "Siguiente" })).toBeDisabled();
    await expect(canvas.getByRole("button", { name: "Saltar" })).toBeEnabled();
    await expect(canvas.queryByText(/lukas/)).toBeNull();
  },
};

/** COP (day theme): each amount and the total carry the small lukas hint. */
export const BudgetsInPesos: Story = {
  globals: { theme: "day" },
  render: () => <BudgetsHarness currency="COP" />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const groceries = canvas.getByRole("textbox", { name: "Presupuesto de Supermercado" });
    await userEvent.type(groceries, "300.000");
    const [row] = canvas.getAllByRole("listitem");
    const amount = within(row as HTMLElement).getByText("$300.000", {
      selector: "[data-budget-amount]",
    });
    await expect(amount.parentElement).toHaveTextContent("$300.000 (300 lukas)");
    const hint = within(amount.parentElement as HTMLElement).getByText("(300 lukas)");
    await expect(hint.className).toMatch(/text-ink-muted/);
    await expect(groceries).toHaveAttribute("aria-describedby", amount.closest("p")?.id);
    await userEvent.type(canvas.getByRole("textbox", { name: "Presupuesto de Casa" }), "4300000");
    await expect(canvas.getByRole("status")).toHaveTextContent("$4.600.000 (4,6 palos)");
  },
};

/** No spending categories (all deselected): a line instead of an empty list. */
export const BudgetsWithoutCategories: Story = {
  render: () => <BudgetsHarness currency="EUR" empty />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/No tienes categorías de gasto/)).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Siguiente" })).toBeEnabled();
  },
};

// -- The whole flow, against a fake API --------------------------------------------------------------

/**
 * ENTRAR DIRECTO on a brand-new account: the browser's time zone, the region's currency (es-CO →
 * COP), the eight suggested categories, no budgets, the onboarding flag, then /app.
 */
export const FlowEnterDirectly: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome"
      currency="EUR"
      categories="none"
      timezone="UTC"
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Entrar directo" }));
    await expect(await canvas.findByText("App (stand-in)", {}, { timeout: 3000 })).toBeVisible();
    const lines = calls(args.onRequest);
    await expect(lines[0]).toBe('PATCH /api/v1/me {"timezone":"America/Bogota"}');
    await expect(lines).toContain('PATCH /api/v1/me {"currency":"COP"}');
    const created = lines.filter((l) => l.startsWith("POST /api/v1/categories "));
    await expect(created).toHaveLength(8);
    await expect(created[0]).toContain('"name":"Supermercado"');
    await expect(lines.some((l) => l.includes("/budget"))).toBe(false);
    await expect(lines.at(-1)).toBe('PATCH /api/v1/me {"onboardingCompleted":true}');
  },
};

/** CONFIGURAR, then SALTAR on every step: still a usable account, and /app. */
export const FlowSkipEveryStep: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome"
      currency="EUR"
      categories="none"
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Configurar en 1 minuto" }));
    for (const title of [
      "¿En qué moneda llevas tus cuentas?",
      "¿En qué se te va el dinero?",
      "¿Traes tu historial?",
      "¿Cuánto quieres gastar al mes?",
    ]) {
      const h1 = await heading(canvas, title);
      await waitFor(() => expect(h1).toHaveFocus());
      await userEvent.click(canvas.getByRole("button", { name: "Saltar" }));
    }
    await expect(await canvas.findByText("App (stand-in)", {}, { timeout: 3000 })).toBeVisible();
    const lines = calls(args.onRequest);
    await expect(lines).toContain('PATCH /api/v1/me {"currency":"COP"}');
    await expect(lines.filter((l) => l.startsWith("POST /api/v1/categories "))).toHaveLength(8);
    await expect(lines.some((l) => l.includes("/budget"))).toBe(false);
    await expect(lines.at(-1)).toBe('PATCH /api/v1/me {"onboardingCompleted":true}');
  },
};

/** "＋ Agregar categoría": name, kind, emoji and tint; saved right away and chosen. */
export const FlowAddCustomCategory: Story = {
  render: (args) => (
    <WelcomeStage initialEntry="/welcome/categories" currency="EUR" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Agregar categoría" }));
    const sheet = within(await screen.findByRole("dialog", { name: "Nueva categoría" }));
    // A name is needed.
    await userEvent.click(sheet.getByRole("button", { name: "Guardar categoría" }));
    await expect(sheet.getByRole("alert")).toHaveTextContent(
      "Escribe un nombre para la categoría.",
    );
    await userEvent.type(sheet.getByRole("textbox", { name: "Nombre" }), "Mascotas");
    await expect(sheet.getByRole("radio", { name: "Gasto" })).toBeChecked();
    await userEvent.click(sheet.getByRole("radio", { name: "🐶" }));
    await userEvent.click(sheet.getByRole("radio", { name: "Verde" }));
    await userEvent.click(sheet.getByRole("button", { name: "Guardar categoría" }));
    // The sheet slides out (`--sheet`) once the save is through; a loaded machine needs headroom.
    await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull(), { timeout: 4000 });
    await expect(args.onRequest).toHaveBeenCalledWith(
      'POST /api/v1/categories {"name":"Mascotas","kind":"expense","icon":"🐶","color":"#2fd388"}',
    );
    const spending = canvas.getByRole("group", { name: "Gastos" });
    await expect(await within(spending).findByRole("button", { name: "Mascotas" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
  },
};

/**
 * A COP account uploads a EUR file: the account (still empty) switches to EUR, the stale preview
 * is dropped and the file is read again; the confirmed preview is in EUR, and the budgets that
 * follow are prefilled from the recent months, in euros.
 */
export const FlowImportSwitchesCurrency: Story = {
  render: (args) => (
    <WelcomeStage initialEntry="/welcome/import" currency="COP" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement, args }) => {
    const { onRequest } = args;
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
    await upload(canvas);
    await expect(
      await canvas.findByText("Tu archivo está en EUR, así que tu cuenta ahora usa EUR."),
    ).toBeVisible();
    // The result takes focus, so a screen reader reads it out.
    await waitFor(() =>
      expect(
        canvas.getByRole("heading", { name: "Esto es lo que vamos a importar" }),
      ).toHaveFocus(),
    );
    await expect(calls(onRequest)).toEqual([
      "POST /api/v1/imports",
      'PATCH /api/v1/me {"currency":"EUR"}',
      "DELETE /api/v1/imports/preview-1",
      "POST /api/v1/imports",
    ]);
    await userEvent.click(canvas.getByRole("button", { name: "Importar 22 movimientos" }));
    const imported = await canvas.findByRole("heading", { name: "Importamos 22 movimientos." });
    await waitFor(() => expect(imported).toHaveFocus());
    await expect(onRequest).toHaveBeenCalledWith("POST /api/v1/imports/preview-2/confirm");
    await expect(onRequest).not.toHaveBeenCalledWith("POST /api/v1/imports/preview-1/confirm");
    await userEvent.click(canvas.getByRole("button", { name: "Siguiente" }));
    await expect(
      await canvas.findByRole("textbox", { name: "Presupuesto de Supermercado" }),
    ).toHaveValue("35,89");
    await expect(
      canvas.getByText("Basado en lo que gastaste en tus últimos 3 meses"),
    ).toBeVisible();
  },
};

/** "Usar otro archivo" after a switch drops the preview and puts the account's currency back. */
export const FlowDiscardRestoresCurrency: Story = {
  render: (args) => (
    <WelcomeStage initialEntry="/welcome/import" currency="COP" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement, args }) => {
    const { onRequest } = args;
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
    await upload(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Usar otro archivo" }));
    await waitFor(() =>
      expect(onRequest).toHaveBeenCalledWith('PATCH /api/v1/me {"currency":"COP"}'),
    );
    await expect(onRequest).toHaveBeenCalledWith("DELETE /api/v1/imports/preview-2");
    // Back to the picker, with focus on it.
    const picker = await canvas.findByLabelText("Subir archivo de Budge");
    await waitFor(() => expect(picker).toHaveFocus());
  },
};

/** SALTAR with a preview open drops it (and its currency switch) and moves on. */
export const FlowSkipImportWithPreview: Story = {
  render: (args) => (
    <WelcomeStage initialEntry="/welcome/import" currency="COP" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
    await upload(canvas);
    await canvas.findByRole("button", { name: "Importar 22 movimientos" });
    await userEvent.click(canvas.getByRole("button", { name: "Saltar" }));
    await heading(canvas, "¿Cuánto quieres gastar al mes?");
    await expect(args.onRequest).toHaveBeenCalledWith("DELETE /api/v1/imports/preview-2");
    await expect(args.onRequest).toHaveBeenCalledWith('PATCH /api/v1/me {"currency":"COP"}');
    await expect(args.onRequest).not.toHaveBeenCalledWith("POST /api/v1/imports/preview-2/confirm");
  },
};

/**
 * The import went in, but reading the categories again failed: the step still says it was
 * imported (pressing Importar again could only fail), shows the problem and offers a retry.
 */
export const FlowRefreshFailsAfterConfirm: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome/import"
      currency="EUR"
      onRequest={args.onRequest}
      failRefreshesAfterConfirm={3}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
    await upload(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Importar 22 movimientos" }));
    await expect(
      await canvas.findByRole("heading", { name: "Importamos 22 movimientos." }),
    ).toBeVisible();
    const alert = await canvas.findByRole("alert", {}, { timeout: 8000 });
    await expect(alert).toHaveTextContent("Tuvimos un problema de nuestro lado");
    await expect(canvas.queryByRole("button", { name: /^Importar/ })).toBeNull();
    await userEvent.click(canvas.getByRole("button", { name: "Reintentar" }));
    await waitFor(() => expect(canvas.queryByRole("alert")).toBeNull());
    await expect(
      canvas.getByText("Llenamos tus presupuestos con lo que gastas en promedio cada mes."),
    ).toBeVisible();
  },
};

/** An old export: the budgets say the amounts come from its last months with activity. */
export const FlowOldExport: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome/import"
      currency="EUR"
      oldExport
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
    await upload(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Importar 22 movimientos" }));
    await expect(
      await canvas.findByText("Basado en tus últimos 3 meses con movimientos"),
    ).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Siguiente" }));
    await heading(canvas, "¿Cuánto quieres gastar al mes?");
    await expect(canvas.getByText("Basado en tus últimos 3 meses con movimientos")).toBeVisible();
  },
};

/** SIGUIENTE on the budgets saves them and the onboarding flag, then goes to /app. */
export const FlowFinish: Story = {
  render: (args) => (
    <WelcomeStage initialEntry="/welcome/budgets" currency="EUR" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement, args }) => {
    const { onRequest } = args;
    const canvas = within(canvasElement);
    // A reload keeps the step: arriving straight at /welcome/budgets shows the budgets.
    await heading(canvas, "¿Cuánto quieres gastar al mes?");
    await userEvent.type(
      await canvas.findByRole("textbox", { name: "Presupuesto de Supermercado" }),
      "300",
    );
    await userEvent.click(canvas.getByRole("button", { name: "Siguiente" }));
    await expect(await canvas.findByText("App (stand-in)")).toBeVisible();
    const month = monthOf(todayIn("America/Bogota"));
    await expect(calls(onRequest)).toContain(
      `PUT /api/v1/categories/cat-groceries/budget {"amount":30000,"effectiveFrom":"${month}"}`,
    );
    await expect(calls(onRequest).at(-1)).toBe('PATCH /api/v1/me {"onboardingCompleted":true}');
  },
};
