// The web's recurring page (apps/web/app/features/recurring/RecurringPage.tsx), as it looks while
// its lists load: the back link, the title and the add button, which waits for the categories.
// Until the recurring payments themselves are ported, this is all the page holds.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../add/add_sheet.dart';
import '../capture/capture_sheet.dart';
import '../home/shell_navigation.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_theme.dart';
import '../ui/manage_page.dart';
import '../ui/page_header.dart';
import '../ui/press_button.dart';

/// `/recurring`: the recurring payments, reached from the face menu's Recurrentes.
class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

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
      key: const Key('recurring.page'),
      current: 'recurring',
      onAdd: () => unawaited(openAddSheet(context)),
      onMic: () => unawaited(openCapture(context, listen: true)),
      onNavigate: (to) => navigateFromShell(context, ref, to, current: 'recurring'),
      header: PageHeader(
        backLabel: l10n.manageBack,
        backShort: l10n.manageBackShort,
        onBack: () => _back(context),
      ),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: LukitasTokens.space2,
          runSpacing: LukitasTokens.space2,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.recurringTitle, style: LkText.pageTitle.copyWith(color: colors.ink)),
            ),
            // Off, as the web's while the categories load.
            PressButton(
              onPressed: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: LukitasTokens.space2,
                children: [
                  const ExcludeSemantics(child: Text('＋')),
                  Text(LkText.upperCase(l10n.recurringAdd)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
