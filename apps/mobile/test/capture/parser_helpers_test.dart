// Unit tests for the parser's helpers: number words, today in a time zone, and splitting.
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/parser/amounts.dart';
import 'package:lukitas/capture/parser/dates.dart';
import 'package:lukitas/capture/parser/parse.dart';
import 'package:lukitas/capture/parser/split.dart';
import 'package:lukitas/capture/parser/words.dart';

/// The amount of [text] in cents, when all of it is one amount.
int? cents(String text, [String locale = 'es']) => readAmountText(text, locale)?.cents;

/// The movements of [text], each as the original text it covers.
List<String> movements(String text, [String locale = 'es']) => [
  for (final m in splitMovements(readItems(text, locale)))
    text.substring(m.items.first.start, m.items.last.end),
];

void main() {
  group('number words, es', () {
    final values = {
      'uno': 1,
      'quince': 15,
      'veintidós': 22,
      'veintidos': 22,
      'dieciseis': 16,
      'treinta y cinco': 35,
      'noventa y nueve': 99,
      'cien': 100,
      'ciento veinte': 120,
      'doscientos cincuenta': 250,
      'mil': 1000,
      'mil quinientos': 1500,
      'quince mil': 15000,
      'treinta y un mil': 31000,
      'veintidós mil novecientos': 22900,
      'noventa y nueve mil novecientos': 99900,
      'ciento veinte mil': 120000,
      'un millón': 1000000,
      'dos millones': 2000000,
      'un millón ochocientos mil': 1800000,
      'novecientos noventa y nueve millones novecientos noventa y nueve mil '
              'novecientos noventa y nueve':
          999999999,
      'medio palo': 500000,
      'un palo y medio': 1500000,
      'dos millones y medio': 2500000,
      'una luca': 1000,
      'cuatro coma tres palos': 4300000,
      'nueve con cincuenta': 9.5,
      'nueve euros con cincuenta': 9.5,
      'cinco con veinticinco': 5.25,
    };
    values.forEach((text, units) {
      test(text, () => expect(cents(text), (units * 100).round()));
    });

    test('`y` joins tens and a unit only', () {
      expect(cents('quinientos y cinco'), isNull);
      expect(cents('siete mil quinientos'), 750000);
    });

    test('`un` and `una` are numbers only before a scale word', () {
      expect(cents('un'), isNull);
      expect(cents('una'), isNull);
      expect(cents('un cuatro'), isNull);
    });

    test('two amounts are not one number', () {
      expect(cents('12 mil 40 mil'), isNull);
      expect(readAmount(tokenize('12 mil 40 mil', 'es'), 0, 'es')!.end, 2);
    });

    test('above 999 999 999 has no usable amount', () {
      final tokens = tokenize('1.000.000.000', 'es');
      expect(readAmount(tokens, 0, 'es')!.cents, isNull);
    });
  });

  group('number words, en', () {
    final values = {
      'twelve': 12,
      'two thousand': 2000,
      'fifteen thousand': 15000,
      'two hundred fifty': 250,
      'two hundred and fifty': 250,
      'a thousand': 1000,
      'twelve fifty': 12.5,
      'one million two hundred thousand': 1200000,
      'twelve dollars and fifty cents': 12.5,
    };
    values.forEach((text, units) {
      test(text, () => expect(cents(text, 'en'), (units * 100).round()));
    });
  });

  group('digits', () {
    test('es: dot and space thousands, comma decimal, k', () {
      expect(cents('15.000'), 1500000);
      expect(cents('1.500.000'), 150000000);
      expect(cents('120 000'), 12000000);
      expect(cents('9,50'), 950);
      expect(cents('4,3 palos'), 430000000);
      expect(cents('15k'), 1500000);
      expect(cents('8K'), 800000);
    });

    test('en: comma thousands, dot decimal', () {
      expect(cents('15,000', 'en'), 1500000);
      expect(cents('1,200.50', 'en'), 120050);
      expect(cents('12.50', 'en'), 1250);
    });

    test('slang units are flagged', () {
      expect(readAmount(tokenize('15 lukas', 'es'), 0, 'es')!.slang, isTrue);
      expect(readAmount(tokenize('15 mil', 'es'), 0, 'es')!.slang, isFalse);
    });
  });

  group('todayIn', () {
    final instant = DateTime.utc(2026, 10, 2, 4, 30);

    test('Bogotá is still the day before', () {
      expect(todayIn('America/Bogota', instant), '2026-10-01');
    });

    test('Lisbon is already the day', () {
      expect(todayIn('Europe/Lisbon', instant), '2026-10-02');
    });

    test('it follows daylight saving time', () {
      // New York is UTC-4 in summer and UTC-5 in winter.
      expect(todayIn('America/New_York', DateTime.utc(2026, 7, 2, 3, 30)), '2026-07-01');
      expect(todayIn('America/New_York', DateTime.utc(2026, 12, 2, 4, 30)), '2026-12-01');
      expect(todayIn('America/New_York', DateTime.utc(2026, 12, 2, 5, 30)), '2026-12-02');
    });

    test('a time given in another offset is the same instant', () {
      expect(todayIn('America/Bogota', DateTime.utc(2026, 10, 2, 4, 30).toLocal()), '2026-10-01');
    });

    test('an unknown zone falls back to UTC', () {
      expect(todayIn('Mars/Olympus', instant), '2026-10-02');
    });
  });

  group('date words', () {
    test('weekdays are strictly in the past', () {
      // 2026-10-22 is a Thursday.
      expect(dateOf('jueves', '2026-10-22'), '2026-10-15');
      expect(dateOf('miercoles', '2026-10-22'), '2026-10-21');
      expect(dateOf('friday', '2026-10-22'), '2026-10-16');
    });

    test('relative days cross months, years and leap days', () {
      expect(dateOf('ayer', '2026-10-01'), '2026-09-30');
      expect(dateOf('yesterday', '2027-01-01'), '2026-12-31');
      expect(dateOf('antier', '2028-03-01'), '2028-02-28');
      expect(addDays('2028-03-01', -1), '2028-02-29');
    });
  });

  group('splitting', () {
    test('a connector splits only between two amounts', () {
      expect(movements('pan y leche 8 mil'), ['pan y leche 8 mil']);
      expect(movements('gasté 8 mil en pan y leche'), ['gasté 8 mil en pan y leche']);
      expect(movements('almuerzo 12 mil y taxi 8 mil'), ['almuerzo 12 mil', 'taxi 8 mil']);
    });

    test('the text after a connector ends at the next connector', () {
      expect(movements('gasté 8 mil en pan y leche, 3 mil en huevos'), [
        'gasté 8 mil en pan y leche',
        '3 mil en huevos',
      ]);
    });

    test('decimal and thousands commas are not connectors', () {
      expect(movements('gasté 9,50 en café y 3,20 en pan'), ['gasté 9,50 en café', '3,20 en pan']);
      expect(movements('spent 1,200 on rent and 15 on lunch', 'en'), [
        'spent 1,200 on rent',
        '15 on lunch',
      ]);
    });

    test('`y` inside a number word is not a connector', () {
      expect(movements('taxi cuarenta y cinco mil y mercado treinta y cinco mil'), [
        'taxi cuarenta y cinco mil',
        'mercado treinta y cinco mil',
      ]);
      expect(movements('uber siete mil quinientos y cinco mil'), [
        'uber siete mil quinientos',
        'cinco mil',
      ]);
    });

    test('with no connector, the middle goes by where the first name sits', () {
      expect(movements('gasté doce mil en taxi cuarenta mil en mercado'), [
        'gasté doce mil en taxi',
        'cuarenta mil en mercado',
      ]);
      expect(movements('taxi doce mil mercado cuarenta mil'), [
        'taxi doce mil',
        'mercado cuarenta mil',
      ]);
    });

    test('with no connector, a verb or a date starts the later movement', () {
      expect(movements('gasté 5 mil en pan pagué 20 mil de internet'), [
        'gasté 5 mil en pan',
        'pagué 20 mil de internet',
      ]);
      expect(movements('ayer gasté 5 mil en taxi hoy 3 mil en café'), [
        'ayer gasté 5 mil en taxi',
        'hoy 3 mil en café',
      ]);
    });

    test('two amounts and no name stay one movement', () {
      expect(movements('gasté 12 mil 40 mil'), ['gasté 12 mil 40 mil']);
    });
  });

  group('parseSentence', () {
    const ctx = ParseContext(
      locale: 'es',
      currency: 'COP',
      today: '2026-10-22',
      timeZone: 'America/Bogota',
    );

    test('empty text reads nothing', () {
      final result = parseSentence('  ', ctx);
      expect(result.drafts, isEmpty);
      expect(result.unread, isEmpty);
    });

    test('a zero amount is unread', () {
      expect(parseSentence('gasté 0 en taxi', ctx).unread, ['gasté 0 en taxi']);
    });
  });
}
