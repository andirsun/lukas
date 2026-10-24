import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stored_flag.dart';

const vibrationSettingKey = 'setting.vibration';

final vibrationSettingStoreProvider = Provider<FlagStore>(
  (ref) => ref.watch(flagStoreProvider(vibrationSettingKey)),
);

/// Whether the phone vibrates for what happens (the Settings switch, Task 14). On by default;
/// turning it off leaves the sounds alone. Like the sound setting, it is kept on the phone and
/// read back at the start: until it has been read ([ready]) nothing vibrates, so a person who
/// turned it off never feels one by mistake. [state] is the choice; [vibratable] is what feedback
/// asks.
class VibrationEnabled extends StoredFlag {
  @override
  FlagStore get store => ref.read(vibrationSettingStoreProvider);

  @override
  bool get initial => true;

  /// Whether a haptic may play now: the choice is known, and it is not off.
  bool get vibratable => active;
}

final vibrationEnabledProvider = NotifierProvider<VibrationEnabled, bool>(VibrationEnabled.new);
