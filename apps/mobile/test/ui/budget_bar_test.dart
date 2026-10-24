import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/theme/text_styles.dart';
import 'package:lukitas/ui/budget_bar.dart';
import 'package:lukitas/ui/money.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

/// `BudgetBar`'s behaviour, as apps/web/app/ui/BudgetBar.tsx and its stories define it. How it
/// looks is test/parity/budget_bar_parity_test.dart's job.
double _fill(WidgetTester t) {
  final fill = find.descendant(
    of: find.byType(BudgetBar),
    matching: find.byType(FractionallySizedBox),
  );
  return t.widget<FractionallySizedBox>(fill).widthFactor!;
}

void main() {
  setUpAll(loadAppFonts);

  group('the share of the budget spent, as the web\'s fillWidth', () {
    test('is the ratio, rounded to a tenth of a percent', () {
      expect(BudgetBar.fillFraction(25813, 64533), 0.4);
      expect(BudgetBar.fillFraction(26254, 30887), 0.85);
      expect(BudgetBar.fillFraction(1, 3), 0.333);
    });

    test('is capped at full when over budget', () {
      expect(BudgetBar.fillFraction(41412, 27300), 1);
    });

    test('is empty at zero, and a negative spend is zero', () {
      expect(BudgetBar.fillFraction(0, 100), 0);
      expect(BudgetBar.fillFraction(-5, 100), 0);
    });

    test('with a budget of nothing it is full once something was spent', () {
      expect(BudgetBar.fillFraction(10, 0), 1);
      expect(BudgetBar.fillFraction(0, 0), 0);
    });
  });

  testWidgets('it fills to the share, and an empty track has nothing to measure', (t) async {
    await t.pumpWidget(
      uiApp(
        const BudgetBar(spent: 2000, budget: 10000, state: BudgetState.ok, label: 'Transporte'),
      ),
    );
    expect(_fill(t), 0.2);
    await t.pumpWidget(
      uiApp(const BudgetBar(spent: 4550, budget: null, state: BudgetState.ok, label: 'Regalos')),
    );
    await t.pumpAndSettle();
    expect(_fill(t), 0);
  });

  testWidgets('a change of spent is followed over --count-up (700 ms), eased out', (t) async {
    Widget bar(int spent) =>
        uiApp(BudgetBar(spent: spent, budget: 10000, state: BudgetState.ok, label: 'Ocio'));
    await t.pumpWidget(bar(2000));
    await t.pumpWidget(bar(8000));
    await t.pump(const Duration(milliseconds: 350));
    final midway = _fill(t);
    expect(midway, inExclusiveRange(0.2, 0.8));
    // Ease-out: more than half of the way at half the time.
    expect(midway, greaterThan(0.5));
    await t.pump(const Duration(milliseconds: 400));
    expect(_fill(t), 0.8);
  });

  testWidgets('with "remove animations" the fill just changes', (t) async {
    Widget bar(int spent) => uiApp(
      BudgetBar(spent: spent, budget: 10000, state: BudgetState.ok, label: 'Ocio'),
      disableAnimations: true,
    );
    await t.pumpWidget(bar(2000));
    await t.pumpWidget(bar(8000));
    await t.pump();
    expect(_fill(t), 0.8);
  });

  testWidgets('it is a meter named by its label, over budget clamped to full', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(
      uiApp(
        const BudgetBar(
          spent: 41412,
          budget: 27300,
          state: BudgetState.over,
          label: 'Supermercado · Te pasaste 141,12 €',
        ),
      ),
    );
    final node = t.getSemantics(find.byType(BudgetBar));
    expect(node.label, 'Supermercado · Te pasaste 141,12 €');
    expect(node.value, '100%');
    handle.dispose();
  });

  testWidgets('without a budget the bar is hidden from assistive technology', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(
      uiApp(
        const BudgetBar(
          spent: 4550,
          budget: null,
          state: BudgetState.ok,
          label: 'Regalos · Sin presupuesto',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Regalos · Sin presupuesto'), findsNothing);
    handle.dispose();
  });

  testWidgets('it is 12px tall, or 7px small', (t) async {
    await t.pumpWidget(
      uiApp(const BudgetBar(spent: 1, budget: 2, state: BudgetState.ok, label: 'a')),
    );
    expect(t.getSize(find.byType(BudgetBar)).height, 12);
    await t.pumpWidget(
      uiApp(
        const BudgetBar(
          spent: 1,
          budget: 2,
          state: BudgetState.ok,
          size: BudgetBarSize.sm,
          label: 'a',
        ),
      ),
    );
    expect(t.getSize(find.byType(BudgetBar)).height, 7);
  });

  // Review Focus 1: "$1.500.000.000" beside its bar, at 130% of the font on a 360px phone.
  testWidgets('a budget of \$1.500.000.000 beside its bar fits a 360px phone at 130%', (t) async {
    await t.pumpWidget(
      uiApp(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Money(cents: 150000000000, currency: 'COP', style: LkText.amount),
            BudgetBar(
              spent: 120000000000,
              budget: 150000000000,
              state: BudgetState.near,
              label: 'Vivienda',
            ),
          ],
        ),
        width: 360,
        textScale: 1.3,
      ),
    );
    expect(t.takeException(), isNull);
    expect(find.text('\$1.500.000.000'), findsOneWidget);
    expect(_fill(t), 0.8);
  });
}
