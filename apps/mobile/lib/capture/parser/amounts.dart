// Amounts in digits and in words, es and en, up to 999 999 999 (spec 5.2 and
// packages/core/quick-capture/README.md, "Number forms").
import 'words.dart';

/// The largest amount read, in currency units.
const maxAmountUnits = 999999999;

/// An exact decimal, [n] / 10^[e]. Amounts never go through a double.
class Dec implements Comparable<Dec> {
  const Dec(this.n, [this.e = 0]);

  final int n;
  final int e;

  static int _pow10(int e) {
    var p = 1;
    for (var i = 0; i < e; i++) {
      p *= 10;
    }
    return p;
  }

  Dec _at(int e) => Dec(n * _pow10(e - this.e), e);

  Dec operator +(Dec other) {
    final e = this.e > other.e ? this.e : other.e;
    return Dec(_at(e).n + other._at(e).n, e);
  }

  Dec times(int k) => Dec(n * k, e);

  bool get isInteger => n % _pow10(e) == 0;

  /// The integer part.
  int get whole => n ~/ _pow10(e);

  /// x100, rounded half up.
  int get cents {
    final d = _pow10(e);
    return (n * 100 * 2 + d) ~/ (2 * d);
  }

  @override
  int compareTo(Dec other) {
    final e = this.e > other.e ? this.e : other.e;
    return _at(e).n.compareTo(other._at(e).n);
  }

  @override
  bool operator ==(Object other) => other is Dec && compareTo(other) == 0;

  @override
  int get hashCode => _at(12).n.hashCode;

  @override
  String toString() => e == 0 ? '$n' : '$n/1e$e';
}

/// An amount found in the tokens `[start, end)`.
class AmountMatch {
  const AmountMatch({
    required this.start,
    required this.end,
    required this.value,
    required this.slang,
  });

  final int start;
  final int end;

  /// In currency units.
  final Dec value;

  /// Read with `luca(s)`/`lukas` or `palo(s)`, which count only in COP.
  final bool slang;

  /// Integer cents, or null when the amount is not usable: zero, or above [maxAmountUnits].
  int? get cents {
    if (value.compareTo(const Dec(0)) <= 0) return null;
    if (value.compareTo(const Dec(maxAmountUnits)) > 0) return null;
    return value.cents;
  }
}

// Words, folded (no accents), by locale.
const _esUnits = {
  'uno': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5, //
  'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9,
};
const _esTeens = {
  'diez': 10, 'once': 11, 'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15, //
  'dieciseis': 16, 'diecisiete': 17, 'dieciocho': 18, 'diecinueve': 19,
  'veintiuno': 21, 'veintiun': 21, 'veintiuna': 21, 'veintidos': 22, 'veintitres': 23,
  'veinticuatro': 24, 'veinticinco': 25, 'veintiseis': 26, 'veintisiete': 27, 'veintiocho': 28,
  'veintinueve': 29,
};
const _esTens = {
  'veinte': 20, 'treinta': 30, 'cuarenta': 40, 'cincuenta': 50, //
  'sesenta': 60, 'setenta': 70, 'ochenta': 80, 'noventa': 90,
};
const _esHundreds = {
  'cien': 100, 'ciento': 100, //
  'doscientos': 200, 'doscientas': 200, 'trescientos': 300, 'trescientas': 300,
  'cuatrocientos': 400, 'cuatrocientas': 400, 'quinientos': 500, 'quinientas': 500,
  'seiscientos': 600, 'seiscientas': 600, 'setecientos': 700, 'setecientas': 700,
  'ochocientos': 800, 'ochocientas': 800, 'novecientos': 900, 'novecientas': 900,
};
const _enUnits = {
  'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, //
  'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
};
const _enTeens = {
  'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15, //
  'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
};
const _enTens = {
  'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50, //
  'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
};

/// Scale words, in every locale. The COP slang units are read everywhere (so `15 lukas` is never
/// taken as a plain 15) and flagged; parse.dart refuses them outside COP.
const _scales = {
  'mil': 1000, 'thousand': 1000, //
  'millon': 1000000, 'millones': 1000000, 'million': 1000000, 'millions': 1000000,
  'luca': 1000, 'lucas': 1000, 'luka': 1000, 'lukas': 1000,
  'palo': 1000000, 'palos': 1000000,
};
const _slangScales = {'luca', 'lucas', 'luka', 'lukas', 'palo', 'palos'};

/// Scale words that are an amount on their own (`gasté mil en chicle`).
const _bareScales = {'mil', 'thousand'};

/// Words that are 1 only right before a scale word (`un millón`, `una luca`, `a thousand`);
/// elsewhere they are articles.
const _oneBeforeScale = {
  'es': {'un', 'una'},
  'en': {'a'},
};

/// Currency words, dropped with their amount (`nueve euros con cincuenta`, `twelve dollars`).
const _currencyWords = {
  'peso', 'pesos', 'euro', 'euros', 'dolar', 'dolares', 'dollar', 'dollars', 'bucks', //
};
const _centWords = {'centavo', 'centavos', 'centimo', 'centimos', 'cent', 'cents'};

const _bigScale = 1 << 62;

class _Reader {
  _Reader(this.tokens, this.locale);

  final List<Token> tokens;
  final String locale;

  bool get _en => locale == 'en';

  /// The folded word at [i], or null past the end or on a number or a comma.
  String? word(int i) {
    if (i < 0 || i >= tokens.length) return null;
    final t = tokens[i];
    return t.isNumber || t.isComma ? null : t.norm;
  }

  bool isNumber(int i) => i < tokens.length && tokens[i].isNumber;

  int? scaleAt(int i) => _scales[word(i)];

  /// A unit 1–9 at [i]; `un`/`una` count only before a scale word (`treinta y un mil`).
  int? _esUnitAt(int i) {
    final w = word(i);
    if (w == null) return null;
    if (_esUnits[w] case final u?) return u;
    if ((w == 'un' || w == 'una') && scaleAt(i + 1) != null) return 1;
    return null;
  }

  /// 1–999 in Spanish words: `[hundreds] [tens [y unit] | 10–29 | unit]`.
  (int, int)? _smallEs(int i) {
    var j = i;
    var v = 0;
    var any = false;
    if (_esHundreds[word(j)] case final h?) {
      v += h;
      j++;
      any = true;
    }
    if (_esTens[word(j)] case final t?) {
      v += t;
      j++;
      any = true;
      if (word(j) == 'y') {
        if (_esUnitAt(j + 1) case final u?) {
          v += u;
          j += 2;
        }
      }
    } else if (_esTeens[word(j)] case final t?) {
      v += t;
      j++;
      any = true;
    } else if (_esUnitAt(j) case final u?) {
      // A lone `un`/`una` is the "one before a scale" of readAmount, not a unit here.
      if (any || (word(j) != 'un' && word(j) != 'una')) {
        v += u;
        j++;
        any = true;
      }
    }
    return any ? (v, j) : null;
  }

  /// 1–999 in English words: `[unit hundred [and]] [tens [unit] | teen | unit]`.
  (int, int)? _smallEn(int i) {
    var j = i;
    var v = 0;
    var any = false;
    final first = word(j);
    final hundreds = first == 'a' ? 1 : _enUnits[first];
    if (hundreds != null && word(j + 1) == 'hundred') {
      v += hundreds * 100;
      j += 2;
      any = true;
      final next = word(j + 1);
      if (word(j) == 'and' &&
          (_enTens.containsKey(next) || _enTeens.containsKey(next) || _enUnits.containsKey(next))) {
        j++;
      }
    }
    if (_enTens[word(j)] case final t?) {
      v += t;
      j++;
      any = true;
      if (_enUnits[word(j)] case final u?) {
        v += u;
        j++;
      }
    } else if (_enTeens[word(j)] case final t?) {
      v += t;
      j++;
      any = true;
    } else if (_enUnits[word(j)] case final u?) {
      v += u;
      j++;
      any = true;
    }
    return any ? (v, j) : null;
  }

  /// A number with no scale word: digits, or words up to 999, with an optional decimal in words
  /// (`cuatro coma tres`, `four point five`).
  (Dec, int)? small(int i) {
    Dec v;
    int j;
    if (isNumber(i)) {
      v = digitsValue(tokens[i].text, locale);
      j = i + 1;
    } else {
      final r = _en ? _smallEn(i) : _smallEs(i);
      if (r == null) return null;
      v = Dec(r.$1);
      j = r.$2;
    }
    if (v.isInteger && word(j) == (_en ? 'point' : 'coma')) {
      final f = _en ? _smallEn(j + 1) : _smallEs(j + 1);
      final fd = f == null && isNumber(j + 1) ? digitsValue(tokens[j + 1].text, locale) : null;
      final frac = f?.$1 ?? (fd != null && fd.isInteger ? fd.whole : null);
      if (frac != null) {
        v = v + Dec(frac, '$frac'.length);
        j = f?.$2 ?? j + 2;
      }
    }
    return (v, j);
  }

  /// Whether [small] at [i] was read from words (not digits).
  bool fromWords(int i) => !isNumber(i);

  AmountMatch? read(int i) {
    var j = i;
    var total = const Dec(0);
    var lastScale = _bigScale;
    var any = false;
    var slang = false;
    while (true) {
      Dec? s;
      var k = j;
      final w = word(j);
      if ((_oneBeforeScale[locale] ?? const {}).contains(w) && scaleAt(j + 1) != null) {
        s = const Dec(1);
        k = j + 1;
      } else if (!_en && w == 'medio' && scaleAt(j + 1) != null) {
        s = const Dec(5, 1);
        k = j + 1;
      } else if (small(j) case (final v, final next)) {
        s = v;
        k = next;
      }
      final scale = scaleAt(k);
      if (s != null && scale != null && scale < lastScale) {
        total = total + s.times(scale);
        lastScale = scale;
        slang = slang || _slangScales.contains(word(k));
        j = k + 1;
        any = true;
        // es "un palo y medio", "dos millones y medio": half of that scale more.
        if (!_en && word(j) == 'y' && (word(j + 1) == 'medio' || word(j + 1) == 'media')) {
          total = total + const Dec(5, 1).times(scale);
          j += 2;
        }
        continue;
      }
      if (s == null && _bareScales.contains(w) && _scales[w]! < lastScale) {
        total = total + Dec(_scales[w]!);
        lastScale = _scales[w]!;
        j++;
        any = true;
        continue;
      }
      if (s != null &&
          scale == null &&
          (lastScale == _bigScale || s.compareTo(Dec(lastScale)) < 0)) {
        total = total + s;
        // en "twelve fifty": two word numbers, the second 10–99, are units and cents.
        if (_en && lastScale == _bigScale && fromWords(j) && s.isInteger && s.whole < 100) {
          final c = fromWords(k) ? _smallEn(k) : null;
          if (c != null && c.$1 >= 10 && c.$1 <= 99 && scaleAt(c.$2) == null) {
            total = total + Dec(c.$1, 2);
            k = c.$2;
          }
        }
        j = k;
        any = true;
      }
      break;
    }
    if (!any) return null;
    final scaled = lastScale != _bigScale;
    if (_currencyWords.contains(word(j))) j++;
    // Units and cents: `nueve con cincuenta`, `9 euros con 50`, `twelve dollars and fifty cents`.
    final joiner = word(j);
    if (!scaled && total.isInteger && (joiner == 'con' || (_en && joiner == 'and'))) {
      final c = small(j + 1);
      if (c != null &&
          c.$1.isInteger &&
          c.$1.whole >= 1 &&
          c.$1.whole <= 99 &&
          scaleAt(c.$2) == null) {
        final hasCentWord = _centWords.contains(word(c.$2));
        if (joiner == 'con' || hasCentWord) {
          total = total + Dec(c.$1.whole, 2);
          j = c.$2;
          if (hasCentWord) j++;
          if (_currencyWords.contains(word(j))) j++;
        }
      }
    }
    return AmountMatch(start: i, end: j, value: total, slang: slang);
  }
}

/// The value of a number written in digits, by the locale's separators (words.dart), with `k`
/// as x1.000.
Dec digitsValue(String text, String locale) {
  var s = text;
  var k = 1;
  if (s.endsWith('k') || s.endsWith('K')) {
    k = 1000;
    s = s.substring(0, s.length - 1);
  }
  String intPart;
  var frac = '';
  if (locale == 'en') {
    final parts = s.replaceAll(',', '').split('.');
    intPart = parts[0];
    if (parts.length > 1) frac = parts[1];
  } else if (s.contains(',')) {
    final parts = s.split(',');
    intPart = parts[0].replaceAll('.', '').replaceAll(' ', '');
    frac = parts[1];
  } else if (RegExp(r'^\d+\.\d{1,2}$').hasMatch(s)) {
    final parts = s.split('.');
    intPart = parts[0];
    frac = parts[1];
  } else {
    intPart = s.replaceAll('.', '').replaceAll(' ', '');
  }
  return Dec(int.parse('$intPart$frac'), frac.length).times(k);
}

/// The longest amount that starts at token [i], or null when none starts there.
AmountMatch? readAmount(List<Token> tokens, int i, String locale) =>
    _Reader(tokens, locale).read(i);

/// The amount, in currency units, when all of [text] is exactly one amount; otherwise null.
/// Used by the tests of the number rules.
Dec? readAmountText(String text, String locale) {
  final tokens = tokenize(text, locale);
  if (tokens.isEmpty) return null;
  final m = readAmount(tokens, 0, locale);
  if (m == null || m.end != tokens.length) return null;
  return m.value;
}
