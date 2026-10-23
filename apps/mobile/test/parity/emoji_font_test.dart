import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../support/emoji_font.dart';

/// The shared emoji font (test/parity/fonts, docs/mobile/parity.md) and test/support/emoji_font.dart.
void main() {
  final font = File('test/parity/fonts/NotoColorEmoji.ttf').readAsBytesSync();

  Map<String, (int, int)> tables(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    return {
      for (var i = 0; i < data.getUint16(4); i++)
        String.fromCharCodes(bytes, 12 + i * 16, 16 + i * 16): (
          data.getUint32(20 + i * 16),
          data.getUint32(24 + i * 16),
        ),
    };
  }

  test('is the CBDT build, which the web draws as it is', () {
    expect(tables(font).keys, containsAll(['CBDT', 'CBLC', 'cmap']));
  });

  test('sbixFromCbdt moves every picture into an sbix table, each with an outline', () {
    final converted = sbixFromCbdt(font);
    final found = tables(converted);
    expect(found.keys, containsAll(['sbix', 'glyf', 'loca']));
    expect(found.keys, isNot(contains('CBDT')));

    final data = ByteData.sublistView(converted);
    final numGlyphs = data.getUint16(found['maxp']!.$1 + 4);
    final (sbix, _) = found['sbix']!;
    final strike = sbix + data.getUint32(sbix + 8);
    final (loca, _) = found['loca']!;
    var pictures = 0;
    for (var g = 0; g < numGlyphs; g++) {
      final start = data.getUint32(strike + 4 + g * 4);
      final end = data.getUint32(strike + 8 + g * 4);
      if (end == start) continue;
      pictures++;
      // 'png ', then the PNG's own signature.
      expect(data.getUint32(strike + start + 4), 0x706e6720);
      expect(converted.sublist(strike + start + 8, strike + start + 12), [137, 80, 78, 71]);
      // An outline (a box) for Core Text to draw the bitmap in.
      expect(data.getUint32(loca + (g + 1) * 4), greaterThan(data.getUint32(loca + g * 4)));
    }
    // Every emoji character has its picture; sequences (flags, skin tones, ZWJ) have more.
    expect(pictures, greaterThanOrEqualTo(emojiWithPictures(font).length));
    expect(emojiWithPictures(font).length, greaterThan(1000));
  });

  test('finds the emoji the font has no picture for', () {
    expect(emojiWithoutPicture('🛒 Supermercado 🍽️ ⭐ ✓', font), isEmpty);
    // U+1FAFF is not assigned: no font draws it.
    expect(emojiWithoutPicture('a \u{1FAFF} b', font), {'\u{1FAFF}'});
  });

  test('every emoji in the parity fixtures has a picture, so none is drawn as a box', () {
    final fixtures = Directory('test/parity/fixtures')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'));
    for (final fixture in fixtures) {
      expect(
        emojiWithoutPicture(fixture.readAsStringSync(), font),
        isEmpty,
        reason:
            '${fixture.path} uses emoji test/parity/fonts/NotoColorEmoji.ttf has no picture for: '
            'update the font (docs/mobile/parity.md)',
      );
    }
  });
}
