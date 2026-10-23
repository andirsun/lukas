import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'api/device.dart';
import 'app.dart';

Future<void> main() async {
  runApp(await bootstrap());
}

/// The app with the phone's time zone and language read first (every request sends them).
/// [overrides] are for the integration tests (a fixed transcript in place of audio, say).
Future<Widget> bootstrap({List<Override> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final hints = await DeviceHints.read();
  return ProviderScope(
    overrides: [deviceHintsProvider.overrideWithValue(hints), ...overrides],
    child: const LukitasApp(),
  );
}
