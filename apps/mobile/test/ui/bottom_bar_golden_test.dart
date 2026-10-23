@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/theme/surfaces.dart';
import 'package:lukitas/ui/bottom_bar.dart';
import 'package:lukitas/ui/lk_theme.dart';

import '../support/parity.dart';

/// The bottom bar with its 🎤: the app's one addition to the web's layout (spec decision 3), a
/// smaller sibling of the ＋ in the same style. The web has no 🎤, so the parity pairs hide it
/// (test/parity/bottom_bar_parity_test.dart) and this picture is the one to review by eye.
///
/// The goldens are the Mac's pixels (emoji from the parity harness's Noto Color Emoji), tagged
/// `golden`; update them with `flutter test --update-goldens test/ui/bottom_bar_golden_test.dart`.
Widget _bar() => Builder(
  builder: (context) {
    final colors = context.lkColors;
    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: 'Nunito',
        fontFamilyFallback: parityFallbackFamilies,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.5,
        color: colors.ink,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: LkSurface.background(colors)),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 32 - 4),
            child: BottomBar(current: 'home', onAdd: () {}, onMic: () {}, onNavigate: (_) {}),
          ),
        ),
      ),
    );
  },
);

Future<void> _pump(WidgetTester t, String theme) async {
  await t.runAsync(loadParityFonts);
  t.view
    ..physicalSize = const Size(412, 130) * 2
    ..devicePixelRatio = 2;
  addTearDown(t.view.reset);
  // `flutter test` draws shadows hard-edged; the ＋'s glow is a blur.
  debugDisableShadows = false;
  try {
    await _draw(t, theme);
  } finally {
    debugDisableShadows = true;
  }
}

Future<void> _draw(WidgetTester t, String theme) async {
  await t.pumpWidget(
    MaterialApp(
      theme: parityTheme(theme),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      home: _bar(),
    ),
  );
  await t.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(
      Uri.file('${Directory.current.path}/test/ui/goldens/bottom_bar_mic_$theme.png'),
    ),
  );
}

void main() {
  testWidgets('the bottom bar with its 🎤, at night', (t) => _pump(t, 'night'));
  testWidgets('the bottom bar with its 🎤, by day', (t) => _pump(t, 'day'));
}
