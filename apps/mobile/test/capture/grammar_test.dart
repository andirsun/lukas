import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/engine/grammar.dart';
import 'package:lukitas/capture/models_download.dart' show voiceModels;
import 'package:lukitas/capture/parser/dates.dart' show dateAt;
import 'package:lukitas/capture/parser/words.dart';

/// The model's words that the grammar and the parser use, checked against the model itself
/// (test/fixtures/vosk_vocab_*.json): the model's vocabulary is a symbol table inside its Gr.fst.
({Set<String> present, Set<String> absent, Map<String, dynamic> json}) _vocabulary(String locale) {
  final json = jsonDecode(
    File('test/fixtures/vosk_vocab_$locale.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return (
    present: (json['present'] as List<dynamic>).cast<String>().toSet(),
    absent: (json['absent'] as List<dynamic>).cast<String>().toSet(),
    json: json,
  );
}

List<String> _words(String locale) =>
    (jsonDecode(grammarJson(locale)) as List<dynamic>).cast<String>();

void main() {
  test('the Spanish grammar has the amount, kind, date and separator words, plus [unk]', () {
    final words = jsonDecode(grammarJson('es')) as List<dynamic>;
    expect(
      words,
      containsAll([
        'quince', 'doce', 'veintidós', 'mil', 'millón', 'millones', 'lukas', 'luca', 'palos', //
        'medio', 'coma', 'con', 'pesos', 'gasté', 'pagué', 'me', 'pagaron', 'llegó', 'hoy', //
        'antier', 'miércoles', 'y', 'también', '[unk]',
      ]),
    );
    expect(words.toSet(), hasLength(words.length), reason: 'no word twice');
  });

  test('the English grammar has its own words, plus [unk]', () {
    final words = jsonDecode(grammarJson('en')) as List<dynamic>;
    expect(
      words,
      containsAll(['three', 'twelve', 'thousand', 'dollars', 'spent', 'got', 'yesterday', 'and']),
    );
    expect(words, contains('[unk]'));
    expect(words, isNot(contains('gasté')));
  });

  test(
    'the grammar JSON is plain UTF-8: Vosk drops every accented word written as \\u escapes',
    () {
      final json = grammarJson('es');
      expect(json, isNot(contains(r'\u')));
      expect(json, contains('"gasté"'));
      expect(utf8.decode(utf8.encode(json)), json);
    },
  );

  test('every grammar word has a class; the rest do not', () {
    expect(grammarClass('quince', 'es'), GrammarClass.number);
    expect(grammarClass('palo', 'es'), GrammarClass.number);
    expect(grammarClass('medio', 'es'), GrammarClass.number);
    expect(grammarClass('con', 'es'), GrammarClass.number);
    expect(grammarClass('pesos', 'es'), GrammarClass.currency);
    expect(grammarClass('gaste', 'es'), GrammarClass.kind, reason: 'accents do not matter');
    expect(grammarClass('ayer', 'es'), GrammarClass.date);
    expect(grammarClass('y', 'es'), GrammarClass.separator);
    expect(grammarClass('almuerzo', 'es'), isNull);
    expect(grammarClass('[unk]', 'es'), isNull);
    expect(grammarClass('hundred', 'en'), GrammarClass.number);
    expect(grammarClass('quince', 'en'), isNull);
  });

  test('the Italian grammar has its amount, kind, date and separator words, plus [unk]', () {
    final words = _words('it');
    expect(
      words,
      containsAll([
        'quindici', 'ventidue', 'trentacinque', 'centoventi', 'duemila', 'quindicimila', 'mille', //
        'mila', 'milione', 'milioni', 'mezzo', 'virgola', 'euro', 'centesimi', 'ho', 'speso', //
        'pagato', 'ricevuto', 'guadagnato', 'mi', 'hanno', 'oggi', 'ieri', 'lunedì', 'venerdì', //
        'domenica', 'e', 'ed', 'anche', '[unk]',
      ]),
    );
    expect(words.toSet(), hasLength(words.length), reason: 'no word twice');
    for (final other in ['gasté', 'gastei', 'hoy', 'spent']) {
      expect(words, isNot(contains(other)));
    }
  });

  test('the Portuguese grammar has its amount, kind, date and separator words, plus [unk]', () {
    final words = _words('pt');
    expect(
      words,
      containsAll([
        'quinze', 'três', 'dezasseis', 'dezesseis', 'vinte', 'quinhentos', 'mil', 'milhão', //
        'milhões', 'meio', 'vírgula', 'euros', 'dólares', 'cêntimos', 'gastei', 'paguei', //
        'comprei', 'recebi', 'ganhei', 'me', 'pagaram', 'hoje', 'ontem', 'terça', 'sábado', //
        'feira', 'e', 'também', '[unk]',
      ]),
    );
    expect(words.toSet(), hasLength(words.length), reason: 'no word twice');
    for (final other in ['gasté', 'gastos', 'hoy', 'spent']) {
      expect(words, isNot(contains(other)));
    }
  });

  for (final locale in ['it', 'pt']) {
    test('every $locale grammar word is in the model vocabulary, and no absent word is used', () {
      final vocabulary = _vocabulary(locale);
      final words = _words(locale);
      expect(
        vocabulary.json['zipSha256'],
        voiceModels[locale]!.sha256,
        reason: 'the fixture is of the shipped model',
      );
      expect(
        [
          for (final w in words)
            if (!vocabulary.present.contains(w)) w,
        ],
        isEmpty,
        reason: 'Vosk warns and drops a grammar word its model does not have',
      );
      expect(words.toSet().intersection(vocabulary.absent), isEmpty);
      // Nothing in the fixture is stale: each present word is still in the grammar.
      expect(vocabulary.present.difference(words.toSet()), isEmpty);
    });

    test('the $locale grammar JSON is plain UTF-8, with no \\u escapes', () {
      final json = grammarJson(locale);
      expect(json, isNot(contains(r'\u')));
      expect(utf8.decode(utf8.encode(json)), json);
      expect(json, locale == 'it' ? contains('"lunedì"') : contains('"três"'));
      expect(json, endsWith('"[unk]"]'));
    });

    test('every $locale kind and connector word of the parser is in the grammar', () {
      final folded = {for (final w in _words(locale)) fold(w)};
      for (final (words, _) in verbsFor(locale)) {
        for (final w in words) {
          expect(folded, contains(w), reason: 'verb word $w');
        }
      }
      for (final w in connectorsFor(locale)) {
        expect(folded, contains(w), reason: 'connector $w');
      }
    });

    test('every $locale date word of the grammar is a date word of the parser', () {
      var count = 0;
      for (final w in _words(locale)) {
        if (grammarClass(w, locale) != GrammarClass.date || w == 'feira') continue;
        count++;
        // After a preposition, which the Portuguese weekdays that are also ordinary words need.
        final tokens = tokenize('na $w', locale);
        expect(dateAt(tokens, 1, locale), isNotNull, reason: w);
      }
      expect(count, locale == 'it' ? 9 : 10);
    });
  }

  test(
    'every Italian number word the model has is in the grammar; the others are listed absent',
    () {
      final vocabulary = _vocabulary('it');
      final words = _words('it').toSet();
      for (final number in italianNumbers.keys) {
        expect(
          words.contains(number) != vocabulary.absent.contains(number),
          isTrue,
          reason: '$number is either in the grammar or absent from the model',
        );
      }
      expect(vocabulary.absent, containsAll(['centoottanta', 'altroieri', 'avantieri']));
    },
  );

  test('every Portuguese number word of the parser is in the grammar', () {
    final words = _words('pt').toSet();
    for (final number in [
      'um', 'uma', 'dois', 'duas', 'três', 'dez', 'onze', 'doze', 'treze', 'catorze', 'quinze', //
      'dezasseis', 'dezassete', 'dezoito', 'dezanove', 'vinte', 'trinta', 'cem', 'cento', //
      'duzentos', 'trezentas', 'quinhentos', 'novecentas', 'mil', 'milhão', 'milhões',
    ]) {
      expect(words, contains(number), reason: number);
    }
  });

  test('Italian and Portuguese words have their classes, accents and case aside', () {
    expect(grammarClass('Quindici', 'it'), GrammarClass.number);
    expect(grammarClass('quindicimila', 'it'), GrammarClass.number);
    expect(grammarClass('virgola', 'it'), GrammarClass.number);
    expect(grammarClass('centesimi', 'it'), GrammarClass.currency);
    expect(grammarClass('speso', 'it'), GrammarClass.kind);
    expect(grammarClass('lunedi', 'it'), GrammarClass.date, reason: 'accents do not matter');
    expect(grammarClass('anche', 'it'), GrammarClass.separator);
    expect(grammarClass('pranzo', 'it'), isNull);
    expect(grammarClass('quince', 'it'), isNull, reason: 'Spanish words are not Italian ones');
    expect(grammarClass('milhao', 'pt'), GrammarClass.number);
    expect(grammarClass('vírgula', 'pt'), GrammarClass.number);
    expect(grammarClass('dolares', 'pt'), GrammarClass.currency);
    expect(grammarClass('gastei', 'pt'), GrammarClass.kind);
    expect(grammarClass('terça', 'pt'), GrammarClass.date);
    expect(grammarClass('tambem', 'pt'), GrammarClass.separator);
    expect(grammarClass('almoço', 'pt'), isNull);
    expect(grammarClass('gastei', 'it'), isNull);
    expect(grammarClass('speso', 'pt'), isNull);
  });
}
