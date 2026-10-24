@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/budget_bar.dart';
import 'package:lukitas/ui/category_row.dart';

import '../support/parity.dart';

/// `CategoryRow` against apps/web/app/ui/CategoryRow.stories.tsx (`ui-categoryrow--*`), each story
/// as Storybook shows it after its `play` function, in night and in day (`OverDayEnglish` pins
/// day).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The stories' decorator: `<div className="max-w-[360px]">` around the row.
Widget _row(CategoryRow row) =>
    ParityStoryFrame(block: true, child: cssBlock(maxWidth: 360, child: row));

/// The stories' default args: Supermercado, 19,412 of 180,00 spent, over.
CategoryRow _category({
  String name = 'Supermercado',
  String glyph = '🛒',
  Color tint = const Color(0xFF4A2140),
  int? budget = 18000,
  int spent = 19412,
  int? remaining = -1412,
  BudgetState state = BudgetState.over,
}) => CategoryRow(
  name: name,
  glyph: glyph,
  tint: tint,
  budget: budget,
  spent: spent,
  remaining: remaining,
  state: state,
  currency: 'EUR',
  onOpen: () {},
);

CategoryRow _restaurante() => _category(
  name: 'Restaurante',
  glyph: '🍽️',
  tint: const Color(0xFF4A2A30),
  budget: 30000,
  spent: 25367,
  remaining: 4633,
  state: BudgetState.near,
);

CategoryRow _ocio() => _category(
  name: 'Ocio',
  glyph: '⭐',
  tint: const Color(0xFF3B2560),
  budget: 65000,
  spent: 26280,
  remaining: 38720,
  state: BudgetState.ok,
);

CategoryRow _regalos() => _category(
  name: 'Regalos',
  glyph: '🎁',
  tint: const Color(0xFF2B2A5A),
  budget: null,
  spent: 2500,
  remaining: null,
  state: BudgetState.ok,
);

Future<void> _tab(WidgetTester t, int times) async {
  for (var i = 0; i < times; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('category row parity: over budget, opened ($theme)', (t) async {
      await parityGolden(
        t,
        'category-row-over',
        _row(_category()),
        theme: theme,
        act: (t) async {
          await t.tap(find.byType(CategoryRow));
          await t.pumpAndSettle();
          await _tab(t, 1);
        },
      );
    });

    testWidgets('category row parity: near the limit ($theme)', (t) async {
      await parityGolden(t, 'category-row-near', _row(_restaurante()), theme: theme);
    });

    testWidgets('category row parity: within budget ($theme)', (t) async {
      await parityGolden(t, 'category-row-ok', _row(_ocio()), theme: theme);
    });

    testWidgets('category row parity: without a budget ($theme)', (t) async {
      await parityGolden(t, 'category-row-no-budget', _row(_regalos()), theme: theme);
    });

    testWidgets('category row parity: focused and opened with the keyboard ($theme)', (t) async {
      await parityGolden(
        t,
        'category-row-press-and-focus',
        _row(_category()),
        theme: theme,
        act: (t) async {
          await _tab(t, 1);
          await t.sendKeyEvent(LogicalKeyboardKey.enter);
        },
      );
    });

    testWidgets('category row parity: without a budget, English ($theme)', (t) async {
      await parityGolden(
        t,
        'category-row-no-budget-english',
        _row(_regalos()),
        theme: theme,
        locale: const Locale('en'),
      );
    });
  }

  testWidgets('category row parity: over budget, day, English (day)', (t) async {
    await parityGolden(
      t,
      'category-row-over-day-english',
      _row(_category()),
      theme: 'day',
      locale: const Locale('en'),
    );
  });
}
