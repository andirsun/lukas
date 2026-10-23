// Where the app gives feedback: the swipes, the keypad, the add sheet and quick capture, with the
// phone's motor and speaker recorded.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_repository.dart';
import 'package:lukitas/capture/capture_repository.dart';
import 'package:lukitas/capture/engine/speech_engine.dart';
import 'package:lukitas/capture/models_download.dart';
import 'package:lukitas/feedback/feedback.dart';
import 'package:lukitas/home/home_repository.dart' show HomeFailure;
import 'package:lukitas/home/lukitas_face.dart';

import '../add/fakes.dart';
import '../capture/fakes.dart';
import '../home/fakes.dart';
import '../home/fixtures.dart';
import '../home/home_harness.dart';
import 'fakes.dart';

class _Env {
  _Env(this.server, this.platform, this.harness);
  final FakeHomeRepository server;
  final FakeFeedbackPlatform platform;
  final HomeHarness harness;

  List<List<int>> get waveforms => [for (final p in platform.haptics) p.waveform];
}

Future<_Env> _pump(
  WidgetTester tester, {
  FakeHomeRepository? server,
  bool withAdd = false,
  bool withCapture = false,
}) async {
  final repo =
      server ??
      (monthWithBudgets()..categoryList.addAll([category('cat-food', 'Comida', icon: '🍽️')]));
  final platform = FakeFeedbackPlatform();
  final harness = await pumpHome(
    tester,
    repo,
    overrides: [
      feedbackPlatformProvider.overrideWithValue(platform),
      soundSettingStoreProvider.overrideWithValue(FakeSoundStore()),
      if (withAdd) addRepositoryProvider.overrideWithValue(FakeAddRepository(repo)),
      if (withCapture) ...[
        captureRepositoryProvider.overrideWithValue(FakeCaptureRepository(repo)),
        speechEngineProvider.overrideWithValue(
          FakeSpeechEngine(
            transcripts: [
              ['gasté 15 mil en almuerzo'],
            ],
          ),
        ),
        modelStoreProvider.overrideWithValue(FakeModelStore()),
      ],
    ],
  );
  return _Env(repo, platform, harness);
}

/// A swipe: the finger down on [row], moved by [dx] over [ms] (a flick is fast).
Future<void> swipe(WidgetTester tester, Finder row, double dx, {int ms = 300}) async {
  await tester.timedDrag(row, Offset(dx, 0), Duration(milliseconds: ms));
  await tester.pumpAndSettle();
}

Future<void> _endTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 12));
  await tester.pumpAndSettle();
}

LukitasMood _mood(WidgetTester tester) => tester.widget<LukitasFace>(find.byType(LukitasFace)).mood;

void main() {
  group('swipes', () {
    testWidgets('a delete ticks at the threshold, then feels deleted; Deshacer feels undone', (
      tester,
    ) async {
      final env = await _pump(tester);
      await swipe(tester, find.text('Café'), -250);
      expect(env.waveforms, [
        [10],
        [14, 30, 8],
      ]);
      expect(env.platform.sounds, isEmpty, reason: 'gestures only vibrate');

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(env.waveforms.last, [8]);
      expect(env.platform.sounds, [FeedbackSound.undo]);
      await _endTimers(tester);
    });

    testWidgets('a delete the server refuses still felt like a delete, but has no undo', (
      tester,
    ) async {
      final repo = monthWithBudgets();
      repo.failures['delete'] = const HomeFailure(500);
      final env = await _pump(tester, server: repo);
      await swipe(tester, find.text('Café'), -250);
      expect(env.waveforms, contains(equals([14, 30, 8])));
      expect(env.platform.sounds, isEmpty);
      await _endTimers(tester);
    });

    testWidgets('paying a pending row plays the paid sound and haptic', (tester) async {
      final env = await _pump(tester);
      await swipe(tester, find.text('Arriendo'), 250);
      expect(env.platform.sounds, [FeedbackSound.paid]);
      expect(env.waveforms.last, [10, 30, 10, 30, 24]);
      await _endTimers(tester);
    });

    testWidgets('a payment the server refuses is not celebrated', (tester) async {
      final repo = monthWithBudgets();
      repo.failures['markPaid'] = const HomeFailure(0);
      final env = await _pump(tester, server: repo);
      await swipe(tester, find.text('Arriendo'), 250);
      expect(env.platform.sounds, isEmpty);
      expect(env.waveforms, isNot(contains(equals([10, 30, 10, 30, 24]))));
      await _endTimers(tester);
    });

    testWidgets('crossing the line and coming back ticks each way, and nothing else', (
      tester,
    ) async {
      final env = await _pump(tester);
      final gesture = await tester.startGesture(tester.getCenter(find.text('Café')));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      expect(env.waveforms, isEmpty, reason: 'not yet at the line');
      await gesture.moveBy(const Offset(-200, 0));
      await tester.pump();
      expect(env.waveforms, [
        [10],
      ]);
      await gesture.moveBy(const Offset(200, 0));
      await tester.pump();
      expect(env.waveforms, [
        [10],
        [10],
      ]);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('the add sheet', () {
    testWidgets('a key press is a haptic tick through feedback, not the framework\'s', (
      tester,
    ) async {
      final env = await _pump(tester, withAdd: true);
      final framework = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        call,
      ) async {
        framework.add(call.method);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.tap(find.byKey(const Key('home.add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('keypad.5')));
      await tester.pump();
      expect(env.waveforms, [
        [8],
      ]);
      expect(env.platform.sounds, isEmpty);
      expect(framework, isNot(contains('HapticFeedback.vibrate')));
    });

    testWidgets('saving plays the saved sound and haptic; Deshacer the undo ones', (tester) async {
      final env = await _pump(tester, withAdd: true);
      await tester.tap(find.byKey(const Key('home.add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('keypad.5')));
      await tester.pump();
      env.platform.haptics.clear();
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(env.platform.sounds, [FeedbackSound.expenseSaved]);
      expect(env.waveforms, [
        [12, 40, 18],
      ]);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(env.platform.sounds, [FeedbackSound.expenseSaved, FeedbackSound.undo]);
      expect(env.waveforms.last, [8]);
      await _endTimers(tester);
    });

    testWidgets('muted, a save still vibrates and plays nothing', (tester) async {
      final env = await _pump(tester, withAdd: true);
      await env.harness.container.read(soundEnabledProvider.notifier).set(false);
      await tester.tap(find.byKey(const Key('home.add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('keypad.5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(env.platform.sounds, isEmpty);
      expect(env.waveforms, contains(equals([12, 40, 18])));
      await _endTimers(tester);
    });
  });

  group('quick capture', () {
    Future<void> saveBatch(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('home.capture')));
      await tester.pumpAndSettle();
      final pick = find.byKey(const Key('capture.card.0.pick'));
      if (pick.evaluate().isNotEmpty) {
        await tester.tap(pick);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('capture.card.0.category.cat-food')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('capture.save')));
      // Not settled: the celebration lasts 2.5 s, the toast 8.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('a batch save celebrates: the sound, the haptic and Lukitas', (tester) async {
      final env = await _pump(tester, withCapture: true);
      expect(_mood(tester), isNot(LukitasMood.celebrating));
      await saveBatch(tester);
      expect(env.platform.sounds, [FeedbackSound.expenseSaved]);
      expect(env.waveforms, [
        [12, 40, 18],
      ]);
      expect(_mood(tester), LukitasMood.celebrating);

      // He rests again after the celebration, like for any save.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(_mood(tester), isNot(LukitasMood.celebrating));
      await _endTimers(tester);
    });

    testWidgets('the batch\'s Deshacer feels undone', (tester) async {
      final env = await _pump(tester, withCapture: true);
      await saveBatch(tester);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(env.platform.sounds, [FeedbackSound.expenseSaved, FeedbackSound.undo]);
      expect(env.waveforms.last, [8]);
      await _endTimers(tester);
    });
  });
}
