// Merges Vosk's two passes over the same audio into one transcript (voice spike report, "Merge
// rules", rule v2), at word level by timestamps. The rules parser then reads the merged text
// unchanged. Pure Dart.
import 'dart:convert';
import 'dart:math' as math;

import '../parser/words.dart' show fold;
import 'grammar.dart';

/// A word one pass heard, with its time in seconds from the start of the audio.
class HeardWord {
  const HeardWord(this.word, this.start, this.end);

  final String word;
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
          ),
    ];
  } on FormatException {
    return const [];
  }
}

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
/// - free words that overlap nothing are kept, and so are grammar words that overlap nothing;
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

  // Number words first: they always win.
  for (final g in heard.where((h) => h.cls == GrammarClass.number)) {
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
