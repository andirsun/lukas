// Merges Vosk's two passes over the same audio into one transcript (voice spike report, "Merge
// rules", rule v2), at word level by timestamps. The rules parser then reads the merged text
// unchanged. Pure Dart.
import 'dart:convert';
import 'dart:math' as math;

import '../parser/words.dart' show fold;
import 'grammar.dart';

/// A word one pass heard, with its time in seconds from the start of the audio.
class HeardWord {
  const HeardWord(this.word, this.start, this.end, {this.conf = 1});

  final String word;

  /// How sure the recognizer was, 0 to 1 (Vosk's `conf`; 1 when the result has none). Only the
  /// Italian gate in [mergePasses] reads it, so it is not part of equality.
  final double conf;
  final double start;
  final double end;

  double get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is HeardWord && other.word == word && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(word, start, end);

  @override
  String toString() => '$word[$start–$end]';
}

/// The words of one Vosk result (`getResult()`, `getFinalResult()`) made with `setWords(true)`:
/// `{"result": [{"word", "start", "end", "conf"}…], "text"}`. None for silence, and never throws.
List<HeardWord> wordsOfResult(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is! Map || decoded['result'] is! List) return const [];
    return [
      for (final w in decoded['result'] as List)
        if (w is Map && w['word'] is String && w['start'] is num && w['end'] is num)
          HeardWord(
            w['word'] as String,
            (w['start'] as num).toDouble(),
            (w['end'] as num).toDouble(),
            conf: w['conf'] is num ? (w['conf'] as num).toDouble() : 1,
          ),
    ];
  } on FormatException {
    return const [];
  }
}

/// Below this `conf`, an Italian grammar-pass number word does not replace a free word that is
/// not grammar vocabulary (measured on synthetic speech: the false ones were 0.51-0.55, the good
/// ones 1.0 apart from one correct "duemila" at 0.58 over a number word). To re-check on the
/// recorded run (docs/superpowers/reports/2026-10-26-it-pt-voice-spike.md).
const italianNumberConf = 0.7;

/// Whether [a] and [b] overlap: their shared time covers at least half of either word.
bool overlaps(HeardWord a, HeardWord b) {
  final shared = math.min(a.end, b.end) - math.max(a.start, b.start);
  if (shared <= 0) return false;
  // A hair of slack for times like 1.0 − 0.9, which is a little under 0.1 in floating point.
  const slack = 1e-9;
  return (a.length > 0 && shared + slack >= a.length / 2) ||
      (b.length > 0 && shared + slack >= b.length / 2);
}

/// Normalized edit similarity, 1 − distance ÷ longer length, on lowercase words without accents.
double similarity(String a, String b) {
  final x = fold(a);
  final y = fold(b);
  final longer = math.max(x.length, y.length);
  if (longer == 0) return 1;
  return 1 - _distance(x, y) / longer;
}

int _distance(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = math.min(math.min(current[j - 1] + 1, previous[j] + 1), previous[j - 1] + cost);
    }
    previous = current;
  }
  return previous[b.length];
}

/// Rule v2:
/// - number words (numbers, multipliers, medio, coma, punto, con) from the grammar pass always
///   win over the free words they overlap;
/// - a grammar currency, kind, date or separator word replaces the free words it overlaps only if
///   each of them is grammar vocabulary itself or looks like it (similarity ≥ 0.5, such as
///   "este"/"gasté"); otherwise the free words stay, as part of a name, and the grammar word goes;
/// - free words that overlap nothing are kept, and so are grammar words that overlap nothing.
///   For number words that follows from "always win" (s08 needs a "doce" the free pass lost). For
///   currency, kind, date and separator words it is a deliberate extension of v2, which says
///   nothing about them: it can add a "y", "me" or "hoy" only the grammar pass heard. Revisit it
///   at the phone test with real voices;
/// - `[unk]` grammar words are ignored.
///
/// The result is the kept words in time order, separated by spaces.
String mergePasses(List<HeardWord> free, List<HeardWord> grammar, String locale) {
  final keptFree = List<bool>.filled(free.length, true);
  final keptGrammar = <HeardWord>[];
  final heard = [
    for (final g in grammar)
      if (grammarClass(g.word, locale) case final cls?) (word: g, cls: cls),
  ];

  // Number words first: they always win. Italian has about a thousand of them in its grammar, so
  // the pass sometimes hears one in a plain name ("benzina" as "ventinove", conf 0.55): there a
  // doubtful one (conf under [italianNumberConf]) that would replace a word that is not grammar
  // vocabulary does not win. Over a number word it still does ("due" fixed to "duemila").
  for (final g in heard.where((h) => h.cls == GrammarClass.number)) {
    if (locale == 'it' && g.word.conf < italianNumberConf) {
      final overName = free.any((f) => overlaps(f, g.word) && grammarClass(f.word, locale) == null);
      if (overName) continue;
    }
    for (var i = 0; i < free.length; i++) {
      if (overlaps(free[i], g.word)) keptFree[i] = false;
    }
    keptGrammar.add(g.word);
  }
  for (final g in heard.where((h) => h.cls != GrammarClass.number)) {
    final under = [
      for (var i = 0; i < free.length; i++)
        if (keptFree[i] && overlaps(free[i], g.word)) i,
    ];
    final replaces = under.every(
      (i) =>
          grammarClass(free[i].word, locale) != null ||
          similarity(free[i].word, g.word.word) >= 0.5,
    );
    if (!replaces) continue;
    for (final i in under) {
      keptFree[i] = false;
    }
    keptGrammar.add(g.word);
  }

  final words = [
    for (var i = 0; i < free.length; i++)
      if (keptFree[i]) free[i],
    ...keptGrammar,
  ]..sort((a, b) => a.start.compareTo(b.start));
  return words.map((w) => w.word).join(' ');
}
