import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/parity.dart';

/// The parity harness itself (test/support/parity.dart, docs/mobile/parity.md): its pairs, its
/// fixtures and the emoji it draws with.
void main() {
  test('every pair has its web shot, its fixture and its app test', () {
    final pairs = parityPairs();
    expect(pairs, isNotEmpty);
    for (final pair in pairs) {
      expect(['night', 'day'], contains(pair.theme));
      expect(File('test/parity/web/${pair.id}-${pair.theme}.png').existsSync(), isTrue);
      expect(File(pair.appTest).existsSync(), isTrue, reason: pair.appTest);
      expect(ParityFixtures.load(pair.storyId).storyId, pair.storyId);
    }
  });

  test('a fixture keeps the clock the story ran at', () {
    final fixture = ParityFixtures.load('ui-money--spanish');
    // apps/web/scripts/parity-storybook.ts PARITY_NOW, the e2e suite's E2E_NOW.
    expect(fixture.now, DateTime.utc(2026, 10, 21, 15));
    expect(fixture.timezone, 'Europe/Madrid');
    expect(fixture.api, isFalse);
    expect(fixture.responses, isEmpty);
  });

  test('requests are keyed as the web script keys them', () {
    // apps/web/scripts/parity-fixtures.ts fixtureKey: no /api mount, the query sorted.
    expect(
      ParityFixture.key('/api/v1/transactions?month=2026-10&limit=50'),
      '/v1/transactions?limit=50&month=2026-10',
    );
    expect(ParityFixture.key('/v1/me'), '/v1/me');
  });

  // Rendering is the macOS test engine's (Core Text); CI's Linux job skips it with the goldens.
  testWidgets('emoji draw in colour with the shared Noto Color Emoji', tags: ['golden'], (t) async {
    await t.runAsync(loadParityFonts);
    final key = GlobalKey();
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: key,
            child: Text(
              '🛒',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontFamilyFallback: const [parityEmojiFamily],
                fontSize: 40,
                color: const Color(0xFF000000),
              ),
            ),
          ),
        ),
      ),
    );
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final colours = await t.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      final seen = <int>{};
      for (var i = 0; i < bytes.lengthInBytes; i += 4) {
        if (bytes.getUint8(i + 3) == 255) seen.add(bytes.getUint32(i));
      }
      return seen;
    });
    // A cart in yellow and grey, not a black box or tofu: many opaque colours.
    expect(colours!.length, greaterThan(20));
  });
}
