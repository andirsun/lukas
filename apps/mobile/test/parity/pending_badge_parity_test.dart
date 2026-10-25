@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/pending_badge.dart';

import '../support/parity.dart';

/// `PendingBadge` against apps/web/app/ui/PendingBadge.stories.tsx (`ui-pendingbadge--*`), each
/// story as Storybook shows it after its `play` function: the story taps the badge, which leaves
/// keyboard-style focus on it (its ring), so the app's side taps it and then tabs to it.
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

Future<void> _tapThenTab(WidgetTester t, {int taps = 1}) async {
  for (var i = 0; i < taps; i++) {
    await t.tap(find.byType(PendingBadge));
    await t.pumpAndSettle();
  }
  await t.sendKeyEvent(LogicalKeyboardKey.tab);
}

/// `IdleToPaid`: `onPay` resolves, so the badge ends as "✓ Pagado"; a second tap changes nothing.
Widget _resolves() => ParityStoryFrame(child: PendingBadge(onPay: () async {}));

/// `Paying`: `onPay` never resolves, so the badge ends busy.
Widget _never() => ParityStoryFrame(child: PendingBadge(onPay: () => Completer<void>().future));

/// `PayFails`: `onPay` rejects, so the badge is back to "Pendiente".
Widget _fails() =>
    ParityStoryFrame(child: PendingBadge(onPay: () => Future<void>.error(Exception('offline'))));

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('pending badge parity: idle, tapped, paid ($theme)', (t) async {
      // The story taps the paid badge a second time: nothing happens.
      await parityGolden(
        t,
        'pending-badge-idle-to-paid',
        _resolves(),
        theme: theme,
        act: (t) => _tapThenTab(t, taps: 2),
      );
    });

    testWidgets('pending badge parity: paying, busy ($theme)', (t) async {
      await parityGolden(t, 'pending-badge-paying', _never(), theme: theme, act: _tapThenTab);
    });

    testWidgets('pending badge parity: paying fails, back to Pendiente ($theme)', (t) async {
      await parityGolden(t, 'pending-badge-pay-fails', _fails(), theme: theme, act: _tapThenTab);
    });
  }

  testWidgets('pending badge parity: paid, day, English (day)', (t) async {
    await parityGolden(
      t,
      'pending-badge-day-english',
      _resolves(),
      theme: 'day',
      locale: const Locale('en'),
      act: _tapThenTab,
    );
  });
}
