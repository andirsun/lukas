import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/day_groups.dart';

import 'fixtures.dart';

void main() {
  group('groupByDay', () {
    test(
      'puts today first, then the upcoming days (nearest first), then the past (newest first)',
      () {
        // The API sends the month newest first.
        final items = [
          tx('internet', '2026-10-28', -3990, status: 'pending'),
          tx('streaming', '2026-10-23', -799, status: 'pending'),
          tx('coffee', '2026-10-21', -120),
          tx('lunch', '2026-10-21', -1240),
          tx('bus', '2026-10-08', -200),
          tx('salary', '2026-10-01', 300000),
        ];
        final groups = groupByDay(items, '2026-10-21');
        expect(groups.map((g) => (g.date, g.when)).toList(), [
          ('2026-10-21', DayWhen.today),
          ('2026-10-23', DayWhen.upcoming),
          ('2026-10-28', DayWhen.upcoming),
          ('2026-10-08', DayWhen.past),
          ('2026-10-01', DayWhen.past),
        ]);
        expect(groups[0].items.map((t) => t.id).toList(), ['coffee', 'lunch']);
        expect(groups[0].total, -1360);
        expect(groups[4].total, 300000);
      },
    );

    test('marks the day before today as yesterday', () {
      final groups = groupByDay([
        tx('a', '2026-10-20', -1),
        tx('b', '2026-10-19', -1),
      ], '2026-10-21');
      expect(groups.map((g) => g.when).toList(), [DayWhen.yesterday, DayWhen.past]);
    });

    test('works across a month boundary for yesterday', () {
      expect(groupByDay([tx('a', '2026-09-30', -1)], '2026-10-01').first.when, DayWhen.yesterday);
    });

    test('is empty without transactions', () {
      expect(groupByDay([], '2026-10-21'), isEmpty);
    });
  });
}
