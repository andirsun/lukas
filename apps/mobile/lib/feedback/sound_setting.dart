import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the sound setting is kept. The app uses `flutter_secure_storage` (already in the app for
/// the session, so no new dependency); tests use memory.
abstract interface class SoundSettingStore {
  /// Null when the person never chose.
  Future<bool?> read();
  Future<void> write(bool on);
}

class SecureSoundSettingStore implements SoundSettingStore {
  const SecureSoundSettingStore([this._storage = const FlutterSecureStorage()]);

  static const key = 'setting.sound';

  final FlutterSecureStorage _storage;

  @override
  Future<bool?> read() async => switch (await _storage.read(key: key)) {
    'off' => false,
    'on' => true,
    _ => null,
  };

  @override
  Future<void> write(bool on) => _storage.write(key: key, value: on ? 'on' : 'off');
}

final soundSettingStoreProvider = Provider<SoundSettingStore>(
  (ref) => const SecureSoundSettingStore(),
);

/// Whether sounds play (the Settings switch, Task 14). On by default, like the web's; muting leaves
/// the haptics alone. The choice is kept on the phone and read back at the start: until it has been
/// read ([ready]) no sound plays, so a muted person never hears one by mistake. A choice made
/// meanwhile wins. [state] is the choice (true until the person mutes); [playable] is what feedback
/// asks.
class SoundEnabled extends Notifier<bool> {
  var _chosen = false;
  var _loaded = false;
  var _ready = Future<void>.value();

  SoundSettingStore get _store => ref.read(soundSettingStoreProvider);

  @override
  bool build() {
    _ready = _load();
    return true;
  }

  Future<void> _load() async {
    try {
      final kept = await _store.read();
      if (kept != null && !_chosen && ref.mounted) state = kept;
    } on Object {
      // Unreadable: sounds stay on.
    }
    _loaded = true;
  }

  /// Whether a sound may play now: the choice is known, and it is not mute.
  bool get playable => _loaded && state;

  /// Completes once the kept choice has been read back (or found unreadable).
  Future<void> get ready => _ready;

  /// Turns sounds on or off, and keeps the choice. A store that cannot be written only means the
  /// choice is forgotten at the next start.
  Future<void> set(bool on) async {
    _chosen = true;
    _loaded = true;
    state = on;
    try {
      await _store.write(on);
    } on Object {
      // Not kept.
    }
  }
}

final soundEnabledProvider = NotifierProvider<SoundEnabled, bool>(SoundEnabled.new);
