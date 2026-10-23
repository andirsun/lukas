import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/theme/text_styles.dart';
import 'package:lukitas/theme/theme.dart';
import 'package:lukitas/theme/tokens.g.dart';

import '../support/fonts.dart';

/// The web's stylesheet and components, relative to apps/mobile (where `flutter test` runs).
const _appCss = '../web/app/styles/app.css';
const _sheetTsx = '../web/app/ui/Sheet.tsx';
const _confirmSheetTsx = '../web/app/ui/ConfirmSheet.tsx';
const _tokensCss = '../web/app/styles/tokens.css';

/// The declarations of `selector { ... }` in app.css, the first rule with exactly that selector.
Map<String, String> _rule(String selector) {
  final css = File(_appCss).readAsStringSync();
  final match = RegExp('\n  ${RegExp.escape(selector)} \\{([^}]*)\\}').firstMatch(css);
  if (match == null) fail('No rule "$selector" in $_appCss');
  return {
    for (final line in match.group(1)!.split(';'))
      if (line.contains(':'))
        line.substring(0, line.indexOf(':')).trim(): line.substring(line.indexOf(':') + 1).trim(),
  };
}

double _px(String value) => double.parse(value.replaceAll('px', ''));

void main() {
  setUpAll(loadAppFonts);

  group('the families', () {
    test('the display and text families are Fredoka and Nunito, as in tokens.css', () {
      // tokens.css:119-121 --font-display "Fredoka", --font-text "Nunito".
      final tokens = File(_tokensCss).readAsStringSync();
      expect(tokens, contains('--font-display: "Fredoka"'));
      expect(tokens, contains('--font-text: "Nunito"'));
      expect(LkText.displayFamily, 'Fredoka');
      expect(LkText.textFamily, 'Nunito');
    });

    test('the theme sets Nunito at the weight the web\'s body has, 700', () {
      // app.css:50-56 body { font-family: var(--font-text); font-weight: 700 }
      for (final theme in [nightTheme, dayTheme]) {
        for (final style in [
          theme.textTheme.bodyLarge,
          theme.textTheme.bodyMedium,
          theme.textTheme.titleMedium,
          theme.textTheme.labelLarge,
        ]) {
          expect(style!.fontFamily, 'Nunito');
          expect(style.fontWeight, FontWeight.w700);
        }
      }
    });

    test('the bundled fonts really draw: the real faces measure differently from Ahem', () {
      double width(String family, FontWeight weight) {
        final painter = TextPainter(
          text: TextSpan(
            text: 'Supermercado 1.234',
            style: TextStyle(fontFamily: family, fontSize: 20, fontWeight: weight),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        return painter.width;
      }

      // Ahem is 1em per glyph: 18 characters at 20 px is 360.
      expect(width('Nunito', FontWeight.w700), isNot(360));
      expect(width('Fredoka', FontWeight.w700), isNot(360));
      // The weights are real: a variable font follows the weight asked for.
      expect(width('Nunito', FontWeight.w900), greaterThan(width('Nunito', FontWeight.w600)));
      // (Fredoka's advances narrow a little as it gets bolder.)
      expect(width('Fredoka', FontWeight.w700), isNot(width('Fredoka', FontWeight.w500)));
    });
  });

  group('each style has the size, weight, height and spacing of its web source', () {
    test('display: the keypad\'s amount, Fredoka 36px 700', () {
      // app.css:409-414 .lk-amount-display
      final css = _rule('.lk-amount-display');
      expect(css['font-family'], 'var(--font-display)');
      expect(css['font-size'], '36px');
      expect(css['font-weight'], '700');
      expect(LkText.display.fontFamily, 'Fredoka');
      expect(LkText.display.fontSize, 36);
      expect(LkText.display.fontWeight, FontWeight.w700);
      // No line-height declared: it inherits Tailwind's preflight 1.5.
      expect(LkText.display.height, 1.5);
      expect(LkText.display.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('amountXl: the hero amount, Fredoka 38px 700, line height 1.05', () {
      // app.css:185-191 .lk-hero-amount
      final css = _rule('.lk-hero-amount');
      expect(css['font-family'], 'var(--font-display)');
      expect(css['font-size'], '38px');
      expect(css['font-weight'], '700');
      expect(css['line-height'], '1.05');
      expect(css['font-variant-numeric'], 'tabular-nums');
      expect(LkText.amountXl.fontFamily, 'Fredoka');
      expect(LkText.amountXl.fontSize, 38);
      expect(LkText.amountXl.fontWeight, FontWeight.w700);
      expect(LkText.amountXl.height, 1.05);
      expect(LkText.amountXl.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('amount: a row\'s amount, Fredoka 14px 600, tabular', () {
      // app.css:271-277 .lk-amount
      final css = _rule('.lk-amount');
      expect(css['font-family'], 'var(--font-display)');
      expect(css['font-size'], '14px');
      expect(css['font-weight'], '600');
      expect(css['font-variant-numeric'], 'tabular-nums');
      expect(css['white-space'], 'nowrap');
      expect(LkText.amount.fontFamily, 'Fredoka');
      expect(LkText.amount.fontSize, 14);
      expect(LkText.amount.fontWeight, FontWeight.w600);
      // No line-height declared: it inherits Tailwind's preflight 1.5.
      expect(LkText.amount.height, 1.5);
      expect(LkText.amount.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('title: a sheet\'s title, Fredoka 24px 700, line height 1.15', () {
      // Sheet.tsx:295 className="m-0 font-display text-[24px] leading-[1.15] font-bold"
      final source = File(_sheetTsx).readAsStringSync();
      expect(source, contains('m-0 font-display text-[24px] leading-[1.15] font-bold'));
      expect(LkText.title.fontFamily, 'Fredoka');
      expect(LkText.title.fontSize, 24);
      expect(LkText.title.fontWeight, FontWeight.w700);
      expect(LkText.title.height, 1.15);
    });

    test('body: running text, Nunito 15px 700, the preflight\'s line height 1.5', () {
      // ConfirmSheet.tsx:54 <p className="m-0 text-[15px] text-ink">, with app.css:55 weight 700
      // and tailwindcss preflight.css:30 `line-height: 1.5` on html.
      expect(File(_confirmSheetTsx).readAsStringSync(), contains('m-0 text-[15px] text-ink'));
      expect(_rule('body')['font-weight'], '700');
      expect(LkText.body.fontFamily, 'Nunito');
      expect(LkText.body.fontSize, 15);
      expect(LkText.body.fontWeight, FontWeight.w700);
      expect(LkText.body.height, 1.5);
    });

    test('label: a row\'s title, Nunito 13px 800', () {
      // app.css:253-259 .lk-rowtop
      final css = _rule('.lk-rowtop');
      expect(css['font-size'], '13px');
      expect(css['font-weight'], '800');
      expect(LkText.label.fontFamily, 'Nunito');
      expect(LkText.label.fontSize, 13);
      expect(LkText.label.fontWeight, FontWeight.w800);
      expect(LkText.label.height, 1.5);
    });

    test('caption: a row\'s status line, Nunito 11px 800', () {
      // app.css:260-264 .lk-status
      final css = _rule('.lk-status');
      expect(css['font-size'], '11px');
      expect(css['font-weight'], '800');
      expect(LkText.caption.fontFamily, 'Nunito');
      expect(LkText.caption.fontSize, 11);
      expect(LkText.caption.fontWeight, FontWeight.w800);
      expect(LkText.caption.height, 1.5);
    });

    test('eyebrow: a day header, Nunito 11px 900, 0.07em apart, upper case', () {
      // app.css:301-310 .lk-overline
      final css = _rule('.lk-overline');
      expect(css['font-size'], '11px');
      expect(css['font-weight'], '900');
      expect(css['letter-spacing'], '0.07em');
      expect(css['text-transform'], 'uppercase');
      expect(LkText.eyebrow.fontFamily, 'Nunito');
      expect(LkText.eyebrow.fontSize, 11);
      expect(LkText.eyebrow.fontWeight, FontWeight.w900);
      // 0.07em of 11px, in logical pixels.
      expect(LkText.eyebrow.letterSpacing, closeTo(0.07 * 11, 1e-9));
      expect(LkText.eyebrow.height, 1.5);
      expect(LkText.upperCase('hoy · mar 21'), 'HOY · MAR 21');
    });

    test('the CSS sizes are read in px: sanity of the parser', () {
      expect(_px('36px'), 36);
    });
  });

  group('default text takes the ink of its own theme', () {
    // tokens.css --ink: #f3f0ff at night, #221a47 by day; app.css:50-56 body { color: var(--ink) }.
    for (final (name, theme, ink) in [
      ('night', nightTheme, LukitasTokens.night.ink),
      ('day', dayTheme, LukitasTokens.day.ink),
    ]) {
      testWidgets('a plain Text and a dialog\'s title and content are the $name ink', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    const Text('plain', key: Key('plain')),
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text('title', key: Key('title')),
                          content: Text('content', key: Key('content')),
                        ),
                      ),
                      child: const Text('open'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        for (final key in ['plain', 'title', 'content']) {
          final text = tester.widget<Text>(find.byKey(Key(key)));
          final style = DefaultTextStyle.of(tester.element(find.byKey(Key(key)))).style
              .merge(text.style);
          expect(style.color, ink, reason: '$key in $name');
        }
      });
    }

    test('every Material text style carries the ink, never Material\'s black or white', () {
      for (final (theme, ink) in [
        (nightTheme, LukitasTokens.night.ink),
        (dayTheme, LukitasTokens.day.ink),
      ]) {
        final t = theme.textTheme;
        for (final style in [
          t.displayLarge, t.displayMedium, t.displaySmall, t.headlineLarge, t.headlineMedium,
          t.headlineSmall, t.titleLarge, t.titleMedium, t.titleSmall, t.bodyLarge, t.bodyMedium,
          t.bodySmall, t.labelLarge, t.labelMedium, t.labelSmall, //
        ]) {
          expect(style!.color, ink);
        }
      }
    });
  });

  testWidgets('the styles draw with the fonts they name, not with Ahem', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            Text('Quedan', key: const Key('a'), style: LkText.amountXl),
            Text('Quedan', key: const Key('b'), style: LkText.label),
          ],
        ),
      ),
    );
    // Ahem would make 6 glyphs exactly 6 em wide.
    expect(tester.getSize(find.byKey(const Key('a'))).width, isNot(6 * 38));
    expect(tester.getSize(find.byKey(const Key('b'))).width, isNot(6 * 13));
  });
}
