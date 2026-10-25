import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/keypad.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

/// `Keypad`'s behaviour, as apps/web/app/ui/Keypad.tsx and its stories define it. How it looks is
/// test/parity/keypad_parity_test.dart's job.
class _Pad extends StatefulWidget {
  const _Pad({this.locale = 'es', this.currency, this.initial = '', this.changes});

  final String locale;
  final String? currency;
  final String initial;
  final List<String>? changes;

  @override
  State<_Pad> createState() => _PadState();
}

class _PadState extends State<_Pad> {
  late var _value = widget.initial;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(_value, key: const Key('raw')),
      SizedBox(
        width: 320,
        child: Keypad(
          value: _value,
          locale: widget.locale,
          currency: widget.currency,
          onChange: (next) {
            widget.changes?.add(next);
            setState(() => _value = next);
          },
        ),
      ),
    ],
  );
}

String _raw(WidgetTester t) => t.widget<Text>(find.byKey(const Key('raw'))).data!;

Future<void> _press(WidgetTester t, List<String> keys) async {
  for (final key in keys) {
    final id = switch (key) {
      ',' || '.' => 'decimal',
      '⌫' => 'backspace',
      _ => key,
    };
    await t.tap(find.byKey(Key('keypad.$id')));
    await t.pump();
  }
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Spanish: 12 keys, the decimal key is a comma; 6 , 0 8 is "6,08"', (t) async {
    final changes = <String>[];
    await t.pumpWidget(uiApp(_Pad(changes: changes)));
    await _press(t, ['6', ',', '0', '8']);
    expect(_raw(t), '6,08');
    expect(changes.last, '6,08');
    expect(find.text(','), findsOneWidget);
  });

  testWidgets('English: the decimal key is a point', (t) async {
    await t.pumpWidget(uiApp(const _Pad(locale: 'en'), locale: const Locale('en')));
    expect(find.text('.'), findsOneWidget);
    await _press(t, ['6', '.', '0', '8']);
    expect(_raw(t), '6.08');
  });

  testWidgets('at most two decimals, and a second decimal key is ignored and reports nothing', (
    t,
  ) async {
    final changes = <String>[];
    await t.pumpWidget(uiApp(_Pad(changes: changes)));
    await _press(t, ['6', ',', '0', ',']);
    expect(_raw(t), '6,0');
    await _press(t, ['8', '9']);
    expect(_raw(t), '6,08');
    expect(changes, ['6', '6,', '6,0', '6,08'], reason: 'the ignored keys did not report a change');
  });

  testWidgets('a leading decimal becomes 0, and a leading zero is replaced by the next digit', (
    t,
  ) async {
    await t.pumpWidget(uiApp(const _Pad()));
    await _press(t, [',', '5']);
    expect(_raw(t), '0,5');
    await _press(t, ['⌫', '⌫', '⌫']);
    expect(_raw(t), '');
    await _press(t, ['0', '0', '7']);
    expect(_raw(t), '7');
  });

  testWidgets('backspace removes the last character and does nothing on an empty value', (t) async {
    final changes = <String>[];
    await t.pumpWidget(uiApp(_Pad(initial: '6,08', changes: changes)));
    await _press(t, ['⌫', '⌫', '⌫', '⌫', '⌫']);
    expect(_raw(t), '');
    expect(changes, ['6,0', '6,', '6', ''], reason: 'the fifth press changed nothing');
  });

  testWidgets('capped at 999.999.999,99: a tenth whole digit is ignored', (t) async {
    await t.pumpWidget(uiApp(const _Pad()));
    await _press(t, [for (var i = 0; i < 11; i++) '9']);
    expect(_raw(t), '999999999');
    await _press(t, [',', '9', '9']);
    expect(_raw(t), '999999999,99');
  });

  testWidgets('pesos are whole: no decimal key and ten-million-peso amounts fit', (t) async {
    await t.pumpWidget(uiApp(const _Pad(currency: 'COP')));
    expect(find.byKey(const Key('keypad.decimal')), findsNothing);
    await _press(t, ['1', '2', '0', '0', '0', '0', '0', '0']);
    expect(_raw(t), '12000000');
  });

  testWidgets('every key is at least a 44px target', (t) async {
    await t.pumpWidget(uiApp(const _Pad()));
    for (final id in ['1', '5', '9', '0', 'decimal', 'backspace']) {
      expect(t.getSize(find.byKey(Key('keypad.$id'))).height, greaterThanOrEqualTo(44));
    }
    expect(t.getSize(find.byKey(const Key('keypad.1'))).height, closeTo(47, 0.5));
  });

  testWidgets('the compact keypad (short phones) keeps 44px targets with tighter gaps', (t) async {
    await t.pumpWidget(
      uiApp(
        SizedBox(
          width: 320,
          child: Keypad(value: '', locale: 'es', onChange: (_) {}, compact: true),
        ),
      ),
    );
    final one = t.getRect(find.byKey(const Key('keypad.1')));
    final four = t.getRect(find.byKey(const Key('keypad.4')));
    expect(one.height, 44);
    expect(four.top - one.bottom, 4);
  });

  testWidgets('a key sinks 3px into its edge while pressed', (t) async {
    await t.pumpWidget(uiApp(const _Pad()));
    final key = find.byKey(const Key('keypad.5'));
    final digit = find.descendant(of: key, matching: find.text('5'));
    final rest = t.getTopLeft(digit).dy;
    final finger = await t.startGesture(t.getCenter(key));
    await t.pump();
    await t.pump(const Duration(milliseconds: 120));
    expect(t.getTopLeft(digit).dy, rest + 3);
    await finger.up();
    await t.pumpAndSettle();
    expect(t.getTopLeft(digit).dy, rest);
  });

  testWidgets('a finger that starts on a key and drags away types nothing', (t) async {
    final changes = <String>[];
    await t.pumpWidget(uiApp(_Pad(changes: changes)));
    await t.drag(find.byKey(const Key('keypad.5')), const Offset(0, 120));
    await t.pumpAndSettle();
    expect(changes, isEmpty);
  });

  testWidgets('Enter on a focused key types it; Tab goes through the keys in order', (t) async {
    await t.pumpWidget(uiApp(const _Pad()));
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(_raw(t), '2');
  });

  testWidgets(
    'screen readers hear "Coma decimal" and "Borrar dígito", the group named, digits as themselves',
    (t) async {
      final handle = t.ensureSemantics();
      await t.pumpWidget(uiApp(const _Pad()));
      expect(find.bySemanticsLabel('Teclado numérico'), findsOneWidget);
      expect(find.bySemanticsLabel('Coma decimal'), findsOneWidget);
      expect(find.bySemanticsLabel('Borrar dígito'), findsOneWidget);
      expect(find.bySemanticsLabel('7'), findsOneWidget);
      handle.dispose();
    },
  );
}
