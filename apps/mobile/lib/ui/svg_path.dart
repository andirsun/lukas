// The path data of an SVG `d` attribute, for the few icons the web draws as inline SVG (the
// fingerprint, the moon and the sun) and the app has no SVG package for.
import 'dart:ui' as ui;

/// Reads SVG path data into a Flutter [ui.Path]: `M L H V C S Q T A Z`, absolute and relative.
///
/// Numbers may be written as SVG allows (`-.9`, `1.2.3` is 1.2 then .3, a sign starts a new
/// number). An arc's two flags are read as the single characters `0` and `1` they are, so they may
/// be glued to the numbers around them.
ui.Path parseSvgPath(String data) {
  final reader = _Reader(data);
  final path = ui.Path();
  var x = 0.0, y = 0.0; // The current point.
  var startX = 0.0, startY = 0.0; // Where the subpath started, for Z.
  var lastCx = 0.0, lastCy = 0.0; // The last control point, for S and T.
  var lastCurve = '';
  var command = '';

  while (true) {
    reader.skipSeparators();
    if (reader.done) break;
    if (reader.atCommand) command = reader.command();
    if (command.isEmpty) throw FormatException('Path data must start with a command', data);
    final relative = command == command.toLowerCase();
    final dx = relative ? x : 0.0, dy = relative ? y : 0.0;
    switch (command.toUpperCase()) {
      case 'M':
        x = reader.number() + dx;
        y = reader.number() + dy;
        path.moveTo(x, y);
        startX = x;
        startY = y;
        // Further pairs after a move are lines.
        command = relative ? 'l' : 'L';
        lastCurve = '';
      case 'L':
        x = reader.number() + dx;
        y = reader.number() + dy;
        path.lineTo(x, y);
        lastCurve = '';
      case 'H':
        x = reader.number() + dx;
        path.lineTo(x, y);
        lastCurve = '';
      case 'V':
        y = reader.number() + dy;
        path.lineTo(x, y);
        lastCurve = '';
      case 'C':
        final x1 = reader.number() + dx, y1 = reader.number() + dy;
        final x2 = reader.number() + dx, y2 = reader.number() + dy;
        final ex = reader.number() + dx, ey = reader.number() + dy;
        path.cubicTo(x1, y1, x2, y2, ex, ey);
        lastCx = x2;
        lastCy = y2;
        x = ex;
        y = ey;
        lastCurve = 'C';
      case 'S':
        final x1 = lastCurve == 'C' ? 2 * x - lastCx : x;
        final y1 = lastCurve == 'C' ? 2 * y - lastCy : y;
        final x2 = reader.number() + dx, y2 = reader.number() + dy;
        final ex = reader.number() + dx, ey = reader.number() + dy;
        path.cubicTo(x1, y1, x2, y2, ex, ey);
        lastCx = x2;
        lastCy = y2;
        x = ex;
        y = ey;
        lastCurve = 'C';
      case 'Q':
        final x1 = reader.number() + dx, y1 = reader.number() + dy;
        final ex = reader.number() + dx, ey = reader.number() + dy;
        path.quadraticBezierTo(x1, y1, ex, ey);
        lastCx = x1;
        lastCy = y1;
        x = ex;
        y = ey;
        lastCurve = 'Q';
      case 'T':
        final x1 = lastCurve == 'Q' ? 2 * x - lastCx : x;
        final y1 = lastCurve == 'Q' ? 2 * y - lastCy : y;
        final ex = reader.number() + dx, ey = reader.number() + dy;
        path.quadraticBezierTo(x1, y1, ex, ey);
        lastCx = x1;
        lastCy = y1;
        x = ex;
        y = ey;
        lastCurve = 'Q';
      case 'A':
        final rx = reader.number(), ry = reader.number();
        final rotation = reader.number();
        final large = reader.flag(), sweep = reader.flag();
        final ex = reader.number() + dx, ey = reader.number() + dy;
        if (rx == 0 || ry == 0) {
          path.lineTo(ex, ey);
        } else {
          path.arcToPoint(
            ui.Offset(ex, ey),
            radius: ui.Radius.elliptical(rx.abs(), ry.abs()),
            rotation: rotation,
            largeArc: large,
            clockwise: sweep,
          );
        }
        x = ex;
        y = ey;
        lastCurve = '';
      case 'Z':
        path.close();
        x = startX;
        y = startY;
        lastCurve = '';
      default:
        throw FormatException('Unknown path command "$command"', data);
    }
  }
  return path;
}

class _Reader {
  _Reader(this.data);

  final String data;
  var _at = 0;

  static final _number = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
  static const _commands = 'MmLlHhVvCcSsQqTtAaZz';

  bool get done => _at >= data.length;

  bool get atCommand => _commands.contains(data[_at]);

  void skipSeparators() {
    while (_at < data.length && (data[_at] == ' ' || data[_at] == ',' || data[_at] == '\n')) {
      _at++;
    }
  }

  String command() => data[_at++];

  double number() {
    skipSeparators();
    final match = _number.matchAsPrefix(data, _at);
    if (match == null) throw FormatException('A number was expected', data, _at);
    _at = match.end;
    return double.parse(match[0]!);
  }

  bool flag() {
    skipSeparators();
    final c = _at < data.length ? data[_at] : '';
    if (c != '0' && c != '1') throw FormatException('An arc flag was expected', data, _at);
    _at++;
    return c == '1';
  }
}
