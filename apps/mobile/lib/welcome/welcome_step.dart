// The welcome's first screen: the web's WelcomeStep (apps/web/app/features/onboarding/
// WelcomeStep.tsx). Set up in a minute, or go straight in; going straight in still leaves a usable
// account (the region's currency, the suggested categories).
import 'package:flutter/material.dart';

import '../import/note_text.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../ui/lk_theme.dart';
import '../ui/press_button.dart';
import 'step_frame.dart';
import 'steps.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({
    super.key,
    required this.currency,
    required this.onSetup,
    required this.onDirect,
    this.busy = false,
    this.error,
  });

  /// The currency "Entrar directo" would set, named in the note.
  final String currency;

  /// CONFIGURAR EN 1 MINUTO: on to the currency.
  final VoidCallback onSetup;

  /// ENTRAR DIRECTO: defaults for everything, then the app.
  final VoidCallback onDirect;

  /// While "Entrar directo" saves the defaults.
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    return StepFrame(
      step: StepId.welcome,
      title: l10n.welcomeTitle,
      lead: l10n.welcomeLead,
      children: [
        SizedBox(
          width: double.infinity,
          child: PressButton.text(
            l10n.welcomeSetup,
            key: const Key('welcome.setup'),
            onPressed: busy ? null : onSetup,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: PressButton.text(
            busy ? l10n.welcomeSaving : l10n.welcomeDirect,
            key: const Key('welcome.direct'),
            tone: PressTone.secondary,
            onPressed: busy ? null : onDirect,
          ),
        ),
        NoteText(
          l10n.welcomeDirectNote(currency),
          LkText.note.copyWith(color: colors.inkMuted),
          key: const Key('welcome.directNote'),
        ),
        if (error != null) StepError(error!),
      ],
    );
  }
}
