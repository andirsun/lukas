// What the web's recurring payments decide, apart from how they look: apps/web/app/features/
// recurring/recurring-model.ts (`nextOccurrence`), core's `occurrences` and date helpers
// (packages/core/src/recurrence.ts and dates.ts), and RecurringForm.tsx's `recurrenceProblem`.
import '../api/gen/lukitas_api.dart';

/// A yearly rule comes round within 12 months of any month, so 13 months always find it.
const _lookaheadMonths = 13;

/// `YYYY-MM` and its two parts.
(int, int) _parts(String month) {
  final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(month);
  if (match == null) throw RangeError('Invalid month: $month');
  return (int.parse(match.group(1)!), int.parse(match.group(2)!));
}

String _pad(int n, [int width = 2]) => n.toString().padLeft(width, '0');

/// Days in [month] (`YYYY-MM`).
int daysInMonth(String month) {
  final (year, m) = _parts(month);
  return DateTime.utc(year, m + 1, 0).day;
}

/// [month] (`YYYY-MM`) moved by [n] months, across years both ways.
String addMonths(String month, int n) {
  final (year, m) = _parts(month);
  final index = year * 12 + (m - 1) + n;
  final years = (index / 12).floor();
  return '${_pad(years, 4)}-${_pad(index - years * 12 + 1)}';
}

/// The month of [date] (`YYYY-MM-DD`).
String monthOf(String date) => date.substring(0, 7);

/// Dates (0 or 1) on which [rule] falls within [month]; days past the month's end clamp to its last
/// day (core's `occurrences`).
List<String> occurrences(Recurrence rule, String month) {
  if (rule.frequency == RecurrenceFrequencyEnum.yearly &&
      int.parse(month.substring(5, 7)) != rule.monthOfYear) {
    return const [];
  }
  final day = rule.dayOfMonth < daysInMonth(month) ? rule.dayOfMonth : daysInMonth(month);
  final date = '$month-${_pad(day)}';
  if (date.compareTo(rule.startDate) < 0) return const [];
  final end = rule.endDate;
  if (end != null && date.compareTo(end) > 0) return const [];
  return [date];
}

/// The next date a recurrence falls on, today included (or its start, if later), or null once it
/// has ended. The dates come from [occurrences] (the rule the API materializes with): for a monthly
/// rule this month or the next, for a yearly one the next time its month comes round.
String? nextOccurrence(Recurrence rule, String today) {
  final from = rule.startDate.compareTo(today) > 0 ? rule.startDate : today;
  for (var step = 0; step < _lookaheadMonths; step++) {
    final dates = occurrences(rule, addMonths(monthOf(from), step));
    if (dates.isNotEmpty && dates.first.compareTo(from) >= 0) return dates.first;
  }
  return null;
}

/// The fields of the form that can carry an error (the web's `Field`).
enum RecurrenceField { amount, name, category, month, start, end }

/// What the form holds, for [recurrenceProblem].
class RecurrenceDraft {
  const RecurrenceDraft({
    required this.cents,
    required this.name,
    required this.categoryId,
    required this.frequency,
    required this.monthOfYear,
    required this.startDate,
    required this.endDate,
  });

  final int cents;
  final String name;
  final String? categoryId;
  final RecurrenceFrequencyEnum frequency;
  final int? monthOfYear;
  final String startDate;

  /// Empty when there is none.
  final String endDate;
}

/// The first error of a draft, by field, or null when it can be sent (the web's
/// `recurrenceProblem`).
RecurrenceField? recurrenceProblem(RecurrenceDraft draft) {
  if (draft.cents <= 0) return RecurrenceField.amount;
  if (draft.name.trim().isEmpty) return RecurrenceField.name;
  if (draft.categoryId == null) return RecurrenceField.category;
  if (draft.frequency == RecurrenceFrequencyEnum.yearly && draft.monthOfYear == null) {
    return RecurrenceField.month;
  }
  if (draft.startDate.isEmpty) return RecurrenceField.start;
  if (draft.endDate.isNotEmpty && draft.endDate.compareTo(draft.startDate) < 0) {
    return RecurrenceField.end;
  }
  return null;
}
