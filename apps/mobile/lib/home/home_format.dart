import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'lukas_line.dart';

/// Short weekday plus day of month: es `mié 21`, en `Wed 21` (the web's `formatDay`). [date] is
/// `YYYY-MM-DD`.
String formatDay(String date, String locale) {
  final p = date.split('-').map(int.parse).toList();
  final d = DateTime.utc(p[0], p[1], p[2]);
  final weekday = DateFormat.E(locale).format(d).replaceFirst(RegExp(r'\.$'), '');
  return '$weekday ${d.day}';
}

/// A month's name, capitalized: es `Octubre`, en `October` (the web's `formatMonth`). [month] is
/// `YYYY-MM`.
String formatMonthName(String month, String locale) {
  final p = month.split('-').map(int.parse).toList();
  final name = DateFormat.MMMM(locale).format(DateTime.utc(p[0], p[1]));
  return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}

/// A month's name in the middle of a sentence: lowercase in Spanish (`mostrando octubre`), as is in
/// English (`showing October`) (the web's `monthInSentence`).
String monthInSentence(String month, String locale) {
  final name = formatMonthName(month, locale);
  return locale == 'es' ? name.toLowerCase() : name;
}

/// The words of [line], from the catalog: one of its three [variant]s (1 to 3) when it has them.
/// [money] writes cents in the person's currency and language.
String lukasLineText(AppLocalizations l, LukasLine line, int variant, String Function(int) money) {
  final v = ((variant - 1) % 3) + 1;
  return switch (line.key) {
    LukasKey.firstOfDay => switch (v) {
      1 => l.lukasFirstOfDay1(line.name),
      2 => l.lukasFirstOfDay2(line.name),
      _ => l.lukasFirstOfDay3(line.name),
    },
    LukasKey.onTrack => switch (v) {
      1 => l.lukasOnTrack1(money(line.remaining), line.daysLeft),
      2 => l.lukasOnTrack2(money(line.remaining), line.daysLeft),
      _ => l.lukasOnTrack3(money(line.remaining), line.daysLeft),
    },
    LukasKey.nearLimit => switch (v) {
      1 => l.lukasNearLimit1(line.category, money(line.remaining)),
      2 => l.lukasNearLimit2(line.category, money(line.remaining)),
      _ => l.lukasNearLimit3(line.category, money(line.remaining)),
    },
    LukasKey.overBudget => switch (v) {
      1 => l.lukasOverBudget1(line.category, money(line.over)),
      2 => l.lukasOverBudget2(line.category, money(line.over)),
      _ => l.lukasOverBudget3(line.category, money(line.over)),
    },
    LukasKey.incomeReceived => switch (v) {
      1 => l.lukasIncomeReceived1(line.name, money(line.amount)),
      2 => l.lukasIncomeReceived2(line.name, money(line.amount)),
      _ => l.lukasIncomeReceived3(line.name, money(line.amount)),
    },
    LukasKey.pendingPaid => switch (v) {
      1 => l.lukasPendingPaid1(line.name, money(line.amount)),
      2 => l.lukasPendingPaid2(line.name, money(line.amount)),
      _ => l.lukasPendingPaid3(line.name, money(line.amount)),
    },
    LukasKey.monthLastDay => switch (v) {
      1 => l.lukasMonthLastDay1(money(line.remaining)),
      2 => l.lukasMonthLastDay2(money(line.remaining)),
      _ => l.lukasMonthLastDay3(money(line.remaining)),
    },
    LukasKey.monthClosedGreen => switch (v) {
      1 => l.lukasMonthClosedGreen1(money(line.remaining)),
      2 => l.lukasMonthClosedGreen2(money(line.remaining)),
      _ => l.lukasMonthClosedGreen3(money(line.remaining)),
    },
    LukasKey.empty => l.lukasEmpty,
    LukasKey.noBudget => l.lukasNoBudget(money(line.spent)),
    LukasKey.overTotal => l.lukasOverTotal(money(line.over)),
  };
}
