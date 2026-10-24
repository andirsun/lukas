import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/category_look.dart';

void main() {
  test('a category made in the app: its emoji and its hex color', () {
    final look = categoryLook(icon: '🛒', color: '#2fd388');
    expect(look.glyph, '🛒');
    expect(look.tint, const Color(0xFF2FD388));
  });

  test('a category from the Budge importer: names map to an emoji and a tint', () {
    final look = categoryLook(icon: 'cart', color: 'orange');
    expect(look.glyph, '🛒');
    expect(look.tint, const Color(0xFFFF9F1C));
  });

  test('anything else falls back to a gray tint, and keeps the icon as it is', () {
    final look = categoryLook(icon: '🐶', color: 'not-a-color');
    expect(look.glyph, '🐶');
    expect(look.tint, const Color(0xFF8E87B8));
    expect(categoryLook(icon: 'tag', color: '#abc').tint, const Color(0xFFAABBCC));
  });
}
