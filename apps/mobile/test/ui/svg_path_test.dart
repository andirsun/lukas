import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/svg_path.dart';

void main() {
  group('SVG path data', () {
    test('lines, relative and absolute, and close', () {
      expect(parseSvgPath('M1 2h10v5z').getBounds(), const Rect.fromLTRB(1, 2, 11, 7));
      expect(parseSvgPath('M1 2H11V7Z').getBounds(), const Rect.fromLTRB(1, 2, 11, 7));
      // Pairs after a move are lines.
      expect(parseSvgPath('M0 0 4 0 4 3').getBounds(), const Rect.fromLTRB(0, 0, 4, 3));
    });

    test('a number may start at a sign or a dot, and a command needs no space', () {
      expect(
        parseSvgPath('M12 2.5v2.2M12 19.3v2.2').getBounds(),
        const Rect.fromLTRB(12, 2.5, 12, 21.5),
      );
      expect(parseSvgPath('M5 5l-.5-.5').getBounds(), const Rect.fromLTRB(4.5, 4.5, 5, 5));
      expect(parseSvgPath('M0 0l.5.5').getBounds(), const Rect.fromLTRB(0, 0, .5, .5));
    });

    test('an arc goes the way its sweep flag says, and relative is the same as absolute', () {
      // From (0,0) to (10,0) with a radius of 5: a half circle, above the line when the sweep
      // flag is 1 (clockwise in SVG's downward y).
      final up = parseSvgPath('M0 0a5 5 0 0 1 10 0').getBounds();
      expect(up.top, closeTo(-5, 1e-6));
      expect(up.bottom, closeTo(0, 1e-6));
      final down = parseSvgPath('M0 0a5 5 0 0 0 10 0').getBounds();
      expect(down.top, closeTo(0, 1e-6));
      expect(down.bottom, closeTo(5, 1e-6));
      expect(
        parseSvgPath('M3 4A5 5 0 0 1 13 4').getBounds(),
        parseSvgPath('M3 4a5 5 0 0 1 10 0').getBounds(),
      );
    });

    test('curves: relative is the same as absolute', () {
      final relative = parseSvgPath('M1 1c1 0 2 1 3 3').getBounds();
      final absolute = parseSvgPath('M1 1C2 1 3 2 4 4').getBounds();
      expect(relative, absolute);
    });

    test('data that is not path data is refused', () {
      expect(() => parseSvgPath('10 10'), throwsFormatException);
      expect(() => parseSvgPath('M1'), throwsFormatException);
      expect(() => parseSvgPath('M1 1X'), throwsFormatException);
    });
  });
}
