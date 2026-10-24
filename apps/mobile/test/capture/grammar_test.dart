import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/engine/grammar.dart';

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
}
