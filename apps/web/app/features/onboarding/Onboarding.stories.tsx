import { monthOf, todayIn } from "@lukas/core";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, screen, userEvent, waitFor, within } from "storybook/test";
import { expectTarget } from "../../../.storybook/story-utils.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { BudgetsStep } from "./BudgetsStep.tsx";
import { CategoriesStep } from "./CategoriesStep.tsx";
import { CurrencyStep } from "./CurrencyStep.tsx";
import { categoryChips } from "./category-chips.ts";
import { ImportStep } from "./ImportStep.tsx";
import type { ImportState } from "./import-state.ts";
import { ImportPageStage, SAMPLE_PREVIEW, WelcomeStage } from "./story-harness.tsx";
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

const heading = (canvas: Canvas, name: string) => canvas.findByRole("heading", { level: 1, name });

const upload = async (canvas: Canvas) =>
  userEvent.upload(
    await canvas.findByLabelText("Subir archivo de Budge"),
    new File(["Date,Payment\n"], "budge.csv", { type: "text/csv" }),
  );

// -- Welcome ---------------------------------------------------------------------------------------

/** Two ways in: set up in a minute, or straight in. No progress yet. */
export const Welcome: Story = {
  render: (args) => <WelcomeStep currency="COP" onSetup={args.onNext} onDirect={args.onSkip} />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const title = canvas.getByRole("heading", {
      level: 1,
      name: "Te damos la bienvenida a Lukitas",
    });
    await waitFor(() => expect(title).toHaveFocus());
    await expect(canvas.queryByText(/^Paso/)).toBeNull();
    // It names the currency going straight in sets, and tells the truth about changing it.
    await expect(
      canvas.getByText(
        "Si entras directo, tu moneda será COP y usamos las categorías sugeridas. Puedes cambiarla en Ajustes antes de tu primer movimiento.",
      ),
    ).toBeVisible();
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
  const { locale } = useLocale();
  const chips = [
    {
      id: "own-1",
      source: "category" as const,
      name: "Mascotas",
      glyph: "🐶",
      tint: "#2fd388",
      kind: "expense" as const,
    },
    ...categoryChips([], locale),
  ];
  const [selected, setSelected] = useState(
    () => new Set(chips.filter((c) => c.source === "suggestion").map((c) => c.id)),
  );
  return (
    <CategoriesStep
      chips={chips}
      selected={selected}
      onToggle={(key) =>
        setSelected((current) => {
          const next = new Set(current);
          if (next.has(key)) next.delete(key);
          else next.add(key);
          return next;
        })
      }
      onCreate={async () => {}}
      onEdit={async () => {}}
      onRemove={async () => {}}
      transactionsOf={async () => ({ count: 0, capped: false })}
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
    await expect(canvas.getByText("Paso 3 de 4")).toBeVisible();
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
    // Their own category first, then the suggestions.
    await expect(within(spending).getAllByRole("button")[0]).toHaveAccessibleName("Mascotas");
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
  onSkip = () => {},
}: {
  state: ImportState;
  currency?: string;
  prefillBasis?: string;
  onSkip?: () => void;
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
      onSkip={onSkip}
      onNext={() => {}}
    />
  );
}

/**
 * "¿Vienes de otra app?" (step 2, before the categories): Budge opens; Excel/CSV, Buddy and other
 * apps are "Pronto"; "No, empiezo de cero" moves on.
 */
export const ImportSources: Story = {
  render: (args) => <ImportHarness state={{ phase: "sources" }} onSkip={args.onSkip} />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Paso 2 de 4")).toBeVisible();
    await expect(
      canvas.getByRole("heading", { level: 1, name: "¿Vienes de otra app?" }),
    ).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "No, empiezo de cero" }));
    await expect(args.onSkip).toHaveBeenCalled();
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
    // Neutral until the founder confirms Budge's menu path: no menu is named.
    await expect(canvas.getByText(/busca la opción para exportar tus movimientos/)).toBeVisible();
    await expect(canvas.queryByText(/Ajustes/)).toBeNull();
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

    // Like the keypad, the field takes only an amount: a letter is not typed at all.
    const home = canvas.getByRole("textbox", { name: "Presupuesto de Casa" });
    await userEvent.type(home, "x");
    await expect(home).toHaveValue("600");
    await expect(home).not.toHaveAttribute("aria-invalid");
    await expect(total).toHaveTextContent("1020,50 €");
    // Thousands are grouped as they are typed, the decimals kept.
    await userEvent.clear(home);
    await userEvent.type(home, "12500,5");
    await expect(home).toHaveValue("12.500,5");
    await expect(total).toHaveTextContent("12.921,00 €");
    await expect(canvas.getByRole("button", { name: "Siguiente" })).toBeEnabled();
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
    // Typed as digits, grouped as typed: "300000" reads "300.000", with "(300 lukas)" beside it.
    await userEvent.type(groceries, "300000");
    await expect(groceries).toHaveValue("300.000");
    const besideField = within(groceries.parentElement as HTMLElement).getByText("(300 lukas)");
    await expect(besideField.className).toMatch(/text-ink-muted/);
    const [row] = canvas.getAllByRole("listitem");
    const amount = within(row as HTMLElement).getByText("$300.000", {
      selector: "[data-budget-amount]",
    });
    // Under the field the amount is read with its hint, which shows only once (beside the field).
    await expect(amount.parentElement).toHaveTextContent("$300.000 (300 lukas)");
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
    await expect(await canvas.findByText("App (stand-in)")).toBeVisible();
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
      "¿Vienes de otra app?",
      "¿En qué se te va el dinero?",
      "¿Cuánto quieres gastar al mes?",
    ]) {
      const h1 = await heading(canvas, title);
      await waitFor(() => expect(h1).toHaveFocus());
      await userEvent.click(canvas.getByRole("button", { name: "Saltar" }));
    }
    await expect(await canvas.findByText("App (stand-in)")).toBeVisible();
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
    await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull());
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
 * A COP account uploads a EUR file: the preview says the (still empty) account will switch to
 * EUR on import; nothing changes until the confirm, which asks the API to adopt the file's currency
 * in the same transaction. The budgets that follow are prefilled from the recent months, in euros.
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
      await canvas.findByText(
        "Tu archivo está en EUR: al importarlo, tu cuenta pasará a usar EUR.",
      ),
    ).toBeVisible();
    // The result takes focus, so a screen reader reads it out.
    await waitFor(() =>
      expect(
        canvas.getByRole("heading", { name: "Esto es lo que vamos a importar" }),
      ).toHaveFocus(),
    );
    // Reading the file changed nothing.
    await expect(calls(onRequest)).toEqual(["POST /api/v1/imports"]);
    await userEvent.click(canvas.getByRole("button", { name: "Importar 22 movimientos" }));
    const imported = await canvas.findByRole("heading", { name: "Importamos 22 movimientos." });
    await waitFor(() => expect(imported).toHaveFocus());
    await expect(calls(onRequest)).toEqual([
      "POST /api/v1/imports",
      'POST /api/v1/imports/preview-1/confirm {"adoptFileCurrency":true}',
    ]);
    await expect(
      canvas.getByText("Tu archivo está en EUR, así que tu cuenta ahora usa EUR."),
    ).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Siguiente" }));
    await heading(canvas, "¿En qué se te va el dinero?");
    await userEvent.click(canvas.getByRole("button", { name: "Siguiente" }));
    await expect(
      await canvas.findByRole("textbox", { name: "Presupuesto de Supermercado" }),
    ).toHaveValue("35,89");
    await expect(
      canvas.getByText("Basado en lo que gastaste en tus últimos 3 meses"),
    ).toBeVisible();
  },
};

/** "Usar otro archivo" drops the preview; the currency was never touched, so nothing to undo. */
export const FlowDiscardChangesNothing: Story = {
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
      expect(calls(onRequest)).toEqual([
        "POST /api/v1/imports",
        "DELETE /api/v1/imports/preview-1",
      ]),
    );
    // Back to the picker, with focus on it.
    const picker = await canvas.findByLabelText("Subir archivo de Budge");
    await waitFor(() => expect(picker).toHaveFocus());
  },
};

/** SALTAR with a preview open drops it and moves on; the currency stays as it was. */
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
    await heading(canvas, "¿En qué se te va el dinero?");
    await expect(calls(args.onRequest)).toEqual([
      "POST /api/v1/imports",
      "DELETE /api/v1/imports/preview-1",
    ]);
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
    await heading(canvas, "¿En qué se te va el dinero?");
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

// -- Fix round 1: safe skip, retries, session draft ---------------------------------------------------

/** While a confirm runs, SALTAR and Back wait: nobody leaves or reverts an import halfway. */
export const FlowSkipLockedWhileConfirming: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome/import"
      currency="EUR"
      confirmDelayMs={1500}
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
    await upload(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Importar 22 movimientos" }));
    await canvas.findByRole("button", { name: "Importando…" });
    await expect(canvas.getByRole("button", { name: "Saltar" })).toBeDisabled();
    await expect(canvas.getByRole("button", { name: "Atrás" })).toBeDisabled();
    await expect(
      await canvas.findByRole("heading", { name: "Importamos 22 movimientos." }),
    ).toBeVisible();
    await expect(calls(args.onRequest).some((l) => l.startsWith("DELETE"))).toBe(false);
  },
};

const enterDirectlyStage = (
  args: Spies,
  options: Partial<Parameters<typeof WelcomeStage>[0]> = {},
) => (
  <WelcomeStage
    initialEntry="/welcome"
    currency="EUR"
    categories="none"
    onRequest={args.onRequest}
    {...options}
  />
);
const categoryPosts = (spy: (line: string) => void) =>
  calls(spy).filter((l) => l.startsWith("POST /api/v1/categories "));

/** One category fails to save: the error shows, and tapping again creates only the missing one. */
export const FlowEnterDirectlyRetries: Story = {
  render: (args) => enterDirectlyStage(args, { failCategoryPost: { nth: 3, created: false } }),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const direct = await canvas.findByRole("button", { name: "Entrar directo" });
    await userEvent.click(direct);
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "Tuvimos un problema de nuestro lado",
    );
    await expect(categoryPosts(args.onRequest)).toHaveLength(8);
    await userEvent.click(direct);
    await expect(await canvas.findByText("App (stand-in)")).toBeVisible();
    await expect(categoryPosts(args.onRequest)).toHaveLength(9);
  },
};

/** The answer to one save was lost although it was made: the retry re-reads and creates nothing. */
export const FlowEnterDirectlyAfterLostAnswer: Story = {
  render: (args) => enterDirectlyStage(args, { failCategoryPost: { nth: 3, created: true } }),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const direct = await canvas.findByRole("button", { name: "Entrar directo" });
    await userEvent.click(direct);
    await canvas.findByRole("alert");
    await userEvent.click(direct);
    await expect(await canvas.findByText("App (stand-in)")).toBeVisible();
    await expect(categoryPosts(args.onRequest)).toHaveLength(8);
  },
};

/** A 409 "name taken" for a suggestion means it is already there: not a failure. */
export const FlowEnterDirectlyNameTaken: Story = {
  render: (args) => enterDirectlyStage(args, { takenNames: ["Ocio"] }),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Entrar directo" }));
    await expect(await canvas.findByText("App (stand-in)")).toBeVisible();
  },
};

/**
 * After adding their own category, the chips survive a reload (session draft), and SALTAR keeps
 * the pre-selected suggestions as well as theirs: it creates the suggestions and archives nothing.
 */
export const FlowSkipCategoriesAfterCustom: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome/categories"
      currency="EUR"
      categories="none"
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Agregar categoría" }));
    const sheet = within(await screen.findByRole("dialog", { name: "Nueva categoría" }));
    await userEvent.type(sheet.getByRole("textbox", { name: "Nombre" }), "Mascotas");
    await userEvent.click(sheet.getByRole("button", { name: "Guardar categoría" }));
    await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull());
    await within(canvas.getByRole("group", { name: "Gastos" })).findByRole("button", {
      name: "Mascotas",
    });

    await userEvent.click(canvas.getByRole("button", { name: "Recargar (stand-in)" }));
    await heading(canvas, "¿En qué se te va el dinero?");
    for (const name of [...SUGGESTED_CATEGORIES.map((c) => c.names.es), "Mascotas"]) {
      await expect(await canvas.findByRole("button", { name })).toHaveAttribute(
        "aria-pressed",
        "true",
      );
    }

    await userEvent.click(canvas.getByRole("button", { name: "Saltar" }));
    await heading(canvas, "¿Cuánto quieres gastar al mes?");
    // Mascotas, then the eight suggestions; nothing archived.
    await expect(categoryPosts(args.onRequest)).toHaveLength(9);
    await expect(calls(args.onRequest).some((l) => l.includes('"archived":true'))).toBe(false);
  },
};

/** A deep link to the budgets before any category exists goes to the categories first. */
export const FlowBudgetsDeepLinkWithoutCategories: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome/budgets"
      currency="EUR"
      categories="none"
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await heading(canvas, "¿En qué se te va el dinero?")).toBeVisible();
  },
};

/** A currency they picked stays picked after a reload (the region's no longer overrides it). */
export const FlowChosenCurrencySurvivesReload: Story = {
  render: (args) => (
    <WelcomeStage initialEntry="/welcome/currency" currency="EUR" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    // In Bogotá the default is COP.
    await expect(await canvas.findByRole("radio", { name: /COP/ })).toBeChecked();
    await userEvent.click(canvas.getByRole("radio", { name: /EUR/ }));
    await userEvent.click(canvas.getByRole("button", { name: "Recargar (stand-in)" }));
    await heading(canvas, "¿En qué moneda llevas tus cuentas?");
    await expect(await canvas.findByRole("radio", { name: /EUR/ })).toBeChecked();
  },
};

/**
 * A reload after a EUR import that switched a COP choice: the account is locked to EUR, so the
 * currency step shows EUR, not the COP still in the session's draft.
 */
export const FlowLockedCurrencyWinsOverDraft: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome/currency"
      currency="EUR"
      hasTransactions
      draft={{ currency: "COP", categoriesDone: true }}
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("radio", { name: /EUR/ })).toBeChecked();
    await expect(canvas.getByRole("radio", { name: /COP/ })).not.toBeChecked();
  },
};

/**
 * ENTRAR DIRECTO when every suggestion was deselected (and archived) in an earlier visit: it never
 * leaves the account without categories; the suggestions come back.
 */
export const FlowEnterDirectlyAfterDeselectingAll: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome"
      currency="EUR"
      categories="archived"
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Entrar directo" }));
    await expect(await canvas.findByText("App (stand-in)")).toBeVisible();
    const restored = calls(args.onRequest).filter((l) => l.endsWith('{"archived":false}'));
    await expect(restored).toHaveLength(SUGGESTED_CATEGORIES.length);
    await expect(calls(args.onRequest).at(-1)).toBe(
      'PATCH /api/v1/me {"onboardingCompleted":true}',
    );
  },
};

// -- Task 10e: import before categories, editable categories ------------------------------------------

/** The new order: currency, "¿Vienes de otra app?", then the categories; "empiezo de cero" skips. */
export const FlowNewOrder: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome"
      currency="EUR"
      categories="none"
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Configurar en 1 minuto" }));
    await heading(canvas, "¿En qué moneda llevas tus cuentas?");
    await userEvent.click(canvas.getByRole("button", { name: "Siguiente" }));
    const importTitle = await heading(canvas, "¿Vienes de otra app?");
    await waitFor(() => expect(importTitle).toHaveFocus());
    await expect(canvas.getByText("Paso 2 de 4")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "No, empiezo de cero" }));
    const categoriesTitle = await heading(canvas, "¿En qué se te va el dinero?");
    await waitFor(() => expect(categoriesTitle).toHaveFocus());
    await expect(canvas.getByText("Paso 3 de 4")).toBeVisible();
    // Nothing imported: the suggestions, pre-selected.
    await expect(canvas.getByRole("button", { name: "Supermercado" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
    await userEvent.click(canvas.getByRole("button", { name: "Siguiente" }));
    await heading(canvas, "¿Cuánto quieres gastar al mes?");
  },
};

/**
 * Import first: the categories step starts from what the file brought (chosen), then the
 * suggestions it doesn't cover (not chosen). "supermercado" and "Salário" cover "Supermercado" and
 * "Salario": no duplicates.
 */
export const FlowImportFirst: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome/import"
      currency="EUR"
      categories="none"
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
    await upload(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Importar 22 movimientos" }));
    await canvas.findByRole("heading", { name: "Importamos 22 movimientos." });
    await userEvent.click(canvas.getByRole("button", { name: "Siguiente" }));
    await heading(canvas, "¿En qué se te va el dinero?");

    const spending = within(canvas.getByRole("group", { name: "Gastos" }));
    // The visible name (the emoji tile is decorative).
    const label = (b: HTMLElement) => b.querySelector(".truncate")?.textContent?.trim();
    const names = spending.getAllByRole("button").map(label);
    await expect(names).toEqual([
      "supermercado",
      "Ocio",
      "Taxes",
      "Restaurante",
      "Casa",
      "Transporte",
      "Suscripciones",
      "Vida",
    ]);
    for (const name of ["supermercado", "Ocio", "Taxes"]) {
      await expect(spending.getByRole("button", { name })).toHaveAttribute("aria-pressed", "true");
    }
    await expect(spending.getByRole("button", { name: "Restaurante" })).toHaveAttribute(
      "aria-pressed",
      "false",
    );
    const income = within(canvas.getByRole("group", { name: "Ingresos" }));
    await expect(income.getAllByRole("button").map(label)).toEqual(["Salário"]);
  },
};

const openEdit = async (canvas: Canvas, name: string) => {
  const toggle = canvas.queryByRole("button", { name: "Editar categorías" });
  if (toggle) await userEvent.click(toggle);
  await userEvent.click(await canvas.findByRole("button", { name: `Editar ${name}` }));
  return within(await screen.findByRole("dialog", { name: "Editar categoría" }));
};
const sheetClosed = () => waitFor(() => expect(screen.queryByRole("dialog")).toBeNull());

/** Rename, emoji and tint in the edit sheet; then delete it (no transactions, so it can go). */
export const FlowEditAndDeleteCategory: Story = {
  render: (args) => (
    <WelcomeStage initialEntry="/welcome/categories" currency="EUR" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await heading(canvas, "¿En qué se te va el dinero?");
    let sheet = await openEdit(canvas, "Supermercado");
    await expect(sheet.getByRole("textbox", { name: "Nombre" })).toHaveValue("Supermercado");
    await expect(await sheet.findByRole("button", { name: "Eliminar categoría" })).toBeVisible();
    const name = sheet.getByRole("textbox", { name: "Nombre" });
    await userEvent.clear(name);
    await userEvent.type(name, "Mercado");
    await userEvent.click(sheet.getByRole("radio", { name: "🧾" }));
    await userEvent.click(sheet.getByRole("radio", { name: "Azul" }));
    await userEvent.click(sheet.getByRole("button", { name: "Guardar categoría" }));
    await sheetClosed();
    await expect(args.onRequest).toHaveBeenCalledWith(
      'PATCH /api/v1/categories/cat-groceries {"name":"Mercado","icon":"🧾","color":"#3fa7ff"}',
    );

    sheet = await openEdit(canvas, "Mercado");
    await userEvent.click(await sheet.findByRole("button", { name: "Eliminar categoría" }));
    await sheetClosed();
    await expect(args.onRequest).toHaveBeenCalledWith(
      'PATCH /api/v1/categories/cat-groceries {"archived":true}',
    );
    await waitFor(() =>
      expect(canvas.queryByRole("button", { name: "Editar Mercado" })).toBeNull(),
    );

    // A suggestion not made yet: editing makes it with the new values; deleting just drops it.
    sheet = await openEdit(canvas, "Restaurante");
    const suggestion = sheet.getByRole("textbox", { name: "Nombre" });
    await userEvent.clear(suggestion);
    await userEvent.type(suggestion, "Comida fuera");
    await userEvent.click(sheet.getByRole("button", { name: "Guardar categoría" }));
    await sheetClosed();
    await expect(
      calls(args.onRequest).some((l) =>
        l.startsWith('POST /api/v1/categories {"name":"Comida fuera","kind":"expense"'),
      ),
    ).toBe(true);
    sheet = await openEdit(canvas, "Vida");
    const before = calls(args.onRequest).length;
    await userEvent.click(sheet.getByRole("button", { name: "Eliminar categoría" }));
    await sheetClosed();
    await expect(calls(args.onRequest)).toHaveLength(before);
    await expect(canvas.queryByRole("button", { name: "Editar Vida" })).toBeNull();
  },
};

/** Spending ↔ income for a category without transactions: one PATCH with the kind, same id. */
export const FlowSwitchKind: Story = {
  render: (args) => (
    <WelcomeStage initialEntry="/welcome/categories" currency="EUR" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await heading(canvas, "¿En qué se te va el dinero?");
    const sheet = await openEdit(canvas, "Salario");
    await sheet.findByRole("button", { name: "Eliminar categoría" });
    await userEvent.click(sheet.getByRole("radio", { name: "Gasto" }));
    await userEvent.click(sheet.getByRole("button", { name: "Guardar categoría" }));
    await sheetClosed();
    await expect(calls(args.onRequest)).toEqual([
      'PATCH /api/v1/categories/cat-salary {"name":"Salario","icon":"💰","color":"#2fd388","kind":"expense"}',
    ]);
    const spending = within(canvas.getByRole("group", { name: "Gastos" }));
    await expect(await spending.findByRole("button", { name: "Editar Salario" })).toBeVisible();
    // The chip may have moved: focus goes to the edit toggle, not a detached node.
    await waitFor(() => expect(canvas.getByRole("button", { name: "Listo" })).toHaveFocus());
  },
};

/**
 * With transactions it can't be deleted: the sheet says how many and offers to archive it; and a
 * plain tap doesn't drop it either (it stays chosen, with the same reason).
 */
export const FlowCategoryWithTransactions: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome/categories"
      currency="EUR"
      transactionsByName={{ Supermercado: 132 }}
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await heading(canvas, "¿En qué se te va el dinero?");
    const chip = canvas.getByRole("button", { name: "Supermercado" });
    await userEvent.click(chip);
    await expect(
      await canvas.findByText(
        "«Supermercado» no se puede quitar porque tiene 132 movimientos. Puedes archivarla en Editar categorías para que no aparezca al anotar.",
      ),
    ).toBeVisible();
    await expect(chip).toHaveAttribute("aria-pressed", "true");

    const sheet = await openEdit(canvas, "Supermercado");
    await expect(
      await sheet.findByText(
        "No se puede borrar porque tiene 132 movimientos. Puedes archivarla para que no aparezca al anotar.",
        {},
      ),
    ).toBeVisible();
    await expect(sheet.queryByRole("button", { name: "Eliminar categoría" })).toBeNull();
    await expect(sheet.getByRole("radio", { name: "Ingreso" })).toBeDisabled();
    await userEvent.click(sheet.getByRole("button", { name: "Archivar categoría" }));
    await sheetClosed();
    await expect(args.onRequest).toHaveBeenCalledWith(
      'PATCH /api/v1/categories/cat-groceries {"archived":true}',
    );
  },
};

// -- Task 10e fix round 1: the app's import page, honest counts, tints, leads -------------------------

const pageImport = async (canvas: Canvas) => {
  await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
  await upload(canvas);
};

/**
 * `/app/import` ends with the budgets, as onboarding does: prefilled from the recent months, shown
 * as a form, and written only by "Guardar presupuestos". No "Llenamos…" line before that.
 */
export const ImportPageSavesBudgets: Story = {
  render: (args) => <ImportPageStage currency="EUR" onRequest={args.onRequest} />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const title = await canvas.findByRole("heading", { level: 1, name: "Trae tu historial" });
    await waitFor(() => expect(title).toHaveFocus());
    await pageImport(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Importar 22 movimientos" }));
    const budgets = await canvas.findByRole("heading", { name: "Tus presupuestos" });
    await waitFor(() => expect(budgets).toHaveFocus());
    await expect(canvas.queryByText(/^Llenamos tus presupuestos/)).toBeNull();
    await expect(
      canvas.getByText("Basado en lo que gastaste en tus últimos 3 meses"),
    ).toBeVisible();
    await expect(canvas.getByRole("textbox", { name: "Presupuesto de Supermercado" })).toHaveValue(
      "35,89",
    );
    await expect(calls(args.onRequest).some((l) => l.includes("/budget"))).toBe(false);
    await userEvent.click(canvas.getByRole("button", { name: "Guardar presupuestos" }));
    await expect(await canvas.findByText("Guardamos tus presupuestos.")).toBeVisible();
    await expect(calls(args.onRequest)).toContain(
      `PUT /api/v1/categories/cat-groceries/budget {"amount":3589,"effectiveFrom":"${monthOf(todayIn("America/Bogota"))}"}`,
    );
    await userEvent.click(canvas.getByRole("link", { name: "Ir al inicio" }));
    await expect(await canvas.findByText("App (stand-in)")).toBeVisible();
  },
};

/**
 * A COP account with budgets, a EUR file: the preview warns that the budgets in COP go with the
 * switch. Dropping the preview (or leaving) changes nothing: only the DELETE of the preview.
 */
export const ImportPageWarnsBeforeSwitching: Story = {
  render: (args) => <ImportPageStage currency="COP" budgeted onRequest={args.onRequest} />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await pageImport(canvas);
    await expect(
      await canvas.findByText("Tus presupuestos en COP se borrarán al cambiar a EUR."),
    ).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Usar otro archivo" }));
    await waitFor(() =>
      expect(calls(args.onRequest)).toEqual([
        "POST /api/v1/imports",
        "DELETE /api/v1/imports/preview-1",
      ]),
    );
  },
};

/** The confirm fails: the preview stays with the reason, and importing again works. */
export const ImportPageConfirmFails: Story = {
  render: (args) => <ImportPageStage currency="EUR" failConfirmOnce onRequest={args.onRequest} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await pageImport(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Importar 22 movimientos" }));
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "Tuvimos un problema de nuestro lado",
    );
    await expect(canvas.queryByRole("heading", { name: "Tus presupuestos" })).toBeNull();
    await userEvent.click(canvas.getByRole("button", { name: "Importar 22 movimientos" }));
    await expect(await canvas.findByRole("heading", { name: "Tus presupuestos" })).toBeVisible();
  },
};

/** Saving the budgets fails: nothing claims they were saved, and trying again does. */
export const ImportPageBudgetsSaveFails: Story = {
  render: (args) => <ImportPageStage currency="EUR" failBudgetOnce onRequest={args.onRequest} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await pageImport(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Importar 22 movimientos" }));
    const save = await canvas.findByRole("button", { name: "Guardar presupuestos" });
    await userEvent.click(save);
    await expect(await canvas.findByRole("alert")).toHaveTextContent(
      "Tuvimos un problema de nuestro lado",
    );
    await expect(canvas.queryByText("Guardamos tus presupuestos.")).toBeNull();
    await userEvent.click(canvas.getByRole("button", { name: "Guardar presupuestos" }));
    await expect(await canvas.findByText("Guardamos tus presupuestos.")).toBeVisible();
  },
};

/** The count fails: no "más de 0", just that it couldn't be counted, and only Archivar. */
export const FlowCountFails: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome/categories"
      currency="EUR"
      failCount
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await heading(canvas, "¿En qué se te va el dinero?");
    const sheet = await openEdit(canvas, "Supermercado");
    await expect(
      await sheet.findByText(
        "No pudimos contar sus movimientos. Puedes archivarla para que no aparezca al anotar.",
        {},
      ),
    ).toBeVisible();
    await expect(sheet.queryByText(/más de 0/)).toBeNull();
    await expect(sheet.queryByRole("button", { name: "Eliminar categoría" })).toBeNull();
    await expect(sheet.getByRole("button", { name: "Archivar categoría" })).toBeVisible();
  },
};

/**
 * After an import the lead speaks of their categories (fresh, of the suggestions), and an
 * importer tint such as yellow shows as its picker radio.
 */
export const FlowImportedLeadAndTints: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome/import"
      currency="EUR"
      categories="none"
      onRequest={args.onRequest}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "No, empiezo de cero" }));
    await heading(canvas, "¿En qué se te va el dinero?");
    await expect(canvas.getByText(/^Ya elegimos algunas por ti/)).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Atrás" }));
    await heading(canvas, "¿Vienes de otra app?");
    await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
    await upload(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Importar 22 movimientos" }));
    await canvas.findByRole("heading", { name: "Importamos 22 movimientos." });
    await userEvent.click(canvas.getByRole("button", { name: "Siguiente" }));
    await heading(canvas, "¿En qué se te va el dinero?");
    await expect(canvas.getByText(/^Estas son tus categorías/)).toBeVisible();
    const sheet = await openEdit(canvas, "Taxes");
    await expect(sheet.getByRole("radio", { name: "Amarillo" })).toBeChecked();
  },
};

/**
 * Re-import with a budget already saved: it keeps its amount (not replaced by the file's average),
 * the categories without one are prefilled, and saving writes only those.
 */
export const ImportPageKeepsSavedBudgets: Story = {
  render: (args) => <ImportPageStage currency="EUR" budgeted onRequest={args.onRequest} />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await pageImport(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Importar 22 movimientos" }));
    await canvas.findByRole("heading", { name: "Tus presupuestos" });
    // Saved 300.000 € stays; the file's 35,89 doesn't replace it.
    await expect(canvas.getByRole("textbox", { name: "Presupuesto de Supermercado" })).toHaveValue(
      "300.000",
    );
    // Ocio (made by the import) had none: prefilled with its average.
    await expect(canvas.getByRole("textbox", { name: "Presupuesto de Ocio" })).toHaveValue("62,25");
    await userEvent.click(canvas.getByRole("button", { name: "Guardar presupuestos" }));
    await canvas.findByText("Guardamos tus presupuestos.");
    const puts = calls(args.onRequest).filter((l) => l.includes("/budget"));
    await expect(puts.some((l) => l.includes("cat-groceries"))).toBe(false);
    await expect(puts).toHaveLength(1);
    await expect(puts[0]).toContain('{"amount":6225,');
  },
};
