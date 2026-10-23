@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/keypad_input.dart';
import 'package:lukitas/theme/text_styles.dart';
import 'package:lukitas/ui/keypad.dart';
import 'package:lukitas/ui/lk_theme.dart';

import '../support/parity.dart';

/// `Keypad` against apps/web/app/ui/Keypad.stories.tsx (`ui-keypad--*`), each story as Storybook
/// shows it after its `play` function, in night and in day (`Day` pins day).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The stories' `KeypadHarness`: the raw text in the amount's style, the cents it parses to, and
/// the keypad, in a column 320px wide with a 12px gap (`flex max-w-[320px] flex-col gap-3`).
class _Harness extends StatefulWidget {
  const _Harness({required this.locale, this.currency});

  final String locale;
  final String? currency;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  var _value = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final cents = _value.isEmpty ? '' : '${centsOf(_value, widget.locale)}';
    return ParityStoryFrame(
      block: true,
      child: cssBlock(
        maxWidth: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            // An empty `<output>` has no line box: no height.
            if (_value.isNotEmpty)
              Text(
                _value,
                textAlign: TextAlign.center,
                style: LkText.display.copyWith(color: colors.ink),
              ),
            if (cents.isNotEmpty) Text(cents, style: TextStyle(color: colors.inkMuted)),
            Keypad(
              value: _value,
              locale: widget.locale,
              currency: widget.currency,
              onChange: (next) => setState(() => _value = next),
            ),
          ],
        ),
      ),
    );
  }
}

/// `press(canvas, ...keys)`: a tap on each key, found by its text.
Future<void> _press(WidgetTester t, List<String> keys) async {
  for (final key in keys) {
    await t.tap(find.byKey(Key('keypad.${key == ',' || key == '.' ? 'decimal' : key}')));
    await t.pump();
  }
  await t.pumpAndSettle();
}

/// `userEvent.click` focuses the key it clicked, and Chrome counts that as the keyboard: the
/// ring is on the last key. In the app it takes that many Tab presses (the keys are in reading
/// order).
Future<void> _focusKey(WidgetTester t, int tabs) async {
  for (var i = 0; i < tabs; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('keypad parity: Spanish, 6,08 ($theme)', (t) async {
      await parityGolden(
        t,
        'keypad-spanish',
        const _Harness(locale: 'es'),
        theme: theme,
        act: (t) async {
          await _press(t, ['6', ',', '0', '8']);
          await _focusKey(t, 8);
        },
      );
    });

    testWidgets('keypad parity: English, 6.08 ($theme)', (t) async {
      await parityGolden(
        t,
        'keypad-english',
        const _Harness(locale: 'en'),
        theme: theme,
        locale: const Locale('en'),
        act: (t) async {
          await _press(t, ['6', '.', '0', '8']);
          await _focusKey(t, 8);
        },
      );
    });

    testWidgets('keypad parity: pesos have no decimal key ($theme)', (t) async {
      await parityGolden(
        t,
        'keypad-pesos',
        const _Harness(locale: 'es', currency: 'COP'),
        theme: theme,
        act: (t) async {
          await _press(t, ['1', '2', '0', '0', '0', '0', '0', '0']);
          await _focusKey(t, 10);
        },
      );
    });

    testWidgets('keypad parity: capped at 999.999.999,99 ($theme)', (t) async {
      await parityGolden(
        t,
        'keypad-max-length',
        const _Harness(locale: 'es'),
        theme: theme,
        act: (t) async {
          await _press(t, [for (var i = 0; i < 11; i++) '9', ',', '9', '9']);
          await _focusKey(t, 9);
        },
      );
    });

    testWidgets('keypad parity: a key pressed with the keyboard ($theme)', (t) async {
      await parityGolden(
        t,
        'keypad-press-and-focus',
        const _Harness(locale: 'es'),
        theme: theme,
        act: (t) async {
          await _focusKey(t, 1);
          await t.sendKeyEvent(LogicalKeyboardKey.enter);
        },
      );
    });
  }

  testWidgets('keypad parity: day, 4,75 (day)', (t) async {
    await parityGolden(
      t,
      'keypad-day',
      const _Harness(locale: 'es'),
      theme: 'day',
      act: (t) async {
        await _press(t, ['4', ',', '7', '5']);
        await _focusKey(t, 5);
      },
    );
  });
}
