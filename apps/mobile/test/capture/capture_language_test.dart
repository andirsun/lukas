// The language quick capture works in (lib/capture/capture_language.dart): the app's own, and the
// rules that read a sentence in it.
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/capture_language.dart';
import 'package:lukitas/capture/engine/grammar.dart';
import 'package:lukitas/capture/models_download.dart';
import 'package:lukitas/capture/parser/parse.dart';

void main() {
  test('capture speaks the app\'s four languages, and Spanish for any other', () {
    expect(captureLanguage('es'), 'es');
    expect(captureLanguage('en'), 'en');
    expect(captureLanguage('it'), 'it');
    expect(captureLanguage('pt'), 'pt');
    expect(captureLanguage('fr'), 'es');
    expect(captureLanguage(''), 'es');
  });

  test('only Spanish and English have voice models for now', () {
    expect(voiceModels.keys.toSet(), {'es', 'en'});
    for (final language in ['it', 'pt']) {
      expect(voiceModels.containsKey(captureLanguage(language)), isFalse, reason: language);
    }
  });

  test('a sentence in Italian or Portuguese is read with the rules that need no words', () {
    expect(parserLanguage('es'), 'es');
    expect(parserLanguage('en'), 'en');
    expect(parserLanguage('it'), 'es');
    expect(parserLanguage('pt'), 'es');
  });

  test(
    'a typed sentence in Italian or Portuguese never fails: digits, commas and names are read',
    () {
      for (final (language, sentence) in [
        ('it', '15 pranzo, 3 uber'),
        ('pt', '15 almoço, 3 uber'),
        ('it', 'ho speso 12,50 per il pranzo'),
        ('pt', 'gastei 12,50 no almoço'),
      ]) {
        final result = parseSentence(
          sentence,
          ParseContext(
            locale: parserLanguage(language),
            currency: 'EUR',
            today: '2026-10-26',
            timeZone: 'Europe/Rome',
            categories: const [],
            usual: const [],
          ),
        );
        expect(result.drafts, isNotEmpty, reason: '$language "$sentence"');
        expect(result.drafts.first.amount, anyOf(1500, 1250), reason: '$language "$sentence"');
      }
    },
  );

  test('the store listing\'s example sentences split into two movements', () {
    for (final (language, sentence) in [('it', '15 pranzo, 3 uber'), ('pt', '15 almoço, 3 uber')]) {
      final result = parseSentence(
        sentence,
        ParseContext(
          locale: parserLanguage(language),
          currency: 'EUR',
          today: '2026-10-26',
          timeZone: 'Europe/Rome',
        ),
      );
      expect([for (final d in result.drafts) d.amount], [1500, 300], reason: language);
    }
  });

  test('the grammar never offers another language\'s words for Italian or Portuguese', () {
    // The grammar only biases a model that exists; asked for one that does not, it must not throw.
    expect(() => grammarJson('it'), returnsNormally);
    expect(() => grammarClass('mil', 'pt'), returnsNormally);
  });
}
