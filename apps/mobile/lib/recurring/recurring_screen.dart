// The web's recurring page (apps/web/app/features/recurring/RecurringPage.tsx): each recurring
// payment with its rule in words and its next date (today counts), oldest first; tapping one edits
// it, and its sheet deletes it after asking (the transactions it already made stay).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../add/add_sheet.dart';
import '../api/gen/lukitas_api.dart';
import '../capture/capture_sheet.dart';
import '../home/home_controller.dart';
import '../home/lukitas_face.dart';
import '../home/screen_error.dart';
import '../home/shell_navigation.dart';
import '../l10n/app_localizations.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_theme.dart';
import '../ui/lukas_bubble.dart';
import '../ui/manage_page.dart';
import '../ui/page_header.dart';
import '../ui/press_button.dart';
import 'recurring_actions.dart';
import 'recurring_form.dart';
import 'recurring_row.dart';

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
    final home = ref.watch(homeProvider);
    final list = ref.watch(recurringListProvider);
    final data = home.data;
    final rules = list.rules;
    // The web waits for both lists (and the profile, which the shell holds up): the add button
    // needs the categories, the list needs both.
    final failure = rules == null ? list.failure : null;
    final homeFailure = data == null ? home.failure : null;

    final header = PageHeader(
      backLabel: l10n.manageBack,
      backShort: l10n.manageBackShort,
      onBack: () => _back(context),
    );

    final String today = data?.todayAt(ref.read(clockProvider)()) ?? '';
    final byId = data?.categories ?? const <String, Category>{};
    void open([Recurrence? editing]) => unawaited(
      openRecurringForm(
        context,
        editing: editing,
        categories: data!.categories.values.toList(),
        currency: data.currency,
        today: today,
      ),
    );

    final Widget? error = homeFailure != null || failure != null
        ? ScreenError(
            message: (homeFailure ?? failure!).offline ? l10n.errorNetwork : l10n.errorGeneric,
            retryLabel: l10n.retry,
            onRetry: () {
              if (homeFailure != null) unawaited(ref.read(homeProvider.notifier).refresh());
              if (failure != null) unawaited(ref.read(recurringListProvider.notifier).refresh());
            },
          )
        : null;

    return ManagePage(
      key: const Key('recurring.page'),
      current: 'recurring',
      onAdd: () => unawaited(openAddSheet(context)),
      onMic: () => unawaited(openCapture(context, listen: true)),
      onNavigate: (to) => navigateFromShell(context, ref, to, current: 'recurring'),
      header: header,
      // `<main className="flex flex-col gap-(--space-3)">`, with no room under it.
      mainGap: LukitasTokens.space3,
      mainBottom: 0,
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
              key: const Key('recurring.add'),
              onPressed: data == null ? null : open,
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
        ?error,
        if (error == null && data != null && rules != null)
          if (rules.isEmpty)
            LukasBubble(message: l10n.recurringEmpty, mood: LukitasMood.happy)
          else ...[
            Text(l10n.recurringLead, style: LkText.bodySm.copyWith(color: colors.inkMuted)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: LukitasTokens.space2,
              children: [
                for (final rule in rules)
                  RecurringRow(
                    key: ValueKey(rule.id),
                    rule: rule,
                    category: byId[rule.categoryId],
                    currency: data.currency,
                    today: today,
                    onOpen: () => open(rule),
                  ),
              ],
            ),
          ],
      ],
    );
  }
}
