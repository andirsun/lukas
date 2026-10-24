// The welcome's last step: the web's BudgetsStep (apps/web/app/features/onboarding/
// BudgetsStep.tsx). An amount per chosen spending category, typed in the locale's way (`300.000`,
// `120,50`), with what it comes to under the field and, for COP, the lukas hint. The running total
// is "what you can spend per month". An empty field means no budget; a field that is not an amount
// says so and holds SIGUIENTE back (SALTAR still finishes, without budgets).
import 'package:flutter/material.dart';

import '../import/budgets_form.dart';
import '../import/note_text.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../ui/lk_theme.dart';
import 'step_frame.dart';
import 'steps.dart';

class BudgetsStep extends StatelessWidget {
  const BudgetsStep({
    super.key,
    required this.categories,
    required this.drafts,
    required this.onChange,
    required this.currency,
    this.prefillBasis,
    this.error,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    this.busy = false,
  });

  /// The chosen spending categories.
  final List<BudgetCategory> categories;

  /// What is typed per category id; empty or missing means no budget.
  final Map<String, String> drafts;
  final void Function(String id, String text) onChange;
  final String currency;

  /// Where prefilled amounts came from ("Basado en lo que gastaste en tus últimos 3 meses").
  final String? prefillBasis;
  final String? error;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    final locale = l10n.localeName;
    final invalid = categories.any((c) => readDraft(drafts[c.id], locale) == invalidDraft);
    final total = draftsTotal([for (final c in categories) c.id], drafts, locale);
    return StepFrame(
      step: StepId.budgets,
      title: l10n.welcomeBudgetsTitle,
      lead: l10n.welcomeBudgetsLead,
      onBack: onBack,
      skip: StepAction(label: l10n.welcomeSkip, onPressed: busy ? null : onSkip),
      next: StepAction(
        label: busy ? l10n.welcomeSaving : l10n.welcomeNext,
        onPressed: busy || invalid ? null : onNext,
      ),
      summary: BudgetsTotal(total: total, currency: currency),
      children: [
        if (prefillBasis != null)
          NoteText(
            prefillBasis!,
            LkText.note.copyWith(color: colors.inkMuted),
            key: const Key('welcome.prefillBasis'),
          ),
        BudgetsList(categories: categories, drafts: drafts, onChange: onChange, currency: currency),
        if (error != null) StepError(error!),
      ],
    );
  }
}
