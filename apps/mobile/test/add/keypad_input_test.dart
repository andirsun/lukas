// The web's test vectors (apps/web/app/ui/keypad-input.test.ts), ported one for one.
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/keypad_input.dart';

/// Types [keys] (as physical key names) from an empty amount; ignored keys change nothing.
String type(String keys, AmountFormat format) {
  var value = '';
  for (final key in keys.split('')) {
    value = typeOnKeypad(value, key, format) ?? value;
  }
  return value;
}

AmountFormat fmt(String locale, String currency) => AmountFormat(locale, currency);

void main() {
  group('typing an amount', () {
    const cases = <(String, String, String, String)>[
      // locale, currency, keys typed, raw value
      ('es', 'COP', '15.000', '15000'),
      // Pesos: the decimal separator ends the amount; what follows it does not count.
      ('es', 'COP', '15.000,5', '15000,'),
      ('es', 'COP', '50.000,50', '50000,'),
      ('es', 'COP', '50000,5', '50000,'),
      ('es', 'COP', '999999999', '999999999'),
      ('es', 'COP', '1000000000', '100000000'),
      ('en', 'COP', '15,000', '15000'),
      ('en', 'COP', '50000.5', '50000.'),
      ('en', 'COP', '50,000.75', '50000.'),
      ('es', 'EUR', '6,08', '6,08'),
      ('es', 'EUR', '15.000', '15000'),
      ('es', 'EUR', '6,089', '6,08'),
      ('es', 'EUR', '6,0,8', '6,08'),
      ('es', 'EUR', ',5', '0,5'),
      ('es', 'EUR', '007', '7'),
      ('en', 'EUR', '6.08', '6.08'),
      ('en', 'EUR', '1,234.5', '1234.5'),
      ('es', 'USD', '1.250,75', '1250,75'),
      ('en', 'USD', '1,250.75', '1250.75'),
      ('en', 'USD', '999999999.99', '999999999.99'),
      ('en', 'USD', '9999999999', '999999999'),
    ];
    for (final (locale, currency, keys, raw) in cases) {
      test('$locale $currency: typing $keys gives $raw', () {
        expect(type(keys, fmt(locale, currency)), raw);
      });
    }

    test('Backspace removes the last character', () {
      expect(typeOnKeypad('6,08', 'Backspace', fmt('es', 'EUR')), '6,0');
    });

    test('is null for keys that are not for the amount, so the page keeps them', () {
      for (final key in ['a', 'Enter', 'Tab', ' ', '-']) {
        expect(typeOnKeypad('6', key, fmt('es', 'EUR')), isNull);
      }
      expect(typeOnKeypad('6', '.', fmt('es', 'EUR')), isNull);
      expect(typeOnKeypad('6', '.', fmt('es', 'COP')), isNull);
    });

    test('in pesos, the amount is what comes before the separator, and Backspace undoes it', () {
      final cop = fmt('es', 'COP');
      var value = type('15.000,5', cop);
      expect(wholeAmount(value, cop), '15000');
      value = typeOnKeypad(value, 'Backspace', cop) ?? value;
      expect(value, '15000');
      expect(typeOnKeypad(value, '7', cop), '150007');
      // A separator with nothing before it is ignored.
      expect(typeOnKeypad('', ',', cop), '');
      expect(wholeAmount('6,08', fmt('es', 'EUR')), '6,08');
    });

    test('a decimal key ends a peso amount and starts euro decimals', () {
      expect(pressKey('50', const DecimalKey(), fmt('es', 'COP')), '50,');
      expect(pressKey('50,', const DigitKey('5'), fmt('es', 'COP')), '50,');
      expect(pressKey('50', const DecimalKey(), fmt('es', 'EUR')), '50,');
    });
  });

  group('pasting an amount', () {
    const cases = <(String, String, String, String?)>[
      // Decimal currencies: a single separator followed by exactly 1-2 digits is the decimal one;
      // otherwise "." and "," are thousands separators. The same in either language.
      ('es', 'EUR', '6.08', '6,08'),
      ('en', 'EUR', '6.08', '6.08'),
      ('es', 'USD', r'$6.08', '6,08'),
      ('es', 'EUR', '1.234', '1234'),
      ('en', 'USD', '1.234', '1234'),
      ('es', 'EUR', '1.234,56', '1234,56'),
      ('en', 'EUR', '1.234,56', '1234.56'),
      ('es', 'EUR', '1,234.56', '1234,56'),
      ('en', 'USD', '€1,234.56', '1234.56'),
      ('es', 'EUR', r'$ 50.000', '50000'),
      ('en', 'USD', r'$ 50.000', '50000'),
      ('es', 'EUR', '1.5', '1,5'),
      ('es', 'EUR', '6,08 €', '6,08'),
      ('es', 'EUR', '−6,08', '6,08'),
      ('es', 'EUR', '6,089', '6089'),
      ('es', 'USD', r'US$ 1.250,75', '1250,75'),
      ('en', 'USD', '1,000,000.50', '1000000.50'),
      ('en', 'USD', '999,999,999.99', '999999999.99'),
      ('es', 'EUR', '007', '7'),
      // Not one clear amount: nothing is pasted.
      ('es', 'EUR', '1,2,3', null),
      ('es', 'EUR', '1234,567', null),
      ('en', 'USD', 'lunch', null),
      ('es', 'EUR', '2024-10-21', null),
      ('es', 'EUR', 'Total 2 items 50.000', null),
      // Pesos: the locale's decimal separator ends the amount; the other one is thousands.
      ('es', 'COP', r'$50.000', '50000'),
      ('es', 'COP', '15.000', '15000'),
      ('es', 'COP', '15.000,5', '15000'),
      ('es', 'COP', '50.000,50', '50000'),
      ('es', 'COP', '4.300.000', '4300000'),
      ('en', 'COP', 'COP 50,000', '50000'),
      ('en', 'COP', '50,000.75', '50000'),
      ('es', 'COP', r'$6.08', null),
      ('es', 'COP', '1.000.000.000', null),
    ];
    for (final (locale, currency, text, raw) in cases) {
      test('$locale $currency: pasting "$text" gives ${raw == null ? 'nothing' : '"$raw"'}', () {
        expect(pasteAmount(text, fmt(locale, currency)), raw);
      });
    }

    test('typing and pasting the same peso text give the same amount', () {
      final cop = fmt('es', 'COP');
      for (final text in ['15.000,5', '50.000,50', '4.300.000']) {
        expect(wholeAmount(type(text, cop), cop), pasteAmount(text, cop));
      }
    });
  });

  group('amountCents: the keypad text as the stored x100 integer', () {
    const cases = <(String, String, String, int)>[
      ('es', 'COP', '', 0),
      ('es', 'COP', '15000', 1500000),
      // Pesos: the decimal separator only ends the amount.
      ('es', 'COP', '15000,', 1500000),
      ('es', 'COP', '15000,5', 1500000),
      ('en', 'COP', '50000.', 5000000),
      ('es', 'EUR', '6,08', 608),
      ('es', 'EUR', '6,', 600),
      ('en', 'USD', '1250.5', 125050),
      ('es', 'EUR', '999999999,99', 99999999999),
    ];
    for (final (locale, currency, raw, cents) in cases) {
      test('$locale $currency: "$raw" is $cents', () {
        expect(amountCents(raw, fmt(locale, currency)), cents);
      });
    }
  });

  group('pastedNegative: a minus before the first digit', () {
    for (final text in ['-50.000', '−6,08 €', '- 50', r'$-15.000', '‑20', '–20']) {
      test('"$text" is negative', () => expect(pastedNegative(text), isTrue));
    }
    for (final text in ['50-', '50.000', '6,08 €', '2026-10-21', r'$ 15.000', '']) {
      test('"$text" is not', () => expect(pastedNegative(text), isFalse));
    }
  });

  group('keypadText: stored cents as keypad text', () {
    test('writes them in the locale, whole when there are no cents', () {
      expect(keypadText(26280, 'es', 'EUR'), '262,80');
      expect(keypadText(26280, 'en', 'EUR'), '262.80');
      expect(keypadText(5000, 'es', 'EUR'), '50');
      expect(keypadText(-608, 'es', 'EUR'), '6,08');
      expect(keypadText(5, 'en', 'USD'), '0.05');
    });

    test('rounds pesos to whole pesos', () {
      expect(keypadText(5000000, 'es', 'COP'), '50000');
      expect(keypadText(-1500050, 'es', 'COP'), '15001');
    });
  });
}
