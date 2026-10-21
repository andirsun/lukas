import { monthOf, todayIn } from "@lukas/core";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { expectTarget } from "../../../.storybook/story-utils.ts";
import { BudgetsStep } from "./BudgetsStep.tsx";
import { CategoriesStep } from "./CategoriesStep.tsx";
import { CurrencyStep } from "./CurrencyStep.tsx";
import { DoneStep } from "./DoneStep.tsx";
import { ImportStep } from "./ImportStep.tsx";
import type { ImportState } from "./import-state.ts";
import { PasskeyStep } from "./PasskeyStep.tsx";
import { SAMPLE_PREVIEW, WelcomeStage } from "./story-harness.tsx";
import { SUGGESTED_CATEGORIES } from "./suggested-categories.ts";

/**
 * The onboarding steps on their own (state held by the story), and the whole `/welcome` flow
 * against a fake API (`WelcomeStage`). Phone first: every story renders at the app's width.
 */
/** Spies the stories hand to the steps (Storybook resets them before each story). */
interface Spies {
  onBack(): void;
  onNext(): void;
  onAdd(): void;
  onRequest(line: string): void;
}

const meta = {
  title: "Onboarding/Welcome",
  args: { onBack: fn(), onNext: fn(), onAdd: fn(), onRequest: fn() },
} satisfies Meta<Spies>;

export default meta;
type Story = StoryObj<Spies>;

/** From the budgets step (where the flows start) on to the import step. */
async function toImport(canvas: ReturnType<typeof within>) {
  await userEvent.click(await canvas.findByRole("button", { name: "Continuar" }));
  await canvas.findByRole("heading", { level: 1, name: "¿Vienes de Budge?" });
}

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

// -- Step 0: currency --------------------------------------------------------------------------

function CurrencyHarness({ onNext }: { onNext(): void }) {
  const [value, setValue] = useState<"COP" | "EUR" | "USD" | "MXN" | "ARS" | "CLP" | "PEN">("COP");
  return <CurrencyStep value={value} onChange={setValue} onNext={onNext} />;
}

/** One radio per supported currency, named in the person's language with its code. */
export const Currency: Story = {
  render: (args) => <CurrencyHarness onNext={args.onNext} />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const title = canvas.getByRole("heading", {
      level: 1,
      name: "¿En qué moneda llevas tus cuentas?",
    });
    await waitFor(() => expect(title).toHaveFocus());
    await expect(canvas.getByText("Paso 1 de 6")).toBeVisible();
    await expect(canvas.getAllByRole("radio")).toHaveLength(7);
    await expect(canvas.getByRole("radio", { name: /Peso colombiano.*COP/i })).toBeChecked();
    await userEvent.click(canvas.getByRole("radio", { name: /Euro.*EUR/i }));
    await expect(canvas.getByRole("radio", { name: /Euro.*EUR/i })).toBeChecked();
    // The first step has nowhere to go back to.
    await expect(canvas.queryByRole("button", { name: "Atrás" })).toBeNull();
    const next = canvas.getByRole("button", { name: "Continuar" });
    await expectTarget(next);
    await userEvent.click(next);
    await expect(args.onNext).toHaveBeenCalled();
  },
};

// -- Step 1: passkey ---------------------------------------------------------------------------

/** The offer: add a passkey, or "Ahora no" to move on. */
export const Passkey: Story = {
  render: (args) => (
    <PasskeyStep onBack={args.onBack} onNext={args.onNext} onAdd={args.onAdd} adding={false} />
  ),
  play: async ({ canvasElement, args: a }) => {
    const canvas = within(canvasElement);
    await expect(
      canvas.getByRole("heading", { level: 1, name: "¿Entrar con tu huella la próxima vez?" }),
    ).toBeVisible();
    await expect(canvas.getByText("Paso 2 de 6")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Usar mi huella" }));
    await expect(a.onAdd).toHaveBeenCalled();
    await userEvent.click(canvas.getByRole("button", { name: "Ahora no" }));
    await expect(a.onNext).toHaveBeenCalled();
    await userEvent.click(canvas.getByRole("button", { name: "Atrás" }));
    await expect(a.onBack).toHaveBeenCalled();
  },
};

/** Saving the passkey failed: the reason under the button, and the step can still be skipped. */
export const PasskeyFailed: Story = {
  render: () => (
    <PasskeyStep
      onBack={() => {}}
      onNext={() => {}}
      onAdd={() => {}}
      adding={false}
      error="No pudimos guardar tu huella. Inténtalo otra vez o sigue sin ella."
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("alert")).toHaveTextContent("No pudimos guardar tu huella");
    await expect(canvas.getByRole("button", { name: "Ahora no" })).toBeEnabled();
  },
};

// -- Step 2: categories ------------------------------------------------------------------------

function CategoriesHarness({ initial, onNext }: { initial: string[]; onNext(): void }) {
  const [selected, setSelected] = useState(() => new Set(initial));
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
      onBack={() => {}}
      onNext={onNext}
    />
  );
}

/** At least one spending category: with none (income alone does not count), Continue is disabled. */
export const CategoriesNeedAnExpense: Story = {
  render: (args) => <CategoriesHarness initial={[]} onNext={args.onNext} />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Paso 3 de 6")).toBeVisible();
    const next = canvas.getByRole("button", { name: "Continuar" });
    await expect(next).toBeDisabled();
    await expect(
      canvas.getByText("Elige al menos una categoría de gasto para seguir."),
    ).toBeVisible();

    const salary = canvas.getByRole("button", { name: "Salario" });
    await userEvent.click(salary);
    await expect(salary).toHaveAttribute("aria-pressed", "true");
    await expect(next).toBeDisabled();

    const groceries = canvas.getByRole("button", { name: "Supermercado" });
    await expectTarget(groceries);
    await userEvent.click(groceries);
    await expect(groceries).toHaveAttribute("aria-pressed", "true");
    await expect(next).toBeEnabled();
    await expect(
      canvas.queryByText("Elige al menos una categoría de gasto para seguir."),
    ).toBeNull();

    // Unselecting it disables Continue again.
    await userEvent.click(groceries);
    await expect(next).toBeDisabled();
    await userEvent.click(groceries);
    await userEvent.click(next);
    await expect(args.onNext).toHaveBeenCalledTimes(1);
  },
};

/** The eight suggestions, spending and income apart. */
export const CategoriesInEnglish: Story = {
  globals: { locale: "en", theme: "day" },
  render: () => <CategoriesHarness initial={["groceries", "home", "salary"]} onNext={() => {}} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(
      canvas.getByRole("heading", { level: 1, name: "Where does your money go?" }),
    ).toBeVisible();
    const spending = canvas.getByRole("group", { name: "Spending" });
    await expect(within(spending).getAllByRole("button")).toHaveLength(7);
    const income = canvas.getByRole("group", { name: "Income" });
    await expect(within(income).getByRole("button", { name: "Salary" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
    await expect(canvas.getByRole("button", { name: "Continue" })).toBeEnabled();
  },
};

// -- Step 3: budgets ---------------------------------------------------------------------------

function BudgetsHarness({ currency }: { currency: string }) {
  const categories = ["groceries", "eating_out", "home"].map(budgetCategory);
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  return (
    <BudgetsStep
      categories={categories}
      drafts={drafts}
      onChange={(id, text) => setDrafts((current) => ({ ...current, [id]: text }))}
      currency={currency}
      onBack={() => {}}
      onNext={() => {}}
    />
  );
}

/** One field per chosen spending category; the total is "what you can spend per month". */
export const BudgetsRunningTotal: Story = {
  render: () => <BudgetsHarness currency="EUR" />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Paso 4 de 6")).toBeVisible();
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

    // Not a number: the field says so, the total ignores it and Continue waits.
    const home = canvas.getByRole("textbox", { name: "Presupuesto de Casa" });
    await userEvent.type(home, "x");
    await expect(home).toHaveAttribute("aria-invalid", "true");
    await expect(canvas.getByText("Escribe solo el número, como 300.")).toBeVisible();
    await expect(total).toHaveTextContent("420,50 €");
    await expect(canvas.getByRole("button", { name: "Continuar" })).toBeDisabled();
    // EUR gets no lukas hint.
    await expect(canvas.queryByText(/lukas/)).toBeNull();
  },
};

/** COP (day theme): each amount and the total carry the small lukas hint, e.g. "$300.000 (300 lukas)". */
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

// -- Step 4: import ----------------------------------------------------------------------------

function ImportHarness({ state, currency = "EUR" }: { state: ImportState; currency?: string }) {
  return (
    <ImportStep
      state={state}
      currency={currency}
      onFile={() => {}}
      onConfirm={() => {}}
      onDiscard={() => {}}
      onReviewBudgets={() => {}}
      onBack={() => {}}
      onNext={() => {}}
    />
  );
}

/** Before a file: what to upload, and "Saltar" to move on without one. */
export const ImportStart: Story = {
  render: () => <ImportHarness state={{ phase: "idle" }} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(
      canvas.getByRole("heading", { level: 1, name: "¿Vienes de Budge?" }),
    ).toBeVisible();
    const input = canvas.getByLabelText("Subir archivo de Budge");
    await expect(input).toHaveAttribute("type", "file");
    await expect(input).toHaveAttribute("accept", ".csv,text/csv");
    await expect(canvas.getByRole("button", { name: "Saltar" })).toBeEnabled();
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
    // 22 rows, 3 of them already there: 19 to import.
    await expect(canvas.getByRole("button", { name: "Importar 19 movimientos" })).toBeEnabled();
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
      currency="EUR"
      state={{
        phase: "preview",
        fileName: "budge.csv",
        preview: SAMPLE_PREVIEW,
        currencyNote: { kind: "switched", file: "EUR", account: "EUR" },
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

/** Imported, with budgets prefilled from the monthly averages. */
export const Imported: Story = {
  render: () => (
    <ImportHarness
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
    await expect(canvas.getByText("Importamos 19 movimientos.")).toBeVisible();
    await expect(
      canvas.getByText("Llenamos tus presupuestos con lo que gastas en promedio cada mes."),
    ).toBeVisible();
    await expect(
      canvas.getByText("Basado en lo que gastaste en tus últimos 3 meses"),
    ).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Revisar presupuestos" })).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Continuar" })).toBeEnabled();
  },
};

// -- Step 5: done ------------------------------------------------------------------------------

/** Lukitas celebrating, the month's budget, and "Empezar". */
export const Done: Story = {
  render: (args) => (
    <DoneStep total={30_000_000} currency="COP" onBack={() => {}} onNext={args.onNext} />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading", { level: 1, name: "¡Todo listo!" })).toBeVisible();
    await expect(canvas.getByText("Paso 6 de 6")).toBeVisible();
    await expect(canvas.getByRole("img", { name: "Lukitas, celebrando" })).toBeVisible();
    await expect(canvas.getByText("Tu presupuesto del mes").parentElement).toHaveTextContent(
      "$300.000 (300 lukas)",
    );
    await userEvent.click(canvas.getByRole("button", { name: "Empezar" }));
    await expect(args.onNext).toHaveBeenCalled();
  },
};

// -- The whole flow, against a fake API ----------------------------------------------------------

/**
 * A COP account uploads a EUR file: the account (still empty) switches to EUR, the stale preview
 * is dropped and the file is read again, so the preview that gets confirmed is in EUR.
 */
export const FlowImportSwitchesCurrency: Story = {
  render: (args) => (
    <WelcomeStage initialEntry="/welcome/budgets" currency="COP" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement, args }) => {
    const { onRequest } = args;
    const canvas = within(canvasElement);
    await userEvent.type(
      await canvas.findByRole("textbox", { name: "Presupuesto de Supermercado" }),
      "300.000",
    );
    await toImport(canvas);
    const input = await canvas.findByLabelText("Subir archivo de Budge");
    await userEvent.upload(input, new File(["Date,Payment\n"], "budge.csv", { type: "text/csv" }));
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
    // The budget typed in pesos is replaced by the recent average, in euros.
    await userEvent.click(canvas.getByRole("button", { name: "Revisar presupuestos" }));
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
    <WelcomeStage initialEntry="/welcome/budgets" currency="COP" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement, args }) => {
    const { onRequest } = args;
    const canvas = within(canvasElement);
    await toImport(canvas);
    await userEvent.upload(
      await canvas.findByLabelText("Subir archivo de Budge"),
      new File(["Date,Payment\n"], "budge.csv", { type: "text/csv" }),
    );
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

/**
 * The import went in, but reading the categories again failed: the step still says it was
 * imported (pressing Importar again could only fail), shows the problem and offers a retry.
 */
export const FlowRefreshFailsAfterConfirm: Story = {
  render: (args) => (
    <WelcomeStage
      initialEntry="/welcome/budgets"
      currency="EUR"
      onRequest={args.onRequest}
      failRefreshesAfterConfirm={3}
    />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await toImport(canvas);
    await userEvent.upload(
      await canvas.findByLabelText("Subir archivo de Budge"),
      new File(["Date,Payment\n"], "budge.csv", { type: "text/csv" }),
    );
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

/** A reload on the last step (nothing typed this visit) goes back to the budgets first. */
export const FlowReloadOnDone: Story = {
  render: (args) => (
    <WelcomeStage initialEntry="/welcome/done" currency="EUR" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(
      await canvas.findByRole("heading", { level: 1, name: "¿Cuánto quieres gastar al mes?" }),
    ).toBeVisible();
    await expect(args.onRequest).not.toHaveBeenCalled();
  },
};

/** "Empezar" saves the budgets and the onboarding flag, celebrates and goes to /app. */
export const FlowDone: Story = {
  render: (args) => (
    <WelcomeStage initialEntry="/welcome/budgets" currency="EUR" onRequest={args.onRequest} />
  ),
  play: async ({ canvasElement, args }) => {
    const { onRequest } = args;
    const canvas = within(canvasElement);
    await userEvent.type(
      await canvas.findByRole("textbox", { name: "Presupuesto de Supermercado" }),
      "300",
    );
    await userEvent.click(canvas.getByRole("button", { name: "Continuar" }));
    await userEvent.click(await canvas.findByRole("button", { name: "Saltar" }));
    const start = await canvas.findByRole("button", { name: "Empezar" });
    await userEvent.click(start);
    await expect(await canvas.findByText("App (stand-in)")).toBeVisible();
    const month = monthOf(todayIn("UTC"));
    await expect(calls(onRequest)).toContain(
      `PUT /api/v1/categories/cat-groceries/budget {"amount":30000,"effectiveFrom":"${month}"}`,
    );
    await expect(calls(onRequest).at(-1)).toBe('PATCH /api/v1/me {"onboardingCompleted":true}');
  },
};
