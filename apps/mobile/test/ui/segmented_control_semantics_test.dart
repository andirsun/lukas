// The tab bar's semantics container must be exactly its tabs: when a scroll cuts through the
// control's 3 px padding, a container outside it survives the cull with no tab (Flutter's debug
// check "a TabBar cannot be empty"). Found sweeping /categories at phone sizes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings/harness.dart';

void main() {
  for (final (language, width, height, scale) in [
    ('es', 320.0, 600.0, 1.15),
    ('es', 393.0, 680.0, 1.5),
    ('en', 393.0, 740.0, 1.5),
    ('en', 412.0, 680.0, 1.5),
    ('pt', 360.0, 760.0, 1.3),
    ('it', 360.0, 640.0, 1.3),
  ]) {
    testWidgets(
      '$language ${width.toInt()}x${height.toInt()} at $scale: /categories has no empty tab bar',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final env = await pumpSettingsApp(tester, locale: Locale(language));
        tester.view
          ..physicalSize = Size(width, height)
          ..devicePixelRatio = 1;
        env.router.go('/categories');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
