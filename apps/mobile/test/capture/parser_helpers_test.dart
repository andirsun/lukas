// Unit tests for the parser's helpers: number words, today in a time zone, and splitting.
import 'dart:math';

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
  group('number words, it', () {
    final values = {
      'uno': 1,
      'quindici': 15,
      'ventitré': 23,
      'ventuno': 21,
      'ventotto': 28,
      'trentacinque': 35,
      'cento': 100,
      'centottanta': 180,
      'centoventi': 120,
      'cento venti': 120,
      'duecentocinquanta': 250,
      'mille': 1000,
      'mille duecento': 1200,
      'mille e duecento': 1200,
      'tremila': 3000,
      'duemilacinquecento': 2500,
      'quindicimila': 15000,
      'centomila': 100000,
      'novecentonovantanovemila': 999000,
      'un milione': 1000000,
      'due milioni': 2000000,
      'un milione e duecentomila': 1200000,
      'un milione e mezzo': 1500000,
      'mezzo milione': 500000,
      'quindici mila': 15000,
      'mille e mezzo': 1500,
    };
    values.forEach((text, units) {
      test(text, () => expect(cents(text, 'it'), units * 100));
    });

    test('words that only look like numbers stay words', () {
      for (final text in ['treno', 'camilla', 'unico', 'seicentesco', 'mila', 'milione']) {
        expect(cents(text, 'it'), isNull, reason: text);
      }
    });

    test('a number word keeps the digits and the e of the sentence apart', () {
      expect(movements('mille e 3 per il taxi', 'it'), ['mille', '3 per il taxi']);
      expect(cents('quindici euro e cinquanta', 'it'), 1550);
      expect(readAmount(tokenize('quindici euro e cinque', 'it'), 0, 'it')!.cents, 1500);
      expect(cents('quindici e cinquanta', 'it'), isNull);
      expect(cents('12 virgola 05', 'it'), 1205);
    });

    test('Spanish words are plain names to the Italian rules', () {
      expect(cents('quince', 'it'), isNull);
      expect(cents('15 mil', 'it'), isNull);
      expect(cents('15 lukas', 'it'), isNull);
    });
  });

  group('number words, pt', () {
    final values = {
      'um': null,
      'quinze': 15,
      'vinte e um': 21,
      'vinte e cinco': 25,
      'noventa e nove': 99,
      'dezasseis': 16,
      'cem': 100,
      'cento': 100,
      'cento e vinte': 120,
      'duzentos e cinquenta': 250,
      'duzentos': 200,
      'mil': 1000,
      'mil e quinhentos': 1500,
      'mil quinhentos': 1500,
      'dois mil': 2000,
      'dois mil e quinhentos': 2500,
      'vinte mil': 20000,
      'um milhão': 1000000,
      'dois milhões': 2000000,
      'um milhão e duzentos mil': 1200000,
      'um milhão e meio': 1500000,
      'meio milhão': 500000,
      'mil e meio': 1500,
    };
    values.forEach((text, units) {
      test(text, () => expect(cents(text, 'pt'), units == null ? null : units * 100));
    });

    test('e joins a number only where Portuguese does', () {
      expect(cents('cem e cinquenta', 'pt'), isNull);
      expect(cents('quinze e cinquenta', 'pt'), isNull);
      expect(cents('quinze euros e cinquenta', 'pt'), 1550);
      expect(movements('mil e 3 no uber', 'pt'), ['mil', '3 no uber']);
    });

    test('Spanish words are plain names to the Portuguese rules', () {
      expect(cents('quince', 'pt'), isNull);
      expect(cents('15 millones', 'pt'), isNull);
    });
  });

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
      for (final text in [
        '1.000.000.000',
        '99999999999999999999',
        '999999999999999999999999999999 millones',
        'mil millones',
        'dos mil millones',
      ]) {
        expect(readAmount(tokenize(text, 'es'), 0, 'es')!.cents, isNull, reason: text);
      }
      expect(cents('999.999.999'), 99999999900);
    });

    test('a larger scale after a scale multiplies', () {
      expect(readAmountText('mil millones', 'es'), Dec(1000000000));
      expect(readAmountText('dos mil millones', 'es'), Dec(2000000000));
    });

    test('decimals in words keep their length', () {
      expect(cents('10 coma 05'), 1005);
      expect(cents('cuatro coma tres'), 430);
    });

    test('`y medio` after a scale, bare or not', () {
      expect(cents('mil y medio'), 150000);
      expect(cents('un millón y medio'), 150000000);
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
      'twelve hundred': 1200,
      'fifteen hundred fifty': 1550,
      'four point five': 4.5,
    };
    values.forEach((text, units) {
      test(text, () => expect(cents(text, 'en'), (units * 100).round()));
    });
  });

  group('digits', () {
    test('three digits after a separator are thousands, in every locale', () {
      for (final locale in ['es', 'en']) {
        expect(cents('15,000', locale), 1500000, reason: locale);
        expect(cents('15.000', locale), 1500000, reason: locale);
        expect(cents('2,500', locale), 250000, reason: locale);
        expect(cents('9,999', locale), 999900, reason: locale);
        expect(cents('1.234,56', locale), 123456, reason: locale);
        expect(cents('1,234.56', locale), 123456, reason: locale);
        expect(cents('9,50', locale), 950, reason: locale);
        expect(cents('12.5', locale), 1250, reason: locale);
      }
    });

    test('thousands before a scale word, or with k, is ambiguous', () {
      int? read(String text) => readAmount(tokenize(text, 'es'), 0, 'es')!.cents;
      expect(read('4,300 palos'), isNull);
      expect(read('4.300 mil'), isNull);
      expect(read('1,500k'), isNull);
      expect(read('4,3 palos'), 430000000);
    });

    test('a scale word lets go of the digits glued after it', () {
      expect(tokenize('2mil500', 'es').map((t) => t.text), ['2', 'mil', '500']);
      expect(tokenize('1millón200', 'es').map((t) => t.text), ['1', 'millón', '200']);
      expect(tokenize('2k500', 'es').map((t) => t.text), ['2', 'k', '500']);
      expect(cents('2mil500'), 250000);
      expect(cents('1millon200'), 100020000);
      expect(cents('15 k'), 1500000);
    });

    test('a separator before four or more digits is unread', () {
      expect(tokenize('12,5000 pan', 'es').map((t) => t.text), ['12,5000', 'pan']);
      expect(readAmount(tokenize('12,5000', 'es'), 0, 'es')!.cents, isNull);
    });

    test('an unused ambiguous number does not spoil the amount before it', () {
      final tokens = tokenize('20 mil 1,500k', 'es');
      final first = readAmount(tokens, 0, 'es')!;
      expect(first.cents, 2000000);
      expect(readAmount(tokens, first.end, 'es')!.cents, isNull);
    });

    test('a word keeps the digits glued to it', () {
      expect(tokenize('el D1 20 mil', 'es').map((t) => t.text), ['el', 'D1', '20', 'mil']);
      expect(tokenize('MiTienda24', 'es').single.isNumber, isFalse);
      expect(tokenize('15mil', 'es').map((t) => t.text), ['15', 'mil']);
    });

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
      // 23:30 in Bogotá is 06:30 the next day in Lisbon (WEST, UTC+1).
      final instant = DateTime.parse('2026-10-01T23:30:00-05:00');
      expect(todayIn('America/Bogota', instant), '2026-10-01');
      expect(todayIn('Europe/Lisbon', instant), '2026-10-02');
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

    test('COP is whole pesos, EUR keeps its cents', () {
      expect(parseSentence('gasté 9,50 en café', ctx).unread, ['gasté 9,50 en café']);
      expect(parseSentence('me pagaron 4,3 palos', ctx).drafts.single.amount, 430000000);
      const eur = ParseContext(
        locale: 'es',
        currency: 'EUR',
        today: '2026-10-22',
        timeZone: 'Europe/Madrid',
      );
      expect(parseSentence('gasté 9,50 en café', eur).drafts.single.amount, 950);
    });

    test('a zero amount is unread', () {
      expect(parseSentence('gasté 0 en taxi', ctx).unread, ['gasté 0 en taxi']);
    });

    test('never throws, on 200 random strings', () {
      final random = Random(20261022);
      const pieces = [
        '9', '99999999999999999999', '0', '1,', ',5', '.', ',', ' ', '  ', 'k', 'K', '\$', '€', //
        '😀', '🇨🇴', '—', '-', '?', '¿', '!', '\n', '\t', '"', "'", '(', ')', ';', ':', '/', //
        'mil', 'millones', 'palos', 'lukas', 'y', 'medio', 'con', 'coma', 'point', 'hundred', //
        'un', 'una', 'a', 'and', 'gasté', 'me', 'pagaron', 'ayer', 'lunes', 'el', 'en', 'D1', //
        'twelve', 'fifty', 'noventa', 'treinta', 'cien', 'ñandú', 'e\u0301', '\u0303', 'x',
        'mila', 'mille', 'milione', 'quindicimila', 'duemilacinquecento', 'virgola', 'mezzo', //
        'e', 'ed', 'ho', 'speso', "l'altro", 'ieri', 'euro', 'cento', 'ventitré', 'tremilamila', //
        'milhão', 'meio', 'vírgula', 'cento e', 'cem', 'sexta-feira', 'antes de', 'ontem', 'um', //
        'pagaram-me', 'quinze', 'dezasseis', 'mil e',
      ];
      for (var n = 0; n < 200; n++) {
        final text = StringBuffer();
        final length = random.nextInt(40);
        for (var i = 0; i < length; i++) {
          final piece = pieces[random.nextInt(pieces.length)];
          // Some long digit runs, up to a few hundred digits.
          text.write(random.nextInt(10) == 0 ? '9' * random.nextInt(400) : piece);
          if (random.nextBool()) text.write(' ');
        }
        for (final context in [
          ctx,
          for (final locale in ['en', 'it', 'pt'])
            ParseContext(
              locale: locale,
              currency: 'EUR',
              today: '2028-02-29',
              timeZone: 'Europe/Lisbon',
              categories: const [Category(id: 'c', name: 'D1', kind: Kind.expense)],
              usual: const [Usual(name: 'x', categoryId: 'missing')],
            ),
        ]) {
          final input = text.toString();
          final result = parseSentence(input, context);
          for (final draft in result.drafts) {
            expect(draft.amount, inInclusiveRange(1, 99999999900), reason: input);
          }
        }
      }
    });
  });
}
