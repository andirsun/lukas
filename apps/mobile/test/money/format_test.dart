import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/money/format.dart';

const nbsp = ' ';

/// The amount as stored: pesos x 100, like every other currency's minor units.
int pesos(int n) => n * 100;

void main() {
  group('formatMoney matches the web', () {
    test('writes COP as \$50.000 in Spanish and keeps the code in English', () {
      expect(formatMoney(5000000, 'COP', 'es'), r'$50.000');
      expect(formatMoney(430000000, 'COP', 'es'), r'$4.300.000');
      expect(formatMoney(5000000, 'COP', 'en'), 'COP${nbsp}50,000');
      expect(formatMoney(0, 'COP', 'es'), r'$0');
    });

    test('formats EUR and USD with the locale conventions', () {
      expect(formatMoney(56292, 'EUR', 'es'), '562,92$nbsp€');
      expect(formatMoney(56292, 'EUR', 'en'), '€562.92');
      expect(formatMoney(123456, 'EUR', 'en'), '€1,234.56');
      expect(formatMoney(56292, 'USD', 'es'), '562,92${nbsp}US\$');
      expect(formatMoney(123456, 'USD', 'en'), r'$1,234.56');
    });

    test('groups thousands in Spanish only from five digits, except for pesos', () {
      expect(formatMoney(123456, 'EUR', 'es'), '1234,56$nbsp€');
      expect(formatMoney(1234500, 'EUR', 'es'), '12.345,00$nbsp€');
      expect(formatMoney(430000000, 'EUR', 'es'), '4.300.000,00$nbsp€');
      expect(formatMoney(123456, 'COP', 'es'), r'$1.235');
    });

    test('uses the real minus sign U+2212, never the hyphen', () {
      expect(formatMoney(-608, 'EUR', 'es'), '−6,08$nbsp€');
      expect(formatMoney(-608, 'EUR', 'en'), '−€6.08');
      expect(formatMoney(-5000000, 'COP', 'es'), '−\$50.000');
      expect(formatMoney(-5000000, 'COP', 'en'), '−COP${nbsp}50,000');
      expect(formatMoney(-5000000, 'COP', 'es').contains('-'), isFalse);
    });

    test('shows an explicit plus with sign: always, and never a negative zero', () {
      expect(formatMoney(1500, 'EUR', 'en', sign: MoneySign.always), '+€15.00');
      expect(formatMoney(-1500, 'EUR', 'en', sign: MoneySign.always), '−€15.00');
      expect(formatMoney(0, 'EUR', 'en', sign: MoneySign.always), '€0.00');
      expect(formatMoney(5000000, 'COP', 'es', sign: MoneySign.always), r'+$50.000');
      expect(formatMoney(-5, 'COP', 'es'), r'$0');
    });

    test('rounds sub-peso amounts, since COP shows no decimals', () {
      expect(formatMoney(150, 'COP', 'es'), r'$2');
      expect(formatMoney(56292, 'COP', 'es'), r'$563');
      expect(formatMoney(-150, 'COP', 'es'), '−\$2');
    });

    test('names a currency it has no symbol for by its code, whole like COP for CLP', () {
      expect(formatMoney(5000000, 'CLP', 'es'), '50.000${nbsp}CLP');
      expect(formatMoney(5000000, 'CLP', 'en'), 'CLP${nbsp}50,000');
    });
  });

  group('formatMoney in Italian and Portuguese matches Intl (it-IT, pt-PT)', () {
    // Vectors from `new Intl.NumberFormat(tag, { style: 'currency', ... })`, the web's.
    test('euros: the symbol after, a comma, and four digits left together', () {
      expect(formatMoney(123450, 'EUR', 'it'), '1234,50$nbsp€');
      expect(formatMoney(123450, 'EUR', 'pt'), '1234,50$nbsp€');
      expect(formatMoney(56292, 'EUR', 'it'), '562,92$nbsp€');
      expect(formatMoney(56292, 'EUR', 'pt'), '562,92$nbsp€');
      expect(formatMoney(0, 'EUR', 'it'), '0,00$nbsp€');
    });

    test('Italian groups with a point, Portuguese with a no-break space', () {
      expect(formatMoney(1234500, 'EUR', 'it'), '12.345,00$nbsp€');
      expect(formatMoney(12345678, 'EUR', 'it'), '123.456,78$nbsp€');
      expect(formatMoney(430000000, 'EUR', 'it'), '4.300.000,00$nbsp€');
      expect(formatMoney(1234500, 'EUR', 'pt'), '12${nbsp}345,00$nbsp€');
      expect(formatMoney(12345678, 'EUR', 'pt'), '123${nbsp}456,78$nbsp€');
      expect(formatMoney(430000000, 'EUR', 'pt'), '4${nbsp}300${nbsp}000,00$nbsp€');
    });

    test('the real minus sign and the explicit plus', () {
      expect(formatMoney(-608, 'EUR', 'it'), '−6,08$nbsp€');
      expect(formatMoney(-608, 'EUR', 'pt'), '−6,08$nbsp€');
      expect(formatMoney(1500, 'EUR', 'pt', sign: MoneySign.always), '+15,00$nbsp€');
      expect(formatMoney(0, 'EUR', 'it', sign: MoneySign.always), '0,00$nbsp€');
    });

    test('other currencies keep their code after the figure', () {
      expect(formatMoney(123400, 'USD', 'it'), '1234,00${nbsp}USD');
      expect(formatMoney(123400, 'USD', 'pt'), '1234,00${nbsp}US\$');
      expect(formatMoney(5000000, 'COP', 'it'), '50.000${nbsp}COP');
      expect(formatMoney(5000000, 'COP', 'pt'), '50${nbsp}000${nbsp}COP');
      expect(formatMoney(5000000, 'CLP', 'it'), '50.000${nbsp}CLP');
    });

    test('typing: a decimal comma, grouped like the money', () {
      expect(formatAmountInput('6,5', 'EUR', 'it'), '6,5$nbsp€');
      expect(formatAmountInput('12345,6', 'EUR', 'it'), '12.345,6$nbsp€');
      expect(formatAmountInput('12345,6', 'EUR', 'pt'), '12${nbsp}345,6$nbsp€');
    });

    test('there is no lukas or palos hint', () {
      expect(lukasHint(pesos(50000), 'it'), isNull);
      expect(lukasHint(pesos(50000), 'pt'), isNull);
    });
  });

  group('lukasHint matches the web', () {
    test('counts lukas (1.000 pesos) in Spanish, in parentheses', () {
      expect(lukasHint(5000000, 'es'), '(50 lukas)');
      expect(lukasHint(pesos(1000), 'es'), '(1 luka)');
      expect(lukasHint(pesos(15500), 'es'), '(15,5 lukas)');
      expect(lukasHint(pesos(15540), 'es'), '(15,5 lukas)');
      expect(lukasHint(pesos(15550), 'es'), '(15,6 lukas)');
      expect(lukasHint(pesos(999000), 'es'), '(999 lukas)');
    });

    test('counts palos (1.000.000 pesos) in Spanish, up to two decimals', () {
      expect(lukasHint(430000000, 'es'), '(4,3 palos)');
      expect(lukasHint(pesos(1000000), 'es'), '(1 palo)');
      expect(lukasHint(pesos(1250000), 'es'), '(1,25 palos)');
      expect(lukasHint(pesos(1256000), 'es'), '(1,26 palos)');
      expect(lukasHint(pesos(12000000), 'es'), '(12 palos)');
    });

    test('moves to palos after rounding', () {
      expect(lukasHint(pesos(999990), 'es'), '(1 palo)');
      expect(lukasHint(pesos(999950), 'es'), '(1 palo)');
      expect(lukasHint(pesos(999940), 'es'), '(999,9 lukas)');
    });

    test('uses k and M in English', () {
      expect(lukasHint(pesos(50000), 'en'), '(50k)');
      expect(lukasHint(pesos(15540), 'en'), '(15.5k)');
      expect(lukasHint(pesos(1000), 'en'), '(1k)');
      expect(lukasHint(pesos(4300000), 'en'), '(4.3M)');
      expect(lukasHint(pesos(1250000), 'en'), '(1.25M)');
      expect(lukasHint(pesos(999990), 'en'), '(1M)');
    });

    test('is null under 1.000 pesos and for any other currency', () {
      expect(lukasHint(0, 'es'), isNull);
      expect(lukasHint(pesos(999), 'es'), isNull);
      expect(lukasHint(99999, 'es'), isNull);
      expect(lukasHint(pesos(50000), 'es', currency: 'EUR'), isNull);
      expect(lukasHint(pesos(50000), 'en', currency: 'USD'), isNull);
    });

    test('describes the size of an amount, whatever its sign', () {
      expect(lukasHint(-pesos(50000), 'es'), '(50 lukas)');
    });
  });
  group('formatAmountInput (the web\'s vectors)', () {
    test('shows what is being typed as money, keeping a trailing separator or zero', () {
      expect(formatAmountInput('', 'EUR', 'es'), '0$nbsp€');
      expect(formatAmountInput('6', 'EUR', 'es'), '6$nbsp€');
      expect(formatAmountInput('6,', 'EUR', 'es'), '6,$nbsp€');
      expect(formatAmountInput('6,0', 'EUR', 'es'), '6,0$nbsp€');
      expect(formatAmountInput('6,08', 'EUR', 'es'), '6,08$nbsp€');
      expect(formatAmountInput('6.5', 'EUR', 'en'), '€6.5');
    });

    test('groups thousands like formatMoney does', () {
      expect(formatAmountInput('50000', 'COP', 'es'), r'$50.000');
      expect(formatAmountInput('4300000', 'COP', 'es'), r'$4.300.000');
      expect(formatAmountInput('50000', 'COP', 'en'), 'COP${nbsp}50,000');
      expect(formatAmountInput('12345,6', 'EUR', 'es'), '12.345,6$nbsp€');
    });

    test('pesos drop a separator that only ended the amount', () {
      expect(formatAmountInput('50000,', 'COP', 'es'), r'$50.000');
    });
  });
}
