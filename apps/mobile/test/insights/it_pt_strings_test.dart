import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukitas/insights/insights_model.dart';
import 'package:lukitas/recurring/recurring_row.dart';

const nbsp = '\u00a0';

void main() {
  setUpAll(() async {
    for (final tag in ['it', 'pt_PT']) {
      await initializeDateFormatting(tag);
    }
  });

  // The web's strings for the same inputs (insights-model.test.ts, format-date.test.ts).
  test('shares, months and axis amounts match the web in Italian and Portuguese', () {
    expect(formatShare(0.5944, 'it'), '59,4%');
    expect(formatShare(0.5944, 'pt'), '59,4%');
    expect(shortMonth('2026-10', 'it'), 'ott');
    expect(shortMonth('2026-10', 'pt'), 'out');
    expect(compactAmount(600000, 'it'), '6K');
    expect(compactAmount(600000, 'pt'), '6${nbsp}mil');
    expect(compactAmount(120000000, 'it'), '1,2${nbsp}Mln');
    expect(compactAmount(120000000, 'pt'), '1,2${nbsp}M');
    expect(monthLabel('2025-12', '2026-10', 'it'), 'dicembre 2025');
    expect(monthLabel('2025-12', '2026-10', 'pt'), 'dezembro de 2025');
    expect(monthLabel('2026-10', '2026-10', 'pt'), 'outubro');
  });

  test('a recurring date matches the web', () {
    expect(formatRecurringDate('2026-10-23', 'it'), '23 ott 2026');
    expect(formatRecurringDate('2026-10-23', 'pt'), '23/10/2026');
  });
}
