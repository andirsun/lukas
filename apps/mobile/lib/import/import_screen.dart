// The web's import page (apps/web/app/features/onboarding/ImportPage.tsx), as far as its head: Lukitas
// and "Trae tu historial" with its line. Until the import itself is ported, this is all it holds.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../add/add_sheet.dart';
import '../capture/capture_sheet.dart';
import '../home/lukitas_face.dart';
import '../home/shell_navigation.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_theme.dart';
import '../ui/manage_page.dart';
import '../ui/page_header.dart';

/// `/import`: bring a history from another app, reached from home's card and from Settings.
class ImportScreen extends ConsumerWidget {
  const ImportScreen({super.key});

  void _back(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.lkColors;
    return ManagePage(
      key: const Key('import.page'),
      current: 'import',
      onAdd: () => unawaited(openAddSheet(context)),
      onMic: () => unawaited(openCapture(context, listen: true)),
      onNavigate: (to) => navigateFromShell(context, ref, to, current: 'import'),
      header: PageHeader(
        backLabel: l10n.manageBack,
        backShort: l10n.manageBackShort,
        onBack: () => _back(context),
      ),
      children: [
        Row(
          spacing: LukitasTokens.space3,
          children: [
            const LukitasFace(mood: LukitasMood.happy, size: 72, decorative: true),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.importPageTitle,
                  style: LkText.pageTitle.copyWith(color: colors.ink, fontSize: 26, height: 1.25),
                ),
              ),
            ),
          ],
        ),
        Text(l10n.importPageLead, style: LkText.body.copyWith(color: colors.inkMuted)),
      ],
    );
  }
}
