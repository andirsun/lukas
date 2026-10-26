// Dates: today in the profile's time zone, and the date words of a sentence (spec 5.2,
// packages/core/quick-capture/README.md, "Dates").
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'words.dart';

var _tzReady = false;

/// Today in [timeZone] (an IANA name, the profile's) at the instant [nowUtc], as `YYYY-MM-DD`.
///
/// The date comes from the time zone rules (the `timezone` package's bundled IANA database,
/// loaded once, with no network), never from the phone's UTC offset. An unknown zone name falls
/// back to UTC.
String todayIn(String timeZone, DateTime nowUtc) {
  if (!_tzReady) {
    tzdata.initializeTimeZones();
    _tzReady = true;
  }
  tz.Location location;
  try {
    location = tz.getLocation(timeZone);
  } on tz.LocationNotFoundException {
    location = tz.UTC;
  }
  final local = tz.TZDateTime.from(nowUtc.toUtc(), location);
  return formatDate(local.year, local.month, local.day);
}

String formatDate(int year, int month, int day) =>
    '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}';

DateTime _parse(String date) {
  final p = date.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

/// [date] (`YYYY-MM-DD`) moved by [days], across months, years and leap days.
String addDays(String date, int days) {
  final d = _parse(date);
  final moved = DateTime.utc(d.year, d.month, d.day + days);
  return formatDate(moved.year, moved.month, moved.day);
}

/// Days back from today for each relative date word (folded), in every language.
const _relative = {
  'hoy': 0, 'today': 0, 'ayer': 1, 'yesterday': 1, 'antier': 2, 'anteayer': 2, //
  'oggi': 0, 'ieri': 1, 'altroieri': 2, 'avantieri': 2, //
  'hoje': 0, 'ontem': 1, 'anteontem': 2,
};

/// Weekday words (folded) to [DateTime.weekday] (Monday is 1), in every language.
const _weekdays = {
  'lunes': 1, 'martes': 2, 'miercoles': 3, 'jueves': 4, 'viernes': 5, 'sabado': 6, 'domingo': 7, //
  'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4, 'friday': 5, 'saturday': 6, //
  'sunday': 7,
  'lunedi': 1, 'martedi': 2, 'mercoledi': 3, 'giovedi': 4, 'venerdi': 5, 'sabato': 6, //
  'domenica': 7,
  'segunda': 1, 'terca': 2, 'quarta': 3, 'quinta': 4, 'sexta': 5,
};

// The date words each language reads. Spanish and English read each other's (as they always
// have); Italian and Portuguese read only their own.
const _wordsEsEn = {
  'hoy', 'today', 'ayer', 'yesterday', 'antier', 'anteayer', //
  'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo', //
  'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
};
const _wordsIt = {
  'oggi', 'ieri', 'altroieri', 'avantieri', //
  'lunedi', 'martedi', 'mercoledi', 'giovedi', 'venerdi', 'sabato', 'domenica',
};
const _wordsPt = {
  'hoje', 'ontem', 'anteontem', //
  'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado', 'domingo',
};

// Portuguese weekdays that are also ordinary words (`segunda mão`, `a quinta do lago`).
const _ptAmbiguousWeekdays = {'segunda', 'terca', 'quarta', 'quinta', 'sexta'};
const _ptPrepositions = {'na', 'no', 'de', 'a', 'em'};

// Date phrases of several words, folded, and the date word each one means.
const _phrasesIt = <(List<String>, String)>[
  (['l', 'altro', 'ieri'], 'altroieri'),
  (['altro', 'ieri'], 'altroieri'),
  (['avant', 'ieri'], 'avantieri'),
];
const _phrasesPt = <(List<String>, String)>[
  (['antes', 'de', 'ontem'], 'anteontem'),
];

/// Whether [word] (folded) is a Spanish or English date word.
bool isDateWord(String word) => _wordsEsEn.contains(word);

bool _wordIs(List<Token> tokens, int i, String word) =>
    i < tokens.length && !tokens[i].isNumber && !tokens[i].isComma && tokens[i].norm == word;

/// The date word at token [i] in [locale], as how many tokens it takes and the folded word it
/// means (`dateOf` takes it), or null. `l'altro ieri` is three tokens and means `altroieri`;
/// Portuguese weekdays may be followed by `feira` (`sexta-feira`).
(int, String)? dateAt(List<Token> tokens, int i, String locale) {
  final t = tokens[i];
  if (t.isNumber || t.isComma) return null;
  final phrases = switch (locale) {
    'it' => _phrasesIt,
    'pt' => _phrasesPt,
    _ => const <(List<String>, String)>[],
  };
  for (final (words, key) in phrases) {
    var all = true;
    for (var k = 0; k < words.length && all; k++) {
      all = _wordIs(tokens, i + k, words[k]);
    }
    if (all) return (words.length, key);
  }
  final words = switch (locale) {
    'it' => _wordsIt,
    'pt' => _wordsPt,
    _ => _wordsEsEn,
  };
  // `ç` is a letter of its own to `fold`; Portuguese weekdays are compared with it as `c`.
  final norm = locale == 'pt' ? t.norm.replaceAll('ç', 'c') : t.norm;
  if (!words.contains(norm)) return null;
  if (locale == 'pt' && _ptAmbiguousWeekdays.contains(norm)) {
    if (_wordIs(tokens, i + 1, 'feira')) return (2, norm);
    // Bare: a date only after a preposition (`na quinta`) and before the end of the fragment, a
    // verb or an amount, so `segunda mão` and `na quinta do lago` are names.
    final after = i + 1;
    final prepositionBefore =
        i > 0 && !tokens[i - 1].isNumber && _ptPrepositions.contains(tokens[i - 1].norm);
    final endsHere =
        after >= tokens.length ||
        tokens[after].isComma ||
        tokens[after].isNumber ||
        connectorsFor(locale).contains(tokens[after].norm) ||
        verbsFor(locale).any((v) {
          for (var k = 0; k < v.$1.length; k++) {
            if (!_wordIs(tokens, after + k, v.$1[k])) return false;
          }
          return true;
        });
    return prepositionBefore && endsHere ? (1, norm) : null;
  }
  return (1, norm);
}

/// The date a date word (folded) means, given [today]. A weekday is the most recent one strictly
/// before today, so today's own weekday is a week ago.
String dateOf(String word, String today) {
  if (_relative[word] case final back?) return addDays(today, -back);
  final target = _weekdays[word]!;
  var back = (_parse(today).weekday - target) % 7;
  if (back == 0) back = 7;
  return addDays(today, -back);
}
