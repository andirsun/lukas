@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/theme/text_styles.dart';
import 'package:lukitas/ui/budget_bar.dart';
import 'package:lukitas/ui/money.dart';

import '../support/parity.dart';

/// `BudgetBar` against apps/web/app/ui/BudgetBar.stories.tsx (`ui-budgetbar--*`), each story in
/// night and in day (`OverDay` pins day).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The stories' decorator: `<div className="max-w-[360px]">` around the bar.
Widget _bar(Widget bar) =>
    ParityStoryFrame(block: true, child: cssBlock(maxWidth: 360, child: bar));

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('budget bar parity: ok, 40 % ($theme)', (t) async {
      await parityGolden(
        t,
        'budget-bar-ok',
        _bar(
          const BudgetBar(
            spent: 25813,
            budget: 64533,
            state: BudgetState.ok,
            label: 'Ocio · Quedan 387,20 €',
          ),
        ),
        theme: theme,
      );
    });

    testWidgets('budget bar parity: near, 85 % ($theme)', (t) async {
      await parityGolden(
        t,
        'budget-bar-near',
        _bar(
          const BudgetBar(
            spent: 26254,
            budget: 30887,
            state: BudgetState.near,
            label: 'Restaurante · Quedan 46,33 €',
          ),
        ),
        theme: theme,
      );
    });

    testWidgets('budget bar parity: over, the fill caps at full ($theme)', (t) async {
      await parityGolden(
        t,
        'budget-bar-over',
        _bar(
          const BudgetBar(
            spent: 41412,
            budget: 27300,
            state: BudgetState.over,
            label: 'Supermercado · Te pasaste 141,12 €',
          ),
        ),
        theme: theme,
      );
    });

    testWidgets('budget bar parity: no budget, an empty track ($theme)', (t) async {
      await parityGolden(
        t,
        'budget-bar-no-budget',
        _bar(
          const BudgetBar(
            spent: 4550,
            budget: null,
            state: BudgetState.ok,
            label: 'Regalos · Sin presupuesto',
          ),
        ),
        theme: theme,
      );
    });

    testWidgets('budget bar parity: small, 7 px ($theme)', (t) async {
      await parityGolden(
        t,
        'budget-bar-small',
        _bar(
          const BudgetBar(
            spent: 2000,
            budget: 10000,
            state: BudgetState.ok,
            size: BudgetBarSize.sm,
            label: 'Transporte',
          ),
        ),
        theme: theme,
      );
    });

    // Review Focus 1: a $1.500.000.000 budget above its bar.
    testWidgets('budget bar parity: a budget of \$1.500.000.000 ($theme)', (t) async {
      await parityGolden(
        t,
        'budget-bar-huge-budget',
        _bar(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const Money(cents: 150000000000, currency: 'COP', style: LkText.amount),
              const BudgetBar(
                spent: 120000000000,
                budget: 150000000000,
                state: BudgetState.near,
                label: r'Vivienda · Quedan $300.000.000',
              ),
            ],
          ),
        ),
        theme: theme,
      );
    });
  }

  testWidgets('budget bar parity: over, day, English (day)', (t) async {
    await parityGolden(
      t,
      'budget-bar-over-day-english',
      _bar(
        const BudgetBar(
          spent: 41412,
          budget: 27300,
          state: BudgetState.over,
          label: 'Supermercado · Te pasaste 141,12 €',
        ),
      ),
      theme: 'day',
      locale: const Locale('en'),
    );
  });
}
