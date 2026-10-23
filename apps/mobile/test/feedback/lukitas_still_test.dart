import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/lukitas_face.dart';
import 'package:lukitas/l10n/app_localizations.dart';

Future<void> pumpFace(WidgetTester tester, LukitasMood mood) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Center(child: LukitasFace(mood: mood, size: 72)),
  ),
);

/// Which of the sprite sheet's eight frames shows: where the sheet is slid inside its window.
AlignmentGeometry frameOf(WidgetTester tester) =>
    tester.widget<OverflowBox>(find.byType(OverflowBox)).alignment;

void main() {
  for (final mood in LukitasMood.values) {
    testWidgets('${mood.name} Lukitas moves through his frames', (tester) async {
      await pumpFace(tester, mood);
      final first = frameOf(tester);
      await tester.pump(mood.loop ~/ 2);
      expect(frameOf(tester), isNot(first));
      await tester.pumpAndSettle();
    });

    testWidgets('under "remove animations" ${mood.name} Lukitas shows a still frame', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpFace(tester, mood);
      final first = frameOf(tester);
      expect(first, const Alignment(-1, -1), reason: 'the first frame');
      for (var i = 0; i < 4; i++) {
        await tester.pump(mood.loop ~/ 3);
        expect(frameOf(tester), first);
      }
      expect(tester.hasRunningAnimations, isFalse);
    });
  }

  testWidgets('a mood that arrives under "remove animations" stays still too', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpFace(tester, LukitasMood.happy);
    await pumpFace(tester, LukitasMood.celebrating);
    await tester.pump(const Duration(milliseconds: 400));
    expect(frameOf(tester), const Alignment(-1, -1));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
