// The live microphone level (lib/capture/mic_level.dart): bars that follow the input level while
// listening, and a plain static indicator under the system's "remove animations".
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/mic_level.dart';
import 'package:lukitas/theme/theme.dart';
import 'package:lukitas/theme/tokens.g.dart';

Future<StreamController<double>> _pump(
  WidgetTester tester, {
  bool disableAnimations = false,
  ThemeData? theme,
  int bars = 8,
}) async {
  final levels = StreamController<double>.broadcast();
  addTearDown(levels.close);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? nightTheme,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(child: MicLevel(levels: levels.stream, bars: bars, height: 60)),
        ),
      ),
    ),
  );
  return levels;
}

double _barHeight(WidgetTester tester, int i) =>
    tester.getSize(find.byKey(Key('mic.bar.$i'))).height;

Color _barColor(WidgetTester tester, int i) {
  final box = tester.widget<AnimatedContainer>(find.byKey(Key('mic.bar.$i')));
  return (box.decoration! as BoxDecoration).color!;
}

Future<void> _send(WidgetTester tester, StreamController<double> levels, double value) async {
  levels.add(value);
  await tester.pump(); // the stream delivers the event, setState marks the bars
  await tester.pump(); // the frame that starts each bar's glide
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('silence is a row of small bars, and speech lifts the newest one', (tester) async {
    final levels = await _pump(tester);
    expect(find.byKey(const Key('mic.bar.0')), findsOneWidget);
    expect(find.byKey(const Key('mic.bar.7')), findsOneWidget);
    expect(find.byKey(const Key('mic.bar.8')), findsNothing);
    final rest = _barHeight(tester, 7);
    expect(rest, lessThan(10));

    await _send(tester, levels, 0.9);
    expect(_barHeight(tester, 7), greaterThan(40), reason: 'the bar follows the level');
    expect(_barHeight(tester, 6), rest, reason: 'the others still show what came before');
  });

  testWidgets('the bars move along: what was newest ends up one bar to the left', (tester) async {
    final levels = await _pump(tester);
    await _send(tester, levels, 1);
    final peak = _barHeight(tester, 7);
    await _send(tester, levels, 0);
    expect(_barHeight(tester, 6), closeTo(peak, 1));
    expect(_barHeight(tester, 7), lessThan(peak));
    for (var i = 0; i < 8; i++) {
      await _send(tester, levels, 0);
    }
    expect(_barHeight(tester, 0), lessThan(10), reason: 'the peak has scrolled out');
  });

  testWidgets('a louder bar is the brand colour, a quiet one the stroke, from the tokens', (
    tester,
  ) async {
    final levels = await _pump(tester);
    final colors = LukitasColors.night;
    await _send(tester, levels, 1);
    expect(_barColor(tester, 7), colors.brand);
    expect(_barColor(tester, 0), colors.stroke);
  });

  testWidgets('a level out of range is held between 0 and 1', (tester) async {
    final levels = await _pump(tester);
    await _send(tester, levels, 7);
    expect(_barHeight(tester, 7), lessThanOrEqualTo(60));
    await _send(tester, levels, -3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a bar glides to its new height rather than snapping, so the wave reads as smooth', (
    tester,
  ) async {
    final levels = await _pump(tester);
    await _send(tester, levels, 1);
    final peak = _barHeight(tester, 7);
    final rest = _barHeight(tester, 0);
    levels.add(0);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final midway = _barHeight(tester, 7);
    expect(midway, lessThan(peak));
    expect(midway, greaterThan(rest + 5), reason: 'not there yet');
    await tester.pumpAndSettle();
    expect(_barHeight(tester, 7), rest);
  });

  testWidgets('with animations removed it is a static level bar that follows the level', (
    tester,
  ) async {
    final levels = await _pump(tester, disableAnimations: true);
    expect(find.byKey(const Key('mic.bar.0')), findsNothing);
    final level = find.byKey(const Key('mic.level'));
    double width() => tester.getSize(level).width;
    final track = tester.getSize(find.byKey(const Key('mic.track'))).width;
    expect(width(), 0);

    Future<void> say(double value) async {
      levels.add(value);
      await tester.pump(); // the event, then the frame it asks for
      await tester.pump();
    }

    await say(0.5);
    expect(width(), closeTo(track * 0.5, 1));
    await say(1);
    expect(width(), closeTo(track, 1));
    await say(0);
    expect(width(), 0);
    // Nothing is animating: there is no frame left to wait for.
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('it stops listening to the stream when it goes away', (tester) async {
    final levels = await _pump(tester);
    expect(levels.hasListener, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(levels.hasListener, isFalse);
  });

  testWidgets('in the day theme the colours are the day tokens', (tester) async {
    final levels = await _pump(tester, theme: dayTheme);
    await _send(tester, levels, 1);
    expect(_barColor(tester, 7), LukitasColors.day.brand);
  });
}
