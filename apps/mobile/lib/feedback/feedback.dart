import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feedback_event.dart';
import 'feedback_platform.dart';
import 'sound_setting.dart';

export 'feedback_event.dart';
export 'feedback_platform.dart';
export 'sound_setting.dart';

/// Gives feedback for something that happened (spec section 6.2): plays its sound (unless muted),
/// vibrates (sounds wait for the sound setting to be read, and stay silent when it is mute), and never throws: a phone with no motor or speaker just skips that part. Call it from
/// a gesture's handler: `ref.read(feedbackProvider)(FeedbackEvent.saved)`, or [FeedbackContext.feedback]
/// where there is only a `BuildContext`.
final feedbackProvider = Provider<void Function(FeedbackEvent event)>((ref) {
  final platform = ref.watch(feedbackPlatformProvider);
  // Starts reading the sound setting now, at the app's start: no sound plays before it is known.
  ref.read(soundEnabledProvider);
  _quietly(platform.warmUp);

  void run(FeedbackEvent event) {
    final pattern = hapticPatterns[event];
    if (pattern != null) _quietly(() => platform.vibrate(pattern));
    final sound = feedbackSounds[event];
    if (sound != null && _soundOn(ref)) _quietly(() => platform.play(sound));
  }

  return run;
});

bool _soundOn(Ref ref) {
  try {
    return ref.read(soundEnabledProvider.notifier).playable;
  } on Object {
    return false;
  }
}

/// Runs [call] without waiting, and without letting it fail.
void _quietly(Future<void> Function() call) {
  try {
    unawaited(call().catchError((Object _) {}));
  } on Object {
    // Feedback is a nicety: one part failing must not stop the other or the caller.
  }
}

/// Counts the moments Lukitas celebrates by himself, apart from a save or a payment he talks about
/// (home shows those through its own events): a batch from quick capture. Each is a new number, so
/// two in a row both count.
class Celebration extends Notifier<int> {
  @override
  int build() => 0;

  void celebrate() => state++;
}

final celebrationProvider = NotifierProvider<Celebration, int>(Celebration.new);

extension FeedbackContext on BuildContext {
  /// [feedbackProvider] for a widget that is not a `ConsumerWidget`. Without a `ProviderScope`
  /// (a bare widget test) it does nothing.
  void feedback(FeedbackEvent event) {
    try {
      ProviderScope.containerOf(this, listen: false).read(feedbackProvider)(event);
    } on Object {
      // No scope: no feedback.
    }
  }
}
