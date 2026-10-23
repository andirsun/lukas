// The feedback channels on an Android emulator (no dev stack needed):
//
//   flutter test integration_test/feedback_test.dart -d emulator-5554
//
// It checks what the unit tests cannot: that the sound assets are found in the APK and load into
// the SoundPool, and that the motor channel answers. How a haptic *feels* is for the founder's
// phone: an emulator has no motor to judge.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lukitas/feedback/feedback.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const sounds = MethodChannel('lukitas/sounds');
  const haptics = MethodChannel('lukitas/haptics');

  testWidgets('every sound is found in the APK and loads', (tester) async {
    final loaded = await sounds.invokeMethod<int>('preload', {
      'assets': [for (final s in FeedbackSound.values) s.asset],
    });
    expect(loaded, FeedbackSound.values.length);
  });

  testWidgets('a sound that is not there is skipped, not an error', (tester) async {
    expect(await sounds.invokeMethod<bool>('play', {'asset': 'assets/sounds/none.mp3'}), isFalse);
  });

  testWidgets('each sound plays', (tester) async {
    for (final sound in FeedbackSound.values) {
      expect(await sounds.invokeMethod<bool>('play', {'asset': sound.asset}), isTrue);
    }
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('each pattern reaches the motor channel without an error', (tester) async {
    for (final entry in hapticPatterns.entries) {
      final played = await haptics.invokeMethod<bool>('vibrate', entry.value.toJson());
      expect(played, isA<bool>(), reason: '${entry.key}');
    }
  });

  testWidgets('a pattern the motor channel cannot read is refused', (tester) async {
    await expectLater(
      haptics.invokeMethod<bool>('vibrate', {'waveform': <int>[]}),
      throwsA(isA<PlatformException>()),
    );
  });

  testWidgets('through feedback(), the whole path runs on the phone', (tester) async {
    final platform = const ChannelFeedbackPlatform();
    await platform.warmUp();
    for (final pattern in hapticPatterns.values) {
      await platform.vibrate(pattern);
    }
    for (final sound in FeedbackSound.values) {
      await platform.play(sound);
    }
  });
}
