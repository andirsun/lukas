// A 🎤 link (the widget's, the Quick Settings tile's) while a capture sheet is already open brings
// that sheet to listening: no second sheet, and nothing the person typed or was shown is lost.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_sheet.dart';
import 'package:lukitas/capture/capture_sheet.dart';
import 'package:lukitas/capture/engine/speech_engine.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/launch/launch_links.dart';

import '../capture/fakes.dart';
import '../settings/harness.dart';
import 'launch_links_test.dart' show FakeLaunchLinks;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<({FakeLaunchLinks links, FakeSpeechEngine engine})> _home(WidgetTester tester) async {
  final links = FakeLaunchLinks();
  final engine = FakeSpeechEngine()..hold = true;
  await pumpSettingsApp(
    tester,
    overrides: [
      launchLinkSourceProvider.overrideWithValue(links),
      speechEngineProvider.overrideWithValue(engine),
    ],
  );
  return (links: links, engine: engine);
}

/// The capture sheet open in its typing state, as the app leaves it when it went to the background
/// (or as "Escribir" opens it).
Future<void> _openTyping(WidgetTester tester) async {
  unawaited(openCapture(tester.element(find.byType(HomeScreen)), listen: false));
  await _settle(tester);
  expect(find.byKey(const Key('capture.field')), findsOneWidget);
}

State _sheet(WidgetTester tester) => tester.state(find.byType(CaptureSheet));

void main() {
  testWidgets('with a sheet already listening, the link opens no second one', (tester) async {
    final env = await _home(tester);
    env.links.open('lukitas://capture');
    await _settle(tester);
    env.engine.held!.add('');
    await tester.pump();
    final sheet = _sheet(tester);
    expect(find.byKey(const Key('capture.stop')), findsOneWidget);

    env.links.open('lukitas://capture');
    await _settle(tester);
    expect(find.byType(CaptureSheet), findsOneWidget);
    expect(identical(_sheet(tester), sheet), isTrue, reason: 'the same sheet, not a new one');
    expect(env.engine.listens, 1, reason: 'it was listening already: nothing restarted');
    expect(find.byKey(const Key('capture.stop')), findsOneWidget);
    await env.engine.held!.close();
  });

  testWidgets('with the typing field open, the link brings that sheet to listening', (
    tester,
  ) async {
    final env = await _home(tester);
    await _openTyping(tester);
    final sheet = _sheet(tester);
    expect(env.engine.listens, 0);

    env.links.open('lukitas://capture');
    await _settle(tester);
    expect(find.byType(CaptureSheet), findsOneWidget);
    expect(identical(_sheet(tester), sheet), isTrue);
    expect(env.engine.listens, 1);
    env.engine.held!.add('');
    await tester.pump();
    expect(find.byKey(const Key('capture.stop')), findsOneWidget);
    expect(find.byKey(const Key('capture.field')), findsNothing);
    await env.engine.held!.close();
  });

  testWidgets('what was typed is still there when listening hears nothing, or the app leaves', (
    tester,
  ) async {
    final env = await _home(tester);
    await _openTyping(tester);
    await tester.enterText(find.byKey(const Key('capture.field')), 'gasté 4000 en café');

    env.links.open('lukitas://capture');
    await _settle(tester);
    expect(env.engine.listens, 1);
    env.engine.held!.add('');
    await tester.pump();

    // The app goes to the background mid-listening, having heard nothing: the field is as it was.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('capture.field')), findsOneWidget);
    expect(find.text('gasté 4000 en café'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    // And listening that ends having heard nothing leaves it too.
    await tester.tap(find.byKey(const Key('capture.listen')));
    await tester.pump();
    await env.engine.held!.close();
    await _settle(tester);
    expect(find.byKey(const Key('capture.note')), findsOneWidget);
    expect(find.text('gasté 4000 en café'), findsOneWidget);
  });

  testWidgets('what is said is read together with what was typed', (tester) async {
    final env = await _home(tester);
    await _openTyping(tester);
    await tester.enterText(find.byKey(const Key('capture.field')), 'gasté 4000 en café');

    env.links.open('lukitas://capture');
    await _settle(tester);
    env.engine.held!
      ..add('')
      ..add('y 3000 en uber');
    await tester.pump();
    await env.engine.held!.close();
    await _settle(tester);
    expect(find.textContaining('gasté 4000 en café y 3000 en uber'), findsWidgets);
  });

  testWidgets('a preview with cards is left exactly as it is: nothing is lost, nothing listens', (
    tester,
  ) async {
    final env = await _home(tester);
    env.links.open('lukitas://capture');
    await _settle(tester);
    env.engine.held!
      ..add('')
      ..add('gasté 15 mil en almuerzo');
    await tester.pump();
    await env.engine.held!.close();
    await _settle(tester);
    expect(find.byKey(const Key('capture.save')), findsOneWidget);
    final sheet = _sheet(tester);

    env.links.open('lukitas://capture');
    await _settle(tester);
    expect(identical(_sheet(tester), sheet), isTrue);
    expect(find.byKey(const Key('capture.save')), findsOneWidget);
    expect(find.byType(CaptureSheet), findsOneWidget);
    expect(env.engine.listens, 1, reason: 'the cards were not replaced by a new listen');
  });

  group('any other link leaves a capture sheet that holds something', () {
    for (final link in ['lukitas://add', 'lukitas://home', 'lukitas://due', 'lukitas://progress']) {
      testWidgets('$link: typed text', (tester) async {
        final env = await _home(tester);
        await _openTyping(tester);
        await tester.enterText(find.byKey(const Key('capture.field')), 'gasté 4000 en café');
        env.links.open(link);
        await _settle(tester);
        expect(find.byType(CaptureSheet), findsOneWidget);
        expect(find.byType(AddSheet), findsNothing);
        expect(find.text('gasté 4000 en café'), findsOneWidget);
      });

      testWidgets('$link: cards to save', (tester) async {
        final env = await _home(tester);
        env.links.open('lukitas://capture');
        await _settle(tester);
        env.engine.held!
          ..add('')
          ..add('gasté 15 mil en almuerzo');
        await tester.pump();
        await env.engine.held!.close();
        await _settle(tester);
        expect(find.byKey(const Key('capture.save')), findsOneWidget);
        env.links.open(link);
        await _settle(tester);
        expect(find.byKey(const Key('capture.save')), findsOneWidget);
        expect(find.byType(AddSheet), findsNothing);
      });
    }

    testWidgets('an empty typing field gives way, as before', (tester) async {
      final env = await _home(tester);
      await _openTyping(tester);
      env.links.open('lukitas://add');
      await _settle(tester);
      expect(find.byType(CaptureSheet), findsNothing);
      expect(find.byType(AddSheet), findsOneWidget);
    });
  });
}
