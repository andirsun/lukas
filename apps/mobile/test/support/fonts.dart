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
