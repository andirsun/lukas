import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/pending_badge.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

/// `PendingBadge`'s behaviour, as apps/web/app/ui/PendingBadge.tsx and its stories define it. How
/// it looks is test/parity/pending_badge_parity_test.dart's job.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('tapping "Pendiente" pays it; once onPay resolves it is "✓ Pagado", and inert', (
    t,
  ) async {
    var paid = 0;
    await t.pumpWidget(uiApp(Row(children: [PendingBadge(onPay: () async => paid++)])));
    expect(find.text('PENDIENTE'), findsOneWidget);
    await t.tap(find.text('PENDIENTE'));
    await t.pumpAndSettle();
    expect(paid, 1);
    expect(find.text('PAGADO'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget);
    // Paying twice is not possible.
    await t.tap(find.text('PAGADO'));
    await t.pumpAndSettle();
    expect(paid, 1);
  });

  testWidgets('while the request is in flight it ignores further taps', (t) async {
    var calls = 0;
    final pending = Completer<void>();
    await t.pumpWidget(
      uiApp(
        Row(
          children: [
            PendingBadge(
              onPay: () {
                calls++;
                return pending.future;
              },
            ),
          ],
        ),
      ),
    );
    await t.tap(find.text('PENDIENTE'));
    await t.pumpAndSettle();
    await t.tap(find.text('PENDIENTE'));
    await t.pumpAndSettle();
    expect(calls, 1);
    pending.complete();
    await t.pumpAndSettle();
    expect(find.text('PAGADO'), findsOneWidget);
  });

  testWidgets('if paying fails it goes back to "Pendiente" so it can be retried', (t) async {
    var calls = 0;
    await t.pumpWidget(
      uiApp(
        Row(
          children: [
            PendingBadge(
              onPay: () async {
                calls++;
                throw Exception('offline');
              },
            ),
          ],
        ),
      ),
    );
    await t.tap(find.text('PENDIENTE'));
    await t.pumpAndSettle();
    expect(find.text('PENDIENTE'), findsOneWidget);
    expect(find.text('PAGADO'), findsNothing);
    await t.tap(find.text('PENDIENTE'));
    await t.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('paid elsewhere (a swipe on the row) it shows "✓ Pagado" and does not pay', (
    t,
  ) async {
    var calls = 0;
    await t.pumpWidget(
      uiApp(Row(children: [PendingBadge(paid: true, onPay: () async => calls++)])),
    );
    expect(find.text('PAGADO'), findsOneWidget);
    await t.tap(find.text('PAGADO'));
    await t.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets('English: "Pending" and "Paid"', (t) async {
    await t.pumpWidget(
      uiApp(
        Row(children: [PendingBadge(onPay: () async {})]),
        locale: const Locale('en'),
      ),
    );
    expect(find.text('PENDING'), findsOneWidget);
    await t.tap(find.text('PENDING'));
    await t.pumpAndSettle();
    expect(find.text('PAID'), findsOneWidget);
  });

  testWidgets('the button is a 44px target around the smaller pill', (t) async {
    await t.pumpWidget(uiApp(Row(children: [PendingBadge(onPay: () async {})])));
    final target = t.getSize(find.byType(PendingBadge));
    expect(target.height, greaterThanOrEqualTo(44));
    expect(target.width, greaterThanOrEqualTo(44));
    expect(t.getSize(find.text('PENDIENTE')).height, lessThan(20));
  });

  testWidgets('screen readers hear "Pendiente, marcar como pagado", then "Pagado"', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(uiApp(Row(children: [PendingBadge(onPay: () async {})])));
    expect(
      t.getSemantics(find.byType(PendingBadge)),
      matchesSemantics(
        label: 'Pendiente, marcar como pagado',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        isLiveRegion: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    await t.tap(find.text('PENDIENTE'));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('PAGADO')), findsOneWidget);
    expect(find.bySemanticsLabel('Pendiente, marcar como pagado'), findsNothing);
    handle.dispose();
  });
}
