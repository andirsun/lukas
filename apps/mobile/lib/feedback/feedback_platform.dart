import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feedback_event.dart';

/// The phone's motor and speaker. The app uses the two Kotlin channels below; tests use a fake.
abstract interface class FeedbackPlatform {
  /// Vibrates with [pattern].
  Future<void> vibrate(HapticPattern pattern);

  /// Plays [sound] once, on top of anything still playing.
  Future<void> play(FeedbackSound sound);

  /// Loads the sounds, so the first one is not late.
  Future<void> warmUp();
}

/// [FeedbackPlatform] over `lukitas/haptics` (android/.../haptics/HapticsChannel.kt) and
/// `lukitas/sounds` (SoundChannel.kt, a `SoundPool`: free, no Play Services). A phone with neither
/// (a test, a desktop) answers with a missing plugin, which is no error here.
class ChannelFeedbackPlatform implements FeedbackPlatform {
  const ChannelFeedbackPlatform();

  static const _haptics = MethodChannel('lukitas/haptics');
  static const _sounds = MethodChannel('lukitas/sounds');

  @override
  Future<void> vibrate(HapticPattern pattern) => _call(_haptics, 'vibrate', pattern.toJson());

  @override
  Future<void> play(FeedbackSound sound) => _call(_sounds, 'play', {'asset': sound.asset});

  @override
  Future<void> warmUp() => _call(_sounds, 'preload', {
    'assets': [for (final sound in FeedbackSound.values) sound.asset],
  });

  static Future<void> _call(MethodChannel channel, String method, Object arguments) async {
    try {
      await channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // No such channel on this platform.
    }
  }
}

final feedbackPlatformProvider = Provider<FeedbackPlatform>(
  (ref) => const ChannelFeedbackPlatform(),
);
