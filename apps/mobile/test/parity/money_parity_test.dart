@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/theme/text_styles.dart';
import 'package:lukitas/theme/theme.dart';
import 'package:lukitas/ui/money.dart';

import '../support/parity.dart';

/// `Money` against apps/web/app/ui/Money.stories.tsx (`ui-money--*`), each story as Storybook
/// shows it, in night and in day (the day English one pins day).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The stories' `className`: `lk-hero-amount` (the default args) or `lk-amount` (Negative).
TextStyle _heroAmount(BuildContext context) =>
    LkText.amountXl.copyWith(color: Theme.of(context).extension<LukitasTheme>()!.colors.good);

Widget _story(int cents, TextStyle Function(BuildContext) style) => _storyIn(cents, 'EUR', style);

Widget _storyIn(int cents, String currency, TextStyle Function(BuildContext) style) =>
    ParityStoryFrame(
      child: Builder(
        builder: (context) => Money(cents: cents, currency: currency, style: style(context)),
      ),
    );

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('money parity: Spanish, 562,92 € as the hero amount ($theme)', (t) async {
      await parityGolden(t, 'money-spanish', _story(56292, _heroAmount), theme: theme);
    });

    testWidgets('money parity: English, €562.92 as the hero amount ($theme)', (t) async {
      await parityGolden(
        t,
        'money-english',
        _story(56292, _heroAmount),
        theme: theme,
        locale: const Locale('en'),
      );
    });

    testWidgets('money parity: negative, −6,08 € as a row amount ($theme)', (t) async {
      await parityGolden(t, 'money-negative', _story(-608, (_) => LkText.amount), theme: theme);
    });
  }

  // Review Focus 1: pesos are written whole, and $1.500.000.000 fits the hero's line.
  for (final theme in ['night', 'day']) {
    testWidgets('money parity: \$1.500.000.000 as the hero amount ($theme)', (t) async {
      await parityGolden(
        t,
        'money-huge-amount',
        _storyIn(150000000000, 'COP', _heroAmount),
        theme: theme,
      );
    });
  }

  testWidgets('money parity: negative by day in English, −€6.08 (day)', (t) async {
    await parityGolden(
      t,
      'money-negative-day-english',
      _story(-608, (_) => LkText.amount),
      theme: 'day',
      locale: const Locale('en'),
    );
  });
}
