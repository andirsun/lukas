import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukitas/home/home_format.dart';

void main() {
  setUpAll(() async {
    for (final tag in ['es', 'en', 'it', 'pt_PT']) {
      await initializeDateFormatting(tag);
    }
  });

  // The web's vectors (`formatDay`, `formatMonth`, `monthInSentence`) from Intl with it-IT / pt-PT.
  group('dates in Italian and Portuguese match Intl', () {
    test('a short weekday and the day of the month', () {
      expect(formatDay('2026-10-21', 'es'), 'mié 21');
      expect(formatDay('2026-10-21', 'it'), 'mer 21');
      expect(formatDay('2026-10-21', 'pt'), 'quarta 21');
    });

    test('a month, capitalized and mid-sentence', () {
      expect(formatMonthName('2026-10', 'it'), 'Ottobre');
      expect(formatMonthName('2026-03', 'pt'), 'Março');
      expect(monthInSentence('2026-10', 'it'), 'ottobre');
      expect(monthInSentence('2026-03', 'pt'), 'março');
      expect(monthInSentence('2026-10', 'en'), 'October');
    });
  });
}
