import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/theme/surfaces.dart';
import 'package:lukitas/theme/theme.dart';
import 'package:lukitas/theme/tokens.g.dart';

void main() {
  const nightLk = LukitasTheme.night;
  const dayLk = LukitasTheme.day;
  final night = nightLk.colors;

  group('edgeShadow: the web\'s shadow-edge-*', () {
    test('sm and md are a solid bottom edge in the surface-edge colour, no blur', () {
      // tokens.css --edge-sm: 0 3px 0 #0f0c22 (night) / #d6ccf5 (day); --edge-md: 0 5px 0.
      expect(LkSurface.edgeShadow(nightLk, LkEdge.sm), const [
        BoxShadow(color: Color(0xFF0F0C22), offset: Offset(0, 3)),
      ]);
      expect(LkSurface.edgeShadow(nightLk, LkEdge.md), const [
        BoxShadow(color: Color(0xFF0F0C22), offset: Offset(0, 5)),
      ]);
      expect(LkSurface.edgeShadow(dayLk, LkEdge.sm), const [
        BoxShadow(color: Color(0xFFD6CCF5), offset: Offset(0, 3)),
      ]);
      expect(LkSurface.edgeShadow(dayLk, LkEdge.md), const [
        BoxShadow(color: Color(0xFFD6CCF5), offset: Offset(0, 5)),
      ]);
    });

    test('brand is a 6px edge in brand-edge plus a 24px glow', () {
      // tokens.css --edge-brand night: 0 6px 0 #3f22a3, 0 10px 24px rgba(139, 92, 255, 0.45).
      expect(LkSurface.edgeShadow(nightLk, LkEdge.brand), const [
        BoxShadow(color: Color(0xFF3F22A3), offset: Offset(0, 6)),
        BoxShadow(color: Color(0x738B5CFF), offset: Offset(0, 10), blurRadius: 24),
      ]);
      // ... day: 0 6px 0 #4a2bbf, 0 10px 24px rgba(123, 61, 240, 0.28).
      expect(LkSurface.edgeShadow(dayLk, LkEdge.brand), const [
        BoxShadow(color: Color(0xFF4A2BBF), offset: Offset(0, 6)),
        BoxShadow(color: Color(0x477B3DF0), offset: Offset(0, 10), blurRadius: 24),
      ]);
    });

    test('they are the web\'s own values: tokens.css has the same ones', () {
      final css = File('../web/app/styles/tokens.css').readAsStringSync();
      expect(css, contains('--edge-sm: 0 3px 0 #0f0c22;'));
      expect(css, contains('--edge-md: 0 5px 0 #d6ccf5;'));
      expect(css, contains('--edge-brand: 0 6px 0 #3f22a3, 0 10px 24px rgba(139, 92, 255, 0.45);'));
    });

    test('pressed: the edge collapses to 1px in the surface-edge colour', () {
      // app.css:106-109 .lk-press:active { box-shadow: 0 1px 0 var(--surface-edge) }
      expect(LkSurface.pressedEdge(nightLk), const [
        BoxShadow(color: Color(0xFF0F0C22), offset: Offset(0, 1)),
      ]);
      // app.css:131-134 .lk-btn-primary:active { box-shadow: 0 1px 0 var(--brand-edge) }
      expect(LkSurface.pressedBrandEdge(dayLk), const [
        BoxShadow(color: Color(0xFF4A2BBF), offset: Offset(0, 1)),
      ]);
    });
  });

  group('background: the screen\'s gradient', () {
    test('is radial-gradient(120% 60% at 50% 0%, bg-glow 0%, bg 55%)', () {
      // app.css:61-63 .lk-screen
      final gradient = LkSurface.background(night) as RadialGradient;
      expect(gradient.colors, [night.bgGlow, night.bg]);
      expect(gradient.stops, [0.0, 0.55]);
      expect(gradient.center, Alignment.topCenter);
      expect(gradient.radius, 1.0);
    });

    test('is an ellipse 120% wide and 60% tall, centred on the top edge', () {
      final gradient = LkSurface.background(dayLk.colors) as RadialGradient;
      // A 412 x 915 screen: the shortest side is 412, so radius 1.0 is 412 px both ways.
      final matrix = gradient.transform!.transform(const Rect.fromLTWH(0, 0, 412, 915))!;
      // The gradient's centre (206, 0) stays where it is; x grows by 1.2 * 412 / 412 = 1.2,
      // y by 0.6 * 915 / 412.
      expect(matrix.getMaxScaleOnAxis(), greaterThan(1));
      final centre = MatrixUtils.transformPoint(matrix, const Offset(206, 0));
      expect(centre.dx, closeTo(206, 1e-6));
      expect(centre.dy, closeTo(0, 1e-6));
      final right = MatrixUtils.transformPoint(matrix, const Offset(206 + 412, 0));
      expect(right.dx - centre.dx, closeTo(1.2 * 412, 1e-6));
      final down = MatrixUtils.transformPoint(matrix, const Offset(206, 412));
      expect(down.dy - centre.dy, closeTo(0.6 * 915, 1e-6));
    });

    test('paints bg-glow at the top centre and bg from 55% of the way down', () async {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(412, 915);
      canvas.drawRect(
        Offset.zero & size,
        Paint()..shader = LkSurface.background(night).createShader(Offset.zero & size),
      );
      final image = await recorder.endRecording().toImage(412, 915);
      final data = (await image.toByteData())!;
      Color at(int x, int y) {
        final i = (y * 412 + x) * 4;
        return Color.fromARGB(
          data.getUint8(i + 3),
          data.getUint8(i),
          data.getUint8(i + 1),
          data.getUint8(i + 2),
        );
      }

      expect(at(206, 0), night.bgGlow);
      expect(at(206, 914), night.bg);
      // 0.6 * 915 * 0.55 = 302 px down the centre column the glow has faded to bg.
      expect(at(206, 310), night.bg);
      expect(at(206, 100), isNot(night.bg));
    });
  });

  group('radii and borders', () {
    test('radius helpers are the tokens\' radii', () {
      expect(LkSurface.radius(LkRadius.sm), BorderRadius.circular(10));
      expect(LkSurface.radius(LkRadius.md), BorderRadius.circular(14));
      expect(LkSurface.radius(LkRadius.lg), BorderRadius.circular(18));
      expect(LkSurface.radius(LkRadius.xl), BorderRadius.circular(24));
      expect(LkSurface.radius(LkRadius.pill), BorderRadius.circular(999));
    });

    test('a card has the 2px stroke border, as .lk-rowcard does', () {
      // app.css:226-235 .lk-rowcard { border-radius: var(--radius-lg); border: 2px solid var(--stroke) }
      final border = LkSurface.border(night);
      expect(border, Border.all(color: night.stroke, width: 2));
    });

    test('a row card puts it all together: surface-row, 18px, 2px stroke, edge-sm', () {
      final decoration = LkSurface.rowCard(nightLk);
      expect(decoration.color, night.surfaceRow);
      expect(decoration.borderRadius, BorderRadius.circular(18));
      expect(decoration.border, Border.all(color: night.stroke, width: 2));
      expect(decoration.boxShadow, LkSurface.edgeShadow(nightLk, LkEdge.sm));
    });
  });

  test('the theme carries the shadows of its mode', () {
    expect(nightTheme.extension<LukitasTheme>()!.shadows, LukitasShadows.night);
    expect(dayTheme.extension<LukitasTheme>()!.shadows, LukitasShadows.day);
  });
}
