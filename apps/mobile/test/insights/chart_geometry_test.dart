import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lukitas/insights/chart_geometry.dart';
import 'package:lukitas/insights/insights_model.dart';

import '../support/parity.dart' show ParityFixtures;

/// The web's `insights-model.test.ts` and the geometry of its insights charts, case by case.
///
/// Part one is `apps/web/app/features/insights/insights-model.test.ts` ported: the same inputs give
/// the same periods, labels and shares. Part two checks the charts' geometry against what the web's
/// Recharts draws for the same data: `recharts_geometry.json` is that picture as numbers, read from
/// the SVG of the insights stories (`pnpm --filter @lukas/web parity:insights-geometry`), and the
/// data is the stories' own (test/parity/fixtures).
const nbsp = ' ';

Future<void> main() async {
  // The month names of intl (the app has them loaded by its localisation delegates).
  await initializeDateFormatting('es');
  await initializeDateFormatting('en');

  group('periods', () {
    test('ends a span at the month on screen', () {
      expect(periodOf('2026-10', 1), const Period('2026-10', '2026-10'));
      expect(periodOf('2026-10', 3), const Period('2026-08', '2026-10'));
      expect(periodOf('2026-02', 12), const Period('2025-03', '2026-02'));
    });

    test('shows the trend over the chosen span, like the donut', () {
      expect(trendPeriod('2026-10', 1), const Period('2026-10', '2026-10'));
      expect(trendPeriod('2026-10', 3), const Period('2026-08', '2026-10'));
      expect(trendPeriod('2026-10', 6), const Period('2026-05', '2026-10'));
      expect(trendPeriod('2026-10', 12), const Period('2025-11', '2026-10'));
    });

    test('knows the spans', () {
      expect(isSpan(3), isTrue);
      expect(isSpan(2), isFalse);
      expect(spans, [1, 3, 6, 12]);
    });
  });

  group('cost of living window', () {
    test('is the six complete months before the current one', () {
      expect(livingPeriod('2026-10'), const Period('2026-04', '2026-09'));
      expect(livingPeriod('2026-01'), const Period('2025-07', '2025-12'));
    });

    ({int income, int expenses}) month(int income, int expenses) =>
        (income: income, expenses: expenses);

    test('starts at the first month with anything in it', () {
      final empty = month(0, 0);
      expect(livingWindow([empty, empty, empty, empty, empty, month(0, 13313)]), 1);
      expect(livingWindow([empty, month(300000, 0), empty, month(0, 5), empty, empty]), 5);
      expect(livingWindow(List.generate(6, (_) => month(1, 1))), 6);
    });

    test('is 0 without any complete month with transactions', () {
      expect(livingWindow(List.generate(6, (_) => month(0, 0))), 0);
      expect(livingWindow([]), 0);
    });
  });

  group('formatting', () {
    test('writes shares with at most one decimal', () {
      expect(formatShare(0.5944, 'es'), '59,4$nbsp%');
      expect(formatShare(0.5944, 'en'), '59.4%');
      expect(formatShare(1, 'es'), '100$nbsp%');
      expect(formatShare(0.05, 'en'), '5%');
    });

    test('names months mid-sentence, with the year only when it is another one', () {
      expect(monthLabel('2026-10', '2026-10', 'es'), 'octubre');
      expect(monthLabel('2025-12', '2026-10', 'es'), 'diciembre de 2025');
      expect(monthLabel('2026-10', '2026-10', 'en'), 'October');
      expect(monthLabel('2025-12', '2026-10', 'en'), 'December 2025');
      expect(monthLabel('2026-10', '2026-10', 'it'), 'ottobre');
      expect(monthLabel('2025-12', '2026-10', 'it'), 'dicembre 2025');
    });

    test('shortens months for the axis', () {
      expect(shortMonth('2026-10', 'es'), 'oct');
      expect(shortMonth('2026-10', 'en'), 'Oct');
      expect(shortMonth('2026-09', 'es'), 'sept');
    });

    test('clamps fractions for bars', () {
      expect(fraction(50, 200), 0.25);
      expect(fraction(-5, 200), 0);
      expect(fraction(5, 0), 0);
      expect(fraction(300, 200), 1);
    });
  });

  group('shares that add up', () {
    int sum(List<double> xs) => (xs.fold<double>(0, (a, x) => a + x) * 1000).round();

    test('keeps the exact shares when they are already tenths', () {
      expect(sharesOf([594, 406]), [0.594, 0.406]);
    });

    test('gives the leftover tenths to the largest remainders, summing to 100 %', () {
      // Thirds: 33,3 + 33,3 + 33,3 = 99,9 without the fix.
      expect(sharesOf([1, 1, 1]), [0.334, 0.333, 0.333]);
      expect(sum(sharesOf([1, 1, 1])), 1000);
      // The October fixture: rounded one by one its shares show 100,1 %.
      const october = [132978, 26280, 25367, 19412, 9832, 6150, 3689];
      expect(sum(sharesOf(october)), 1000);
      expect(sharesOf(october)[0], 0.594);
    });

    test('is all zeros without a positive sum', () {
      expect(sharesOf([0, 0]), [0, 0]);
      expect(sharesOf([]), <double>[]);
    });
  });

  group('axis amounts', () {
    test("shortens amounts in the locale's words", () {
      expect(compactAmount(600000, 'es'), '6${nbsp}mil');
      expect(compactAmount(120000000, 'es'), '1,2${nbsp}M');
      expect(compactAmount(50000000, 'es'), '500${nbsp}mil');
      expect(compactAmount(600000, 'en'), '6k');
      expect(compactAmount(50000000, 'en'), '500k');
      expect(compactAmount(120000000, 'en'), '1.2M');
      expect(compactAmount(0, 'es'), '0');
    });
  });

  // -- the geometry -----------------------------------------------------------------------------

  final web = jsonDecode(File('test/insights/recharts_geometry.json').readAsStringSync()) as Map;

  /// The story's answer to `path`, as JSON.
  Map<String, Object?> answer(String story, String path) =>
      (ParityFixtures.load(story).get(path).body! as Map).cast<String, Object?>();

  List<int> totalsOf(Map<String, Object?> report) => [
    for (final item in report['items']! as List) (item as Map)['total']! as int,
  ];

  List<TrendPoint> pointsOf(Map<String, Object?> report) => [
    for (final m in report['months']! as List)
      TrendPoint(
        month: (m as Map)['month']! as String,
        label: shortMonth(m['month']! as String, 'es'),
        income: m['income']! as int,
        expenses: m['expenses']! as int,
        budget: (m['budget']! as int) > 0 ? m['budget']! as int : null,
      ),
  ];

  /// Whitespace out, as Recharts' templates have it in their line breaks.
  String squash(String path) => path.replaceAll(RegExp(r'\s+'), '');

  /// The same path to the 4 decimals Recharts rounds to: same commands, numbers within a hair.
  void expectSamePath(String actual, String expected, {String? reason, double tolerance = 1.5e-4}) {
    final number = RegExp(r'-?\d+(?:\.\d+)?');
    final a = squash(actual);
    final e = squash(expected);
    expect(a.replaceAll(number, '#'), e.replaceAll(number, '#'), reason: reason);
    final an = number.allMatches(a).map((m) => double.parse(m[0]!)).toList();
    final en = number.allMatches(e).map((m) => double.parse(m[0]!)).toList();
    expect(an.length, en.length, reason: reason);
    for (var i = 0; i < an.length; i++) {
      expect(an[i], closeTo(en[i], tolerance), reason: '$reason: number $i of $e');
    }
  }

  group('nice ticks (what Recharts rounds an axis to)', () {
    // Recharts' getNiceTickValues([0, max], 4, false), for maxima around where each step changes.
    const cases = {
      1: [0, 1, 2, 3],
      2: [0, 1, 2, 3],
      4: [0, 2, 4, 6],
      6: [0, 2, 4, 6],
      7: [0, 3, 6, 9],
      10: [0, 4, 8, 12],
      25: [0, 9, 18, 27],
      99: [0, 35, 70, 105],
      101: [0, 35, 70, 105],
      250: [0, 85, 170, 255],
      999: [0, 350, 700, 1050],
      12345: [0, 4500, 9000, 13500],
      56789: [0, 20000, 40000, 60000],
      280000: [0, 95000, 190000, 285000],
      620000: [0, 250000, 500000, 750000],
      1329780: [0, 450000, 900000, 1350000],
      2237080: [0, 750000, 1500000, 2250000],
      6711240: [0, 2500000, 5000000, 7500000],
      9999999: [0, 3500000, 7000000, 10500000],
      99999999: [0, 35000000, 70000000, 105000000],
      150000000000: [0, 50000000000, 100000000000, 150000000000],
    };
    cases.forEach((max, ticks) {
      test('up to $max', () => expect(niceTicks(max), ticks));
    });
  });

  group('the donut', () {
    void donutCase(String name, String story, String path) {
      test('draws $name as the web does', () {
        final totals = totalsOf(answer(story, path));
        final sectors = (web[name] as Map)['donut']['sectors'] as List;
        final geometry = DonutGeometry(200, totals);
        expect(geometry.sectors, hasLength(sectors.length));
        for (var i = 0; i < sectors.length; i++) {
          expectSamePath(
            geometry.sectors[i].path().toString(),
            (sectors[i] as Map)['d']! as String,
            reason: '$name sector $i',
          );
        }
      });
    }

    donutCase(
      'donut-expenses',
      'insights-insights--donut-by-category',
      '/v1/reports/by-category?from=2026-10&kind=expense&to=2026-10',
    );
    donutCase(
      'donut-income',
      'insights-insights--donut-income',
      '/v1/reports/by-category?from=2026-10&kind=income&to=2026-10',
    );
    donutCase(
      'donut-pending',
      'insights-insights--donut-pending',
      '/v1/reports/by-category?from=2026-10&kind=expense&status=paid&to=2026-10',
    );

    test('sweeps in clockwise from the top: every sector grows with the time', () {
      final geometry = DonutGeometry(200, [600, 300, 100]);
      final start = geometry.sectorsAt(0);
      final half = geometry.sectorsAt(0.5);
      final end = geometry.sectorsAt(1);
      // Nothing at first, whole at the end, and the first sector starts at the top (90 degrees).
      expect(start.map((s) => s.sweep), everyElement(0));
      for (var i = 0; i < 3; i++) {
        expect(half[i].sweep, closeTo(geometry.sectors[i].sweep / 2, 1e-9));
        expect(end[i].sweep, closeTo(geometry.sectors[i].sweep, 1e-9));
      }
      expect(half.first.startAngle, 90);
      // Each next sector starts one padding (2 degrees) after the one before.
      expect(half[1].startAngle, closeTo(half[0].endAngle - 2, 1e-9));
    });

    test('a single sector is a whole ring with no padding or rounding', () {
      final geometry = DonutGeometry(200, [100]);
      expect(geometry.sectors.single.startAngle, 90);
      expect(geometry.sectors.single.endAngle, -270);
      expect(geometry.cornerRadius, 0);
    });
  });

  group('the trend', () {
    // The text widths Chrome measures the axis' names with (Nunito 11px, the body's weight 700),
    // which Recharts uses to leave out the names that would touch.
    const widths = {
      'ene': 18.359375,
      'feb': 16.4375,
      'mar': 19.984375,
      'abr': 16.9375,
      'may': 21.40625,
      'jun': 15.65625,
      'jul': 12.734375,
      'ago': 19.0,
      'sept': 22.109375,
      'oct': 15.78125,
      'nov': 18.46875,
      'dic': 14.609375,
    };

    void trendCase(String name, String story, String path) {
      group(name, () {
        final points = pointsOf(answer(story, path));
        final expected = (web[name] as Map)['trend'] as Map;
        final layout = trendLayout(
          points: points,
          width: (expected['width'] as num).toDouble(),
          height: (expected['height'] as num).toDouble(),
          formatTick: (cents) => compactAmount(cents, 'es'),
          measure: (text) => widths[text] ?? 6.609375,
        );

        test('puts a bar on every month that has something, as the web does', () {
          for (final (key, bars) in [('income', layout.income), ('expenses', layout.expenses)]) {
            final web = (expected[key] as List).cast<Map>();
            final drawn = [for (final bar in bars) ?bar];
            expect(drawn, hasLength(web.length), reason: key);
            for (var i = 0; i < web.length; i++) {
              expectSamePath(drawn[i].path().toString(), web[i]['d']! as String, reason: '$key $i');
            }
          }
        });

        test('draws the grid and the axis names where the web does', () {
          final grid = (expected['grid'] as List).cast<Map>();
          expect(layout.gridY, hasLength(grid.length));
          for (var i = 0; i < grid.length; i++) {
            expect(layout.gridY[i], closeTo((grid[i]['y'] as num).toDouble(), 1e-6));
            expect(layout.plotLeft, (grid[i]['x1'] as num).toDouble());
            expect(layout.plotRight, (grid[i]['x2'] as num).toDouble());
          }
          final yTicks = (expected['yTicks'] as List).cast<Map>();
          expect(layout.yTicks.map((t) => t.text), yTicks.map((t) => t['text']));
          for (var i = 0; i < yTicks.length; i++) {
            expect(layout.yTicks[i].x, (yTicks[i]['x'] as num).toDouble());
            expect(layout.yTicks[i].y, closeTo((yTicks[i]['y'] as num).toDouble(), 1e-6));
          }
          final xTicks = (expected['xTicks'] as List).cast<Map>();
          expect(layout.xTicks.map((t) => t.text), xTicks.map((t) => t['text']));
          for (var i = 0; i < xTicks.length; i++) {
            expect(layout.xTicks[i].x, closeTo((xTicks[i]['x'] as num).toDouble(), 1e-6));
            expect(layout.xTicks[i].y, (xTicks[i]['y'] as num).toDouble());
          }
        });

        test('draws the budget as a line of dots, with a gap where there is none', () {
          final dots = (expected['dots'] as List).cast<Map>();
          final drawn = [for (final dot in layout.budget) ?dot];
          expect(drawn, hasLength(dots.length));
          for (var i = 0; i < dots.length; i++) {
            expect(drawn[i].dx, closeTo((dots[i]['cx'] as num).toDouble(), 1e-6));
            expect(drawn[i].dy, closeTo((dots[i]['cy'] as num).toDouble(), 1e-3));
          }
          final path = expected['budget'] as String?;
          if (path == null) {
            // One month, say: a dot, and no line to stroke.
            expect(layout.budgetPath().isEmpty, isTrue);
          } else {
            // The web's line has one run per stretch of months with a budget.
            expectSamePath(layout.budgetPath().toString(), path, tolerance: 1e-3);
          }
        });
      });
    }

    trendCase(
      'trend-1-month',
      'insights-insights--donut-by-category',
      '/v1/reports/trend?from=2026-10&to=2026-10',
    );
    trendCase(
      'trend-3-months',
      'insights-insights--donut-range',
      '/v1/reports/trend?from=2026-08&to=2026-10',
    );
    trendCase(
      'trend-6-months',
      'insights-insights--trend-scrolled',
      '/v1/reports/trend?from=2026-05&to=2026-10',
    );
    trendCase(
      'trend-year',
      'insights-insights--trend-year-scrolled',
      '/v1/reports/trend?from=2025-11&to=2026-10',
    );
    trendCase(
      'trend-budget-gaps',
      'insights-insights--trend-gaps-scrolled',
      '/v1/reports/trend?from=2026-05&to=2026-10',
    );

    test('bars rise from the axis: height and top follow the time', () {
      final layout = trendLayout(
        points: const [
          TrendPoint(month: '2026-10', label: 'oct', income: 600, expenses: 300, budget: null),
        ],
        width: 324,
        height: 190,
        formatTick: (c) => '$c',
        measure: (_) => 10,
      );
      final bar = layout.income.single!;
      final base = layout.plotBottom;
      expect(bar.pathAt(0).toString(), isNotEmpty);
      expect(bar.heightAt(0), 0);
      expect(bar.topAt(0), base);
      expect(bar.heightAt(1), bar.height);
      expect(bar.topAt(1), bar.y);
      expect(bar.heightAt(0.5), closeTo(bar.height / 2, 1e-9));
      expect(bar.topAt(0.5), closeTo(base - bar.height / 2, 1e-9));
    });
  });
}
