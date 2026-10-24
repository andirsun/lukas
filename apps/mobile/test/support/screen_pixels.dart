import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter_test/flutter_test.dart';

/// What the screen shows, as pixels (the test view's root layer, at the view's own size and a ratio
/// of 1): for a check on what is drawn where, which no widget's rect says (what paints under a bar,
/// whether an edge is cut).
class ScreenPixels {
  ScreenPixels._(this._image, this._bytes);

  final Image _image;
  final ByteData _bytes;

  static Future<ScreenPixels> capture(WidgetTester tester) async {
    final root = tester.binding.renderViews.first;
    final layer = root.debugLayer! as OffsetLayer;
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final image = (await tester.runAsync(() => layer.toImage(Offset.zero & size)))!;
    final bytes = (await tester.runAsync(() => image.toByteData()))!;
    return ScreenPixels._(image, bytes);
  }

  int get width => _image.width;
  int get height => _image.height;

  /// The colour of the pixel at ([x], [y]), as 0xAARRGGBB.
  int at(double x, double y) {
    final i = ((y.floor() * _image.width) + x.floor()) * 4;
    return Color.fromARGB(
      _bytes.getUint8(i + 3),
      _bytes.getUint8(i),
      _bytes.getUint8(i + 1),
      _bytes.getUint8(i + 2),
    ).toARGB32();
  }
}
