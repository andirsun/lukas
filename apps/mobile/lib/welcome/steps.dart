// The welcome's steps: a port of apps/web/app/features/onboarding/steps.ts.
//
// A welcome with "Configurar en 1 minuto" / "Entrar directo", then four setup steps. The import
// comes before the categories (founder, Task 10e), so the categories step can start from what the
// file brought; budgets last. The welcome lives at `/welcome`, the rest below it, so back, forward
// and a restart keep the step.

enum StepId {
  welcome('welcome'),
  currency('currency'),
  import('import'),
  categories('categories'),
  budgets('budgets');

  const StepId(this.id);

  final String id;
}

/// The steps counted in the progress ("Paso 1 de 4"): all but the welcome.
final setupSteps = StepId.values.skip(1).toList();

String stepPath(StepId step) => step == StepId.welcome ? '/welcome' : '/welcome/${step.id}';

/// The step a `/welcome/:step?` param names; no param is the welcome, an unknown one null.
StepId? stepFromParam(String? param) {
  if (param == null) return StepId.welcome;
  for (final step in StepId.values) {
    if (step.id == param && step != StepId.welcome) return step;
  }
  return null;
}

StepId? nextStep(StepId step) => StepId.values.elementAtOrNull(step.index + 1);

StepId? previousStep(StepId step) => step.index == 0 ? null : StepId.values[step.index - 1];
