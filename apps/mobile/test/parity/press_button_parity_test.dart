@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/press_button.dart';

import '../support/parity.dart';

/// `PressButton` against apps/web/app/ui/PressButton.stories.tsx (`ui-pressbutton--*`), each story
/// as Storybook shows it after its `play` function, in night and in day (the English one pins day).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The story's `Variants`: two rows of buttons in a `lk-pad`. The last one is disabled.
Widget _variants(List<String> labels) {
  void noop() {}
  return ParityStoryFrame(
    block: true,
    child: lkPad([
      lkRowFlex([
        PressButton.text(labels[0], onPressed: noop),
        PressButton.text(labels[1], tone: PressTone.secondary, onPressed: noop),
        PressButton.text(labels[2], tone: PressTone.ghost, onPressed: noop),
      ]),
      lkRowFlex([
        PressButton.text(labels[3], size: PressSize.sm, onPressed: noop),
        PressButton.text(labels[1], tone: PressTone.secondary, size: PressSize.sm, onPressed: noop),
        PressButton.text(labels[4], tone: PressTone.ghost, size: PressSize.sm, onPressed: noop),
        PressButton.text(labels[3]),
      ]),
    ]),
  );
}

const _spanish = ['Agregar gasto', 'Cancelar', 'Ahora no', 'Guardar', 'Cerrar'];
const _english = ['Add expense', 'Cancel', 'Not now', 'Save', 'Close'];

/// The story's `userEvent.tab()`: keyboard focus on the first button, which draws its ring.
Future<void> _tab(WidgetTester t) => t.sendKeyEvent(LogicalKeyboardKey.tab);

/// The story's `is-pressed` on the first three buttons: a finger held on each.
Future<void> _holdFirstThree(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.startGesture(t.getCenter(find.byType(PressButton).at(i)), pointer: i + 1);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('press button parity: all variants ($theme)', (t) async {
      await parityGolden(
        t,
        'press-button-all-variants',
        _variants(_spanish),
        theme: theme,
        act: _tab,
      );
    });

    testWidgets('press button parity: pressed ($theme)', (t) async {
      await parityGolden(
        t,
        'press-button-pressed',
        _variants(_spanish),
        theme: theme,
        act: _holdFirstThree,
      );
    });

    testWidgets('press button parity: keyboard focus ($theme)', (t) async {
      await parityGolden(
        t,
        'press-button-keyboard-focus',
        _variants(_spanish),
        theme: theme,
        act: _tab,
      );
    });
  }

  testWidgets('press button parity: day, English (day)', (t) async {
    await parityGolden(
      t,
      'press-button-day-english',
      _variants(_english),
      theme: 'day',
      locale: const Locale('en'),
    );
  });
}
