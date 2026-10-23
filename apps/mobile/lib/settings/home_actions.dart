import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/session.dart';
import '../home/home_header.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';

/// What the face button's menu on home holds: Ajustes (Settings), and, for a guest, "Guarda tu
/// progreso". Each closes the menu and goes there.
class HomeMenuLinks extends ConsumerWidget {
  const HomeMenuLinks({super.key, required this.close});

  /// Closes the menu.
  final VoidCallback close;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final guest = ref.watch(sessionProvider.select((s) => s.isGuest));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: LukitasTokens.space1,
      children: [
        if (guest)
          HomeMenuLink(
            key: const Key('home.saveProgress'),
            label: l10n.progressTitle,
            onPressed: () {
              close();
              context.push('/progress');
            },
          ),
        HomeMenuLink(
          key: const Key('home.settings'),
          label: l10n.settingsOpenLabel,
          onPressed: () {
            close();
            context.push('/settings');
          },
        ),
      ],
    );
  }
}
