// Merge rule v2 of the voice spike (docs/superpowers/reports/2026-10-22-stage-3-voice-spike.md,
// "Merge rules"), on the report's own examples. Word timings are made up but shaped like Vosk's:
// the free pass hears whole words, the grammar pass the amount, kind, date and separator words,
// and `[unk]` for the rest.
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/engine/merge.dart';
import 'package:lukitas/capture/parser/parse.dart';

/// Words laid end to end from [from] seconds, each [each] long, as a pass would time them.
List<HeardWord> _words(String text, {double from = 0, double each = 0.4}) {
  final out = <HeardWord>[];
  var at = from;
  for (final word in text.split(' ')) {
    out.add(HeardWord(word, at, at + each));
    at += each;
  }
  return out;
}

HeardWord _w(String word, double start, double end) => HeardWord(word, start, end);

const _cop = ParseContext(
  locale: 'es',
  currency: 'COP',
  today: '2026-10-22',
  timeZone: 'America/Bogota',
);

ParseContext _eur(String locale) =>
    ParseContext(locale: locale, currency: 'EUR', today: '2026-10-26', timeZone: 'Europe/Rome');

void main() {
  group('overlap', () {
    test('two words overlap when their shared time covers half of either', () {
      expect(overlaps(_w('a', 0, 1), _w('b', 0.5, 2)), isTrue); // half of a
      expect(overlaps(_w('a', 0, 1), _w('b', 0.9, 1.1)), isTrue); // half of b
      expect(overlaps(_w('a', 0, 1), _w('b', 0.8, 2)), isFalse); // 20 % of a, 17 % of b
      expect(overlaps(_w('a', 0, 1), _w('b', 1, 2)), isFalse);
    });
  });

  group('similarity', () {
    test('normalized edit similarity ignores case and accents', () {
      expect(similarity('este', 'gasté'), closeTo(0.6, 1e-9)); // g added, e → a
      expect(similarity('pagar', 'pagaron'), closeTo(5 / 7, 1e-9));
      expect(similarity('Gaste', 'gasté'), 1);
      expect(similarity('pan', 'pagué'), lessThan(0.5));
      expect(similarity('almuerzo', 'peso'), lessThan(0.5));
    });
  });

  group('rule v2', () {
    test('s07: "medio palo" from the grammar pass, "en el éxito" from the free pass', () {
      final free = [
        _w('me', 0.30, 0.42),
        _w('de', 0.42, 0.55),
        _w('ópalo', 0.55, 1.00),
        _w('en', 1.10, 1.20),
        _w('el', 1.20, 1.30),
        _w('éxito', 1.30, 1.80),
      ];
      final grammar = [_w('medio', 0.30, 0.60), _w('palo', 0.60, 1.00), _w('[unk]', 1.10, 1.80)];
      final merged = mergePasses(free, grammar, 'es');
      expect(merged, 'medio palo en el éxito');

      final result = parseSentence(merged, _cop);
      expect(result.unread, isEmpty);
      expect(result.drafts, hasLength(1));
      expect(result.drafts.single.amount, 500000 * 100);
      // The parser leaves the article out of a name.
      expect(result.drafts.single.name, 'éxito');
    });

    test('s08: "doce" from the grammar pass fixes both amounts', () {
      final free = _words('gaste dos mil en taxi cuarenta mil el mercado');
      // gasté doce mil [unk] [unk] cuarenta mil [unk] [unk], timed like the free words.
      final grammar = [
        for (final w in free)
          switch (w.word) {
            'gaste' => _w('gasté', w.start, w.end),
            'dos' => _w('doce', w.start, w.end),
            'mil' || 'cuarenta' => w,
            _ => _w('[unk]', w.start, w.end),
          },
      ];
      final merged = mergePasses(free, grammar, 'es');
      expect(merged, 'gasté doce mil en taxi cuarenta mil el mercado');
      final amounts = parseSentence(merged, _cop).drafts.map((d) => d.amount);
      expect(amounts, [12000 * 100, 40000 * 100]);
    });

    test('s02: a kind word replaces a free word that looks like it ("este" → "gasté")', () {
      final free = _words('este quince mil en el almuerzo');
      final grammar = [
        _w('gasté', 0, 0.4),
        _w('quince', 0.4, 0.8),
        _w('mil', 0.8, 1.2),
        _w('[unk]', 1.2, 2.4),
      ];
      expect(mergePasses(free, grammar, 'es'), 'gasté quince mil en el almuerzo');
    });

    test('s01: a currency word never eats a name ("almuerzo" stays, "peso" goes)', () {
      final free = _words('gaste quince mil en el almuerzo');
      final grammar = [
        _w('gasté', 0, 0.4),
        _w('quince', 0.4, 0.8),
        _w('mil', 0.8, 1.2),
        _w('[unk]', 1.2, 2.0),
        _w('peso', 2.0, 2.4),
      ];
      expect(mergePasses(free, grammar, 'es'), 'gasté quince mil en el almuerzo');
    });

    test('s04: a kind word never eats a name ("pan" stays, "pagué" goes)', () {
      final free = _words('ayer compré pan y leche por ocho mil quinientos');
      final grammar = [
        _w('ayer', 0, 0.4),
        _w('compré', 0.4, 0.8),
        _w('pagué', 0.8, 1.2),
        _w('y', 1.2, 1.6),
        _w('[unk]', 1.6, 2.4),
        _w('ocho', 2.4, 2.8),
        _w('mil', 2.8, 3.2),
        _w('quinientos', 3.2, 3.6),
      ];
      expect(mergePasses(free, grammar, 'es'), 'ayer compré pan y leche por ocho mil quinientos');
    });

    test('a kind word replaces a free word that is itself grammar vocabulary', () {
      final free = [_w('hoy', 0, 0.4), _w('quince', 0.4, 0.8), _w('mil', 0.8, 1.2)];
      final grammar = [_w('ayer', 0, 0.4), _w('quince', 0.4, 0.8), _w('mil', 0.8, 1.2)];
      expect(mergePasses(free, grammar, 'es'), 'ayer quince mil');
    });

    test('number words win even over free words that look nothing like them', () {
      final free = [_w('almuerzo', 0, 0.5), _w('tren', 0.5, 0.9), _w('lucas', 0.9, 1.3)];
      final grammar = [_w('[unk]', 0, 0.5), _w('tres', 0.5, 0.9), _w('lucas', 0.9, 1.3)];
      expect(mergePasses(free, grammar, 'es'), 'almuerzo tres lucas');
    });

    test('free words that overlap nothing are kept, and grammar words alone are added', () {
      final free = [_w('uber', 0, 0.4), _w('mil', 1.6, 2.0)];
      final grammar = [_w('siete', 1.0, 1.5), _w('mil', 1.6, 2.0)];
      expect(mergePasses(free, grammar, 'es'), 'uber siete mil');
    });

    test('[unk] grammar words are ignored', () {
      final free = _words('spotify dieciseis mil');
      final grammar = [_w('[unk]', 0, 0.4), _w('dieciséis', 0.4, 0.8), _w('mil', 0.8, 1.2)];
      expect(mergePasses(free, grammar, 'es'), 'spotify dieciséis mil');
    });

    test('English: "spend" becomes "spent", "tree" stays when the grammar pass hears [unk]', () {
      final free = _words('spend twelve dollars on lunch and tree on coffee');
      final grammar = [
        _w('spent', 0, 0.4),
        _w('twelve', 0.4, 0.8),
        _w('dollars', 0.8, 1.2),
        _w('[unk]', 1.2, 2.4),
        _w('[unk]', 2.4, 3.6),
      ];
      expect(mergePasses(free, grammar, 'en'), 'spent twelve dollars on lunch and tree on coffee');
    });

    test('Italian: the grammar pass fixes a mis-heard amount, the free pass keeps the name', () {
      // "ho speso quindici euro e cinquanta per il pranzo", with "quindici" heard as "quindi chi".
      final free = [
        _w('ho', 0, 0.2),
        _w('speso', 0.2, 0.6),
        _w('quindi', 0.6, 0.9),
        _w('chi', 0.9, 1.1),
        _w('euro', 1.1, 1.5),
        _w('e', 1.5, 1.6),
        _w('cinquanta', 1.6, 2.1),
        _w('per', 2.1, 2.3),
        _w('il', 2.3, 2.4),
        _w('pranzo', 2.4, 3.0),
      ];
      final grammar = [
        _w('ho', 0, 0.2),
        _w('speso', 0.2, 0.6),
        _w('quindici', 0.6, 1.1),
        _w('euro', 1.1, 1.5),
        _w('e', 1.5, 1.6),
        _w('cinquanta', 1.6, 2.1),
        _w('[unk]', 2.1, 3.0),
      ];
      final merged = mergePasses(free, grammar, 'it');
      expect(merged, 'ho speso quindici euro e cinquanta per il pranzo');
      const eur = ParseContext(
        locale: 'it',
        currency: 'EUR',
        today: '2026-10-26',
        timeZone: 'Europe/Rome',
      );
      final draft = parseSentence(merged, eur).drafts.single;
      expect(draft.amount, 1550);
      expect(draft.name, 'pranzo');
    });

    test('Portuguese: a number word always wins, a name that sounds like a verb stays', () {
      // "gastei vinte e cinco euros em pagamentos", with "vinte" heard as "vindo".
      final free = [
        _w('gastei', 0, 0.5),
        _w('vindo', 0.5, 0.9),
        _w('e', 0.9, 1.0),
        _w('cinco', 1.0, 1.4),
        _w('euros', 1.4, 1.9),
        _w('em', 1.9, 2.0),
        _w('pagamentos', 2.0, 2.8),
      ];
      final grammar = [
        _w('gastei', 0, 0.5),
        _w('vinte', 0.5, 0.9),
        _w('e', 0.9, 1.0),
        _w('cinco', 1.0, 1.4),
        _w('euros', 1.4, 1.9),
        _w('[unk]', 1.9, 2.8),
      ];
      final merged = mergePasses(free, grammar, 'pt');
      expect(merged, 'gastei vinte e cinco euros em pagamentos');
      const eur = ParseContext(
        locale: 'pt',
        currency: 'EUR',
        today: '2026-10-26',
        timeZone: 'Europe/Lisbon',
      );
      final draft = parseSentence(merged, eur).drafts.single;
      expect(draft.amount, 2500);
      expect(draft.name, 'pagamentos');
    });

    group('Italian gate: a doubtful grammar number word does not replace a name', () {
      // Timings and conf are those of the saved synthetic run (macOS voice Alice).
      HeardWord c(String w, double a, double b, double conf) => HeardWord(w, a, b, conf: conf);

      test('"benzina" stays when the grammar pass hears "ventinove" at conf 0.55', () {
        final free = [
          c('benzina', 0, 0.45, 1),
          c('quaranta', 0.45, 0.9, 1),
          c('euro', 0.9, 1.14, 1),
          c('e', 1.14, 1.2, 0.47),
          c('farmacie', 1.2, 1.74, 0.63),
          c('dodici', 1.74, 2.19, 1),
          c('euro', 2.19, 2.52, 1),
        ];
        final grammar = [
          c('ventinove', 0, 0.45, 0.55),
          c('quaranta', 0.45, 0.9, 1),
          c('euro', 0.9, 1.14, 1),
          c('dodici', 1.74, 2.19, 1),
          c('euro', 2.19, 2.52, 1),
        ];
        expect(mergePasses(free, grammar, 'it'), 'benzina quaranta euro e farmacie dodici euro');
      });

      test('"l\'affitto" stays when the grammar pass hears "otto" at conf 0.54', () {
        final free = [
          c("l'aereo", 0, 0.35, 0.67),
          c('pagato', 0.37, 0.78, 1),
          c("l'affitto", 0.78, 1.44, 1),
          c('ottocento', 1.59, 2.19, 1),
          c('euro', 2.19, 2.58, 1),
        ];
        final grammar = [
          c('dollari', 0, 0.3, 0.51),
          c('pagato', 0.39, 0.78, 1),
          c('otto', 1.11, 1.44, 0.54),
          c('ottocento', 1.59, 2.19, 1),
          c('euro', 2.19, 2.55, 1),
        ];
        final merged = mergePasses(free, grammar, 'it');
        expect(merged, "l'aereo pagato l'affitto ottocento euro");
        expect(parseSentence(merged, _eur('it')).drafts.single.amount, 80000);
      });

      test('"duemila" at conf 0.58 still wins over the number word "due"', () {
        final free = [
          c('ho', 0, 0.12, 1),
          c('speso', 0.12, 0.48, 1),
          c('due', 0.48, 0.65, 1),
          c('cinquecento', 0.85, 1.53, 1),
          c('euro', 1.53, 1.8, 1),
          c('per', 1.8, 1.95, 1),
          c('vacanze', 2.04, 2.73, 1),
        ];
        final grammar = [
          c('speso', 0, 0.48, 1),
          c('duemila', 0.48, 0.84, 0.58),
          c('cinquecento', 0.86, 1.53, 1),
          c('euro', 1.53, 1.8, 1),
        ];
        final merged = mergePasses(free, grammar, 'it');
        expect(merged, 'speso duemila cinquecento euro per vacanze');
        expect(parseSentence(merged, _eur('it')).drafts.single.amount, 250000);
      });

      test('a doubtful number word fills a gap, and a sure one still wins over a name', () {
        final gap = mergePasses(
          [c('euro', 1, 1.4, 1)],
          [c('quindici', 0.2, 0.9, 0.5), c('euro', 1, 1.4, 1)],
          'it',
        );
        expect(gap, 'quindici euro');
        final sure = mergePasses([c('quindi', 0, 0.4, 0.6)], [c('quindici', 0, 0.4, 0.9)], 'it');
        expect(sure, 'quindici');
      });

      test('Spanish, English and Portuguese merge as before, whatever the conf', () {
        final free = [_w('gaste', 0, 0.4), _w('almuerzo', 0.4, 0.9)];
        final low = [c('gasté', 0, 0.4, 0.1), c('doce', 0.4, 0.9, 0.1)];
        final sure = [_w('gasté', 0, 0.4), _w('doce', 0.4, 0.9)];
        for (final l in ['es', 'en', 'pt']) {
          expect(mergePasses(free, low, l), mergePasses(free, sure, l), reason: l);
        }
        expect(mergePasses(free, low, 'es'), 'gasté doce');
      });

      test('a result without conf reads as sure, and conf is not part of equality', () {
        expect(wordsOfResult('{"result":[{"word":"a","start":0,"end":1}]}').single.conf, 1);
        expect(
          wordsOfResult('{"result":[{"word":"a","start":0,"end":1,"conf":0.4}]}').single.conf,
          0.4,
        );
        expect(HeardWord('a', 0, 1, conf: 0.2), HeardWord('a', 0, 1));
      });
    });

    test('no grammar pass at all gives the free text', () {
      expect(
        mergePasses(_words('almuerzo dieciocho mil'), const [], 'es'),
        'almuerzo dieciocho mil',
      );
    });
  });

  group('Vosk results', () {
    test('words are read from a result with word timestamps', () {
      const json =
          '{"result":[{"conf":1.0,"end":0.9,"start":0.3,"word":"gaste"},'
          '{"conf":0.8,"end":1.4,"start":0.9,"word":"quince"}],"text":"gaste quince"}';
      expect(wordsOfResult(json), [_w('gaste', 0.3, 0.9), _w('quince', 0.9, 1.4)]);
    });

    test('a result without words (silence) gives none, and junk never throws', () {
      expect(wordsOfResult('{"text":""}'), isEmpty);
      expect(wordsOfResult('not json'), isEmpty);
      expect(wordsOfResult('{"result":[{"word":"x"}]}'), isEmpty);
    });
  });
}
