import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/parity/compose.dart';
import '../../tool/parity/png.dart';

/// tool/parity/compose.dart and its PNG reader and writer (docs/mobile/parity.md).
void main() {
  Rgba square(int r, int g, int b, {int size = 10}) => Rgba.filled(size, size, r, g, b);

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

  test('counts the pixels that differ by more than the tolerance', () {
    final web = square(100, 100, 100);
    final app = square(100, 100, 100);
    // Within the tolerance: the same colour.
    app.pixels[app.offset(0, 0)] = 100 + tolerance;
    expect(compose(web, app).$2, 0);
    // Past it, in 5 of 100 pixels.
    for (var x = 0; x < 5; x++) {
      app.pixels[app.offset(x, 1) + 2] = 100 + tolerance + 1;
    }
    final (sheet, share) = compose(web, app);
    expect(share, 0.05);
    // Web and app side by side, the overlay under them.
    expect(sheet.width, 2 * 10 + 3 * 24);
    expect(sheet.height, greaterThan(2 * 10));
  });

  test('pictures of different sizes differ wherever only one has pixels', () {
    expect(compose(square(0, 0, 0, size: 10), Rgba.filled(10, 5, 0, 0, 0)).$2, 0.5);
  });
}
