import 'dart:typed_data';

/// Noto Color Emoji's bitmaps, rewrapped so the macOS test engine can draw them.
///
/// Noto Color Emoji keeps its pictures as PNGs in the `CBDT`/`CBLC` tables. Android and Chrome
/// draw those, but `flutter test` on macOS hands fonts to Core Text, which draws Apple's `sbix`
/// bitmap table and not `CBDT` (it shows a box). [sbixFromCbdt] moves the very same PNGs, at the
/// same strike, size and placement, into an `sbix` table (plus the box outlines Core Text expects
/// of an `sbix` font), in memory, for the goldens only. The committed font stays the
/// unmodified upstream file, and the web's shots draw that file as it is.
///
/// Reads `CBLC` index formats 1 to 5 and `CBDT` image formats 17, 18 and 19 (the PNG ones), as
/// the OpenType spec defines them (https://learn.microsoft.com/typography/opentype/spec/cblc,
/// .../cbdt, .../sbix).
Uint8List sbixFromCbdt(Uint8List font) {
  final data = ByteData.sublistView(font);
  final tables = _tables(data);
  final cblc = tables['CBLC'];
  final cbdt = tables['CBDT'];
  if (cblc == null || cbdt == null) {
    throw ArgumentError('The font has no CBLC/CBDT tables to convert.');
  }
  final numGlyphs = data.getUint16(tables['maxp']!.offset + 4);

  // The largest strike: Noto ships one, at 109 ppem.
  final numSizes = data.getUint32(cblc.offset + 4);
  var best = 0;
  var bestPpem = -1;
  for (var i = 0; i < numSizes; i++) {
    final ppem = data.getUint8(cblc.offset + 8 + i * 48 + 45);
    if (ppem > bestPpem) (best, bestPpem) = (i, ppem);
  }
  final size = cblc.offset + 8 + best * 48;
  final arrayStart = cblc.offset + data.getUint32(size);
  final subtables = data.getUint32(size + 8);

  final glyphs = <int, _Bitmap>{};
  for (var s = 0; s < subtables; s++) {
    final entry = arrayStart + s * 8;
    final first = data.getUint16(entry);
    final last = data.getUint16(entry + 2);
    final sub = arrayStart + data.getUint32(entry + 4);
    final indexFormat = data.getUint16(sub);
    final imageFormat = data.getUint16(sub + 2);
    final imageData = cbdt.offset + data.getUint32(sub + 4);
    void add(int glyph, int start, int end, [_Metrics? shared]) {
      if (end > start) glyphs[glyph] = _bitmap(data, imageFormat, start, end, shared);
    }

    switch (indexFormat) {
      case 1 || 3:
        final wide = indexFormat == 1;
        int offset(int i) =>
            wide ? data.getUint32(sub + 8 + i * 4) : data.getUint16(sub + 8 + i * 2);
        for (var g = first; g <= last; g++) {
          add(g, imageData + offset(g - first), imageData + offset(g - first + 1));
        }
      case 2:
        final imageSize = data.getUint32(sub + 8);
        final metrics = _Metrics.big(data, sub + 12);
        for (var g = first; g <= last; g++) {
          final start = imageData + (g - first) * imageSize;
          add(g, start, start + imageSize, metrics);
        }
      case 4:
        final count = data.getUint32(sub + 8);
        for (var i = 0; i < count; i++) {
          final pair = sub + 12 + i * 4;
          add(
            data.getUint16(pair),
            imageData + data.getUint16(pair + 2),
            imageData + data.getUint16(pair + 6),
          );
        }
      case 5:
        final imageSize = data.getUint32(sub + 8);
        final metrics = _Metrics.big(data, sub + 12);
        final count = data.getUint32(sub + 20);
        for (var i = 0; i < count; i++) {
          final start = imageData + i * imageSize;
          add(data.getUint16(sub + 24 + i * 2), start, start + imageSize, metrics);
        }
      default:
        throw UnsupportedError('CBLC index format $indexFormat');
    }
  }

  final out = Map.of({
    for (final MapEntry(:key, :value) in tables.entries)
      if (key != 'CBLC' && key != 'CBDT') key: Uint8List.sublistView(font, value.offset, value.end),
  });
  out['sbix'] = _sbix(glyphs, numGlyphs, bestPpem);
  final head = Uint8List.fromList(out['head']!);
  final upem = ByteData.sublistView(head).getUint16(18);
  final (glyf, loca) = _boxes(glyphs, numGlyphs, upem / bestPpem);
  out['glyf'] = glyf;
  out['loca'] = loca;
  ByteData.sublistView(head)
    ..setUint32(8, 0) // checkSumAdjustment: not checked by the engine.
    ..setInt16(50, 1); // indexToLocFormat: long offsets.
  out['head'] = head;
  out['maxp'] =
      (ByteData(32)
            ..setUint32(0, 0x00010000)
            ..setUint16(4, numGlyphs)
            ..setUint16(14, 2)) // maxZones
          .buffer
          .asUint8List();
  return _assemble(out);
}

class _Table {
  const _Table(this.offset, this.length);
  final int offset;
  final int length;
  int get end => offset + length;
}

Map<String, _Table> _tables(ByteData data) {
  final count = data.getUint16(4);
  return {
    for (var i = 0; i < count; i++)
      String.fromCharCodes(Uint8List.sublistView(data, 12 + i * 16, 16 + i * 16)): _Table(
        data.getUint32(20 + i * 16),
        data.getUint32(24 + i * 16),
      ),
  };
}

class _Metrics {
  const _Metrics(this.height, this.width, this.bearingX, this.bearingY);
  _Metrics.small(ByteData d, int at)
    : this(d.getUint8(at), d.getUint8(at + 1), d.getInt8(at + 2), d.getInt8(at + 3));
  _Metrics.big(ByteData d, int at)
    : this(d.getUint8(at), d.getUint8(at + 1), d.getInt8(at + 2), d.getInt8(at + 3));
  final int height;
  final int width;
  final int bearingX;
  final int bearingY;
}

class _Bitmap {
  const _Bitmap(this.metrics, this.png);
  final _Metrics metrics;
  final Uint8List png;
}

_Bitmap _bitmap(ByteData data, int format, int start, int end, _Metrics? shared) {
  Uint8List png(int at) => Uint8List.sublistView(data, at + 4, at + 4 + data.getUint32(at));
  switch (format) {
    case 17:
      return _Bitmap(_Metrics.small(data, start), png(start + 5));
    case 18:
      return _Bitmap(_Metrics.big(data, start), png(start + 8));
    case 19:
      return _Bitmap(shared!, png(start));
    default:
      throw UnsupportedError('CBDT image format $format');
  }
}

/// One strike at [ppem] (72 ppi). Core Text puts an `sbix` bitmap's bottom-left corner at the
/// bottom-left of the glyph's outline plus the origin offset, so the offsets are 0 and the
/// outline ([_boxes]) is where CBDT puts the bitmap.
Uint8List _sbix(Map<int, _Bitmap> glyphs, int numGlyphs, int ppem) {
  final body = BytesBuilder();
  final offsets = <int>[];
  final dataStart = 4 + (numGlyphs + 1) * 4;
  for (var g = 0; g < numGlyphs; g++) {
    offsets.add(dataStart + body.length);
    final bitmap = glyphs[g];
    if (bitmap == null) continue;
    body
      ..add(
        (ByteData(8)
              ..setInt16(0, 0)
              ..setInt16(2, 0)
              ..setUint32(4, 0x706e6720)) // 'png '
            .buffer
            .asUint8List(),
      )
      ..add(bitmap.png);
  }
  offsets.add(dataStart + body.length);
  final strike = BytesBuilder()
    ..add(
      (ByteData(4)
            ..setUint16(0, ppem)
            ..setUint16(2, 72))
          .buffer
          .asUint8List(),
    );
  final offsetBytes = ByteData(offsets.length * 4);
  for (var i = 0; i < offsets.length; i++) {
    offsetBytes.setUint32(i * 4, offsets[i]);
  }
  strike
    ..add(offsetBytes.buffer.asUint8List())
    ..add(body.takeBytes());
  // Header: version 1, flags 1 (draw the bitmaps only), one strike right after.
  return (BytesBuilder()
        ..add(
          (ByteData(12)
                ..setUint16(0, 1)
                ..setUint16(2, 1)
                ..setUint32(4, 1)
                ..setUint32(8, 12))
              .buffer
              .asUint8List(),
        )
        ..add(strike.takeBytes()))
      .takeBytes();
}

/// Core Text draws an `sbix` bitmap only inside the glyph's outline, from its bottom-left corner
/// (Apple Color Emoji has one outline per glyph). Each bitmap gets a rectangle over the area its
/// PNG covers in CBDT (bearingX, bearingY − height, width × height), in font units; glyphs
/// without a bitmap (the space) get none.
(Uint8List, Uint8List) _boxes(Map<int, _Bitmap> glyphs, int numGlyphs, double unitsPerPixel) {
  final glyf = BytesBuilder();
  final loca = ByteData((numGlyphs + 1) * 4);
  for (var g = 0; g < numGlyphs; g++) {
    loca.setUint32(g * 4, glyf.length);
    final m = glyphs[g]?.metrics;
    if (m == null) continue;
    int units(int pixels) => (pixels * unitsPerPixel).round();
    final (x0, y0) = (units(m.bearingX), units(m.bearingY - m.height));
    final (x1, y1) = (units(m.bearingX + m.width), units(m.bearingY));
    final points = [(x0, y0), (x0, y1), (x1, y1), (x1, y0)];
    final outline = ByteData(34)
      ..setInt16(0, 1) // one contour
      ..setInt16(2, x0)
      ..setInt16(4, y0)
      ..setInt16(6, x1)
      ..setInt16(8, y1)
      ..setUint16(10, 3) // its last point
      ..setUint16(12, 0); // no instructions
    var (x, y) = (0, 0);
    for (var i = 0; i < 4; i++) {
      final (px, py) = points[i];
      outline
        ..setUint8(14 + i, 1) // on the curve; x and y as int16 deltas
        ..setInt16(18 + i * 2, px - x)
        ..setInt16(26 + i * 2, py - y);
      (x, y) = (px, py);
    }
    glyf.add(outline.buffer.asUint8List());
  }
  loca.setUint32(numGlyphs * 4, glyf.length);
  return (glyf.takeBytes(), loca.buffer.asUint8List());
}

Uint8List _assemble(Map<String, Uint8List> tables) {
  final tags = tables.keys.toList()..sort();
  final n = tags.length;
  var entrySelector = 0;
  while ((1 << (entrySelector + 1)) <= n) {
    entrySelector++;
  }
  final searchRange = (1 << entrySelector) * 16;
  final header = ByteData(12 + n * 16)
    ..setUint32(0, 0x00010000)
    ..setUint16(4, n)
    ..setUint16(6, searchRange)
    ..setUint16(8, entrySelector)
    ..setUint16(10, n * 16 - searchRange);
  final body = BytesBuilder();
  var offset = 12 + n * 16;
  for (var i = 0; i < n; i++) {
    final bytes = tables[tags[i]]!;
    final padded = Uint8List((bytes.length + 3) & ~3)..setAll(0, bytes);
    var sum = 0;
    final view = ByteData.sublistView(padded);
    for (var j = 0; j < padded.length; j += 4) {
      sum = (sum + view.getUint32(j)) & 0xffffffff;
    }
    final at = 12 + i * 16;
    for (var c = 0; c < 4; c++) {
      header.setUint8(at + c, tags[i].codeUnitAt(c));
    }
    header
      ..setUint32(at + 4, sum)
      ..setUint32(at + 8, offset)
      ..setUint32(at + 12, bytes.length);
    body.add(padded);
    offset += padded.length;
  }
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(body.takeBytes()))
      .takeBytes();
}
