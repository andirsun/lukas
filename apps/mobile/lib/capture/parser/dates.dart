// Dates: today in the profile's time zone, and the date words of a sentence (spec 5.2,
// packages/core/quick-capture/README.md, "Dates").
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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

/// Days back from today for each relative date word (folded).
const _relative = {'hoy': 0, 'today': 0, 'ayer': 1, 'yesterday': 1, 'antier': 2, 'anteayer': 2};

/// Weekday words (folded) to [DateTime.weekday] (Monday is 1).
const _weekdays = {
  'lunes': 1,
  'martes': 2,
  'miercoles': 3,
  'jueves': 4,
  'viernes': 5,
  'sabado': 6,
  'domingo': 7,
  'monday': 1,
  'tuesday': 2,
  'wednesday': 3,
  'thursday': 4,
  'friday': 5,
  'saturday': 6,
  'sunday': 7,
};

/// Whether [word] (folded) is a date word.
bool isDateWord(String word) => _relative.containsKey(word) || _weekdays.containsKey(word);

/// The date a date word (folded) means, given [today]. A weekday is the most recent one strictly
/// before today, so today's own weekday is a week ago.
String dateOf(String word, String today) {
  if (_relative[word] case final back?) return addDays(today, -back);
  final target = _weekdays[word]!;
  var back = (_parse(today).weekday - target) % 7;
  if (back == 0) back = 7;
  return addDays(today, -back);
}
