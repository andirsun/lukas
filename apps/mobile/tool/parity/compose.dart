// Lays each parity pair side by side for review (docs/mobile/parity.md):
//
//   dart run tool/parity/compose.dart [id filter]
//
// For each pair in test/parity/parity.json, reads the web's shot (test/parity/web/<id>-<theme>.png,
// apps/web's `pnpm parity:shots`) and the app's golden (test/parity/app/<id>-<theme>.png,
// `flutter test --update-goldens test/parity`) and writes build/parity/<id>-<theme>.png: the web
// on the left, the app on the right, and under them the web faded to grey with every pixel that
// differs in magenta, and the share of pixels that differ. build/parity is git-ignored; it also
// gets summary.json with every pair's share.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'png.dart';

/// A pixel differs when one of its channels differs by more than this (out of 255): a colour
/// rounded one way in Chrome and the other in Flutter is the same colour.
const tolerance = 2;

const _gutter = 24;
const _scale = 4;
const _label = 7 * _scale + 16;

void main(List<String> args) {
  final only = args.isEmpty ? null : args.first;
  final pairs = (jsonDecode(File('test/parity/parity.json').readAsStringSync()) as List<Object?>)
      .cast<Map<String, Object?>>()
      .where((pair) => only == null || (pair['id']! as String).contains(only));
  final summary = <String, Object?>{};
  var missing = false;
  for (final pair in pairs) {
    final name = '${pair['id']}-${pair['theme']}';
    final webFile = 'test/parity/web/$name.png';
    final appFile = 'test/parity/app/$name.png';
    if (!File(webFile).existsSync() || !File(appFile).existsSync()) {
      stdout.writeln('$name: missing ${File(webFile).existsSync() ? appFile : webFile}');
      missing = true;
      continue;
    }
    final (image, share) = compose(readPng(webFile), readPng(appFile));
    final out = 'build/parity/$name.png';
    writePng(out, image);
    summary[name] = {'storyId': pair['storyId'], 'differingPercent': share * 100, 'image': out};
    stdout.writeln('$name: ${_percent(share)} of pixels differ  →  $out');
  }
  File('build/parity/summary.json')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(summary)}\n');
  if (missing) exitCode = 1;
}

String _percent(double share) => '${(share * 100).toStringAsFixed(2)}%';

/// The review picture of one pair, and the share (0-1) of pixels that differ. Pictures of
/// different sizes are compared over the larger one, where a pixel only one has differs.
(Rgba, double) compose(Rgba web, Rgba app) {
  final w = max(web.width, app.width);
  final h = max(web.height, app.height);
  final overlay = Rgba(w, h);
  var differing = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final inWeb = x < web.width && y < web.height;
      final inApp = x < app.width && y < app.height;
      final to = overlay.offset(x, y);
      var differs = inWeb != inApp;
      if (inWeb && inApp) {
        final a = web.offset(x, y);
        final b = app.offset(x, y);
        for (var c = 0; c < 4; c++) {
          if ((web.pixels[a + c] - app.pixels[b + c]).abs() > tolerance) differs = true;
        }
      }
      if (differs) {
        differing++;
        overlay.pixels
          ..[to] = 255
          ..[to + 1] = 0
          ..[to + 2] = 255
          ..[to + 3] = 255;
      } else {
        // The web's picture in grey, faded toward white, so the magenta stands out.
        final a = web.offset(x, y);
        final grey =
            (web.pixels[a] * 0.299 + web.pixels[a + 1] * 0.587 + web.pixels[a + 2] * 0.114) * 0.3 +
            255 * 0.7;
        overlay.pixels
          ..fillRange(to, to + 3, grey.round())
          ..[to + 3] = 255;
      }
    }
  }
  final share = differing / (w * h);

  final sheet = Rgba.filled(_gutter * 3 + w * 2, _gutter * 3 + _label * 2 + h * 2, 43, 43, 43);
  final top = _gutter + _label;
  _text(sheet, 'WEB', _gutter, _gutter);
  _text(sheet, 'APP', _gutter * 2 + w, _gutter);
  sheet
    ..draw(web, _gutter, top)
    ..draw(app, _gutter * 2 + w, top);
  final bottom = top + h + _gutter + _label;
  _text(sheet, 'DIFF ${_percent(share)}', _gutter, bottom - _label);
  sheet.draw(overlay, _gutter, bottom);
  return (sheet, share);
}

/// A 5 × 7 pixel font for the labels: each glyph is seven rows of five bits, top row first.
const _glyphs = <String, List<int>>{
  'A': [14, 17, 17, 31, 17, 17, 17],
  'B': [30, 17, 17, 30, 17, 17, 30],
  'D': [30, 17, 17, 17, 17, 17, 30],
  'E': [31, 16, 16, 30, 16, 16, 31],
  'F': [31, 16, 16, 30, 16, 16, 16],
  'I': [14, 4, 4, 4, 4, 4, 14],
  'P': [30, 17, 17, 30, 16, 16, 16],
  'W': [17, 17, 17, 21, 21, 21, 10],
  '0': [14, 17, 19, 21, 25, 17, 14],
  '1': [4, 12, 4, 4, 4, 4, 14],
  '2': [14, 17, 1, 2, 4, 8, 31],
  '3': [31, 2, 4, 2, 1, 17, 14],
  '4': [2, 6, 10, 18, 31, 2, 2],
  '5': [31, 16, 30, 1, 1, 17, 14],
  '6': [6, 8, 16, 30, 17, 17, 14],
  '7': [31, 1, 2, 4, 8, 8, 8],
  '8': [14, 17, 17, 14, 17, 17, 14],
  '9': [14, 17, 17, 15, 1, 2, 12],
  '.': [0, 0, 0, 0, 0, 12, 12],
  '%': [24, 25, 2, 4, 8, 19, 3],
  ' ': [0, 0, 0, 0, 0, 0, 0],
};

void _text(Rgba image, String text, int left, int top) {
  var x = left;
  for (final char in text.split('')) {
    final rows = _glyphs[char]!;
    for (var row = 0; row < 7; row++) {
      for (var col = 0; col < 5; col++) {
        if (rows[row] & (16 >> col) == 0) continue;
        for (var dy = 0; dy < _scale; dy++) {
          for (var dx = 0; dx < _scale; dx++) {
            final at = image.offset(x + col * _scale + dx, top + row * _scale + dy);
            image.pixels.fillRange(at, at + 4, 255);
          }
        }
      }
    }
    x += 6 * _scale;
  }
}
