import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/device.dart';
import 'app.dart';

Future<void> main() async {
  runApp(await bootstrap());
}

/// The app with the phone's time zone and language read first (every request sends them).
Future<Widget> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hints = await DeviceHints.read();
  return ProviderScope(
    overrides: [deviceHintsProvider.overrideWithValue(hints)],
    child: const LukitasApp(),
  );
}
