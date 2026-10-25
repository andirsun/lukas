// The geometry of the insights charts: a port of what the web's chart library (Recharts 3.10)
// computes for them, so the same data gives the same arcs, bars, points and axis names. The web
// draws the donut and the trend with Recharts (apps/web/app/features/insights/charts.tsx); the app
// draws them with a CustomPainter from the numbers here, and uses no chart library.
//
// `chart_geometry.dart` of the web (apps/web/app/features/insights/chart-geometry.ts) is the first
// block: where the trend's plot sits inside its chart. The rest is Recharts':
// - `niceTicks`: `getNiceTickValues` (util/scale/getNiceTickValues.js);
// - [DonutGeometry]: `computePieSectors` and the `Sector` shape (polar/Pie.js, shape/Sector.js);
// - [trendLayout]: the bars (state/selectors/combiners/combineAllBarPositions.js, shape/Rectangle.js),
//   the axes' ticks (cartesian/getTicks.js) and the line.
// test/insights/chart_geometry_test.dart checks them against what the web draws.
import 'dart:math' as math;
import 'dart:ui' as ui;

// -- where the trend's plot sits (chart-geometry.ts) -----------------------------------------------

/// The y-axis' width, in px: the plot starts after it (`Y_AXIS_WIDTH`).
const yAxisWidth = 44.0;

/// The plot's margins inside the chart, in px (`TREND_MARGIN`).
const trendMargin = (top: 8.0, right: 4.0, bottom: 0.0, left: 0.0);

/// The x-axis' height, in px, under the plot (`X_AXIS_HEIGHT`).
const xAxisHeight = 24.0;

// -- paths -----------------------------------------------------------------------------------------

/// An SVG path, as Recharts writes it: it prints as the `d` attribute does (numbers rounded to
/// four decimals) and draws as a Flutter [ui.Path].
class SvgPath {
  final _commands = <_Command>[];

  bool get isEmpty => _commands.isEmpty;

  void moveTo(double x, double y) => _commands.add(_Command('M', [x, y]));

  void lineTo(double x, double y) => _commands.add(_Command('L', [x, y]));

  /// `A rx,ry,0,large,sweep,x,y`.
  void arcTo(double rx, double ry, bool large, bool sweep, double x, double y) =>
      _commands.add(_Command('A', [rx, ry, 0, large ? 1 : 0, sweep ? 1 : 0, x, y]));

  void close() => _commands.add(const _Command('Z', []));

  /// The path as a Flutter path, each arc drawn as the SVG arc it is (a sweep of 1 is clockwise).
  ui.Path toPath() {
    final path = ui.Path();
    for (final c in _commands) {
      final v = c.values;
      switch (c.letter) {
        case 'M':
          path.moveTo(v[0], v[1]);
        case 'L':
          path.lineTo(v[0], v[1]);
        case 'A':
          path.arcToPoint(
            ui.Offset(v[5], v[6]),
            radius: ui.Radius.elliptical(v[0], v[1]),
            largeArc: v[3] == 1,
            clockwise: v[4] == 1,
          );
        case 'Z':
          path.close();
      }
    }
    return path;
  }

  @override
  String toString() => _commands.join();
}

class _Command {
  const _Command(this.letter, this.values);

  final String letter;
  final List<double> values;

  @override
  String toString() => '$letter${values.map(_round).join(',')}';
}

/// A number as Recharts' `round` writes it into a path: four decimals, no trailing zeros.
String _round(double value) {
  final text = value.toStringAsFixed(4);
  final trimmed = text.contains('.') ? text.replaceFirst(RegExp(r'\.?0+$'), '') : text;
  return trimmed == '-0' ? '0' : trimmed;
}

// -- nice ticks ------------------------------------------------------------------------------------

/// The ticks Recharts' y-axis rounds to for data from 0 to [max] (`getNiceTickValues([0, max], 4,
/// false)` with the axis' domain `[0, 'auto']`): [count] whole numbers from 0 in equal steps, the
/// last at or above [max]. The axis ends at the last one.
List<int> niceTicks(int max, {int count = 4}) {
  if (max <= 0) return [for (var i = 0; i < count; i++) i];
  var correction = 0;
  while (true) {
    final step = _adaptiveStep(max / (count - 1), correction);
    final up = _ceil(max / step);
    // `belowCount` is 0: the interval starts at 0.
    final scale = up + 1;
    if (scale > count) {
      correction += 1;
      continue;
    }
    final ups = scale < count ? up + (count - scale) : up;
    return [for (var i = 0; i <= ups; i++) (i * step).round()];
  }
}

/// `Math.ceil` as Recharts' decimal arithmetic gets it: a value that is a whole number up to
/// floating point noise stays there.
int _ceil(double value) => (value - 1e-9).ceil();

/// `getAdaptiveStep(roughStep, false, correction)`: the next step of 1, 1.5, ... in tenths (and
/// of 0.05 above one digit) of the rough step's magnitude, rounded up to a whole number.
int _adaptiveStep(double rough, int correction) {
  if (rough <= 0) return 0;
  final digits = (math.log(rough) / math.ln10 + 1e-12).floor() + 1;
  final magnitude = math.pow(10, digits).toDouble();
  final ratio = rough / magnitude;
  final scale = digits != 1 ? 0.05 : 0.1;
  final amended = (_ceil(ratio / scale) + correction) * scale;
  return _ceil(amended * magnitude);
}

// -- the donut -------------------------------------------------------------------------------------

const _radian = math.pi / 180;

ui.Offset _polar(double cx, double cy, double radius, double angle) =>
    ui.Offset(cx + math.cos(-_radian * angle) * radius, cy + math.sin(-_radian * angle) * radius);

/// One sector of the donut, between two angles (in degrees, positive counterclockwise from the
/// right, as Recharts has them: the donut starts at 90, the top, and goes clockwise to -270).
class PieSector {
  const PieSector({
    required this.cx,
    required this.cy,
    required this.innerRadius,
    required this.outerRadius,
    required this.cornerRadius,
    required this.startAngle,
    required this.endAngle,
  });

  final double cx;
  final double cy;
  final double innerRadius;
  final double outerRadius;
  final double cornerRadius;
  final double startAngle;
  final double endAngle;

  /// How many degrees it spans.
  double get sweep => (endAngle - startAngle).abs();

  /// Recharts' `Sector`: with rounded corners when it has some and is not a whole ring, and a
  /// plain ring segment when it is too narrow for them; nothing for an empty one.
  SvgPath path() {
    if (outerRadius < innerRadius || startAngle == endAngle) return SvgPath();
    final cr = math.min(cornerRadius, (outerRadius - innerRadius) / 2);
    if (cr > 0 && sweep < 360) return _withCorner(cr);
    return _plain();
  }

  /// `getSectorPath`.
  SvgPath _plain() {
    final sign = (endAngle - startAngle).sign;
    final angle = sign * math.min(sweep, 359.999);
    final end = startAngle + angle;
    final outerStart = _polar(cx, cy, outerRadius, startAngle);
    final outerEnd = _polar(cx, cy, outerRadius, end);
    final path = SvgPath()
      ..moveTo(outerStart.dx, outerStart.dy)
      ..arcTo(
        outerRadius,
        outerRadius,
        angle.abs() > 180,
        startAngle > end,
        outerEnd.dx,
        outerEnd.dy,
      );
    if (innerRadius > 0) {
      final innerStart = _polar(cx, cy, innerRadius, startAngle);
      final innerEnd = _polar(cx, cy, innerRadius, end);
      path
        ..lineTo(innerEnd.dx, innerEnd.dy)
        ..arcTo(
          innerRadius,
          innerRadius,
          angle.abs() > 180,
          startAngle <= end,
          innerStart.dx,
          innerStart.dy,
        )
        ..close();
    } else {
      path
        ..lineTo(cx, cy)
        ..close();
    }
    return path;
  }

  /// `getTangentCircle` (the corner is inside the sector, `cornerIsExternal` false).
  ({ui.Offset circle, ui.Offset line, double theta}) _tangent(
    double radius,
    double angle,
    double sign,
    double cr, {
    required bool external,
  }) {
    final centerRadius = cr * (external ? 1 : -1) + radius;
    final theta = math.asin(cr / centerRadius) / _radian;
    final centerAngle = angle + sign * theta;
    return (
      circle: _polar(cx, cy, radius, centerAngle),
      line: _polar(cx, cy, centerRadius * math.cos(theta * _radian), angle),
      theta: theta,
    );
  }

  /// `getSectorWithCorner`.
  SvgPath _withCorner(double cr) {
    final sign = (endAngle - startAngle).sign;
    final start = _tangent(outerRadius, startAngle, sign, cr, external: false);
    final end = _tangent(outerRadius, endAngle, -sign, cr, external: false);
    final outerArc = (startAngle - endAngle).abs() - start.theta - end.theta;
    if (outerArc < 0) return _plain();
    final cw = sign < 0;
    final path = SvgPath()
      ..moveTo(start.line.dx, start.line.dy)
      ..arcTo(cr, cr, false, cw, start.circle.dx, start.circle.dy)
      ..arcTo(outerRadius, outerRadius, outerArc > 180, cw, end.circle.dx, end.circle.dy)
      ..arcTo(cr, cr, false, cw, end.line.dx, end.line.dy);
    if (innerRadius > 0) {
      final innerStart = _tangent(innerRadius, startAngle, sign, cr, external: true);
      final innerEnd = _tangent(innerRadius, endAngle, -sign, cr, external: true);
      final innerArc = (startAngle - endAngle).abs() - innerStart.theta - innerEnd.theta;
      if (innerArc < 0 && cr == 0) {
        return path
          ..lineTo(cx, cy)
          ..close();
      }
      path
        ..lineTo(innerEnd.line.dx, innerEnd.line.dy)
        ..arcTo(cr, cr, false, cw, innerEnd.circle.dx, innerEnd.circle.dy)
        ..arcTo(
          innerRadius,
          innerRadius,
          innerArc > 180,
          sign > 0,
          innerStart.circle.dx,
          innerStart.circle.dy,
        )
        ..arcTo(cr, cr, false, cw, innerStart.line.dx, innerStart.line.dy)
        ..close();
    } else {
      path
        ..lineTo(cx, cy)
        ..close();
    }
    return path;
  }
}

/// The donut of `charts.tsx`'s `DonutChart` ([size] px square): a ring from 33 % of the size to
/// 4px short of its edge, its sectors from the top clockwise, 2 degrees apart and with corners
/// rounded to 5px (neither when there is only one).
class DonutGeometry {
  DonutGeometry(this.size, this.totals, {this.ids}) {
    final single = totals.length <= 1;
    paddingAngle = single ? 0 : 2;
    cornerRadius = single ? 0 : 5;
    innerRadius = (size * 0.33).roundToDouble();
    outerRadius = (size / 2).roundToDouble() - 4;
    // `computePieSectors`: from 90 to -270 (a whole turn, so every sector is followed by a
    // padding, the last one too), in proportion to the totals.
    const startAngle = 90.0;
    const direction = -1.0;
    final nonZero = totals.where((t) => t != 0).length;
    final real = 360 - nonZero * paddingAngle;
    final sum = totals.fold<int>(0, (a, t) => a + t);
    var end = startAngle;
    for (var i = 0; i < totals.length; i++) {
      final from = i == 0 ? startAngle : end + direction * paddingAngle * (totals[i] != 0 ? 1 : 0);
      end = from + direction * (sum > 0 ? totals[i] / sum * real : 0);
      sectors.add(_sector(from, end));
    }
  }

  /// The donut's width and height.
  final double size;

  /// What each sector stands for, in the order they go round.
  final List<int> totals;

  /// What names each sector (a category's id), to match the sectors of one answer with the next's.
  final List<String>? ids;

  late final double paddingAngle;
  late final double cornerRadius;
  late final double innerRadius;
  late final double outerRadius;

  /// The sectors at rest.
  final sectors = <PieSector>[];

  PieSector _sector(double start, double end) => PieSector(
    cx: size / 2,
    cy: size / 2,
    innerRadius: innerRadius,
    outerRadius: outerRadius,
    cornerRadius: cornerRadius,
    startAngle: start,
    endAngle: end,
  );

  /// The sectors [t] of the way through the entrance animation (`defaultPieAnimateItems`): each
  /// grows from nothing to its angle, all at once, the first from the top. With [from] (the donut
  /// of the answer before) a sector it had grows from its old angle instead, matched by [ids].
  List<PieSector> sectorsAt(double t, {DonutGeometry? from}) {
    final previous = <String, double>{};
    final old = from;
    if (old != null && old.ids != null && ids != null) {
      for (var i = 0; i < old.ids!.length; i++) {
        previous[old.ids![i]] = old.sectors[i].sweep;
      }
    }
    final result = <PieSector>[];
    var current = 90.0;
    for (var i = 0; i < sectors.length; i++) {
      final padding = i > 0 ? -paddingAngle : 0.0;
      final sweep = sectors[i].sweep;
      final before = previous[ids?[i]] ?? 0.0;
      final angle = before + (sweep - before) * t;
      final start = current + padding;
      current = start - angle;
      result.add(_sector(start, current));
    }
    return result;
  }
}

// -- the trend -------------------------------------------------------------------------------------

/// One month of the trend: its totals, and its budget (null when it had none: the line leaves a
/// gap there).
class TrendPoint {
  const TrendPoint({
    required this.month,
    required this.label,
    required this.income,
    required this.expenses,
    required this.budget,
  });

  final String month;

  /// The month's short name for the axis (`oct`).
  final String label;
  final int income;
  final int expenses;
  final int? budget;
}

/// A bar standing on the axis: the rectangle at rest, with its top corners rounded to 6px.
class TrendBar {
  const TrendBar({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.base,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  /// Where the axis is: the bar rises from it.
  final double base;

  /// The corner radius of the top corners (`radius={[6, 6, 0, 0]}`).
  static const radius = 6.0;

  /// The bar's height [t] of the way through its entrance (`defaultBarAnimateItems`).
  double heightAt(double t) => height * t;

  /// Where its top is then.
  double topAt(double t) => base + (y - base) * t;

  /// Recharts' `getRectanglePath` with `[6, 6, 0, 0]`.
  SvgPath pathAt(double t) => rectanglePath(x, topAt(t), width, heightAt(t));

  /// The bar [t] of the way from [old] (the bar of the answer before, at rest) to this one
  /// (`defaultBarAnimateItems` for a bar that is still there).
  SvgPath pathFrom(TrendBar old, double t) => rectanglePath(
    old.x + (x - old.x) * t,
    old.y + (y - old.y) * t,
    old.width + (width - old.width) * t,
    old.height + (height - old.height) * t,
  );

  SvgPath path() => pathAt(1);
}

/// `getRectanglePath(x, y, width, height, [6, 6, 0, 0])`: a bar with its top corners rounded, as
/// far as the bar is wide and tall enough for.
SvgPath rectanglePath(double x, double y, double width, double height) {
  final maxRadius = math.min(width.abs() / 2, height.abs() / 2);
  final path = SvgPath();
  if (maxRadius <= 0) {
    return path
      ..moveTo(x, y)
      ..lineTo(x + width, y)
      ..lineTo(x + width, y + height)
      ..lineTo(x, y + height)
      ..close();
  }
  final r = math.min(TrendBar.radius, maxRadius);
  return path
    ..moveTo(x, y + r)
    ..arcTo(r, r, false, true, x + r, y)
    ..lineTo(x + width - r, y)
    ..arcTo(r, r, false, true, x + width, y + r)
    ..lineTo(x + width, y + height)
    ..lineTo(x, y + height)
    ..close();
}

/// An axis name and where it is drawn: [x] and [y] are the text's anchor (the right end of a
/// y-axis name, the middle of an x-axis one).
class TrendTick {
  const TrendTick(this.text, this.x, this.y);

  final String text;
  final double x;
  final double y;
}

/// What the trend draws, in the chart's own pixels (`charts.tsx`'s `TrendBars`).
class TrendLayout {
  TrendLayout._({
    required this.width,
    required this.height,
    required this.plotLeft,
    required this.plotRight,
    required this.plotTop,
    required this.plotBottom,
    required this.domainMax,
    required this.gridY,
    required this.yTicks,
    required this.xTicks,
    required this.income,
    required this.expenses,
    required this.budget,
    required this.bandWidth,
  });

  final double width;
  final double height;
  final double plotLeft;
  final double plotRight;
  final double plotTop;
  final double plotBottom;

  /// The top of the y-axis: its last tick.
  final int domainMax;

  /// The grid's horizontal lines, one at each y-axis tick, from the bottom up.
  final List<double> gridY;
  final List<TrendTick> yTicks;

  /// The month names that fit under the bars.
  final List<TrendTick> xTicks;

  /// A bar per month, null where it would have no height.
  final List<TrendBar?> income;
  final List<TrendBar?> expenses;

  /// The budget line's dot of each month, null where there was no budget.
  final List<ui.Offset?> budget;

  /// The width of one month's band of the plot.
  final double bandWidth;

  /// Where a value sits on the y-axis.
  double yOf(num value) => plotBottom - value / domainMax * (plotBottom - plotTop);

  /// The budget line: a run of points for each stretch of months with a budget. A month alone
  /// between gaps has a dot and no line (Recharts draws none for a single point).
  SvgPath budgetPath() {
    final path = SvgPath();
    var run = <ui.Offset>[];
    void flush() {
      if (run.length > 1) {
        path.moveTo(run.first.dx, run.first.dy);
        for (final p in run.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
      }
      run = [];
    }

    for (final dot in budget) {
      if (dot == null) {
        flush();
      } else {
        run.add(dot);
      }
    }
    flush();
    return path;
  }
}

/// The drawing of [points] in a chart of [width] × [height] px: the plot under the 8px margin
/// above and after the y-axis, with the x-axis under it.
///
/// - The y-axis goes from 0 to the last of four [niceTicks] of the largest total (budget
///   included), named by [formatTick].
/// - Each month has a band of the plot's width over the number of months: two bars of at most
///   18px 3px apart, centred in it with 22 % of the band either side; the budget's dot is at its
///   middle.
/// - The x-axis names every month's [TrendPoint.label], leaving out those that would be closer
///   than 4px to the one before (`interval="preserveStartEnd"`), as wide as [measure] says. Recharts
///   measures them in a hidden span under the page's `body` (Nunito 700), not as they are drawn
///   (800).
TrendLayout trendLayout({
  required List<TrendPoint> points,
  required double width,
  required double height,
  required String Function(int cents) formatTick,
  required double Function(String text) measure,
}) {
  final plotLeft = yAxisWidth + trendMargin.left;
  final plotRight = width - trendMargin.right;
  final plotTop = trendMargin.top;
  final plotBottom = height - xAxisHeight - trendMargin.bottom;
  var max = 0;
  for (final p in points) {
    max = math.max(max, math.max(p.income, math.max(p.expenses, p.budget ?? 0)));
  }
  final ticks = niceTicks(max);
  final domainMax = ticks.last;
  double yOf(num v) => plotBottom - v / domainMax * (plotBottom - plotTop);

  // The bars (`getBarPositions`, the branch without a set bar size).
  final band = (plotRight - plotLeft) / points.length;
  const gap = 3.0;
  const count = 2;
  final categoryGap = 0.22 * band;
  final realGap = band - 2 * categoryGap - (count - 1) * gap <= 0 ? 0.0 : gap;
  var original = (band - 2 * categoryGap - (count - 1) * realGap) / count;
  if (original > 1) original = original.roundToDouble();
  final size = math.min(original, 18.0);
  double offset(int series) =>
      categoryGap + count * (original - size) / 2 + (size + realGap) * series;

  TrendBar? bar(int month, int series, int value) {
    final h = value / domainMax * (plotBottom - plotTop);
    if (h <= 0) return null;
    return TrendBar(
      x: plotLeft + band * month + offset(series),
      y: plotBottom - h,
      width: size,
      height: h,
      base: plotBottom,
    );
  }

  double center(int month) => plotLeft + band * (month + 0.5);

  // The y-axis' names, to the left of the plot, which Recharts nudges down by a quarter of a px
  // at the top (found by reading the web's picture).
  final yTicks = [
    for (var i = 0; i < ticks.length; i++)
      TrendTick(
        formatTick(ticks[i]),
        plotLeft - 8,
        yOf(ticks[i]) + (i == ticks.length - 1 && ticks.length > 1 ? 0.25 : 0),
      ),
  ];

  return TrendLayout._(
    width: width,
    height: height,
    plotLeft: plotLeft,
    plotRight: plotRight,
    plotTop: plotTop,
    plotBottom: plotBottom,
    domainMax: domainMax,
    gridY: [for (final t in ticks) yOf(t)],
    yTicks: yTicks,
    xTicks: _xTicks(points, center, plotLeft, plotRight, plotBottom, measure),
    income: [for (var i = 0; i < points.length; i++) bar(i, 0, points[i].income)],
    expenses: [for (var i = 0; i < points.length; i++) bar(i, 1, points[i].expenses)],
    budget: [
      for (var i = 0; i < points.length; i++)
        points[i].budget == null ? null : ui.Offset(center(i), yOf(points[i].budget!)),
    ],
    bandWidth: band,
  );
}

/// The month names under the bars: `getTicks` with `interval="preserveStartEnd"` and a minimum
/// gap of 4px. The last name is kept (moved in if it would stick out), then each from the first
/// is kept when it fits between the one kept before and the last.
List<TrendTick> _xTicks(
  List<TrendPoint> points,
  double Function(int month) center,
  double left,
  double right,
  double plotBottom,
  double Function(String text) measure,
) {
  const minGap = 4.0;
  final n = points.length;
  if (n == 0) return const [];
  final y = plotBottom + 6 + 2;
  final shown = <int, double>{};
  var start = left;
  var end = right;
  bool visible(double at, double size) =>
      at >= start && at <= end && at - size / 2 - start >= 0 && at + size / 2 - end <= 0;

  // The last one first, so it is always there if it can be.
  final tailSize = measure(points[n - 1].label);
  final tailGap = center(n - 1) + tailSize / 2 - end;
  final tail = tailGap > 0 ? center(n - 1) - tailGap : center(n - 1);
  if (visible(tail, tailSize)) {
    end = tail - (tailSize / 2 + minGap);
    shown[n - 1] = tail;
  }
  for (var i = 0; i < n - 1; i++) {
    final size = measure(points[i].label);
    var at = center(i);
    if (i == 0) {
      final gap = at - size / 2 - start;
      at = gap < 0 ? at - gap : at;
    }
    if (visible(at, size)) {
      start = at + size / 2 + minGap;
      shown[i] = at;
    }
  }
  return [for (final i in shown.keys.toList()..sort()) TrendTick(points[i].label, shown[i]!, y)];
}
