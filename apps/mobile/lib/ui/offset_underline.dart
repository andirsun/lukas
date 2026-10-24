import 'package:flutter/widgets.dart';

/// A ghost button's label with the web's `underline underline-offset-3` (app.css `.lk-btn-ghost`):
/// the line sits 3px further from the text than Flutter's own underline does, so it is drawn here,
/// 3.7px under the baseline and a pixel thick, in the text's colour.
class OffsetUnderline extends StatelessWidget {
  const OffsetUnderline(this.text, {super.key, this.style});

  final String text;

  /// The text's style; the surrounding one (a button's) when null.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final style = (this.style ?? DefaultTextStyle.of(context).style).copyWith(
      decoration: TextDecoration.none,
    );
    return CustomPaint(
      painter: _UnderlinePainter(text, style, MediaQuery.textScalerOf(context)),
      size: _measure(text, style, MediaQuery.textScalerOf(context)),
    );
  }

  static Size _measure(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    return painter.size;
  }
}

class _UnderlinePainter extends CustomPainter {
  _UnderlinePainter(this.text, this.style, this.scaler);

  final String text;
  final TextStyle style;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    painter.paint(canvas, Offset.zero);
    final baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final y = baseline + 3.2;
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width - (style.letterSpacing ?? 0), 1),
      Paint()
        ..color = style.color ?? const Color(0xFF000000)
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_UnderlinePainter old) =>
      old.text != text || old.style != style || old.scaler != scaler;
}
