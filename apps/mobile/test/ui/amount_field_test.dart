import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/amount_field.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

/// `AmountField`'s behaviour, as apps/web/app/ui/AmountField.tsx defines it. How it looks is the add
/// sheet's pair (Task 8).
class _Field extends StatefulWidget {
  const _Field({
    this.currency = 'EUR',
    this.sign = '',
    this.tone = AmountTone.neutral,
    this.initial = '',
  });

  final String currency;
  final String sign;
  final AmountTone tone;
  final String initial;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late var _raw = widget.initial;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: AmountField(
      raw: _raw,
      onChanged: (next) => setState(() => _raw = next),
      currency: widget.currency,
      sign: widget.sign,
      tone: widget.tone,
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'the figure follows the keypad, formatted in the language, with the sign once there is an amount',
    (t) async {
      await t.pumpWidget(uiApp(const _Field(sign: '−', tone: AmountTone.expense)));
      expect(find.text('0 €'), findsOneWidget, reason: 'no sign before an amount');
      for (final key in ['6', 'decimal', '0']) {
        await t.tap(find.byKey(Key('keypad.$key')));
        await t.pump();
      }
      expect(find.textContaining('−6,0', findRichText: true), findsOneWidget);
    },
  );

  testWidgets('pesos show the lukas hint, muted, after the figure', (t) async {
    await t.pumpWidget(uiApp(const _Field(currency: 'COP', initial: '50000')));
    expect(find.textContaining(r'$50.000', findRichText: true), findsOneWidget);
    expect(find.textContaining('(50 lukas)', findRichText: true), findsOneWidget);
  });

  testWidgets('the tone colours the figure: spending in over, income in good, a budget in ink', (
    t,
  ) async {
    Color colour(WidgetTester t) {
      final figure = find.descendant(of: find.byType(AmountDisplay), matching: find.byType(Text));
      return (t.widget<Text>(figure.first).textSpan! as TextSpan).style!.color!;
    }

    await t.pumpWidget(uiApp(const _Field(tone: AmountTone.expense, initial: '7')));
    expect(colour(t), const Color(0xFFFF5C7A));
    await t.pumpWidget(uiApp(const _Field(tone: AmountTone.income, initial: '7')));
    expect(colour(t), const Color(0xFF7CFFB2));
    await t.pumpWidget(uiApp(const _Field(initial: '7')));
    expect(colour(t), const Color(0xFFF3F0FF));
  });

  testWidgets(
    'a physical keyboard types too, while focus is in the field: digits, the decimal, Backspace',
    (t) async {
      await t.pumpWidget(uiApp(const _Field()));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      for (final (key, character) in [
        (LogicalKeyboardKey.digit4, '4'),
        (LogicalKeyboardKey.comma, ','),
        (LogicalKeyboardKey.digit7, '7'),
        (LogicalKeyboardKey.digit5, '5'),
      ]) {
        await t.sendKeyEvent(key, character: character);
        await t.pump();
      }
      expect(find.textContaining('4,75', findRichText: true), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.backspace);
      await t.pump();
      expect(find.textContaining('4,7 €', findRichText: true), findsOneWidget);
    },
  );

  testWidgets('screen readers hear the amount once typing pauses, not at every key', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(uiApp(const _Field()));
    await t.tap(find.byKey(const Key('keypad.1')));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byKey(const Key('keypad.2')));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('12 €'), findsNothing, reason: 'still typing');
    await t.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel('12 €'), findsOneWidget);
    handle.dispose();
  });
}
