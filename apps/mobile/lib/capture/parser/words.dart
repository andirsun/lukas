// Tokens and the small word lists the rules read (packages/core/quick-capture/README.md).

/// Lowercases and drops accents (á→a, ü→u…), for comparing words. `ñ` stays: it is a letter of
/// its own, not an accent.
String fold(String text) {
  final out = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    if (rune >= 0x300 && rune <= 0x36F) continue; // combining accents (decomposed input)
    out.write(_folded[rune] ?? String.fromCharCode(rune));
  }
  return out.toString();
}

const _folded = {
  0xE1: 'a', 0xE0: 'a', 0xE4: 'a', 0xE2: 'a', 0xE3: 'a', //
  0xE9: 'e', 0xE8: 'e', 0xEB: 'e', 0xEA: 'e', //
  0xED: 'i', 0xEC: 'i', 0xEF: 'i', 0xEE: 'i', //
  0xF3: 'o', 0xF2: 'o', 0xF6: 'o', 0xF4: 'o', 0xF5: 'o', //
  0xFA: 'u', 0xF9: 'u', 0xFC: 'u', 0xFB: 'u', //
};

/// A word, a number written in digits, or a comma that is not part of a number.
class Token {
  Token(this.text, this.start, this.end, {this.isNumber = false, this.isComma = false})
    : lower = text.toLowerCase(),
      norm = fold(text);

  /// As written in the sentence.
  final String text;

  /// Offsets in the sentence, so a fragment can be given back as heard.
  final int start;
  final int end;

  final bool isNumber;
  final bool isComma;

  /// Lowercase, accents kept (names are given in this form).
  final String lower;

  /// Lowercase, without accents (every comparison uses this form).
  final String norm;

  @override
  String toString() => text;
}

// Numbers in digits, by locale, with an optional `k` (x1.000) right after them.
//  es: a dot before exactly three digits is thousands, and so is a space (`120 000`); a comma is
//      the decimal. A dot before one or two digits is read as a decimal too (`12.50`).
//  en: a comma before exactly three digits is thousands; a dot is the decimal.
const _kSuffix = r'(?:[kK](?![\p{L}\p{N}]))?';
final _numberEs = RegExp(
  r'(?:\d+\.\d{1,2}(?![\d.])'
  r'|(?:\d{1,3}(?:\.\d{3})+(?!\d)|\d{1,3}(?: \d{3})+(?![\d.])|\d+)(?:,\d+)?)'
  '$_kSuffix',
  unicode: true,
);
final _numberEn = RegExp(
  r'(?:\d{1,3}(?:,\d{3})+(?!\d)|\d+)(?:\.\d+)?'
  '$_kSuffix',
  unicode: true,
);
final _word = RegExp(r'[\p{L}\p{M}]+', unicode: true);

/// Splits [text] into words, numbers and commas. Everything else (spaces, dots ending a sentence,
/// other punctuation) separates tokens and is dropped.
List<Token> tokenize(String text, String locale) {
  final number = locale == 'en' ? _numberEn : _numberEs;
  final tokens = <Token>[];
  var i = 0;
  while (i < text.length) {
    final c = text.codeUnitAt(i);
    if (c >= 0x30 && c <= 0x39) {
      final m = number.matchAsPrefix(text, i)!;
      tokens.add(Token(m[0]!, i, m.end, isNumber: true));
      i = m.end;
      continue;
    }
    if (c == 0x2C) {
      tokens.add(Token(',', i, i + 1, isComma: true));
      i++;
      continue;
    }
    final w = _word.matchAsPrefix(text, i);
    if (w != null) {
      tokens.add(Token(w[0]!, i, w.end));
      i = w.end;
      continue;
    }
    i++;
  }
  return tokens;
}

/// Words that join movements (a comma joins too). They split only where both sides have an
/// amount (split.dart); otherwise they stay in the name (`pan y leche`).
const connectorWords = {'y', 'and', 'tambien', 'also'};

/// Function words and articles, dropped from names. `un` and `una` are numbers before a scale
/// word (amounts.dart reads them first).
const droppedWords = {
  'en', 'de', 'para', 'por', 'on', 'for', //
  'el', 'la', 'los', 'las', 'un', 'una', 'the', 'a', 'an', //
};

/// The verbs of spec 5.2, folded, as word sequences, longest first.
const verbs = <(List<String>, bool)>[
  // (words, isIncome)
  (['me', 'pagaron'], true),
  (['me', 'llego'], true),
  (['got', 'paid'], true),
  (['recibi'], true),
  (['ingreso'], true),
  (['received'], true),
  (['gaste'], false),
  (['pague'], false),
  (['compre'], false),
  (['spent'], false),
  (['paid'], false),
];
