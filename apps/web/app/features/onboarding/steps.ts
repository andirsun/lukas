/**
 * The onboarding's steps (spec §2.4, revised): a welcome with "Configurar en 1 minuto" / "Entrar
 * directo", then four setup steps. The import comes before the categories (founder, Task 10e), so
 * the categories step can start from what the file brought; budgets last. The welcome lives at
 * `/welcome`, the rest below it, so back, forward and a reload keep the step.
 */
export const STEPS = ["welcome", "currency", "import", "categories", "budgets"] as const;
export type StepId = (typeof STEPS)[number];

/** The steps counted in the progress ("Paso 1 de 4"): all but the welcome. */
export const SETUP_STEPS = STEPS.slice(1) as readonly Exclude<StepId, "welcome">[];

export function stepPath(step: StepId): string {
  return step === "welcome" ? "/welcome" : `/welcome/${step}`;
}

/** The step a `/welcome/:step?` param names; no param is the welcome, an unknown one null. */
export function stepFromParam(param: string | undefined): StepId | null {
  if (param === undefined) return "welcome";
  return (STEPS as readonly string[]).includes(param) && param !== "welcome"
    ? (param as StepId)
    : null;
}

export function nextStep(step: StepId): StepId | null {
  return STEPS[STEPS.indexOf(step) + 1] ?? null;
}

export function previousStep(step: StepId): StepId | null {
  return STEPS[STEPS.indexOf(step) - 1] ?? null;
}
