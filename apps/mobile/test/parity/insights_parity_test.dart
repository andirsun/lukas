@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/insights/insights_controller.dart';
import 'package:lukitas/insights/insights_repository.dart';
import 'package:lukitas/insights/insights_screen.dart';
import 'package:lukitas/ui/app_shell.dart';
import 'package:lukitas/ui/segmented_control.dart';

import '../support/parity.dart';
import '../support/parity_home.dart';

/// Análisis against the stories that show it, `insights-insights--*`
/// (apps/web/app/features/insights/Insights.stories.tsx), each as Storybook shows it after its
/// `play` function.
///
/// The app reads what the story's fake API answered (test/parity/fixtures): the profile, the
/// summary, the categories and the reports the page asked for. The page is as long as its three
/// cards (the web's page, and its background gradient with it), and the pictures show the top
/// 915px of it; the stories that look at a card below the fold scroll the page to it
/// (`TrendScrolled`, `TrendYearScrolled`, `TrendGapsScrolled`, `CostOfLivingScrolled`): the frame
/// moves the screen up by as much, which is what a scrolled page looks like with the bottom bar
/// fixed over it.
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The story's reports, as the fake API answered them.
class _FixtureInsights implements InsightsRepository {
  _FixtureInsights(this.fixture);

  final ParityFixture fixture;

  @override
  Future<CategoryReport> byCategory({
    required String from,
    required String to,
    required String kind,
    String? status,
  }) async {
    final query = 'from=$from&kind=$kind${status == null ? '' : '&status=$status'}&to=$to';
    return readBuilt(
      CategoryReport.serializer,
      fixtureJson(fixture, '/v1/reports/by-category?$query'),
    );
  }

  @override
  Future<TrendReport> trend({required String from, required String to}) async => readBuilt(
    TrendReport.serializer,
    fixtureJson(fixture, '/v1/reports/trend?from=$from&to=$to'),
  );

  @override
  Future<CostOfLivingReport> costOfLiving(int months) async => readBuilt(
    CostOfLivingReport.serializer,
    fixtureJson(fixture, '/v1/reports/cost-of-living?months=$months'),
  );
}

/// Análisis in the story's frame: Storybook's 16px of padding, the page as long as the web's
/// ([height]: its `.lk-screen`), scrolled by [scroll] px, the bar under it, no 🎤.
class _Frame extends StatelessWidget {
  const _Frame({required this.height, required this.scroll});

  final double height;
  final ValueNotifier<double> scroll;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: scroll,
    builder: (context, scrolled, _) => ShellFrame(
      padding: EdgeInsets.fromLTRB(16, 16 - scrolled, 16, 16),
      screenHeight: height,
      showMic: false,
      child: const InsightsScreen(),
    ),
  );
}

/// A click in Chrome puts the focus on what it clicked, which rings it; a tap does not in Flutter.
/// A key puts the app in keyboard mode, where the focused control draws its ring.
Future<void> _keyboardMode(WidgetTester t) => t.sendKeyEvent(LogicalKeyboardKey.shift);

/// A click focuses a button in Chrome; a tap does not in Flutter: focus the control [inside] is in.
void _focus(WidgetTester t, Finder inside) => Focus.of(t.element(inside)).requestFocus();

/// The option [label] of the control that holds [T] values (the first of several with that text).
Finder _option<T>(String label) =>
    find.descendant(of: find.byType(SegmentedControl<T>), matching: find.text(label));

/// [act] does what the story's `play` function does, with the page at the top (the controls it
/// clicks are there); [scrolled] is where the page ends up, once it has.
Future<void> _pair(
  WidgetTester t, {
  required String id,
  required String story,
  required String theme,
  required double height,
  double scrolled = 0,
  Locale locale = const Locale('es'),
  Future<void> Function(WidgetTester t, ValueNotifier<double> scroll)? act,
}) async {
  final fixture = ParityFixtures.load(story);
  final scroll = ValueNotifier<double>(0);
  addTearDown(scroll.dispose);
  await parityGolden(
    t,
    id,
    _Frame(height: height, scroll: scroll),
    theme: theme,
    locale: locale,
    overrides: [
      ...parityHomeOverrides(FixtureHomeRepository(fixture)),
      insightsRepositoryProvider.overrideWithValue(_FixtureInsights(fixture)),
    ],
    act: (t) async {
      await precacheLukitas(t);
      await act?.call(t, scroll);
      scroll.value = scrolled;
      await t.pumpAndSettle();
      // A key puts the app in keyboard mode, where the focused control draws its ring.
      if (act != null) await _keyboardMode(t);
    },
  );
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('insights parity: this month\'s spending by category ($theme)', (t) async {
      await _pair(
        t,
        id: 'insights-donut',
        story: 'insights-insights--donut-by-category',
        theme: theme,
        height: 2132,
      );
    });

    testWidgets('insights parity: income, Ingresos clicked ($theme)', (t) async {
      await _pair(
        t,
        id: 'insights-income',
        story: 'insights-insights--donut-income',
        theme: theme,
        height: 1796,
        act: (t, _) async {
          await t.tap(_option<InsightsKind>('Ingresos'));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('insights parity: paid spending, Pendientes then Pagados clicked ($theme)', (
      t,
    ) async {
      await _pair(
        t,
        id: 'insights-pending',
        story: 'insights-insights--donut-pending',
        theme: theme,
        height: 2076,
        act: (t, _) async {
          await t.tap(_option<InsightsStatus>('Pendientes'));
          await t.pumpAndSettle();
          await t.tap(_option<InsightsStatus>('Pagados'));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('insights parity: three months, then a month back ($theme)', (t) async {
      await _pair(
        t,
        id: 'insights-range',
        story: 'insights-insights--donut-range',
        theme: theme,
        height: 2132,
        act: (t, _) async {
          await t.tap(_option<int>('3 meses'));
          await t.pumpAndSettle();
          await t.tap(find.bySemanticsLabel('Mes anterior'));
          await t.pumpAndSettle();
          _focus(t, find.text('‹').first);
        },
      );
    });

    testWidgets('insights parity: the trend over six months ($theme)', (t) async {
      await _pair(
        t,
        id: 'insights-trend',
        story: 'insights-insights--trend-scrolled',
        theme: theme,
        height: 2132,
        scrolled: 1027,
        act: (t, _) async {
          await t.tap(_option<int>('6 meses'));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('insights parity: the trend over a year ($theme)', (t) async {
      await _pair(
        t,
        id: 'insights-trend-year',
        story: 'insights-insights--trend-year-scrolled',
        theme: theme,
        height: 2132,
        scrolled: 1027,
        act: (t, _) async {
          await t.tap(_option<int>('1 año'));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('insights parity: the trend with gaps in the budget, an older month ($theme)', (
      t,
    ) async {
      await _pair(
        t,
        id: 'insights-trend-gaps',
        story: 'insights-insights--trend-gaps-scrolled',
        theme: theme,
        height: 2132,
        scrolled: 1027,
        act: (t, scroll) async {
          await t.tap(_option<int>('6 meses'));
          await t.pumpAndSettle();
          // The arrows of the trend are below the fold: the story clicks them from script.
          scroll.value = 1027;
          await t.pumpAndSettle();
          for (var i = 0; i < 3; i++) {
            await t.tap(find.bySemanticsLabel('Ver el mes anterior en el gráfico'));
            await t.pumpAndSettle();
          }
          _focus(t, find.text('‹').last);
        },
      );
    });

    testWidgets('insights parity: what living costs ($theme)', (t) async {
      await _pair(
        t,
        id: 'insights-living',
        story: 'insights-insights--cost-of-living-scrolled',
        theme: theme,
        height: 2132,
        scrolled: 1249,
      );
    });

    testWidgets('insights parity: nothing logged yet ($theme)', (t) async {
      await _pair(
        t,
        id: 'insights-empty',
        story: 'insights-insights--empty',
        theme: theme,
        height: 915,
      );
    });

    testWidgets('insights parity: in English ($theme)', (t) async {
      await _pair(
        t,
        id: 'insights-english',
        story: 'insights-insights--english',
        theme: theme,
        height: 2132,
        locale: const Locale('en'),
      );
    });
  }
}
