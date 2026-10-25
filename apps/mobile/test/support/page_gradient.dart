import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/app_shell.dart';

/// Where the page's background gradient is now, on the test's screen: the web's `.lk-screen`, as
/// tall as the page and scrolling with it (the shell paints it from its screen's scroll metrics).
Rect pageGradient(WidgetTester t) {
  final paint = t.widget<CustomPaint>(find.byKey(const Key('shell.gradient')));
  final size = t.view.physicalSize / t.view.devicePixelRatio;
  return (paint.painter! as PageGradientPainter).rectIn(size);
}

/// The screen the test draws on.
Size screenOf(WidgetTester t) => t.view.physicalSize / t.view.devicePixelRatio;
