import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// One line of text laid out the way Blink adds it up. Blink shapes a line word by word (and every
/// space on its own) and keeps each width in 64ths of a pixel, rounded up, so a line is a few
/// hundredths of a pixel wider than the same text shaped whole, as Flutter does, and every word
/// after the first starts a hair further right. A hundredth of a pixel decides which quarter of a
/// device pixel a glyph is drawn on, so a flowed row of text (name shortcuts, one after another)
/// drifts off the web's picture unless it is laid out the same way.
///
/// [span] is the text and its styles (flat: a text per child); the line never wraps.
class CssText extends StatelessWidget {
  const CssText(this.span, {super.key});

  final TextSpan span;

  /// A word or a run of spaces, with the style it is drawn in.
  static List<(String, TextStyle)> _tokens(TextSpan span) {
    final tokens = <(String, TextStyle)>[];
    void walk(TextSpan node, TextStyle inherited) {
      final style = inherited.merge(node.style);
      final text = node.text;
      if (text != null) {
        for (final match in RegExp(' |[^ ]+').allMatches(text)) {
          tokens.add((match[0]!, style));
        }
      }
      for (final child in node.children ?? const <InlineSpan>[]) {
        if (child is TextSpan) walk(child, style);
      }
    }

    walk(span, const TextStyle());
    return tokens;
  }

  static double _ceil64(double value) => (value * 64).ceil() / 64;

  static double _measure(
    BuildContext context,
    String token,
    TextStyle style,
    TextScaler scaler,
    TextDirection dir,
  ) {
    // As `Text` merges it: the surrounding style (and its fallback fonts) under [style].
    final painter = TextPainter(
      text: TextSpan(text: token, style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: dir,
      textScaler: scaler,
    )..layout();
    // A trailing space has no width in the line's metrics: its own box says how wide it is.
    final width = token == ' '
        ? painter
              .getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 1))
              .first
              .right
        : painter.computeLineMetrics().first.width;
    painter.dispose();
    return _ceil64(width);
  }

  /// How wide [span] is as a line.
  static double widthOf(BuildContext context, TextSpan span) {
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    return [
      for (final (token, style) in _tokens(span)) _measure(context, token, style, scaler, dir),
    ].fold(0.0, (a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (token, style) in _tokens(span))
          SizedBox(
            width: _measure(context, token, style, scaler, dir),
            child: UnconstrainedBox(
              alignment: Alignment.centerLeft,
              constrainedAxis: Axis.vertical,
              clipBehavior: Clip.none,
              child: Text(token, style: style, maxLines: 1, softWrap: false),
            ),
          ),
      ],
    );
  }
}

/// A paragraph broken into lines the way Blink does it: a line takes words while their widths, each
/// kept in 64ths of a pixel and rounded up as [CssText] has them, still fit. Flutter breaks where
/// the whole text's shaped width fits, which can be a hair more, so a line that is exactly as wide
/// as its column breaks in a different place. Each line is a [CssText], and the paragraph is as
/// tall as CSS makes it ([CssLines]).
///
/// [text] is in [style]; a word wider than the column (an address) is left to [Text].
class CssParagraph extends StatelessWidget {
  const CssParagraph(this.text, {super.key, required this.style, this.textAlign});

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    // Read as one text, whatever the words' boxes are.
    return Semantics(
      label: text,
      textDirection: Directionality.of(context),
      child: ExcludeSemantics(child: _lines(context)),
    );
  }

  Widget _lines(BuildContext context) {
    return CssLines(
      style: style,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final max = constraints.maxWidth;
          final scaler = MediaQuery.textScalerOf(context);
          final dir = Directionality.of(context);
          double width(String token) => CssText._measure(context, token, style, scaler, dir);
          final space = width(' ');
          final lines = <String>[];
          var line = '';
          var lineWidth = 0.0;
          for (final word in text.split(' ')) {
            final w = width(word);
            if (w > max) return Text(text, style: style, textAlign: textAlign);
            if (line.isEmpty) {
              line = word;
              lineWidth = w;
            } else if (lineWidth + space + w <= max) {
              line = '$line $word';
              lineWidth += space + w;
            } else {
              lines.add(line);
              line = word;
              lineWidth = w;
            }
          }
          lines.add(line);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: switch (textAlign) {
              TextAlign.center => CrossAxisAlignment.center,
              TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
              _ => CrossAxisAlignment.start,
            },
            children: [for (final l in lines) CssText(TextSpan(text: l, style: style))],
          );
        },
      ),
    );
  }
}

final _lineUnits = <(String?, double?, FontWeight?, double?, double), double>{};

/// How tall Flutter makes one line of [style] at [scale]: a whole number of pixels (a 13px font at
/// a line height of 1.5 is 19.5px in CSS and 20px here).
double _flutterLine(TextStyle style, double scale) {
  final key = (style.fontFamily, style.fontSize, style.fontWeight, style.height, scale);
  return _lineUnits.putIfAbsent(key, () {
    final painter = TextPainter(
      text: TextSpan(
        text: 'x',
        style: style.copyWith(fontFeatures: const []),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.linear(scale),
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  });
}

/// A text as tall as CSS makes it. CSS adds line boxes up as they are (19.5px for one line of 13px
/// at 1.5), while Flutter rounds every line up to whole pixels (20px), so a screen of such lines
/// drifts further from the web's with each one. This takes the rounding back: [child] (a `Text`
/// in [style]) keeps its lines, and the box is [style]'s real line height times their number, with
/// the text centred in it (which is where half-leading puts the glyphs).
class CssLines extends SingleChildRenderObjectWidget {
  const CssLines({super.key, required this.style, required Widget super.child});

  /// The text style of [child]: its size and line height are the CSS line height.
  final TextStyle style;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCssLines(_lines(context), _flutterLine(style, _scale(context)));

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderCssLines)
      ..cssLine = _lines(context)
      ..flutterLine = _flutterLine(style, _scale(context));
  }

  double _scale(BuildContext context) => MediaQuery.textScalerOf(context).scale(1);

  double _lines(BuildContext context) => style.fontSize! * _scale(context) * style.height!;
}

class _RenderCssLines extends RenderShiftedBox {
  _RenderCssLines(this._cssLine, this._flutterLine) : super(null);

  double _cssLine;
  double _flutterLine;

  set cssLine(double value) {
    if (value == _cssLine) return;
    _cssLine = value;
    markNeedsLayout();
  }

  set flutterLine(double value) {
    if (value == _flutterLine) return;
    _flutterLine = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints, parentUsesSize: true);
    final lines = (child.size.height / _flutterLine).round().clamp(1, 1000);
    final height = lines * _cssLine;
    size = constraints.constrain(Size(child.size.width, height));
    (child.parentData! as BoxParentData).offset = Offset(0, (size.height - child.size.height) / 2);
  }
}
