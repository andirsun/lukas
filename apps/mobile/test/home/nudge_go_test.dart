import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/bottom_bar.dart';
import 'package:lukitas/ui/category_row.dart';

import '../budgets/budgets_test.dart' show pumpBudgets;
import '../budgets/fakes.dart';
import 'fakes.dart';
import 'fixtures.dart';

/// The home card "Ponle presupuesto a tus categorías": on the web "Ir a Categorías" opens the
/// categories page, which the app has not; in the app the categories are Presupuestos, a tab of
/// home. So the button must show that tab, with the categories in view, not leave the card on
/// screen with a thumb that moved somewhere below it.

FakeHomeRepository _noBudgets() => FakeHomeRepository(
  categoryList: [for (var i = 0; i < 12; i++) category('cat-$i', 'Categoría $i')],
  items: [tx('a', '2026-10-21', -18000, name: 'Mercado')],
);

void main() {
  for (final size in const [Size(412, 915), Size(360, 640)]) {
    testWidgets('on a ${size.width.toInt()} × ${size.height.toInt()} phone "Ir a Categorías" shows '
        'Presupuestos with the first category in view', (tester) async {
      final home = _noBudgets();
      await pumpBudgets(tester, home: home, budgets: FakeBudgetsRepository(home));
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(find.text('Ponle presupuesto a tus categorías'), findsOneWidget);
      expect(find.byType(CategoryRow), findsNothing, reason: 'Movimientos is showing');

      await tester.tap(find.text('IR A CATEGORÍAS'));
      await tester.pumpAndSettle();

      // The tab is Presupuestos, and the tabs' strip has come up to the top of the screen: the
      // card above it is scrolled away, the categories fill the screen.
      expect(find.byType(CategoryRow), findsWidgets);
      expect(find.text('Mercado'), findsNothing);
      expect(tester.getTopLeft(find.text('Presupuestos')).dy, lessThan(80));
      final first = tester.getRect(find.byType(CategoryRow).first);
      final bar = tester.getTopLeft(find.byType(BottomBar)).dy;
      expect(first.top, greaterThan(0));
      expect(first.bottom, lessThanOrEqualTo(bar), reason: 'the first category is above the bar');
    });
  }

  testWidgets('and from a list scrolled down, it brings the strip to the top too', (tester) async {
    final home = FakeHomeRepository(
      categoryList: [for (var i = 0; i < 12; i++) category('cat-$i', 'Categoría $i')],
      items: [
        for (var i = 1; i <= 20; i++)
          tx('t$i', '2026-10-${i.toString().padLeft(2, '0')}', -100 - i, name: 'Gasto $i'),
      ],
    );
    await pumpBudgets(tester, home: home, budgets: FakeBudgetsRepository(home));
    // The nudge is at the top of the page: scrolled a little, the button is still in view.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('IR A CATEGORÍAS'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryRow), findsWidgets);
    expect(tester.getTopLeft(find.text('Presupuestos')).dy, lessThan(80));
  });
}
