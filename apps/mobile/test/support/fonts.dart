import 'dart:io';

import 'package:flutter/services.dart';

/// The app's bundled fonts, as the web loads them (assets/fonts, declared in pubspec.yaml):
/// Fredoka for display text and Nunito for the rest.
///
/// Call it at the start of a golden test, before pumping anything. Without it `flutter test` draws
/// every glyph with the Ahem test font, whose squares tell nothing about typography. The files are
/// read through [rootBundle], so a font missing from pubspec.yaml fails here, not on a phone.
Future<void> loadAppFonts() async {
  const files = {
    'Fredoka': 'assets/fonts/Fredoka-Variable.ttf',
    'Nunito': 'assets/fonts/Nunito-Variable.ttf',
  };
  for (final MapEntry(key: family, value: asset) in files.entries) {
    final loader = FontLoader(family)..addFont(rootBundle.load(asset));
    await loader.load();
  }
}

/// Material's icon font (`Icons.*`), which `flutter test` leaves out: the one `flutter build`
/// bundles, from the SDK's cache (bin/cache/artifacts/material_fonts).
Future<void> loadMaterialIcons() async {
  final file = File('${_flutterCache()}/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final bytes = file.readAsBytesSync();
  await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

/// The SDK's bin/cache: `flutter test` runs the tests in bin/cache/artifacts/engine/*/flutter_tester.
String _flutterCache() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null && Directory('$root/bin/cache').existsSync()) return '$root/bin/cache';
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.parent.path != dir.path) {
    if (dir.path.endsWith('/bin/cache')) return dir.path;
    dir = dir.parent;
  }
  throw StateError('Cannot find the Flutter SDK cache from ${Platform.resolvedExecutable}');
}
