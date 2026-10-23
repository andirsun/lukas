import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'api/device.dart';
import 'app.dart';
import 'settings/initial_settings.dart';
import 'settings/licenses.dart';
import 'settings/settings_store.dart';

Future<void> main() async {
  runApp(await bootstrap());
}

/// The app with the phone's time zone and language read first (every request sends them), and the
/// server, theme and language the person chose in Settings.
/// [overrides] are for the integration tests (a fixed transcript in place of audio, say).
Future<Widget> bootstrap({List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  registerExtraLicenses();
  final hints = await DeviceHints.read();
  final settings = await InitialSettings.read(const SecureSettingsStore());
  return ProviderScope(
    overrides: [
      deviceHintsProvider.overrideWithValue(hints),
      initialSettingsProvider.overrideWithValue(settings),
      ...overrides,
    ],
    child: const LukitasApp(),
  );
}
