// The drawings of the insights screen: the web's `charts.tsx` (apps/web/app/features/insights/),
// which Recharts makes there, drawn here with a CustomPainter from the geometry in
// chart_geometry.dart. They draw only: the figures and the words are the cards'.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/lk_theme.dart';
import 'chart_geometry.dart';

/// One slice of the donut: what it stands for, how much, and its colour (the category's tint as a
/// mark).
class DonutSlice {
  const DonutSlice({required this.id, required this.value, required this.fill});

  final String id;
  final int value;
  final Color fill;
}

/// A donut of [size] px: its sectors sweep in clockwise from the top over [duration] (ease-out)
/// when it first shows, and grow from their old angle to the new one when another answer comes;
/// with [animate] false they are there at once (`DonutChart`).
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.size,
    required this.animate,
    required this.duration,
  });

  final List<DonutSlice> slices;
  final double size;
  final bool animate;
  final Duration duration;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late DonutGeometry _geometry = _geometryOf(widget);
  DonutGeometry? _from;

  static DonutGeometry _geometryOf(DonutChart widget) => DonutGeometry(
    widget.size,
    [for (final s in widget.slices) s.value],
    ids: [for (final s in widget.slices) s.id],
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(DonutChart old) {
    super.didUpdateWidget(old);
    final next = _geometryOf(widget);
    final same =
        next.ids!.join(',') == _geometry.ids!.join(',') &&
        next.totals.join(',') == _geometry.totals.join(',') &&
        next.size == _geometry.size;
    if (same) return;
    _from = _geometry;
    _geometry = next;
    if (widget.animate) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fills = [for (final s in widget.slices) s.fill];
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _DonutPainter(
            _geometry.sectorsAt(Curves.easeOut.transform(_controller.value), from: _from),
            fills,
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.sectors, this.fills);

  final List<PieSector> sectors;
  final List<Color> fills;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < sectors.length; i++) {
      final path = sectors[i].path();
      if (path.isEmpty) continue;
      canvas.drawPath(path.toPath(), Paint()..color = fills[i]);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

/// What the trend's drawing is coloured with.
class TrendColors {
  const TrendColors({
    required this.grid,
    required this.income,
    required this.expense,
    required this.muted,
  });

  factory TrendColors.of(BuildContext context) {
    final colors = context.lkColors;
    return TrendColors(
      grid: colors.stroke,
      income: colors.chartIncome,
      expense: colors.chartExpense,
      muted: colors.inkMuted,
    );
  }

  /// The grid's lines (`--stroke`).
  final Color grid;

  /// The income bars (`--chart-income`) and the spending bars (`--chart-expense`).
  final Color income;
  final Color expense;

  /// The axis' names, the budget line and its dots (`--ink-muted`).
  final Color muted;
}

/// An axis name: app.css `.lk-trend .recharts-cartesian-axis-tick-value`, Nunito 11px 800.
const trendTickStyle = TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800);

/// How wide Recharts thinks a month's name is: it measures in a hidden span under the page's
/// `body` (Nunito 11px at the body's 700), not as drawn (800).
double measureTickName(String text) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: trendTickStyle.copyWith(fontWeight: FontWeight.w700),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// Income and expense bars per month that rise from the axis, the budget as a dashed straight line
/// with a dot per month that has one (months without a budget leave a gap), and a y-axis in
/// compact amounts ([formatTick]); `TrendBars`. Selecting a month is the trend card's (its tap
/// targets lie over this). The bars rise over [duration] (the spending ones 80ms later) and the
/// line is drawn from the left from half-way through; another answer moves them from where they
/// were; with [animate] false they are there at once.
class TrendBars extends StatefulWidget {
  const TrendBars({
    super.key,
    required this.points,
    required this.height,
    required this.animate,
    required this.duration,
    required this.formatTick,
  });

  final List<TrendPoint> points;
  final double height;
  final bool animate;
  final Duration duration;
  final String Function(int cents) formatTick;

  @override
  State<TrendBars> createState() => _TrendBarsState();
}

class _TrendBarsState extends State<TrendBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  TrendLayout? _layout;
  TrendLayout? _from;
  double _width = 0;

  static const _spendingBegin = Duration(milliseconds: 80);

  /// The whole animation: the line begins half-way through the bars' and lasts as long.
  Duration get _total => widget.duration + widget.duration ~/ 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _total);
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(TrendBars old) {
    super.didUpdateWidget(old);
    if (_samePoints(old.points, widget.points)) return;
    _from = _layout;
    if (widget.animate) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  static bool _samePoints(List<TrendPoint> a, List<TrendPoint> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].month != b[i].month ||
          a[i].income != b[i].income ||
          a[i].expenses != b[i].expenses ||
          a[i].budget != b[i].budget ||
          a[i].label != b[i].label) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The progress of an animation that begins [begin] into the whole, over the bars' duration.
  double _progress(Duration begin) {
    final elapsed = _controller.value * _total.inMicroseconds - begin.inMicroseconds;
    return Curves.easeOut.transform((elapsed / widget.duration.inMicroseconds).clamp(0, 1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = TrendColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (_layout == null || _width != width || _layoutPoints != widget.points) {
          _width = width;
          _layoutPoints = widget.points;
          _layout = trendLayout(
            points: widget.points,
            width: width,
            height: widget.height,
            formatTick: widget.formatTick,
            measure: measureTickName,
          );
        }
        final layout = _layout!;
        final from = _from;
        return SizedBox(
          width: width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _TrendPainter(
                layout: layout,
                from: from,
                colors: colors,
                income: _progress(Duration.zero),
                spending: _progress(_spendingBegin),
                line: _progress(widget.duration ~/ 2),
              ),
            ),
          ),
        );
      },
    );
  }

  List<TrendPoint>? _layoutPoints;
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.layout,
    required this.from,
    required this.colors,
    required this.income,
    required this.spending,
    required this.line,
  });

  final TrendLayout layout;

  /// The layout of the answer before, which the bars move from.
  final TrendLayout? from;
  final TrendColors colors;

  /// How far along the income bars, the spending bars and the budget line are, 0 to 1.
  final double income;
  final double spending;
  final double line;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = colors.grid
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final y in layout.gridY) {
      canvas.drawLine(Offset(layout.plotLeft, y), Offset(layout.plotRight, y), grid);
    }

    _bars(canvas, layout.income, from?.income, colors.income, income);
    _bars(canvas, layout.expenses, from?.expenses, colors.expense, spending);
    _budget(canvas);

    for (final tick in layout.yTicks) {
      // `text-anchor: end` and `dy: 0.355em` (the name centred on its line).
      _text(canvas, tick.text, tick.x, tick.y + 0.355 * 11, _Anchor.end);
    }
    for (final tick in layout.xTicks) {
      // `text-anchor: middle` and `dy: 0.71em` (the name hanging from its line).
      _text(canvas, tick.text, tick.x, tick.y + 0.71 * 11, _Anchor.middle);
    }
  }

  void _bars(Canvas canvas, List<TrendBar?> bars, List<TrendBar?>? before, Color color, double t) {
    final paint = Paint()..color = color;
    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      if (bar == null) continue;
      final old = before != null && before.length == bars.length ? before[i] : null;
      final path = (old == null ? bar.pathAt(t) : bar.pathFrom(old, t)).toPath();
      canvas.drawPath(path, paint);
    }
  }

  void _budget(Canvas canvas) {
    final dots = [for (final dot in layout.budget) ?dot];
    if (dots.isEmpty) return;
    // The line is drawn from the left, over the dots' span; each dot is there once it is reached.
    final reach = dots.first.dx + (dots.last.dx - dots.first.dx) * line;
    canvas.save();
    if (line < 1) {
      canvas.clipRect(Rect.fromLTRB(0, 0, reach, layout.height));
    }
    final stroke = Paint()
      ..color = colors.muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    var run = <Offset>[];
    void flush() {
      if (run.length > 1) {
        final path = Path()..moveTo(run.first.dx, run.first.dy);
        for (final p in run.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(_dashed(path, const [5, 4]), stroke);
      }
      run = [];
    }

    for (final dot in layout.budget) {
      if (dot == null) {
        flush();
      } else {
        run.add(dot);
      }
    }
    flush();
    final fill = Paint()..color = colors.muted;
    for (final dot in dots) {
      if (line >= 1 || dot.dx <= reach + 0.01) canvas.drawCircle(dot, 3, fill);
    }
    canvas.restore();
  }

  /// [path] as dashes: [pattern] is the length of a dash and of the gap after it (`5 4`), the
  /// pattern starting again at the start of every run.
  static Path _dashed(Path path, List<double> pattern) {
    final result = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var index = 0;
      while (distance < metric.length) {
        final length = pattern[index % pattern.length];
        if (index.isEven) {
          result.addPath(
            metric.extractPath(distance, math.min(distance + length, metric.length)),
            Offset.zero,
          );
        }
        distance += length;
        index++;
      }
    }
    return result;
  }

  void _text(Canvas canvas, String text, double x, double baseline, _Anchor anchor) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: trendTickStyle.copyWith(color: colors.muted),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final ascent = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final left = switch (anchor) {
      _Anchor.end => x - painter.width,
      _Anchor.middle => x - painter.width / 2,
    };
    painter.paint(canvas, Offset(left, baseline - ascent));
    painter.dispose();
  }

  @override
  bool shouldRepaint(_TrendPainter old) => true;
}

enum _Anchor { end, middle }
