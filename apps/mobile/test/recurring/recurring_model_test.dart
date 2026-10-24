// apps/web/app/features/recurring/recurring-model.test.ts, one test for one, and the rules of
// RecurringForm.tsx's `recurrenceProblem` and core's `occurrences` (packages/core/src/recurrence.ts)
// that the model rests on.
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/recurring/recurring_model.dart';

Recurrence rule({
  RecurrenceFrequencyEnum frequency = RecurrenceFrequencyEnum.monthly,
  int dayOfMonth = 23,
  int? monthOfYear,
  String startDate = '2026-01-01',
  String? endDate,
}) => Recurrence(
  (b) => b
    ..id = 'r'
    ..name = 'Spotify'
    ..amount = -353
    ..categoryId = 'c'
    ..frequency = frequency
    ..dayOfMonth = dayOfMonth
    ..monthOfYear = monthOfYear
    ..startDate = startDate
    ..endDate = endDate,
);

void main() {
  group('nextOccurrence', () {
    final monthly = rule();

    test('later this month, today included', () {
      expect(nextOccurrence(monthly, '2026-10-21'), '2026-10-23');
      expect(nextOccurrence(monthly, '2026-10-23'), '2026-10-23');
    });

    test('past this month: next month\'s', () {
      expect(nextOccurrence(monthly, '2026-10-24'), '2026-11-23');
    });

    test('a day past the month\'s end falls on its last day', () {
      expect(nextOccurrence(rule(dayOfMonth: 31), '2026-11-02'), '2026-11-30');
      expect(nextOccurrence(rule(dayOfMonth: 31), '2027-02-01'), '2027-02-28');
    });

    test('not before it starts', () {
      expect(nextOccurrence(rule(startDate: '2027-03-10'), '2026-10-21'), '2027-03-23');
    });

    test('none once it ended', () {
      expect(nextOccurrence(rule(endDate: '2026-10-20'), '2026-10-21'), isNull);
      expect(nextOccurrence(rule(endDate: '2026-11-23'), '2026-10-24'), '2026-11-23');
    });

    test('yearly: the next time its month comes round', () {
      final yearly = rule(
        frequency: RecurrenceFrequencyEnum.yearly,
        dayOfMonth: 15,
        monthOfYear: 3,
      );
      expect(nextOccurrence(yearly, '2026-10-21'), '2027-03-15');
      expect(nextOccurrence(yearly, '2027-03-15'), '2027-03-15');
      expect(nextOccurrence(yearly, '2027-03-16'), '2028-03-15');
    });
  });

  group('occurrences (core)', () {
    test('a monthly rule falls once a month, clamped to the month\'s last day', () {
      expect(occurrences(rule(dayOfMonth: 31), '2028-02'), ['2028-02-29']);
      expect(occurrences(rule(dayOfMonth: 31), '2026-04'), ['2026-04-30']);
      expect(occurrences(rule(), '2026-12'), ['2026-12-23']);
    });

    test('nothing before its start or after its end', () {
      expect(occurrences(rule(startDate: '2026-06-24'), '2026-06'), isEmpty);
      expect(occurrences(rule(startDate: '2026-06-23'), '2026-06'), ['2026-06-23']);
      expect(occurrences(rule(endDate: '2026-06-22'), '2026-06'), isEmpty);
      expect(occurrences(rule(endDate: '2026-06-23'), '2026-06'), ['2026-06-23']);
    });

    test('a yearly rule falls only in its month', () {
      final yearly = rule(
        frequency: RecurrenceFrequencyEnum.yearly,
        dayOfMonth: 15,
        monthOfYear: 3,
      );
      expect(occurrences(yearly, '2027-03'), ['2027-03-15']);
      expect(occurrences(yearly, '2027-04'), isEmpty);
    });
  });

  group('the months', () {
    test('addMonths crosses years both ways', () {
      expect(addMonths('2026-10', 3), '2027-01');
      expect(addMonths('2026-01', -1), '2025-12');
      expect(addMonths('2026-10', 0), '2026-10');
      expect(addMonths('2026-12', 13), '2028-01');
    });

    test('daysInMonth knows leap years', () {
      expect(daysInMonth('2028-02'), 29);
      expect(daysInMonth('2027-02'), 28);
      expect(daysInMonth('2026-04'), 30);
      expect(daysInMonth('2026-12'), 31);
    });
  });

  group('recurrenceProblem: the first error of a draft, by field', () {
    RecurrenceDraft draft({
      int cents = 15000,
      String name = 'Clases',
      String? categoryId = 'cat',
      RecurrenceFrequencyEnum frequency = RecurrenceFrequencyEnum.monthly,
      int? monthOfYear,
      String startDate = '2026-10-21',
      String endDate = '',
    }) => RecurrenceDraft(
      cents: cents,
      name: name,
      categoryId: categoryId,
      frequency: frequency,
      monthOfYear: monthOfYear,
      startDate: startDate,
      endDate: endDate,
    );

    test('a whole draft has none', () {
      expect(recurrenceProblem(draft()), isNull);
    });

    test('an amount of nothing, then a blank name, then no category', () {
      expect(
        recurrenceProblem(draft(cents: 0, name: '', categoryId: null)),
        RecurrenceField.amount,
      );
      expect(recurrenceProblem(draft(name: '   ', categoryId: null)), RecurrenceField.name);
      expect(recurrenceProblem(draft(categoryId: null)), RecurrenceField.category);
    });

    test('a yearly one needs its month; a monthly one does not', () {
      final yearly = RecurrenceFrequencyEnum.yearly;
      expect(recurrenceProblem(draft(frequency: yearly)), RecurrenceField.month);
      expect(recurrenceProblem(draft(frequency: yearly, monthOfYear: 3)), isNull);
      expect(recurrenceProblem(draft()), isNull);
    });

    test('it needs a start, and an end that is not before it', () {
      expect(recurrenceProblem(draft(startDate: '')), RecurrenceField.start);
      expect(recurrenceProblem(draft(endDate: '2026-10-20')), RecurrenceField.end);
      expect(recurrenceProblem(draft(endDate: '2026-10-21')), isNull);
    });
  });
}
