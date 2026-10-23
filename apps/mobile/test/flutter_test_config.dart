import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Every test draws with the app's own fonts (Fredoka and Nunito), not the test font Ahem: home
/// has the web's bottom bar and rows, whose line heights are the real fonts' (a screen test that
/// pumps home with Ahem boxes would overflow them).
///
/// The files are read from disk, not through the asset bundle: that would start the test binding
/// for every test file, and with it the test HTTP client that answers 400 to a plain test of the
/// model download.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  for (final MapEntry(key: family, value: path) in {
    'Fredoka': 'assets/fonts/Fredoka-Variable.ttf',
    'Nunito': 'assets/fonts/Nunito-Variable.ttf',
  }.entries) {
    final bytes = File(path).readAsBytesSync();
    await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
  await testMain();
}
