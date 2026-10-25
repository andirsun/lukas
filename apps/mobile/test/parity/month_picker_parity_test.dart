@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/ui/month_picker.dart';

import '../support/parity.dart';

/// `MonthPicker` against apps/web/app/ui/MonthPicker.stories.tsx (`ui-monthpicker--*`), each story
/// as Storybook shows it after its `play` function, in night and in day (the English one pins day).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The story's `MonthPickerHarness`: an inline group, as the story's element is on its line.
class _Harness extends StatefulWidget {
  const _Harness({required this.initial});

  final String initial;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late var _month = widget.initial;

  @override
  Widget build(BuildContext context) =>
      MonthPicker(month: _month, max: '2026-10', onChange: (next) => setState(() => _month = next));
}

Future<void> _tapPrevious(WidgetTester t) async {
  final l10n = AppLocalizations.of(t.element(find.byType(MonthPicker)));
  await t.tap(find.bySemanticsLabel(l10n.monthPickerPrevious));
  await t.pumpAndSettle();
}

Future<void> _tapNext(WidgetTester t) async {
  final l10n = AppLocalizations.of(t.element(find.byType(MonthPicker)));
  await t.tap(find.bySemanticsLabel(l10n.monthPickerNext));
  await t.pumpAndSettle();
}

Future<void> _tab(WidgetTester t, int times) async {
  for (var i = 0; i < times; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('month picker parity: the current month, back and forth ($theme)', (t) async {
      await parityGolden(
        t,
        'month-picker-current-month',
        const ParityStoryFrame(child: _Harness(initial: '2026-10')),
        theme: theme,
        act: (t) async {
          await _tapPrevious(t);
          await _tapNext(t);
        },
      );
    });

    testWidgets('month picker parity: across years, December 2025 ($theme)', (t) async {
      await parityGolden(
        t,
        'month-picker-across-years',
        const ParityStoryFrame(child: _Harness(initial: '2026-01')),
        theme: theme,
        act: (t) async {
          await _tapPrevious(t);
          await _tab(t, 1);
        },
      );
    });

    testWidgets('month picker parity: announced, Septiembre by the keyboard ($theme)', (t) async {
      await parityGolden(
        t,
        'month-picker-announced',
        const ParityStoryFrame(child: _Harness(initial: '2026-10')),
        theme: theme,
        act: (t) async {
          await _tab(t, 1);
          await t.sendKeyEvent(LogicalKeyboardKey.enter);
        },
      );
    });
  }

  testWidgets('month picker parity: November 2025, next, day, English (day)', (t) async {
    await parityGolden(
      t,
      'month-picker-day-english',
      const ParityStoryFrame(child: _Harness(initial: '2025-11')),
      theme: 'day',
      locale: const Locale('en'),
      act: (t) async {
        await _tapNext(t);
        await _tab(t, 2);
      },
    );
  });
}
