// The web's ThemeToggle (apps/web/app/ui/ThemeToggle.tsx).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../settings/preferences.dart';
import 'lk_icons.dart';
import 'press_button.dart';

/// The day/night switch: a compact pressable icon button. It shows the theme that is on (a moon at
/// night, a sun by day) and its name says what a press does ("Cambiar a modo día"). It is an
/// action, not a toggle state. A press keeps an explicit choice, which replaces "Sistema".
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final night = Theme.of(context).brightness == Brightness.dark;
    return PressButton(
      tone: PressTone.secondary,
      size: PressSize.sm,
      padding: EdgeInsets.zero,
      semanticLabel: night ? l10n.themeSwitchToDay : l10n.themeSwitchToNight,
      onPressed: () =>
          ref.read(themeModeProvider.notifier).set(night ? ThemeMode.light : ThemeMode.dark),
      child: ThemeIcon(night: night),
    );
  }
}
