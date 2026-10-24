// The welcome's currency: the web's CurrencyStep (apps/web/app/features/onboarding/CurrencyStep.tsx).
// One radio per supported currency (COP, USD, EUR), preselected.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;

import '../l10n/app_localizations.dart';
import '../profile/currency.dart';
import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_theme.dart';
import '../ui/native_radio.dart';
import '../ui/pressable.dart';
import 'step_frame.dart';
import 'steps.dart';

class CurrencyStep extends StatelessWidget {
  const CurrencyStep({
    super.key,
    required this.value,
    required this.onChange,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
    this.busy = false,
    this.error,
  });

  final String value;
  final ValueChanged<String> onChange;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  /// While the step's write is in flight: the buttons wait.
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    return StepFrame(
      step: StepId.currency,
      title: l10n.welcomeCurrencyTitle,
      lead: l10n.welcomeCurrencyLead,
      onBack: onBack,
      skip: StepAction(label: l10n.welcomeSkip, onPressed: busy ? null : onSkip),
      next: StepAction(
        label: busy ? l10n.welcomeSaving : l10n.welcomeNext,
        onPressed: busy ? null : onNext,
      ),
      children: [
        Semantics(
          container: true,
          role: SemanticsRole.radioGroup,
          label: l10n.welcomeCurrencyLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: LukitasTokens.space2,
            children: [
              for (final code in supportedCurrencies)
                _CurrencyOption(
                  code: code,
                  name: currencyName(code, locale),
                  selected: value == code,
                  onSelect: () => onChange(code),
                ),
            ],
          ),
        ),
        if (error != null) StepError(error!),
      ],
    );
  }
}

/// `flex min-h-11 items-center gap-3 rounded-lg border-2 border-stroke bg-surface-row px-4 py-3
/// shadow-edge-sm has-checked:border-brand-glow has-focus-visible:outline-3 outline-focus
/// outline-offset-2`: a native radio (20px, `accent-brand`), the currency's name and its code.
class _CurrencyOption extends StatelessWidget {
  const _CurrencyOption({
    required this.code,
    required this.name,
    required this.selected,
    required this.onSelect,
  });

  final String code;
  final String name;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final lk = context.lk;
    final colors = lk.colors;
    final radius = LkSurface.radius(LkRadius.lg);
    return Pressable(
      key: Key('welcome.currency.$code'),
      onPressed: onSelect,
      label: '$name $code',
      checked: selected,
      builder: (context, state) => PressSurface(
        decoration: BoxDecoration(
          color: colors.surfaceRow,
          borderRadius: radius,
          border: Border.all(color: selected ? colors.brandGlow : colors.stroke, width: 2),
          boxShadow: LkSurface.edgeShadow(lk, LkEdge.sm),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LukitasTokens.space4,
          vertical: LukitasTokens.space3,
        ),
        ringRadius: state.focusVisible ? radius : null,
        ringColor: colors.focus,
        child: ExcludeSemantics(
          child: Row(
            spacing: LukitasTokens.space3,
            children: [
              NativeRadio(checked: selected, accent: colors.brand),
              Expanded(
                child: Text(name, style: LkText.copy.copyWith(color: colors.ink)),
              ),
              Text(
                code,
                style: LkText.copy.copyWith(
                  color: colors.inkMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
