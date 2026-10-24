@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/transaction_row.dart';

import '../support/parity.dart';

/// `TransactionRow` against apps/web/app/ui/TransactionRow.stories.tsx (`ui-transactionrow--*`),
/// each story as Storybook shows it after its `play` function, in night and in day
/// (`PendingDayEnglish` pins day).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The stories' decorator: `<div className="max-w-[360px]">` around the row.
Widget _row(TransactionRow row) =>
    ParityStoryFrame(block: true, child: cssBlock(maxWidth: 360, child: row));

TransactionRow _expense({
  String name = 'continente',
  int amount = -608,
  String categoryName = 'Supermercado',
  String glyph = '🛒',
}) => TransactionRow(
  name: name,
  categoryName: categoryName,
  glyph: glyph,
  amount: amount,
  currency: 'EUR',
  status: TransactionRowStatus.paid,
  onOpen: () {},
);

TransactionRow _spotify({bool pay = true}) => TransactionRow(
  name: 'Spotify',
  categoryName: 'suscripciones',
  glyph: '☂️',
  amount: -353,
  currency: 'EUR',
  status: TransactionRowStatus.pending,
  onOpen: () {},
  onPay: pay ? () async {} : null,
);

Future<void> _tab(WidgetTester t, int times) async {
  for (var i = 0; i < times; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('transaction row parity: an expense, opened ($theme)', (t) async {
      await parityGolden(
        t,
        'transaction-row-expense',
        _row(_expense()),
        theme: theme,
        act: (t) async {
          await t.tap(find.byType(TransactionRow));
          await t.pumpAndSettle();
          // `userEvent.click` leaves the focus on the row, and Chrome rings it.
          await _tab(t, 1);
        },
      );
    });

    testWidgets('transaction row parity: unnamed, titled by its category ($theme)', (t) async {
      await parityGolden(t, 'transaction-row-unnamed', _row(_expense(name: '  ')), theme: theme);
    });

    testWidgets('transaction row parity: income, a plus in good ($theme)', (t) async {
      await parityGolden(
        t,
        'transaction-row-income',
        _row(_expense(name: 'nómina', categoryName: 'Salario', glyph: '💼', amount: 120000)),
        theme: theme,
      );
    });

    testWidgets('transaction row parity: pending, paid from its badge, then opened ($theme)', (
      t,
    ) async {
      await parityGolden(
        t,
        'transaction-row-pending',
        _row(_spotify()),
        theme: theme,
        act: (t) async {
          await t.tap(find.text('PENDIENTE'));
          await t.pumpAndSettle();
          await t.tapAt(t.getTopLeft(find.byType(TransactionRow)) + const Offset(100, 10));
          await t.pumpAndSettle();
          await _tab(t, 1);
        },
      );
    });

    testWidgets('transaction row parity: pending without a way to pay it ($theme)', (t) async {
      await parityGolden(
        t,
        'transaction-row-pending-read-only',
        _row(_spotify(pay: false)),
        theme: theme,
      );
    });

    testWidgets('transaction row parity: focus on the row, then on its badge ($theme)', (t) async {
      await parityGolden(
        t,
        'transaction-row-press-and-focus',
        _row(_spotify()),
        theme: theme,
        act: (t) => _tab(t, 2),
      );
    });
  }

  testWidgets('transaction row parity: pending, day, English (day)', (t) async {
    await parityGolden(
      t,
      'transaction-row-pending-day-english',
      _row(_spotify()),
      theme: 'day',
      locale: const Locale('en'),
    );
  });
}
