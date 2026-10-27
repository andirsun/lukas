// The welcome's suggested categories in the four languages (the web's SUGGESTED_CATEGORIES).
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/welcome/suggested_categories.dart';

void main() {
  test('every suggestion has a name in each of the four languages', () {
    for (final s in suggestedCategories) {
      expect(s.names.keys.toSet(), {'es', 'en', 'it', 'pt'}, reason: s.key);
      for (final name in s.names.values) {
        expect(name.trim(), isNotEmpty, reason: s.key);
      }
    }
  });

  test('the Italian and Portuguese names are the web\'s', () {
    final names = {for (final s in suggestedCategories) s.key: s.names};
    expect(names['groceries']!['it'], 'Supermercato');
    expect(names['fun']!['it'], 'Tempo libero');
    expect(names['subscriptions']!['pt'], 'Subscrições');
    expect(names['health']!['pt'], 'Saúde');
    expect(names['salary']!['it'], 'Stipendio');
  });

  test('a name in any language finds its suggestion, accents aside', () {
    expect(suggestionFor('Stipendio')?.key, 'salary');
    expect(suggestionFor('salario')?.key, 'salary');
    expect(suggestionFor('SAUDE')?.key, 'health');
    expect(suggestionFor('Tempo libero')?.key, 'fun');
    expect(suggestionFor('Nope'), isNull);
  });
}
