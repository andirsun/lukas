// Amounts in digits and in words, es and en, up to 999 999 999 (spec 5.2 and
// packages/core/quick-capture/README.md, "Number forms").
import 'words.dart';

/// The largest amount read, in currency units.
const maxAmountUnits = 999999999;

/// An exact decimal, [n] / 10^[e], on [BigInt] so no digit run can overflow it. Amounts never
/// go through a double.
class Dec implements Comparable<Dec> {
  Dec(int n, [int e = 0]) : this.big(BigInt.from(n), e);
  Dec.big(this.n, [this.e = 0]);

  static final zero = Dec(0);
  static final half = Dec(5, 1);

  final BigInt n;
  final int e;

  static final _ten = BigInt.from(10);

  Dec _at(int e) => Dec.big(n * _ten.pow(e - this.e), e);

  Dec operator +(Dec other) {
    final e = this.e > other.e ? this.e : other.e;
    return Dec.big(_at(e).n + other._at(e).n, e);
  }

  Dec times(int k) => Dec.big(n * BigInt.from(k), e);

  Dec timesDec(Dec other) => Dec.big(n * other.n, e + other.e);

  bool get isInteger => n % _ten.pow(e) == BigInt.zero;

  /// The integer part.
  BigInt get whole => n ~/ _ten.pow(e);

  /// Whether this is an integer from [low] to [high].
  bool isIntegerIn(int low, int high) =>
      isInteger && whole >= BigInt.from(low) && whole <= BigInt.from(high);

  /// x100, rounded half up. Only for values that fit an int (callers check the cap first).
  int get cents {
    final d = _ten.pow(e);
    return ((n * BigInt.from(200) + d) ~/ (d * BigInt.two)).toInt();
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
    this.ambiguous = false,
  });

  final int start;
  final int end;

  /// In currency units.
  final Dec value;

  /// Read with `luca(s)`/`lukas` or `palo(s)`, which count only in COP.
  final bool slang;

  /// Digits with a thousands separator before a scale word (`4,300 palos`): 4,3 or 4.300?
  final bool ambiguous;

  /// Integer cents, or null when the amount is not usable: ambiguous, zero, or above
  /// [maxAmountUnits].
  int? get cents {
    if (ambiguous) return null;
    if (value.compareTo(Dec.zero) <= 0) return null;
    if (value.compareTo(Dec(maxAmountUnits)) > 0) return null;
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

// Italian and Portuguese words, folded.
const _ptUnits = {
  'um': 1, 'uma': 1, 'dois': 2, 'duas': 2, 'tres': 3, 'quatro': 4, 'cinco': 5, 'seis': 6, //
  'sete': 7, 'oito': 8, 'nove': 9,
};
const _ptTeens = {
  'dez': 10, 'onze': 11, 'doze': 12, 'treze': 13, 'catorze': 14, 'quatorze': 14, 'quinze': 15, //
  'dezasseis': 16, 'dezassete': 17, 'dezoito': 18, 'dezanove': 19, //
  // The voice model is trained on Brazilian speech, so its spellings are read too.
  'dezesseis': 16, 'dezessete': 17, 'dezenove': 19,
};
const _ptTens = {
  'vinte': 20, 'trinta': 30, 'quarenta': 40, 'cinquenta': 50, //
  'sessenta': 60, 'setenta': 70, 'oitenta': 80, 'noventa': 90,
};
const _ptHundreds = {
  'cem': 100, 'cento': 100, 'duzentos': 200, 'duzentas': 200, 'trezentos': 300, //
  'trezentas': 300, 'quatrocentos': 400, 'quatrocentas': 400, 'quinhentos': 500, //
  'quinhentas': 500, 'seiscentos': 600, 'seiscentas': 600, 'setecentos': 700, //
  'setecentas': 700, 'oitocentos': 800, 'oitocentas': 800, 'novecentos': 900, 'novecentas': 900,
};
const _scalesIt = {'mila': 1000, 'mille': 1000, 'milione': 1000000, 'milioni': 1000000, 'k': 1000};
const _scalesPt = {'mil': 1000, 'milhao': 1000000, 'milhoes': 1000000, 'k': 1000};

/// Scale words, in every locale. The COP slang units are read everywhere (so `15 lukas` is never
/// taken as a plain 15) and flagged; parse.dart refuses them outside COP.
const _scales = {
  'mil': 1000, 'thousand': 1000, //
  'millon': 1000000, 'millones': 1000000, 'million': 1000000, 'millions': 1000000,
  'luca': 1000, 'lucas': 1000, 'luka': 1000, 'lukas': 1000,
  'palo': 1000000, 'palos': 1000000,
  'k': 1000,
};
const _slangScales = {'luca', 'lucas', 'luka', 'lukas', 'palo', 'palos'};

/// Scale words that are an amount on their own (`gasté mil en chicle`).
const _bareScales = {'mil', 'thousand'};
const _bareScalesIt = {'mille'};
const _bareScalesPt = {'mil'};

/// Words that are 1 only right before a scale word (`un millón`, `una luca`, `a thousand`);
/// elsewhere they are articles.
const _oneBeforeScale = {
  'es': {'un', 'una'},
  'en': {'a'},
  'it': {'un', 'una'},
  'pt': {'um', 'uma'},
};

/// `medio palo`: half, right before a scale word.
const _halfBeforeScale = {
  'es': {'medio'},
  'it': {'mezzo'},
  'pt': {'meio'},
};

/// After a scale word, a joiner and a word that add half of it (`un palo y medio`).
const _halfAfterScale = {
  'es': ('y', {'medio', 'media'}),
  'it': ('e', {'mezzo', 'mezza'}),
  'pt': ('e', {'meio', 'meia'}),
};

/// Currency words, dropped with their amount (`nueve euros con cincuenta`, `twelve dollars`).
const _currencyWords = {
  'peso', 'pesos', 'euro', 'euros', 'dolar', 'dolares', 'dollar', 'dollars', 'bucks', //
};
const _centWords = {'centavo', 'centavos', 'centimo', 'centimos', 'cent', 'cents'};
const _currencyWordsIt = {'euro', 'dollaro', 'dollari'};
const _centWordsIt = {'centesimo', 'centesimi', 'cent'};
const _currencyWordsPt = {'euro', 'euros', 'dolar', 'dolares'};
const _centWordsPt = {'centimo', 'centimos', 'centavo', 'centavos', 'cent'};

const _bigScale = 1 << 62;

class _Reader {
  _Reader(this.tokens, this.locale);

  final List<Token> tokens;
  final String locale;

  bool get _en => locale == 'en';
  bool get _it => locale == 'it';
  bool get _pt => locale == 'pt';

  /// Italian and Portuguese let a spelled-out number follow `e` after a scale (`mil e quinhentos`).
  bool get _eJoins => _it || _pt;

  Map<String, int> get _scaleWords => switch (locale) {
    'it' => _scalesIt,
    'pt' => _scalesPt,
    _ => _scales,
  };
  Set<String> get _bare => switch (locale) {
    'it' => _bareScalesIt,
    'pt' => _bareScalesPt,
    _ => _bareScales,
  };
  Set<String> get _currency => switch (locale) {
    'it' => _currencyWordsIt,
    'pt' => _currencyWordsPt,
    _ => _currencyWords,
  };
  Set<String> get _cents => switch (locale) {
    'it' => _centWordsIt,
    'pt' => _centWordsPt,
    _ => _centWords,
  };
  String get _decimalWord => switch (locale) {
    'en' => 'point',
    'it' => 'virgola',
    'pt' => 'virgula',
    _ => 'coma',
  };

  /// The folded word at [i], or null past the end or on a number or a comma.
  String? word(int i) {
    if (i < 0 || i >= tokens.length) return null;
    final t = tokens[i];
    return t.isNumber || t.isComma ? null : t.norm;
  }

  bool isNumber(int i) => i < tokens.length && tokens[i].isNumber;

  int? scaleAt(int i) => _scaleWords[word(i)];

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

  /// 1–99 in English words: `tens [unit] | teen | unit`.
  (int, int)? _below100En(int j) {
    if (_enTens[word(j)] case final t?) {
      if (_enUnits[word(j + 1)] case final u?) return (t + u, j + 2);
      return (t, j + 1);
    }
    if (_enTeens[word(j)] case final t?) return (t, j + 1);
    if (_enUnits[word(j)] case final u?) return (u, j + 1);
    return null;
  }

  /// 1–9 999 in English words: `[(a | 1–99) hundred [and]] [1–99]`, so `two hundred fifty` and
  /// `twelve hundred` (1 200).
  (int, int)? _smallEn(int i) {
    var j = i;
    var v = 0;
    var any = false;
    final h = word(j) == 'a' && word(j + 1) == 'hundred' ? (1, j + 1) : _below100En(j);
    if (h != null && word(h.$2) == 'hundred') {
      v = h.$1 * 100;
      j = h.$2 + 1;
      any = true;
      if (word(j) == 'and' && _below100En(j + 1) != null) j++;
    }
    if (_below100En(j) case (final r, final next)) {
      v += r;
      j = next;
      any = true;
    }
    return any ? (v, j) : null;
  }

  /// 1–999 in Italian words, each written as one word (`trentacinque`, `centoventi`), or a round
  /// hundred followed by its tens (`cento venti`).
  (int, int)? _smallIt(int i) {
    final v = italianNumbers[word(i)];
    if (v == null) return null;
    if (v % 100 == 0) {
      final rest = italianNumbers[word(i + 1)];
      if (rest != null && rest < 100) return (v + rest, i + 2);
    }
    return (v, i + 1);
  }

  /// A unit 1–9 in Portuguese at [i]; `um`/`uma` count right after `e`, or before a scale word.
  int? _ptUnitAt(int i, {bool afterE = false}) {
    final w = word(i);
    if (w == null) return null;
    final u = _ptUnits[w];
    if (u == null) return null;
    if (w == 'um' || w == 'uma') return afterE || scaleAt(i + 1) != null ? 1 : null;
    return u;
  }

  /// 1–99 in Portuguese words: `tens [e unit] | 10–19 | unit`.
  (int, int)? _belowHundredPt(int j) {
    if (_ptTens[word(j)] case final t?) {
      if (word(j + 1) == 'e') {
        if (_ptUnitAt(j + 2, afterE: true) case final u?) return (t + u, j + 3);
      }
      return (t, j + 1);
    }
    if (_ptTeens[word(j)] case final t?) return (t, j + 1);
    if (_ptUnitAt(j) case final u?) return (u, j + 1);
    return null;
  }

  /// 1–999 in Portuguese words: `[hundreds [e 1–99]] | 1–99` (`cento e vinte`; `cem` stands alone).
  (int, int)? _smallPt(int i) {
    if (_ptHundreds[word(i)] case final h?) {
      if (word(i) != 'cem' && word(i + 1) == 'e') {
        if (_belowHundredPt(i + 2) case (final rest, final next)) return (h + rest, next);
      }
      return (h, i + 1);
    }
    return _belowHundredPt(i);
  }

  (int, int)? _words(int i) => switch (locale) {
    'en' => _smallEn(i),
    'it' => _smallIt(i),
    'pt' => _smallPt(i),
    _ => _smallEs(i),
  };

  /// A number with no scale word: digits, or words, with an optional decimal in words
  /// (`cuatro coma tres`, `10 coma 05`, `four point five`). `grouped` says the digits carry a
  /// thousands separator.
  ({Dec value, int next, bool grouped, bool ambiguous})? small(int i) {
    Dec v;
    int j;
    var grouped = false;
    var ambiguous = false;
    if (isNumber(i)) {
      final d = readDigits(tokens[i].text);
      v = d.value;
      grouped = d.grouped;
      ambiguous = d.ambiguous;
      j = i + 1;
    } else {
      final r = _words(i);
      if (r == null) return null;
      v = Dec(r.$1);
      j = r.$2;
    }
    if (v.isInteger && word(j) == _decimalWord) {
      // The decimals keep their written length: `05` is five hundredths.
      String? frac;
      var next = j + 2;
      if (isNumber(j + 1) && RegExp(r'^\d{1,3}$').hasMatch(tokens[j + 1].text)) {
        frac = tokens[j + 1].text;
      } else if (_words(j + 1) case (final f, final n)) {
        frac = '$f';
        next = n;
      }
      if (frac != null) {
        v = v + Dec(int.parse(frac), frac.length);
        j = next;
      }
    }
    return (value: v, next: j, grouped: grouped, ambiguous: ambiguous);
  }

  AmountMatch? read(int i) {
    var j = i;
    var total = Dec.zero;
    var lastScale = _bigScale;
    var any = false;
    var slang = false;
    var ambiguous = false;
    var currencyWord = false;

    // After a scale word: es `y medio`/`y media` adds half of it (`un palo y medio`).
    void halfMore(int scale) {
      if (_halfAfterScale[locale] case (final joiner, final halves)) {
        if (word(j) == joiner && halves.contains(word(j + 1))) {
          total = total + Dec.half.times(scale);
          j += 2;
        }
      }
    }

    while (true) {
      // A larger scale right after a scale multiplies everything so far: `mil millones`.
      final bigger = scaleAt(j);
      if (any && lastScale != _bigScale && bigger != null && bigger > lastScale) {
        total = total.times(bigger);
        lastScale = bigger;
        slang = slang || _slangScales.contains(word(j));
        j++;
        continue;
      }
      // it, pt: after a scale, a spelled-out number may follow an `e` (`mil e quinhentos`). Digits
      // do not: `mille e 3 per l'uber` is two movements.
      var p = j;
      if (_eJoins && any && lastScale != _bigScale && word(j) == 'e' && !isNumber(j + 1)) p = j + 1;
      Dec? s;
      var k = p;
      var grouped = false;
      var sAmbiguous = false;
      final w = word(p);
      if ((_oneBeforeScale[locale] ?? const {}).contains(w) && scaleAt(p + 1) != null) {
        s = Dec(1);
        k = p + 1;
      } else if ((_halfBeforeScale[locale] ?? const {}).contains(w) && scaleAt(p + 1) != null) {
        s = Dec.half;
        k = p + 1;
      } else if (small(p) case final r?) {
        s = r.value;
        k = r.next;
        grouped = r.grouped;
        sAmbiguous = r.ambiguous;
      }
      final scale = scaleAt(k);
      if (s != null && scale != null && scale < lastScale) {
        total = total + s.times(scale);
        lastScale = scale;
        slang = slang || _slangScales.contains(word(k));
        ambiguous = ambiguous || grouped || sAmbiguous;
        j = k + 1;
        any = true;
        halfMore(scale);
        continue;
      }
      if (s == null && _bare.contains(w) && _scaleWords[w]! < lastScale) {
        total = total + Dec(_scaleWords[w]!);
        lastScale = _scaleWords[w]!;
        j = p + 1;
        any = true;
        halfMore(lastScale);
        continue;
      }
      if (s != null &&
          scale == null &&
          (lastScale == _bigScale || s.compareTo(Dec(lastScale)) < 0)) {
        total = total + s;
        ambiguous = ambiguous || sAmbiguous;
        // en "twelve fifty": two word numbers, the second 10–99, are units and cents.
        if (_en && lastScale == _bigScale && !isNumber(j) && s.isIntegerIn(1, 99)) {
          final c = isNumber(k) ? null : _below100En(k);
          if (c != null && c.$1 >= 10 && scaleAt(c.$2) == null && word(c.$2) != 'hundred') {
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
    if (_currency.contains(word(j))) {
      j++;
      currencyWord = true;
    }
    // Units and cents: `nueve con cincuenta`, `9 euros con 50`, `twelve dollars and fifty cents`.
    // it, pt: `quindici euro e cinquanta`; the `e` joins only right after the currency word, and
    // only to a number from 10 to 99 (or with a cent word), so `15 euro e 3 per l'uber` splits.
    final joiner = word(j);
    final eCents = _eJoins && currencyWord && joiner == 'e';
    if (!scaled &&
        total.isInteger &&
        (joiner == 'con' && !_eJoins || (_en && joiner == 'and') || eCents)) {
      final c = small(j + 1);
      if (c != null && !c.ambiguous && c.value.isIntegerIn(1, 99) && scaleAt(c.next) == null) {
        final hasCentWord = _cents.contains(word(c.next));
        if (!eCents || hasCentWord || c.value.isIntegerIn(10, 99)) {
          if (joiner == 'con' || hasCentWord || eCents) {
            total = total + Dec.big(c.value.whole, 2);
            j = c.next;
            if (hasCentWord) j++;
            if (_currency.contains(word(j))) j++;
          }
        }
      }
    }
    return AmountMatch(start: i, end: j, value: total, slang: slang, ambiguous: ambiguous);
  }
}

/// More integer digits than this are above any amount read; they are not parsed.
const _maxIntegerDigits = 15;

/// The value of a number token in digits (words.dart), the same in every locale and currency:
/// - a dot or comma followed by exactly three digits is a thousands separator (cents have two);
/// - a last dot or comma followed by one or two digits is the decimal;
/// - a space before three digits is thousands (`120 000`, es);
/// - `k` after the digits is x1.000.
/// `grouped` is true when a thousands separator was used, and `ambiguous` when one was used with
/// `k` (`1,500k`).
({Dec value, bool grouped, bool ambiguous}) readDigits(String text) {
  var s = text;
  var k = 1;
  if (s.endsWith('k') || s.endsWith('K')) {
    k = 1000;
    s = s.substring(0, s.length - 1);
  }
  // A separator before four or more digits (`12,5000`): neither thousands nor cents.
  if (RegExp(r'[.,]\d{4,}$').hasMatch(s)) {
    return (value: Dec.zero, grouped: false, ambiguous: true);
  }
  var frac = '';
  final decimal = RegExp(r'[.,](\d{1,2})$').firstMatch(s);
  if (decimal != null) {
    frac = decimal[1]!;
    s = s.substring(0, decimal.start);
  }
  final grouped = RegExp(r'[., ]').hasMatch(s);
  var digits = s.replaceAll(RegExp(r'[., ]'), '').replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (digits.length > _maxIntegerDigits) digits = '1${'0' * _maxIntegerDigits}';
  final value = Dec.big(BigInt.parse('$digits$frac'), frac.length).times(k);
  return (value: value, grouped: grouped, ambiguous: grouped && k != 1);
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
