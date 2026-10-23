import 'package:lukitas/feedback/feedback.dart';

/// The phone's motor and speaker, recorded.
class FakeFeedbackPlatform implements FeedbackPlatform {
  final haptics = <HapticPattern>[];
  final sounds = <FeedbackSound>[];
  var warmUps = 0;

  /// While set, every call throws it (a phone with no motor, a channel that is gone).
  Object? failure;

  @override
  Future<void> vibrate(HapticPattern pattern) async {
    if (failure != null) throw failure!;
    haptics.add(pattern);
  }

  @override
  Future<void> play(FeedbackSound sound) async {
    if (failure != null) throw failure!;
    sounds.add(sound);
  }

  @override
  Future<void> warmUp() async => warmUps++;
}

/// The sound setting kept in memory.
class FakeSoundStore implements SoundSettingStore {
  FakeSoundStore([this.value]);

  bool? value;
  var writes = 0;
  var reads = 0;

  @override
  Future<bool?> read() async {
    reads++;
    return value;
  }

  @override
  Future<void> write(bool on) async {
    writes++;
    value = on;
  }
}
