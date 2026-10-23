import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/feedback/feedback.dart';

import 'fakes.dart';

ProviderContainer containerWith(
  FakeFeedbackPlatform platform, {
  SoundSettingStore? store,
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      feedbackPlatformProvider.overrideWithValue(platform),
      soundSettingStoreProvider.overrideWithValue(store ?? FakeSoundStore()),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('events', () {
    // The web's patterns (apps/web/app/feedback/feedback.ts), in ms: vibrate, pause, vibrate...
    // Sounds are the web's too; gestures only vibrate there, and so here.
    const table = <FeedbackEvent, (List<int>, FeedbackSound?)>{
      FeedbackEvent.saved: ([12, 40, 18], FeedbackSound.expenseSaved),
      FeedbackEvent.paid: ([10, 30, 10, 30, 24], FeedbackSound.paid),
      FeedbackEvent.deleted: ([14, 30, 8], null),
      FeedbackEvent.undo: ([8], FeedbackSound.undo),
      FeedbackEvent.thresholdCrossed: ([10], null),
      FeedbackEvent.pageChanged: ([15], null),
      FeedbackEvent.keyPressed: ([8], null),
    };

    test('each event maps to its haptic pattern and sound', () async {
      expect(table.keys.toSet(), FeedbackEvent.values.toSet(), reason: 'every event is covered');
      for (final entry in table.entries) {
        final platform = FakeFeedbackPlatform();
        final container = containerWith(platform);
        container.read(feedbackProvider)(entry.key);
        await Future<void>.delayed(Duration.zero);
        final (waveform, sound) = entry.value;
        expect(platform.haptics, hasLength(1), reason: '${entry.key}');
        expect(platform.haptics.single.waveform, waveform, reason: '${entry.key}');
        expect(platform.sounds, sound == null ? isEmpty : [sound], reason: '${entry.key}');
      }
    });

    test('every pattern also has Android 11 primitives, each with a scale between 0 and 1', () {
      for (final event in FeedbackEvent.values) {
        final pattern = hapticPatterns[event]!;
        expect(pattern.primitives, isNotEmpty, reason: '$event');
        for (final step in pattern.primitives) {
          expect(['click', 'tick'], contains(step.name), reason: '$event');
          expect(step.scale, inInclusiveRange(0.1, 1.0), reason: '$event');
          expect(step.delayMs, greaterThanOrEqualTo(0), reason: '$event');
        }
      }
    });

    test('the sound files are the web\'s, in the app\'s assets', () {
      expect(FeedbackSound.expenseSaved.asset, 'assets/sounds/expense-saved.mp3');
      expect(FeedbackSound.paid.asset, 'assets/sounds/paid.mp3');
      expect(FeedbackSound.undo.asset, 'assets/sounds/undo.mp3');
    });

    test('feedback never throws, whatever the phone does', () async {
      final platform = FakeFeedbackPlatform()..failure = PlatformException(code: 'no-motor');
      final container = containerWith(platform);
      for (final event in FeedbackEvent.values) {
        container.read(feedbackProvider)(event);
      }
      await Future<void>.delayed(Duration.zero);
      expect(platform.haptics, isEmpty);
    });

    test('the platform is warmed up once, when feedback is first used', () async {
      final platform = FakeFeedbackPlatform();
      final container = containerWith(platform);
      container.read(feedbackProvider);
      container.read(feedbackProvider);
      await Future<void>.delayed(Duration.zero);
      expect(platform.warmUps, 1);
    });
  });

  group('the sound setting', () {
    test('sounds are on by default, like the web\'s', () {
      final container = containerWith(FakeFeedbackPlatform());
      expect(container.read(soundEnabledProvider), isTrue);
    });

    test('mute stops sounds, not haptics', () async {
      final platform = FakeFeedbackPlatform();
      final container = containerWith(platform);
      await container.read(soundEnabledProvider.notifier).set(false);
      container.read(feedbackProvider)(FeedbackEvent.paid);
      container.read(feedbackProvider)(FeedbackEvent.undo);
      await Future<void>.delayed(Duration.zero);
      expect(platform.sounds, isEmpty);
      expect(platform.haptics.map((p) => p.waveform), [
        [10, 30, 10, 30, 24],
        [8],
      ]);
    });

    test('turning sounds back on plays them again', () async {
      final platform = FakeFeedbackPlatform();
      final container = containerWith(platform);
      final setting = container.read(soundEnabledProvider.notifier);
      await setting.set(false);
      await setting.set(true);
      container.read(feedbackProvider)(FeedbackEvent.saved);
      await Future<void>.delayed(Duration.zero);
      expect(platform.sounds, [FeedbackSound.expenseSaved]);
    });

    test('the choice is kept: a new start reads it back', () async {
      final store = FakeSoundStore();
      final first = containerWith(FakeFeedbackPlatform(), store: store);
      await first.read(soundEnabledProvider.notifier).set(false);
      expect(store.value, isFalse);

      final second = containerWith(FakeFeedbackPlatform(), store: store);
      second.listen(soundEnabledProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(second.read(soundEnabledProvider), isFalse);
    });

    test(
      'a store that cannot be read leaves sounds on, and one that cannot be written does not throw',
      () async {
        final store = _BrokenStore();
        final container = containerWith(FakeFeedbackPlatform(), store: store);
        container.listen(soundEnabledProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        expect(container.read(soundEnabledProvider), isTrue);
        await container.read(soundEnabledProvider.notifier).set(false);
        expect(container.read(soundEnabledProvider), isFalse, reason: 'for this run, at least');
      },
    );

    test('a choice made while the old one is still being read wins', () async {
      final store = FakeSoundStore(true);
      final container = containerWith(FakeFeedbackPlatform(), store: store);
      container.listen(soundEnabledProvider, (_, _) {});
      await container.read(soundEnabledProvider.notifier).set(false);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(soundEnabledProvider), isFalse);
    });
  });

  group('celebration', () {
    test('each celebration is a new beat, so the same one twice still counts', () {
      final container = containerWith(FakeFeedbackPlatform());
      expect(container.read(celebrationProvider), 0);
      container.read(celebrationProvider.notifier).celebrate();
      container.read(celebrationProvider.notifier).celebrate();
      expect(container.read(celebrationProvider), 2);
    });
  });

  group('the Android channels', () {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      for (final name in ['lukitas/haptics', 'lukitas/sounds']) {
        messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
          calls.add(call);
          return null;
        });
      }
    });

    tearDown(() {
      for (final name in ['lukitas/haptics', 'lukitas/sounds']) {
        messenger.setMockMethodCallHandler(MethodChannel(name), null);
      }
    });

    test('a pattern goes to lukitas/haptics as its timings and its primitives', () async {
      await const ChannelFeedbackPlatform().vibrate(hapticPatterns[FeedbackEvent.deleted]!);
      expect(calls.single.method, 'vibrate');
      final args = calls.single.arguments as Map<Object?, Object?>;
      expect(args['waveform'], [14, 30, 8]);
      expect(args['primitives'], [
        {'name': 'click', 'scale': 0.8, 'delay': 0},
        {'name': 'tick', 'scale': 0.5, 'delay': 30},
      ]);
    });

    test('a sound goes to lukitas/sounds as its asset', () async {
      await const ChannelFeedbackPlatform().play(FeedbackSound.paid);
      expect(calls.single.method, 'play');
      expect(calls.single.arguments, {'asset': 'assets/sounds/paid.mp3'});
    });

    test('warming up asks the speaker to load every sound', () async {
      await const ChannelFeedbackPlatform().warmUp();
      expect(calls.single.method, 'preload');
      expect(calls.single.arguments, {
        'assets': [for (final s in FeedbackSound.values) s.asset],
      });
    });

    test('a phone with no such channel (a test, say) is not an error', () async {
      messenger.setMockMethodCallHandler(const MethodChannel('lukitas/haptics'), null);
      await const ChannelFeedbackPlatform().vibrate(hapticPatterns[FeedbackEvent.undo]!);
    });
  });
}

class _BrokenStore implements SoundSettingStore {
  @override
  Future<bool?> read() async => throw PlatformException(code: 'keystore');

  @override
  Future<void> write(bool on) async => throw PlatformException(code: 'keystore');
}
