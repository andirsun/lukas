import 'package:lukitas/feedback/stored_flag.dart';
import 'package:lukitas/settings/settings_store.dart';

/// Keyed settings in memory.
class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// One on/off setting in memory.
class FakeFlagStore implements FlagStore {
  FakeFlagStore([this.value]);

  bool? value;

  @override
  Future<bool?> read() async => value;

  @override
  Future<void> write(bool on) async => value = on;
}
