import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/parity/compose.dart';
import '../../tool/parity/png.dart';

/// tool/parity/compose.dart and its PNG reader and writer (docs/mobile/parity.md).
void main() {
  Rgba square(int r, int g, int b, {int size = 10}) => Rgba.filled(size, size, r, g, b);

  /// A [size]² page in the night background with a [w] × [h] block of ink at ([x], [y]).
  Rgba page({int size = 20, int x = 5, int y = 5, int w = 6, int h = 4, int ink = 240}) {
    final image = square(21, 18, 43, size: size);
    for (var j = y; j < y + h; j++) {
      for (var i = x; i < x + w; i++) {
        image.pixels.fillRange(image.offset(i, j), image.offset(i, j) + 3, ink);
      }
    }
    return image;
  }

  test('a PNG it writes reads back pixel for pixel', () {
    final dir = Directory.systemTemp.createTempSync('parity-png');
    addTearDown(() => dir.deleteSync(recursive: true));
    final image = square(21, 18, 43);
    image.pixels
      ..[image.offset(3, 4)] = 250
      ..[image.offset(3, 4) + 3] = 128;
    writePng('${dir.path}/a.png', image);
    expect(readPng('${dir.path}/a.png').pixels, image.pixels);
  });

  test('reads the RGB PNGs Chrome writes and the RGBA ones Flutter writes', () {
    final web = readPng('test/parity/web/money-spanish-night.png');
    final app = readPng('test/parity/app/money-spanish-night.png');
    expect((web.width, web.height), (824, 1830));
    expect((app.width, app.height), (824, 1830));
    // The night background (tokens.css --bg #15122b) in a corner of both.
    for (final image in [web, app]) {
      final corner = image.offset(image.width - 1, image.height - 1);
      expect(image.pixels.sublist(corner, corner + 4), [0x15, 0x12, 0x2b, 255]);
    }
  });

  group('the share of ink that differs', () {
    test('ink is what is not the page background, on either side', () {
      final diff = compare(page(), page(x: 8));
      // 6 × 4 on each side, 3 columns shared: 24 + 24 − 12.
      expect(diff.ink, 36);
      expect(diff.pixels, 400);
    });

    test('the same picture differs nowhere', () {
      final diff = compare(page(), page());
      expect(diff.differing, 0);
      expect(diff.inkShare, 0);
    });

    test('a shift of one logical pixel (two physical: antialiasing, rounding) is not a '
        'difference', () {
      expect(compare(page(), page(x: 6)).differing, 0);
      expect(compare(page(), page(x: 7)).differing, 0);
      expect(compare(page(), page(y: 3)).differing, 0);
      expect(compare(page(), page(x: 7, y: 7)).differing, 0);
    });

    test('a shift of three physical pixels is', () {
      final diff = compare(page(), page(x: 8));
      // The web's first column and the app's last find no ink within two pixels: 2 × 4. The ink
      // is 24 + 24 − 12 shared.
      expect(diff.differing, 8);
      expect(diff.inkShare, closeTo(8 / 36, 1e-9));
      expect(diff.canvasShare, closeTo(8 / 400, 1e-9));
    });

    test('a colour off by more than the tolerance is, everywhere it is drawn', () {
      final diff = compare(page(), page(ink: 240 - colourTolerance - 1));
      expect(diff.differing, 24);
      expect(diff.inkShare, 1);
    });

    test('a colour within the tolerance is not', () {
      expect(compare(page(), page(ink: 240 - colourTolerance)).differing, 0);
    });

    test('pictures of different sizes differ wherever only one has pixels', () {
      final diff = compare(square(0, 0, 0, size: 10), Rgba.filled(10, 5, 0, 0, 0));
      expect(diff.differing, 50);
      expect(diff.canvasShare, 0.5);
    });

    test('lays out web and app side by side, the overlay under them', () {
      final sheet = compare(page(), page(x: 8)).sheet;
      expect(sheet.width, 2 * 20 + 3 * 24);
      expect(sheet.height, greaterThan(2 * 20));
    });
  });

  group('run', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('parity-compose');
      for (final dir in ['web', 'app']) {
        Directory('${root.path}/test/parity/$dir').createSync(recursive: true);
      }
      File('${root.path}/test/parity/parity.json').writeAsStringSync(
        jsonEncode([
          {'id': 'same', 'storyId': 'ui-x--same', 'theme': 'night', 'appTest': 'x_test.dart'},
          {'id': 'off', 'storyId': 'ui-x--off', 'theme': 'night', 'appTest': 'x_test.dart'},
        ]),
      );
      writePng('${root.path}/test/parity/web/same-night.png', page());
      writePng('${root.path}/test/parity/app/same-night.png', page(x: 7));
      writePng('${root.path}/test/parity/web/off-night.png', page());
      writePng('${root.path}/test/parity/app/off-night.png', page(x: 8));
    });
    tearDown(() => root.deleteSync(recursive: true));

    test('writes the pictures and a summary with both shares', () {
      expect(run([], root: root.path, out: StringBuffer()), 0);
      expect(File('${root.path}/build/parity/same-night.png').existsSync(), isTrue);
      final summary = jsonDecode(
        File('${root.path}/build/parity/summary.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final off = summary['off-night']! as Map<String, Object?>;
      expect(off['inkPercent'], closeTo(800 / 36, 1e-9));
      expect(off['canvasPercent'], closeTo(2, 1e-9));
    });

    test('--max fails when a pair\'s ink share is over it, and names the pair', () {
      final out = StringBuffer();
      expect(run(['--max', '2'], root: root.path, out: out), 1);
      expect(out.toString(), contains('off-night'));
      expect(out.toString(), contains('over 2'));
      expect(run(['same', '--max', '2'], root: root.path, out: StringBuffer()), 0);
      expect(run(['--max', '30'], root: root.path, out: StringBuffer()), 0);
    });

    test('a pair with known differences says so, on its line and in the summary', () {
      File('${root.path}/test/parity/parity.json').writeAsStringSync(
        jsonEncode([
          {
            'id': 'same',
            'storyId': 'ui-x--same',
            'theme': 'night',
            'appTest': 'x_test.dart',
            'knownDifferences': ['✓ is drawn from a different test font on each side'],
          },
          {'id': 'off', 'storyId': 'ui-x--off', 'theme': 'night', 'appTest': 'x_test.dart'},
        ]),
      );
      final out = StringBuffer();
      run([], root: root.path, out: out);
      final lines = out.toString().trim().split('\n');
      final same = lines.firstWhere((l) => l.startsWith('same-night'));
      expect(same, contains('KNOWN DIFFERENCE'));
      expect(same, contains('✓ is drawn from a different test font on each side'));
      expect(lines.firstWhere((l) => l.startsWith('off-night')), isNot(contains('KNOWN')));
      final summary = jsonDecode(
        File('${root.path}/build/parity/summary.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expect((summary['same-night']! as Map<String, Object?>)['knownDifferences'], [
        '✓ is drawn from a different test font on each side',
      ]);
      expect(
        (summary['off-night']! as Map<String, Object?>).containsKey('knownDifferences'),
        isFalse,
      );
    });

    test('a pair without both pictures fails', () {
      File('${root.path}/test/parity/app/same-night.png').deleteSync();
      final out = StringBuffer();
      expect(run([], root: root.path, out: out), 1);
      expect(out.toString(), contains('missing'));
    });
  });
}
