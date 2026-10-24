import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/theme/theme.dart';
import 'package:lukitas/ui/amount_field.dart' show AmountDisplay;
import 'package:lukitas/ui/lk_theme.dart';

import '../home/fakes.dart';
import '../support/screen_pixels.dart';
import '../home/fixtures.dart';
import 'budgets_test.dart' show openBudgetSheet, pumpBudgets;
import 'fakes.dart';

/// The budget sheet on the phones it has to fit: its keypad's last row (",", 0, ⌫) must be whole
/// and tappable above "Guardar presupuesto", never cut by it. The founder's Galaxy S25 Ultra is
/// about 412 × 915 with a gesture bar under it; the short one is 360 × 640; and a big font makes
/// every row taller.

/// Euros, as the founder's account: the keypad has the decimal key the pesos' has not.
FakeHomeRepository _euros() => FakeHomeRepository(
  currency: 'EUR',
  categoryList: [category('cat-groceries', 'Supermercado', icon: '🛒')],
  items: [tx('market', '2026-10-21', -22293, name: 'Mercado')],
);

const _keys = [
  'keypad.1',
  'keypad.2',
  'keypad.3',
  'keypad.4',
  'keypad.5',
  'keypad.6',
  'keypad.7',
  'keypad.8',
  'keypad.9',
  'keypad.decimal',
  'keypad.0',
  'keypad.backspace',
];

/// The pixels of the key's solid edge under it (`0 3px 0`).
const _keyEdge = 3.0;

Future<void> _openOn(
  WidgetTester tester, {
  required Size size,
  required double inset,
  double textScale = 1,
}) async {
  final home = _euros();
  await pumpBudgets(
    tester,
    home: home,
    budgets: FakeBudgetsRepository(home),
    location: '/categories/cat-groceries',
  );
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1
    ..viewPadding = FakeViewPadding(bottom: inset)
    ..padding = FakeViewPadding(bottom: inset);
  addTearDown(tester.view.resetViewPadding);
  addTearDown(tester.view.resetPadding);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpAndSettle();
  // The detail's button may be below the fold of a short phone: a person scrolls to it.
  await tester.ensureVisible(find.byKey(const Key('detail.changeBudget')));
  await tester.pumpAndSettle();
  await openBudgetSheet(tester);
}

/// The figure the sheet shows, as a person reads it.
String _amount(WidgetTester tester) {
  final texts = tester.widgetList<Text>(
    find.descendant(of: find.byType(AmountDisplay), matching: find.byType(Text)),
  );
  return [for (final t in texts) t.textSpan?.toPlainText() ?? t.data ?? ''].first
      .replaceAll(RegExp(r'[\u00a0\u202f]'), ' ')
      .trim();
}

void main() {
  const phones = {
    'the S25 Ultra, 412 × 915 with a gesture bar': (Size(412, 915), 24.0),
    'the same with a thick bar (48)': (Size(412, 915), 48.0),
    'a short phone, 360 × 640': (Size(360, 640), 24.0),
    'the short phone with a navigation bar (48)': (Size(360, 640), 48.0),
  };
  for (final MapEntry(key: name, value: (size, inset)) in phones.entries) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('$name, text ×$scale: every key is whole above Guardar', (tester) async {
        await _openOn(tester, size: size, inset: inset, textScale: scale);
        final save = tester.getRect(find.byKey(const Key('budget.save')));
        final screen = Offset.zero & size;
        for (final id in _keys) {
          final key = tester.getRect(find.byKey(Key(id)));
          expect(
            key.bottom + _keyEdge,
            lessThanOrEqualTo(save.top),
            reason: '$id (${key.top}-${key.bottom}) is above Guardar (from ${save.top})',
          );
          expect(screen.contains(key.topLeft) && screen.contains(key.bottomRight), isTrue);
        }
        expect(save.bottom, lessThanOrEqualTo(size.height - inset), reason: 'Guardar is in view');
        // And tappable: a tap on the last row's keys lands on them (it types, and erases).
        await tester.tap(find.byKey(const Key('keypad.5')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('keypad.0')));
        await tester.pump();
        expect(_amount(tester), '50 €');
        await tester.tap(find.byKey(const Key('keypad.backspace')));
        await tester.pump();
        expect(_amount(tester), '5 €');
        await tester.tap(find.byKey(const Key('keypad.decimal')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('keypad.5')));
        await tester.pump();
        expect(_amount(tester), '5,5 €');
      });
    }
  }

  testWidgets('the last row\'s solid edge is drawn whole, not cut by the footer\'s line', (
    tester,
  ) async {
    await _openOn(tester, size: const Size(412, 915), inset: 24);
    final context = tester.element(find.byKey(const Key('keypad.0')));
    final edge = context.lkColors.keyEdge;
    final key = tester.getRect(find.byKey(const Key('keypad.0')));
    final pixels = await ScreenPixels.capture(tester);
    // The pixels under the last key are its solid edge (`0 3px 0`), the same as under the keys
    // above it, not the footer's line.
    final above = tester.getRect(find.byKey(const Key('keypad.7')));
    for (final dy in [0.5, 1.5, 2.5]) {
      expect(
        pixels.at(key.center.dx, key.bottom + dy),
        pixels.at(above.center.dx, above.bottom + dy),
        reason: '${dy.toStringAsFixed(1)}px under the last key',
      );
    }
    expect(pixels.at(key.center.dx, key.bottom + 0.5), edge.toARGB32());
  });
}
