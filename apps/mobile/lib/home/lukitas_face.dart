import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';

/// How Lukitas feels about the month (the web's `moodFor`): celebrating right after a save or a
/// payment, worried while any category is near or over its limit, happy otherwise.
enum LukitasMood {
  happy('assets/lukas/wave.webp', Duration(milliseconds: 1200), 2, 0),
  worried('assets/lukas/worried.webp', LukitasTokens.durationShiver, 1, 3),
  celebrating('assets/lukas/celebrate.webp', LukitasTokens.durationCelebrate, 2, 4);

  const LukitasMood(this.sheet, this.loop, this.loops, this.stillFrame);

  /// The web's own sprite sheet: 4x2 frames of 500 px.
  final String sheet;

  /// One pass over the eight frames.
  final Duration loop;

  /// How many passes it plays before it rests on the first frame.
  final int loops;

  /// The frame shown under "remove animations" (0-based, in reading order), as the web's
  /// `LUKAS_ART[mood].stillFrame` (apps/web/app/lukas/Lukas.tsx): happy the first, a soft smile;
  /// worried frame 3, hands clasped and a sweat drop; celebrating frame 4, fists up among sparkles.
  final int stillFrame;
}

/// Lukitas' face for a [mood], from the web's sprite sheets. It plays its loop a couple of times
/// when the mood arrives, then rests on the first frame; with the system's "remove animations" it
/// stands still on the mood's [LukitasMood.stillFrame].
class LukitasFace extends StatefulWidget {
  const LukitasFace({
    super.key,
    required this.mood,
    this.size = 72,
    this.decorative = false,
    this.label,
  });

  final LukitasMood mood;
  final double size;

  /// Hidden from assistive technology, when something next to Lukitas already says the same (the
  /// web's `decorative`).
  final bool decorative;

  /// How he is named for assistive technology (the web's `mascot.<mood>`); "Lukitas" when null.
  final String? label;

  @override
  State<LukitasFace> createState() => _LukitasFaceState();
}

class _LukitasFaceState extends State<LukitasFace> with SingleTickerProviderStateMixin {
  static const _columns = 4;
  static const _rows = 2;
  static const _frames = _columns * _rows;

  late final AnimationController _controller = AnimationController(vsync: this);
  bool _animate = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (animate != _animate || !_controller.isAnimating && _controller.value == 0) {
      _animate = animate;
      _play();
    }
  }

  @override
  void didUpdateWidget(LukitasFace old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _play();
  }

  void _play() {
    _controller
      ..stop()
      ..value = 0
      ..duration = widget.mood.loop;
    if (_animate) _controller.repeat(count: widget.mood.loops);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final picture = SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final frame = _animate
                ? (_controller.value * _frames).floor() % _frames
                : widget.mood.stillFrame;
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
            widget.mood.sheet,
            width: size * _columns,
            height: size * _rows,
            excludeFromSemantics: true,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
    if (widget.decorative) return ExcludeSemantics(child: picture);
    return Semantics(
      label: widget.label ?? AppLocalizations.of(context).lukitasMood,
      image: true,
      child: picture,
    );
  }
}
