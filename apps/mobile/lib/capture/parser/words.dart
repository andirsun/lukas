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

// Numbers in digits, with an optional `k` (x1.000) right after them. A dot or comma before
// exactly three digits is a thousands separator; a last dot or comma before one or two digits is
// the decimal (amounts.dart, readDigits). In es, a space before three digits is thousands too
// (`120 000`; Whisper writes that).
const _kSuffix = r'(?:[kK](?![\p{L}\p{N}]))?';
// A separator before four or more digits (`12,5000`) is taken into the number, which is then
// malformed and unread (readDigits), rather than a connector.
const _fraction = r'(?:[.,]\d{1,2}(?!\d)|[.,]\d{4,})?';
const _digits =
    r'\d+(?:[.,]\d{3}(?!\d))*'
    '$_fraction';
final _numberEs = RegExp(
  r'(?:\d{1,3}(?: \d{3})+(?!\d)'
  '$_fraction|'
  '$_digits)$_kSuffix',
  unicode: true,
);
final _numberEn = RegExp('$_digits$_kSuffix', unicode: true);

// A word starts with a letter and keeps the digits glued to it (`D1`, `MiTienda24`), except a
// scale word, which lets go of the digits after it (`2mil500` is `2`, `mil`, `500`).
final _word = RegExp(r'[\p{L}\p{M}][\p{L}\p{M}\p{N}]*', unicode: true);
final _letters = RegExp(r'[\p{L}\p{M}]+', unicode: true);

/// Scale words (folded) that split from digits glued after them.
const gluedScaleWords = {
  'mil', 'millon', 'millones', 'palo', 'palos', 'luca', 'lucas', 'luka', 'lukas', //
  'thousand', 'million', 'millions', 'k',
};
const _gluedScaleWordsIt = {'mila', 'mille', 'milione', 'milioni', 'k'};
const _gluedScaleWordsPt = {'mil', 'milhao', 'milhoes', 'k'};

Set<String> _gluedScalesFor(String locale) => switch (locale) {
  'it' => _gluedScaleWordsIt,
  'pt' => _gluedScaleWordsPt,
  _ => gluedScaleWords,
};

/// Splits [text] into words, numbers and commas. Everything else (spaces, dots ending a sentence,
/// other punctuation) separates tokens and is dropped.
List<Token> tokenize(String text, String locale) {
  final number = locale == 'en' ? _numberEn : _numberEs;
  final glued = _gluedScalesFor(locale);
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
      final letters = _letters.matchAsPrefix(text, i)!;
      final end = letters.end < w.end && glued.contains(fold(letters[0]!)) ? letters.end : w.end;
      final word = text.substring(i, end);
      // Italian writes a number as one word (`quindicimila`): read it as the words it is made of.
      final parts = locale == 'it' && letters.end == end ? italianNumberParts(fold(word)) : null;
      if (parts != null) {
        for (final part in parts) {
          tokens.add(Token(part, i, end));
        }
      } else {
        tokens.add(Token(word, i, end));
      }
      i = end;
      continue;
    }
    i++;
  }
  return tokens;
}

/// Words that join movements (a comma joins too). They split only where both sides have an
/// amount (split.dart); otherwise they stay in the name (`pan y leche`).
const connectorWords = {'y', 'and', 'tambien', 'also'};
const _connectorWordsIt = {'e', 'ed', 'anche'};
const _connectorWordsPt = {'e', 'tambem'};

/// The connector words [locale] reads. Spanish and English read each other's.
Set<String> connectorsFor(String locale) => switch (locale) {
  'it' => _connectorWordsIt,
  'pt' => _connectorWordsPt,
  _ => connectorWords,
};

/// Function words and articles, dropped from names. `un` and `una` are numbers before a scale
/// word (amounts.dart reads them first).
const droppedWords = {
  'en', 'de', 'para', 'por', 'on', 'for', //
  'el', 'la', 'los', 'las', 'un', 'una', 'the', 'a', 'an', //
};

const _droppedWordsIt = {
  'in', 'per', 'al', 'alla', 'allo', 'ai', 'alle', 'all', 'di', 'del', 'della', 'dello', 'dei', //
  'delle', 'dell', 'd', 'da', 'a', 'il', 'lo', 'la', 'i', 'gli', 'le', 'l', 'un', 'uno', 'una', //
  'nel', 'nella', 'nello', 'nei', 'nelle', 'nell', 'sul', 'sulla', 'sullo', 'sui', 'sulle', //
  'sugli', 'sull', 'dal', 'dalla', 'dallo', 'dai', 'dalle', 'dagli', 'dall',
};
const _droppedWordsPt = {
  'em', 'no', 'na', 'nos', 'nas', 'para', 'pra', 'de', 'do', 'da', 'dos', 'das', 'por', 'pelo', //
  'pela', 'pelos', 'pelas', 'ao', 'aos', 'a', 'as', 'o', 'os', 'um', 'uma', 'uns', 'umas',
};

/// The function words and articles [locale] drops from names.
Set<String> droppedFor(String locale) => switch (locale) {
  'it' => _droppedWordsIt,
  'pt' => _droppedWordsPt,
  _ => droppedWords,
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

const _verbsIt = <(List<String>, bool)>[
  (['mi', 'hanno', 'pagato'], true),
  (['ho', 'ricevuto'], true),
  (['ho', 'guadagnato'], true),
  (['ho', 'incassato'], true),
  (['ricevuto'], true),
  (['guadagnato'], true),
  (['incassato'], true),
  (['ho', 'speso'], false),
  (['ho', 'pagato'], false),
  (['ho', 'comprato'], false),
  (['speso'], false),
  (['pagato'], false),
  (['comprato'], false),
];
const _verbsPt = <(List<String>, bool)>[
  (['me', 'pagaram'], true),
  (['pagaram', 'me'], true),
  (['recebi'], true),
  (['ganhei'], true),
  (['gastei'], false),
  (['paguei'], false),
  (['comprei'], false),
];

/// The verbs [locale] reads, longest first.
List<(List<String>, bool)> verbsFor(String locale) => switch (locale) {
  'it' => _verbsIt,
  'pt' => _verbsPt,
  _ => verbs,
};

// Italian writes a number as one word: `trentacinque`, `centoventi`, `duemilacinquecento`.
// italianNumberParts splits such a word into the words amounts.dart reads.

const _itUnits = {
  'uno': 1, 'due': 2, 'tre': 3, 'quattro': 4, 'cinque': 5, 'sei': 6, 'sette': 7, 'otto': 8, //
  'nove': 9,
};
const _itTeens = {
  'dieci': 10, 'undici': 11, 'dodici': 12, 'tredici': 13, 'quattordici': 14, 'quindici': 15, //
  'sedici': 16, 'diciassette': 17, 'diciotto': 18, 'diciannove': 19,
};
const _itTens = {
  'venti': 20, 'trenta': 30, 'quaranta': 40, 'cinquanta': 50, 'sessanta': 60, 'settanta': 70, //
  'ottanta': 80, 'novanta': 90,
};

/// Italian number words (folded) from 1 to 999, with the glued and the elided forms.
final Map<String, int> italianNumbers = _buildItalianNumbers();

Map<String, int> _buildItalianNumbers() {
  final below100 = <String, int>{..._itUnits, ..._itTeens, ..._itTens};
  _itTens.forEach((ten, tv) {
    // `venti` + `uno` is `ventuno`; the final vowel drops before `uno` and `otto`.
    final stem = ten.substring(0, ten.length - 1);
    _itUnits.forEach((unit, uv) {
      below100['${unit == 'uno' || unit == 'otto' ? stem : ten}$unit'] = tv + uv;
    });
  });
  final all = <String, int>{...below100};
  final hundreds = <String, int>{'cento': 100};
  _itUnits.forEach((unit, uv) {
    if (uv > 1) hundreds['${unit}cento'] = uv * 100;
  });
  hundreds.forEach((hundred, hv) {
    all[hundred] = hv;
    below100.forEach((rest, rv) {
      all['$hundred$rest'] = hv + rv;
      // `cento` + `ottanta` is `centottanta`.
      if (rest.startsWith('o')) all['${hundred.substring(0, hundred.length - 1)}$rest'] = hv + rv;
    });
  });
  return all;
}

/// The words an Italian number word [folded] is made of, when it is one number written as a
/// single word with a thousand in it (`quindicimila` is `quindici`, `mila`; `milleduecento` is
/// `mille`, `duecento`), else null.
List<String>? italianNumberParts(String folded) {
  for (final scale in const ['mila', 'mille']) {
    final at = folded.indexOf(scale);
    if (at < 0) continue;
    final head = folded.substring(0, at);
    final tail = folded.substring(at + scale.length);
    if (scale == 'mille' ? head.isNotEmpty : !italianNumbers.containsKey(head)) continue;
    if (tail.isNotEmpty && !italianNumbers.containsKey(tail)) continue;
    if (head.isEmpty && tail.isEmpty) return null;
    return [if (head.isNotEmpty) head, scale, if (tail.isNotEmpty) tail];
  }
  return null;
}
