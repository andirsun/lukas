/** The onboarding's steps (spec §2.4), in order. Step 0 lives at `/welcome`, the rest below it. */
export const STEPS = ["currency", "passkey", "categories", "budgets", "import", "done"] as const;
export type StepId = (typeof STEPS)[number];

/** What decides which steps apply: without WebAuthn there is no passkey to offer. */
export interface StepContext {
  passkeys: boolean;
}

export function stepPath(step: StepId): string {
  return step === "currency" ? "/welcome" : `/welcome/${step}`;
}

/** The step a `/welcome/:step?` param names; no param is the first step, an unknown one null. */
export function stepFromParam(param: string | undefined): StepId | null {
  if (param === undefined) return "currency";
  return (STEPS as readonly string[]).includes(param) ? (param as StepId) : null;
}

const applies = (step: StepId, context: StepContext) => step !== "passkey" || context.passkeys;

export function nextStep(step: StepId, context: StepContext): StepId | null {
  return STEPS.slice(STEPS.indexOf(step) + 1).find((s) => applies(s, context)) ?? null;
}

export function previousStep(step: StepId, context: StepContext): StepId | null {
  return (
    STEPS.slice(0, STEPS.indexOf(step))
      .reverse()
      .find((s) => applies(s, context)) ?? null
  );
}
