@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/press_button.dart';
import 'package:lukitas/ui/sheet.dart';

import '../support/parity.dart';

/// `LkSheet` against apps/web/app/ui/Sheet.stories.tsx (`ui-sheet--*`), each story as Storybook
/// shows it after its `play` function, in night and in day (`OpenDayEnglish` pins day).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The stories' `SheetHarness`: an "Agregar gasto" button that opens a sheet holding Cancelar and
/// Guardar side by side (`lk-row-flex` with `flex-1` buttons).
class _Harness extends StatelessWidget {
  const _Harness({required this.add, required this.cancel, required this.save});

  final String add;
  final String cancel;
  final String save;

  @override
  Widget build(BuildContext context) => ParityStoryFrame(
    child: PressButton.text(
      add,
      onPressed: () => LkSheet.show<void>(
        context,
        title: add,
        children: [
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: PressButton.text(cancel, tone: PressTone.secondary, onPressed: () {}),
              ),
              Expanded(child: PressButton.text(save, onPressed: () {})),
            ],
          ),
        ],
      ),
    ),
  );
}

/// `initiallyOpen`: the sheet is open when the story starts. Then `Open`'s play moves focus with
/// the keyboard: Tab goes Cerrar, Cancelar, Guardar, so Guardar has the ring.
Future<void> _openAndTab(WidgetTester t) async {
  await t.tap(find.byType(PressButton));
  await t.pumpAndSettle();
  for (var i = 0; i < 3; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('sheet parity: open ($theme)', (t) async {
      await parityGolden(
        t,
        'sheet-open',
        const _Harness(add: 'Agregar gasto', cancel: 'Cancelar', save: 'Guardar'),
        theme: theme,
        act: _openAndTab,
      );
    });
  }

  testWidgets('sheet parity: open, day, English (day)', (t) async {
    await parityGolden(
      t,
      'sheet-open-day-english',
      const _Harness(add: 'Add expense', cancel: 'Cancel', save: 'Save'),
      theme: 'day',
      locale: const Locale('en'),
      act: (t) async {
        await t.tap(find.byType(PressButton));
        await t.pumpAndSettle();
      },
    );
  });
}
