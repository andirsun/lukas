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
