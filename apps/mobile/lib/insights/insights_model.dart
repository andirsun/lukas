// A port of apps/web/app/features/insights/insights-model.ts: the periods Análisis looks at, how
// they are named, and the figures its charts and legends show.
import 'package:intl/intl.dart';

import '../home/home_format.dart';
import '../ui/month_picker.dart' show addMonths;

/// How many months the insights look at, ending at the month on screen (`SPANS`).
const spans = [1, 3, 6, 12];

/// Whether [value] is one of the [spans] (`isSpan`).
bool isSpan(int value) => spans.contains(value);

/// A run of whole months, both ends included (`Period`). `YYYY-MM` each.
class Period {
  const Period(this.from, this.to);

  final String from;
  final String to;

  @override
  bool operator ==(Object other) => other is Period && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'Period($from, $to)';
}

/// The [span] months ending at [end] (`periodOf`).
Period periodOf(String end, int span) => Period(addMonths(end, 1 - span), end);

/// The trend covers the span on screen, the same months as the donut (`trendPeriod`; founder,
/// 2026-10-22).
Period trendPeriod(String end, int span) => periodOf(end, span);

/// How many complete months "¿Cuánto me cuesta vivir?" averages at most (`LIVING_MONTHS`).
const livingMonths = 6;

/// The last [livingMonths] complete months before [current] (`livingPeriod`).
Period livingPeriod(String current) {
  final to = addMonths(current, -1);
  return Period(addMonths(to, 1 - livingMonths), to);
}

/// How many of those months to average: from the first one with any transaction up to the last
/// complete month, so a short history is not divided by months that had nothing in them (a person
/// who started in September has one complete month in October, not six). 0 when none has any.
/// [months] is the trend of [livingPeriod], oldest first (`livingWindow`).
int livingWindow(List<({int income, int expenses})> months) {
  final first = months.indexWhere((m) => m.income != 0 || m.expenses != 0);
  return first == -1 ? 0 : months.length - first;
}

/// A month mid-sentence, with its year when it is not the current one's: `octubre`,
/// `diciembre de 2025` (`monthLabel`).
String monthLabel(String month, String current, String locale) {
  final year = month.substring(0, 4);
  final sameYear = year == current.substring(0, 4);
  if (locale == 'es' || locale == 'pt') {
    return sameYear ? monthInSentence(month, locale) : '${monthInSentence(month, locale)} de $year';
  }
  return sameYear ? formatMonthName(month, locale) : '${formatMonthName(month, locale)} $year';
}

/// A share of the total (0.5944) as a percentage with at most one decimal: `59,4 %`, `59.4%`
/// (`formatShare`).
String formatShare(double share, String locale) {
  final format = NumberFormat.percentPattern(dateTag(locale))
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = 1;
  return format.format(share);
}

/// A month's short name for an axis: `oct`, `Oct` (`shortMonth`).
String shortMonth(String month, String locale) {
  final p = month.split('-').map(int.parse).toList();
  return DateFormat.MMM(dateTag(locale))
      .format(DateTime.utc(p[0], p[1]))
      .replaceFirst(RegExp(r'\.$'), '');
}

/// The part of a whole that [value] is, for bars: between 0 and 1, and 0 when there is no whole
/// (`fraction`).
double fraction(num value, num whole) {
  if (whole <= 0 || value <= 0) return 0;
  return value / whole > 1 ? 1 : (value / whole).toDouble();
}

/// Each total's share of their sum, rounded to a tenth of a percent so the shown shares add up to
/// exactly 100 % (largest remainder: round all down, then give the tenths left over to the ones
/// that lost the most). Returned as fractions (0.594) for [formatShare]; all 0 when the sum is not
/// positive (`sharesOf`).
List<double> sharesOf(List<int> totals) {
  final sum = totals.fold<int>(0, (acc, t) => acc + (t > 0 ? t : 0));
  if (sum <= 0) return [for (final _ in totals) 0.0];
  final exact = [for (final t in totals) (t > 0 ? t : 0) / sum * 1000];
  final tenths = [for (final e in exact) e.floor()];
  var left = 1000 - tenths.fold<int>(0, (acc, t) => acc + t);
  final order =
      [for (var i = 0; i < exact.length; i++) (index: i, remainder: exact[i] - exact[i].floor())]
        ..sort((a, b) {
          final byRemainder = b.remainder.compareTo(a.remainder);
          return byRemainder != 0 ? byRemainder : a.index.compareTo(b.index);
        });
  for (final (:index, remainder: _) in order) {
    if (left <= 0) break;
    tenths[index] += 1;
    left -= 1;
  }
  return [for (final t in tenths) t / 1000];
}

/// An amount (in hundredths) for a chart's axis, short and in the locale's words: `6 mil`,
/// `1,2 M` (es); `6k`, `1.2M` (en). No currency: the axis sits next to full amounts
/// (`compactAmount`).
String compactAmount(int cents, String locale) {
  final format = NumberFormat.compact(locale: dateTag(locale))..maximumFractionDigits = 1;
  final text = format.format(cents / 100);
  return locale == 'en' ? text.replaceFirst(RegExp(r'K$'), 'k') : text;
}
