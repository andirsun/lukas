import 'dart:io';
import 'dart:typed_data';

/// Just enough PNG for the parity pictures, with no package: reads 8-bit, non-interlaced
/// greyscale, RGB, RGBA and palette images (what Chrome's screenshots and Flutter's goldens are)
/// and writes 8-bit RGBA. https://www.w3.org/TR/png/
class Rgba {
  Rgba(this.width, this.height) : pixels = Uint8List(width * height * 4);

  Rgba.filled(this.width, this.height, int r, int g, int b)
    : pixels = Uint8List(width * height * 4) {
    for (var i = 0; i < pixels.length; i += 4) {
      pixels
        ..[i] = r
        ..[i + 1] = g
        ..[i + 2] = b
        ..[i + 3] = 255;
    }
  }

  final int width;
  final int height;

  /// Row after row, 4 bytes (r, g, b, a) per pixel.
  final Uint8List pixels;

  int offset(int x, int y) => (y * width + x) * 4;

  /// Copies [other] in with its top-left corner at ([left], [top]).
  void draw(Rgba other, int left, int top) {
    for (var y = 0; y < other.height; y++) {
      final ty = top + y;
      if (ty < 0 || ty >= height) continue;
      for (var x = 0; x < other.width; x++) {
        final tx = left + x;
        if (tx < 0 || tx >= width) continue;
        final from = other.offset(x, y);
        pixels.setRange(offset(tx, ty), offset(tx, ty) + 4, other.pixels, from);
      }
    }
  }
}

const _signature = [137, 80, 78, 71, 13, 10, 26, 10];

Rgba readPng(String path) => decodePng(File(path).readAsBytesSync(), path);

Rgba decodePng(Uint8List bytes, [String name = 'image']) {
  for (var i = 0; i < 8; i++) {
    if (bytes[i] != _signature[i]) throw FormatException('$name is not a PNG');
  }
  final data = ByteData.sublistView(bytes);
  var at = 8;
  late int width, height, depth, colour, interlace;
  Uint8List? palette;
  Uint8List? paletteAlpha;
  final idat = BytesBuilder(copy: false);
  while (at < bytes.length) {
    final length = data.getUint32(at);
    final type = String.fromCharCodes(bytes, at + 4, at + 8);
    final body = Uint8List.sublistView(bytes, at + 8, at + 8 + length);
    switch (type) {
      case 'IHDR':
        final h = ByteData.sublistView(body);
        width = h.getUint32(0);
        height = h.getUint32(4);
        depth = body[8];
        colour = body[9];
        interlace = body[12];
      case 'PLTE':
        palette = body;
      case 'tRNS':
        paletteAlpha = body;
      case 'IDAT':
        idat.add(body);
      case 'IEND':
        at = bytes.length;
        continue;
    }
    at += 12 + length;
  }
  if (depth != 8 || interlace != 0) {
    throw FormatException('$name: only 8-bit, non-interlaced PNGs are read');
  }
  final channels = switch (colour) {
    0 => 1,
    2 => 3,
    3 => 1,
    4 => 2,
    6 => 4,
    _ => throw FormatException('$name: colour type $colour'),
  };
  final raw = Uint8List.fromList(zlib.decode(idat.takeBytes()));
  final stride = width * channels;
  final rows = Uint8List(height * stride);
  for (var y = 0; y < height; y++) {
    final filter = raw[y * (stride + 1)];
    final line = y * (stride + 1) + 1;
    for (var x = 0; x < stride; x++) {
      final a = x >= channels ? rows[y * stride + x - channels] : 0;
      final b = y > 0 ? rows[(y - 1) * stride + x] : 0;
      final c = x >= channels && y > 0 ? rows[(y - 1) * stride + x - channels] : 0;
      final value = raw[line + x];
      rows[y * stride + x] = switch (filter) {
        0 => value,
        1 => value + a,
        2 => value + b,
        3 => value + ((a + b) >> 1),
        4 => value + _paeth(a, b, c),
        _ => throw FormatException('$name: filter $filter'),
      };
    }
  }
  final image = Rgba(width, height);
  final out = image.pixels;
  for (var i = 0; i < width * height; i++) {
    final from = i * channels;
    final to = i * 4;
    switch (colour) {
      case 0:
        out.fillRange(to, to + 3, rows[from]);
        out[to + 3] = 255;
      case 2:
        out.setRange(to, to + 3, rows, from);
        out[to + 3] = 255;
      case 3:
        final index = rows[from];
        out.setRange(to, to + 3, palette!, index * 3);
        out[to + 3] = paletteAlpha != null && index < paletteAlpha.length
            ? paletteAlpha[index]
            : 255;
      case 4:
        out.fillRange(to, to + 3, rows[from]);
        out[to + 3] = rows[from + 1];
      case 6:
        out.setRange(to, to + 4, rows, from);
    }
  }
  return image;
}

int _paeth(int a, int b, int c) {
  final p = a + b - c;
  final pa = (p - a).abs();
  final pb = (p - b).abs();
  final pc = (p - c).abs();
  if (pa <= pb && pa <= pc) return a;
  return pb <= pc ? b : c;
}

void writePng(String path, Rgba image) {
  final raw = BytesBuilder(copy: false);
  final stride = image.width * 4;
  for (var y = 0; y < image.height; y++) {
    raw
      ..addByte(0)
      ..add(Uint8List.sublistView(image.pixels, y * stride, (y + 1) * stride));
  }
  final header = ByteData(13)
    ..setUint32(0, image.width)
    ..setUint32(4, image.height)
    ..setUint8(8, 8)
    ..setUint8(9, 6);
  final out = BytesBuilder(copy: false)
    ..add(_signature)
    ..add(_chunk('IHDR', header.buffer.asUint8List()))
    ..add(_chunk('IDAT', Uint8List.fromList(zlib.encode(raw.takeBytes()))))
    ..add(_chunk('IEND', Uint8List(0)));
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(out.takeBytes());
}

Uint8List _chunk(String type, Uint8List body) {
  final typed = Uint8List.fromList([...type.codeUnits, ...body]);
  final out = ByteData(12 + body.length)..setUint32(0, body.length);
  final bytes = out.buffer.asUint8List()..setRange(4, 8 + body.length, typed);
  out.setUint32(8 + body.length, _crc(typed));
  return bytes;
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 != 0 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  }
  return c;
});

int _crc(Uint8List bytes) {
  var c = 0xffffffff;
  for (final byte in bytes) {
    c = _crcTable[(c ^ byte) & 0xff] ^ (c >>> 8);
  }
  return c ^ 0xffffffff;
}
