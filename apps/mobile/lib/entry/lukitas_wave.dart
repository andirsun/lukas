import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Lukitas waving, from the web's sprite sheet (4x2 frames, 1.2 s a wave). He waves twice, then
/// rests on the first frame; with the system's "remove animations" he stands still.
class LukitasWave extends StatefulWidget {
  const LukitasWave({super.key, this.size = 160});

  final double size;

  @override
  State<LukitasWave> createState() => _LukitasWaveState();
}

class _LukitasWaveState extends State<LukitasWave> with SingleTickerProviderStateMixin {
  static const _columns = 4;
  static const _rows = 2;
  static const _frames = _columns * _rows;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) _controller.repeat(count: 2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Semantics(
      label: AppLocalizations.of(context).lukitasWaves,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final frame = (_controller.value * _frames).floor() % _frames;
              final column = frame % _columns;
              final row = frame ~/ _columns;
              return OverflowBox(
                maxWidth: size * _columns,
                maxHeight: size * _rows,
                alignment: Alignment(-1 + 2 * column / (_columns - 1), -1 + 2 * row / (_rows - 1)),
                child: child,
              );
            },
            child: Image.asset(
              'assets/lukas/wave.webp',
              width: size * _columns,
              height: size * _rows,
              excludeFromSemantics: true,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}
