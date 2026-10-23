// Lays each parity pair side by side for review (docs/mobile/parity.md):
//
//   dart run tool/parity/compose.dart [id filter] [--max <percent>]
//
// For each pair in test/parity/parity.json, reads the web's shot (test/parity/web/<id>-<theme>.png,
// apps/web's `pnpm parity:shots`) and the app's golden (test/parity/app/<id>-<theme>.png,
// `flutter test --update-goldens test/parity`) and writes build/parity/<id>-<theme>.png: the web
// on the left, the app on the right, and under them the web faded to grey with every pixel that
// differs in magenta, and the share of the ink that differs. build/parity is git-ignored; it also
// gets summary.json with every pair's shares.
//
// A pixel differs when the colour one side has there is nowhere within one logical pixel (two
// physical) of it on the other side (within [colourTolerance]): a glyph drawn half a pixel lower in Flutter than in
// Chrome is the same glyph, a glyph one pixel bigger or 15% paler is not. The share is taken of
// the ink, the pixels that are not the page's background on either side, so a small component on
// a big empty page counts as much as a full screen. With --max, any pair over that share of its
// ink fails the run (exit 1).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'png.dart';

/// Two colours are the same when no channel differs by more than this (out of 255): enough for
/// the rounding and antialiasing of two renderers, little enough that a colour 15% off (a
/// translucent ink, the wrong token) is caught.
const colourTolerance = 24;

/// How far, in physical pixels, a matching colour may be on the other side: one logical pixel at
/// the parity's device pixel ratio of 2 (spec §5's one-pixel wobble).
const shiftTolerance = 2;

const _gutter = 24;
const _scale = 4;
const _label = 7 * _scale + 16;

void main(List<String> args) {
  exitCode = run(args, root: Directory.current.path, out: stdout);
}

/// Composes the pairs under [root] (apps/mobile) and returns the exit code: 1 when a picture is
/// missing or a pair's ink share is over `--max`.
int run(List<String> args, {required String root, required StringSink out}) {
  String? only;
  double? maxPercent;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--max') {
      maxPercent = double.parse(args[++i]);
    } else {
      only = args[i];
    }
  }
  final pairs =
      (jsonDecode(File('$root/test/parity/parity.json').readAsStringSync()) as List<Object?>)
          .cast<Map<String, Object?>>()
          .where((pair) => only == null || (pair['id']! as String).contains(only));
  final summary = <String, Object?>{};
  var failed = false;
  for (final pair in pairs) {
    final name = '${pair['id']}-${pair['theme']}';
    final webFile = '$root/test/parity/web/$name.png';
    final appFile = '$root/test/parity/app/$name.png';
    if (!File(webFile).existsSync() || !File(appFile).existsSync()) {
      out.writeln('$name: missing ${File(webFile).existsSync() ? appFile : webFile}');
      failed = true;
      continue;
    }
    final diff = compare(readPng(webFile), readPng(appFile));
    final image = 'build/parity/$name.png';
    writePng('$root/$image', diff.sheet);
    summary[name] = {
      'storyId': pair['storyId'],
      'inkPercent': diff.inkShare * 100,
      'canvasPercent': diff.canvasShare * 100,
      'image': image,
    };
    final over = maxPercent != null && diff.inkShare * 100 > maxPercent;
    if (over) failed = true;
    out.writeln(
      '$name: ${_percent(diff.inkShare)} of the ink differs '
      '(${_percent(diff.canvasShare)} of the page)  $image${over ? '  FAIL: over $maxPercent%' : ''}',
    );
  }
  File('$root/build/parity/summary.json')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(summary)}\n');
  return failed ? 1 : 0;
}

String _percent(double share) => '${(share * 100).toStringAsFixed(2)}%';

/// One pair compared: the review picture and the counts behind its shares.
class ParityDiff {
  const ParityDiff(this.sheet, this.differing, this.ink, this.pixels);

  final Rgba sheet;

  /// Pixels that differ (see the file's comment).
  final int differing;

  /// Pixels that are not the page's background (its top-left pixel) on one side or the other.
  final int ink;

  /// Pixels compared: the larger picture's.
  final int pixels;

  /// The share of the ink that differs (0 when neither side draws anything).
  double get inkShare => ink == 0 ? 0 : differing / ink;

  /// The share of the whole page that differs.
  double get canvasShare => differing / pixels;
}

/// Compares the two pictures. Pictures of different sizes are compared over the larger one,
/// where a pixel only one has differs.
ParityDiff compare(Rgba web, Rgba app) {
  final w = max(web.width, app.width);
  final h = max(web.height, app.height);
  final overlay = Rgba(w, h);
  final webBackground = web.offset(0, 0);
  final appBackground = app.offset(0, 0);
  var differing = 0;
  var ink = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final inWeb = x < web.width && y < web.height;
      final inApp = x < app.width && y < app.height;
      final to = overlay.offset(x, y);
      final isInk =
          (inWeb && !_same(web, web.offset(x, y), web, webBackground)) ||
          (inApp && !_same(app, app.offset(x, y), app, appBackground));
      if (isInk) ink++;
      final differs = inWeb != inApp || !_nearby(web, x, y, app) || !_nearby(app, x, y, web);
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
  final diff = ParityDiff(overlay, differing, ink, w * h);

  final sheet = Rgba.filled(_gutter * 3 + w * 2, _gutter * 3 + _label * 2 + h * 2, 43, 43, 43);
  final top = _gutter + _label;
  _text(sheet, 'WEB', _gutter, _gutter);
  _text(sheet, 'APP', _gutter * 2 + w, _gutter);
  sheet
    ..draw(web, _gutter, top)
    ..draw(app, _gutter * 2 + w, top);
  final bottom = top + h + _gutter + _label;
  _text(
    sheet,
    'INK ${_percent(diff.inkShare)}  PAGE ${_percent(diff.canvasShare)}',
    _gutter,
    bottom - _label,
  );
  sheet.draw(overlay, _gutter, bottom);
  return ParityDiff(sheet, differing, ink, w * h);
}

bool _same(Rgba a, int at, Rgba b, int bt) {
  for (var c = 0; c < 4; c++) {
    if ((a.pixels[at + c] - b.pixels[bt + c]).abs() > colourTolerance) return false;
  }
  return true;
}

/// Whether [from]'s colour at (x, y) is on [other] within [shiftTolerance] pixels of (x, y).
bool _nearby(Rgba from, int x, int y, Rgba other) {
  if (x >= from.width || y >= from.height) return true;
  final at = from.offset(x, y);
  for (var dy = -shiftTolerance; dy <= shiftTolerance; dy++) {
    final oy = y + dy;
    if (oy < 0 || oy >= other.height) continue;
    for (var dx = -shiftTolerance; dx <= shiftTolerance; dx++) {
      final ox = x + dx;
      if (ox < 0 || ox >= other.width) continue;
      if (_same(from, at, other, other.offset(ox, oy))) return true;
    }
  }
  return false;
}

/// A 5 × 7 pixel font for the labels: each glyph is seven rows of five bits, top row first.
const _glyphs = <String, List<int>>{
  'A': [14, 17, 17, 31, 17, 17, 17],
  'B': [30, 17, 17, 30, 17, 17, 30],
  'D': [30, 17, 17, 17, 17, 17, 30],
  'E': [31, 16, 16, 30, 16, 16, 31],
  'F': [31, 16, 16, 30, 16, 16, 16],
  'G': [14, 17, 16, 23, 17, 17, 15],
  'I': [14, 4, 4, 4, 4, 4, 14],
  'K': [17, 18, 20, 24, 20, 18, 17],
  'N': [17, 17, 25, 21, 19, 17, 17],
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
