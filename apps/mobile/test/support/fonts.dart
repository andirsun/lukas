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

/// Face [index] of a TrueType collection (`.ttc`) as a font of its own. The engine loads only a
/// collection's first face, so another one has to be taken out: its tables are copied after a new
/// directory, with their offsets moved.
Uint8List ttcFace(Uint8List collection, int index) {
  final data = ByteData.sublistView(collection);
  if (String.fromCharCodes(collection.sublist(0, 4)) != 'ttcf') {
    throw ArgumentError('not a TrueType collection');
  }
  final faces = data.getUint32(8);
  if (index >= faces) throw RangeError.index(index, List<int>.filled(faces, 0));
  final directory = data.getUint32(12 + index * 4);
  final count = data.getUint16(directory + 4);
  var next = (12 + count * 16 + 3) & ~3;
  final tables = <(int record, int offset, int length)>[];
  for (var i = 0; i < count; i++) {
    final record = directory + 12 + i * 16;
    final length = data.getUint32(record + 12);
    tables.add((record, next, length));
    next = (next + length + 3) & ~3;
  }
  final out = Uint8List(next);
  final view = ByteData.sublistView(out);
  out.setRange(0, 12, collection.sublist(directory, directory + 12));
  for (var i = 0; i < count; i++) {
    final (record, offset, length) = tables[i];
    out.setRange(12 + i * 16, 12 + i * 16 + 16, collection.sublist(record, record + 16));
    view.setUint32(12 + i * 16 + 8, offset);
    final from = data.getUint32(record + 8);
    out.setRange(offset, offset + length, collection.sublist(from, from + length));
  }
  return out;
}
