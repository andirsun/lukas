import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stored_flag.dart';

export 'stored_flag.dart';

/// Where the sound setting is kept.
typedef SoundSettingStore = FlagStore;

const soundSettingKey = 'setting.sound';

final soundSettingStoreProvider = Provider<SoundSettingStore>(
  (ref) => ref.watch(flagStoreProvider(soundSettingKey)),
);

/// Whether sounds play (the Settings switch, Task 14). On by default, like the web's; muting leaves
/// the haptics alone. The choice is kept on the phone and read back at the start: until it has been
/// read ([ready]) no sound plays, so a muted person never hears one by mistake. [state] is the
/// choice (true until the person mutes); [playable] is what feedback asks.
class SoundEnabled extends StoredFlag {
  @override
  FlagStore get store => ref.read(soundSettingStoreProvider);

  @override
  bool get initial => true;

  /// Whether a sound may play now: the choice is known, and it is not mute.
  bool get playable => active;
}

final soundEnabledProvider = NotifierProvider<SoundEnabled, bool>(SoundEnabled.new);
