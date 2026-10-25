@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/theme/surfaces.dart';
import 'package:lukitas/theme/text_styles.dart';
import 'package:lukitas/ui/bottom_bar.dart';
import 'package:lukitas/ui/lk_theme.dart';

import '../support/parity.dart';

/// `BottomBar` against apps/web/app/ui/BottomBar.stories.tsx (`ui-bottombar--*`), each story as
/// Storybook shows it after its `play` function, in night and in day (`InsightsDayEnglish` pins
/// day).
///
/// The web has no 🎤: these pairs hide it (`showMic: false`). The 🎤 has a picture of its own,
/// test/ui/bottom_bar_golden_test.dart, to review by eye.
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The stories' decorator: a `lk-screen max-w-[390px] pt-6` (the screen's background gradient and
/// 32px above the bar) in the page's 16px padding, the bar inside it.
Widget _screen({required String current}) => ColoredBox(
  color: Colors.transparent,
  child: Builder(
    builder: (context) {
      final colors = context.lkColors;
      return DefaultTextStyle(
        style: TextStyle(
          fontFamily: LkText.textFamily,
          fontFamilyFallback: parityFallbackFamilies,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.5,
          color: colors.ink,
        ),
        child: ColoredBox(
          color: colors.bg,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 380,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: LkSurface.background(colors)),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32 - 4),
                    child: BottomBar(
                      current: current,
                      showMic: false,
                      onAdd: () {},
                      onMic: () {},
                      onNavigate: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  ),
);

Future<void> _tab(WidgetTester t, int times) async {
  for (var i = 0; i < times; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('bottom bar parity: Inicio · ＋ · Análisis ($theme)', (t) async {
      await parityGolden(
        t,
        'bottom-bar-home',
        _screen(current: 'home'),
        theme: theme,
        // The story clicked the ＋, which keeps the focus (and Chrome rings it).
        act: (t) => _tab(t, 2),
      );
    });

    testWidgets('bottom bar parity: focus on Inicio, then on the ＋ ($theme)', (t) async {
      await parityGolden(
        t,
        'bottom-bar-press-and-focus',
        _screen(current: 'home'),
        theme: theme,
        act: (t) => _tab(t, 2),
      );
    });
  }

  testWidgets('bottom bar parity: Insights current, day, English (day)', (t) async {
    await parityGolden(
      t,
      'bottom-bar-insights-day-english',
      _screen(current: 'insights'),
      theme: 'day',
      locale: const Locale('en'),
    );
  });
}
