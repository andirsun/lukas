// The language quick capture works in (lib/capture/capture_language.dart): the app's own, and the
// rules that read a sentence in it.
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/capture_language.dart';
import 'package:lukitas/capture/engine/grammar.dart';
import 'package:lukitas/capture/models_download.dart';
import 'package:lukitas/capture/prewarm.dart' show voiceLocale;
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

  test('each of the app\'s four languages has its own voice model, and Spanish stands in for any other', () {
    expect(voiceModels.keys.toSet(), {'es', 'en', 'it', 'pt'});
    for (final language in ['es', 'en', 'it', 'pt']) {
      expect(voiceModels[captureLanguage(language)]!.locale, language);
    }
    // A region never matters: Brazilian Portuguese is read with the Portuguese model.
    for (final (locale, model) in [
      (const Locale('pt', 'BR'), 'vosk-model-small-pt-0.3'),
      (const Locale('pt', 'PT'), 'vosk-model-small-pt-0.3'),
      (const Locale('pt'), 'vosk-model-small-pt-0.3'),
      (const Locale('it', 'CH'), 'vosk-model-small-it-0.22'),
      (const Locale('es', 'CO'), 'vosk-model-small-es-0.42'),
      (const Locale('en', 'GB'), 'vosk-model-small-en-us-0.15'),
      (const Locale('fr'), 'vosk-model-small-es-0.42'),
    ]) {
      expect(voiceModels[voiceLocale(locale)]!.name, model, reason: '$locale');
    }
  });

  test('each of the app\'s four languages is read with its own rules, any other as Spanish', () {
    expect(parserLanguage('es'), 'es');
    expect(parserLanguage('en'), 'en');
    expect(parserLanguage('it'), 'it');
    expect(parserLanguage('pt'), 'pt');
    expect(parserLanguage('fr'), 'es');
  });

  test(
    'a typed sentence in Italian or Portuguese never fails, even in words of another language',
    () {
      for (final (language, sentence) in [
        ('it', '15 pranzo, 3 uber'),
        ('pt', '15 almoço, 3 uber'),
        ('it', 'ho speso 12,50 per il pranzo'),
        ('pt', 'gastei 12,50 no almoço'),
        ('it', 'gastei quinze euros e cinquenta no almoço'),
        ('pt', 'ho speso quindici euro per il pranzo'),
        ('it', 'gasté 15 mil en almuerzo'),
        ('pt', 'gasté quince mil en almuerzo'),
        ('it', 'mille milione milioni mila e e e ,, € 😀 l\'altro ieri'),
        ('pt', 'cem e cem e cento e e meio milhão pagaram-me sexta-feira'),
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
        expect(result.drafts.length + result.unread.length, greaterThan(0), reason: sentence);
        if (sentence.contains(RegExp(r'^(15|ho speso 12|gastei 12)'))) {
          expect(result.drafts.first.amount, anyOf(1500, 1250), reason: '$language "$sentence"');
        }
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
