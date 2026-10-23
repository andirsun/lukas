import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/bottom_bar.dart';
import 'package:lukitas/ui/category_row.dart';
import 'package:lukitas/ui/transaction_row.dart';

import '../budgets/budgets_test.dart' show pumpBudgets;
import '../budgets/fakes.dart' show budgetsMonth;
import 'fakes.dart';
import 'fixtures.dart';
import 'home_harness.dart';

/// The room a list leaves under its last row, as the web's `pb-[calc(112px+env(safe-area-inset-bottom))]`:
/// on a short phone with a system navigation bar the last row must scroll fully clear of the
/// bottom bar (and of the raised ＋), not end under it.
void _insetBottom(WidgetTester tester, double inset) {
  tester.view.viewPadding = FakeViewPadding(bottom: inset);
  tester.view.padding = FakeViewPadding(bottom: inset);
  addTearDown(tester.view.resetViewPadding);
  addTearDown(tester.view.resetPadding);
}

Future<void> _toTheEnd(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
  await tester.pumpAndSettle();
}

/// The top of what the bottom bar covers: the bar, or the ＋ that rises above it.
double _barTop(WidgetTester tester) {
  final bar = tester.getTopLeft(find.byType(BottomBar)).dy;
  final add = tester.getTopLeft(find.byKey(const Key('home.add'))).dy;
  return add < bar ? add : bar;
}

void main() {
  testWidgets(
    'on a short phone with a system bar, the last movement scrolls clear of the bottom bar',
    (tester) async {
      final repo = FakeHomeRepository(
        budgetTotal: 100000000,
        items: [
          for (var i = 0; i < 12; i++)
            tx('t$i', '2026-10-${10 + i}', -100000 - i, name: 'Compra $i'),
        ],
      );
      await pumpHome(tester, repo, size: const Size(360, 640));
      _insetBottom(tester, 48);
      await tester.pumpAndSettle();
      await _toTheEnd(tester);
      final last = tester.getBottomLeft(find.byType(TransactionRow).last).dy;
      expect(last, lessThanOrEqualTo(_barTop(tester)), reason: 'the last row ends above the bar');
    },
  );

  testWidgets('and so does the last Presupuestos row', (tester) async {
    final home = budgetsMonth();
    for (var i = 0; i < 8; i++) {
      home.categoryList.add(category('cat-$i', 'Categoría $i'));
    }
    await pumpBudgets(tester, home: home);
    tester.view.physicalSize = const Size(360, 640);
    _insetBottom(tester, 48);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Presupuestos'));
    await tester.pumpAndSettle();
    await _toTheEnd(tester);
    final last = tester.getBottomLeft(find.byType(CategoryRow).last).dy;
    expect(last, lessThanOrEqualTo(_barTop(tester)), reason: 'the last row ends above the bar');
  });

  testWidgets('the detail leaves the same room', (tester) async {
    final home = budgetsMonth();
    for (var i = 0; i < 12; i++) {
      home.items.add(tx('g$i', '2026-10-${10 + i}', -100000 - i, name: 'Mercado $i'));
    }
    await pumpBudgets(tester, home: home, location: '/categories/cat-groceries');
    tester.view.physicalSize = const Size(360, 640);
    _insetBottom(tester, 48);
    await tester.pumpAndSettle();
    await _toTheEnd(tester);
    final last = tester.getBottomLeft(find.byType(TransactionRow).last).dy;
    expect(last, lessThanOrEqualTo(_barTop(tester)));
  });
}
