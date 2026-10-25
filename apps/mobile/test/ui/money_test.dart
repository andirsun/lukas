import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/theme/tokens.g.dart';
import 'package:lukitas/ui/money.dart';

/// `Money`'s behaviour, as apps/web/app/ui/Money.tsx and its stories define it. How it looks is
/// test/parity/money_parity_test.dart's job.
Widget _app(Widget child, {Locale locale = const Locale('es'), bool reduceMotion = false}) =>
    Localizations(
      locale: locale,
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: child),
        ),
      ),
    );

/// What is drawn (the counting figure, when there is one). In Spanish a no-break space comes
/// before the euro sign, as the web's Intl writes it.
String _shown(WidgetTester tester) => tester.widget<Text>(find.byType(Text)).data!;

void main() {
  testWidgets('writes the amount in the app\'s language: 562,92 € and €562.92', (tester) async {
    await tester.pumpWidget(_app(const Money(cents: 56292, currency: 'EUR')));
    expect(_shown(tester), '562,92\u00a0€');
    await tester.pumpWidget(
      _app(const Money(cents: 56292, currency: 'EUR'), locale: const Locale('en')),
    );
    expect(_shown(tester), '€562.92');
  });

  testWidgets('expenses carry the real minus sign (U+2212), never a hyphen', (tester) async {
    await tester.pumpWidget(_app(const Money(cents: -608, currency: 'EUR')));
    expect(_shown(tester), '−6,08\u00a0€');
    expect(_shown(tester), isNot(contains('-')));
  });

  testWidgets('figures are tabular (`lk-num`), whatever style it is given', (tester) async {
    await tester.pumpWidget(
      _app(const Money(cents: -608, currency: 'EUR', style: TextStyle(fontSize: 14))),
    );
    final style = tester.widget<Text>(find.byType(Text)).style!;
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(style.fontSize, 14);
  });

  testWidgets('with animate, a new value counts up over --count-up, and assistive technology '
      'reads the final amount at once', (tester) async {
    final handle = tester.ensureSemantics();
    Widget money(int cents) => _app(Money(cents: cents, currency: 'EUR', animate: true));
    await tester.pumpWidget(money(56292));
    expect(_shown(tester), '562,92\u00a0€');

    await tester.pumpWidget(money(55684));
    await tester.pump(LukitasTokens.durationCountUp * 0.2);
    // Mid-count: the drawn figure is on its way, the spoken one is already final.
    expect(_shown(tester), isNot('556,84\u00a0€'));
    expect(_shown(tester), isNot('562,92\u00a0€'));
    expect(find.bySemanticsLabel('556,84\u00a0€'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('562')), findsNothing);

    await tester.pump(LukitasTokens.durationCountUp);
    expect(_shown(tester), '556,84\u00a0€');
    handle.dispose();
  });

  testWidgets('without animate, a new value just shows', (tester) async {
    await tester.pumpWidget(_app(const Money(cents: 56292, currency: 'EUR')));
    await tester.pumpWidget(_app(const Money(cents: 55684, currency: 'EUR')));
    expect(_shown(tester), '556,84\u00a0€');
  });

  testWidgets('under reduced motion, no count-up: the new amount shows at once', (tester) async {
    Widget money(int cents) =>
        _app(Money(cents: cents, currency: 'EUR', animate: true), reduceMotion: true);
    await tester.pumpWidget(money(56292));
    await tester.pumpWidget(money(55684));
    expect(_shown(tester), '556,84\u00a0€');
    await tester.pump(const Duration(milliseconds: 150));
    expect(_shown(tester), '556,84\u00a0€');
  });

  testWidgets('with countFrom, it counts up from that value when it first shows', (tester) async {
    await tester.pumpWidget(
      _app(const Money(cents: 56292, currency: 'EUR', animate: true, countFrom: 0)),
    );
    expect(_shown(tester), '0,00\u00a0€');
    await tester.pump(LukitasTokens.durationCountUp * 0.5);
    expect(_shown(tester), isNot('0,00\u00a0€'));
    await tester.pumpAndSettle();
    expect(_shown(tester), '562,92\u00a0€');
  });
}
