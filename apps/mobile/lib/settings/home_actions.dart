import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/session.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme.dart';

/// What sits beside the month on home: "Guarda tu progreso" for a guest, and the gear that opens
/// Settings.
class HomeActions extends ConsumerWidget {
  const HomeActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final guest = ref.watch(sessionProvider.select((s) => s.isGuest));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (guest)
          Flexible(
            child: TextButton.icon(
              key: const Key('home.saveProgress'),
              style: TextButton.styleFrom(
                foregroundColor: colors.brand,
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              onPressed: () => context.push('/progress'),
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: Text(l10n.progressTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        IconButton(
          key: const Key('home.settings'),
          tooltip: l10n.settingsOpenLabel,
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}
