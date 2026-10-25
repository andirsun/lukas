import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/notices/notice_backend.dart';

Recurrence _rule({String? endDate, String startDate = '2026-01-05'}) => Recurrence(
  (b) => b
    ..id = '00000000-0000-4000-8000-000000000001'
    ..name = 'Arriendo'
    ..amount = -150000000
    ..categoryId = '00000000-0000-4000-8000-000000000002'
    ..frequency = RecurrenceFrequencyEnum.monthly
    ..dayOfMonth = 5
    ..startDate = startDate
    ..endDate = endDate,
);

void main() {
  group('a recurring payment that is still running', () {
    test('no rules, none', () {
      expect(hasActiveRecurrence(const [], '2026-10-22'), isFalse);
    });

    test('a rule with no end counts', () {
      expect(hasActiveRecurrence([_rule()], '2026-10-22'), isTrue);
    });

    test('a rule that ends today or later counts; one that ended does not', () {
      expect(hasActiveRecurrence([_rule(endDate: '2026-10-22')], '2026-10-22'), isTrue);
      expect(hasActiveRecurrence([_rule(endDate: '2026-12-31')], '2026-10-22'), isTrue);
      expect(hasActiveRecurrence([_rule(endDate: '2026-10-21')], '2026-10-22'), isFalse);
    });

    test('one running rule among ended ones is enough; a rule that has not started yet counts', () {
      expect(
        hasActiveRecurrence([_rule(endDate: '2026-01-01'), _rule(endDate: '2026-11-01')], '2026-10-22'),
        isTrue,
      );
      expect(hasActiveRecurrence([_rule(startDate: '2026-12-01')], '2026-10-22'), isTrue);
    });
  });
}
