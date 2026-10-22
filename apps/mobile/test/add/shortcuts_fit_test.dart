import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/name_field.dart';

void main() {
  group('shortcutsThatFit: wrapped rows, the first ones kept', () {
    test('everything fits in one row', () {
      expect(shortcutsThatFit([100, 100, 100], 328), 3);
    });

    test('two rows hold what fits, a third is cut', () {
      // Three of 100 + 6 gaps = 312 per row: two rows hold 6 of 8.
      expect(shortcutsThatFit(List.filled(8, 100.0), 328), 6);
    });

    test('a row breaks before a chip that would overflow it', () {
      expect(shortcutsThatFit([200, 200, 200, 200, 200], 328), 2);
    });

    test('a chip wider than the row takes a whole row and is never dropped for it', () {
      expect(shortcutsThatFit([500, 100], 328), 2);
      expect(shortcutsThatFit([100, 500, 500, 100], 328), 2);
    });

    test('one row only', () {
      expect(shortcutsThatFit(List.filled(8, 100.0), 328, maxRows: 1), 3);
    });

    test('nothing to show', () {
      expect(shortcutsThatFit([], 328), 0);
    });
  });
}
