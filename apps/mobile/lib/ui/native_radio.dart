import 'package:flutter/widgets.dart';

/// A native radio as Chrome draws it with `accent-color` (`size-5`, 20px): a white disc with a 1px
/// grey edge; chosen, the edge and a 12px dot are the accent. The welcome's currency step and
/// Settings' currency both draw one.
class NativeRadio extends StatelessWidget {
  const NativeRadio({super.key, required this.checked, required this.accent});

  final bool checked;
  final Color accent;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size.square(20), painter: _RadioPainter(checked, accent));
}

class _RadioPainter extends CustomPainter {
  const _RadioPainter(this.checked, this.accent);

  final bool checked;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(
      center,
      radius - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = checked ? accent : const Color(0xFF767676),
    );
    if (checked) canvas.drawCircle(center, 6, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_RadioPainter old) => old.checked != checked || old.accent != accent;
}
