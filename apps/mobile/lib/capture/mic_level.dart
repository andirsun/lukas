import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.g.dart';

/// The microphone's live level while quick capture listens: a row of bars, the newest on the right,
/// each as tall as the input was at that moment (silence is a row of dots, speech lifts the bars),
/// so the person sees at a glance that the microphone is in use. [levels] is 0 to 1, about 25 times
/// a second (`SpeechEngine.levels`); each bar glides to its height rather than jumping.
///
/// Under the system's "remove animations" it is a plain static indicator instead: one bar as wide
/// as the current level, which only changes, never moves in between.
///
/// A widget of its own, with colours and radii from the design tokens (`LukitasColors`: the
/// stroke for quiet, the brand for loud, and the candy at the peaks; pill bars), so the capture
/// sheet can place it anywhere. The sheet sets it in a sunken box (capture_listening.dart).
class MicLevel extends StatefulWidget {
  const MicLevel({super.key, required this.levels, this.bars = defaultBars, this.height = 56});

  /// The default number of bars: about a second of speech at 25 levels a second.
  static const defaultBars = 24;

  final Stream<double> levels;

  /// How many bars, the history it shows.
  final int bars;

  /// The tallest a bar gets, and the height of the static indicator's track's box.
  final double height;

  @override
  State<MicLevel> createState() => _MicLevelState();
}

class _MicLevelState extends State<MicLevel> {
  static const _barWidth = 6.0;
  static const _gap = 4.0;
  static const _smallest = 4.0;

  late List<double> _history = List.filled(widget.bars, 0);
  StreamSubscription<double>? _subscription;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(MicLevel old) {
    super.didUpdateWidget(old);
    if (old.levels != widget.levels) {
      unawaited(_subscription?.cancel());
      _listen();
    }
    if (old.bars != widget.bars) _history = List.filled(widget.bars, 0);
  }

  void _listen() {
    _subscription = widget.levels.listen((level) {
      final clamped = level.isNaN ? 0.0 : level.clamp(0.0, 1.0);
      setState(() {
        _history = [..._history.skip(1), clamped];
      });
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final plain = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: SizedBox(height: widget.height, child: plain ? _static(colors) : _bars(colors)),
    );
  }

  /// Quiet is the stroke and a loud moment the brand; a little speech already reads as brand.
  static Color? _tint(LukitasColors colors, double level) =>
      Color.lerp(colors.stroke, colors.brand, (level * 1.3).clamp(0.0, 1.0));

  Widget _bars(LukitasColors colors) => Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: _gap,
      children: [
        for (var i = 0; i < _history.length; i++)
          AnimatedContainer(
            key: Key('mic.bar.$i'),
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            width: _barWidth,
            height: _smallest + _history[i] * (widget.height - _smallest),
            decoration: BoxDecoration(
              color: _tint(colors, _history[i]),
              borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
            ),
          ),
      ],
    ),
  );

  Widget _static(LukitasColors colors) => Center(
    child: Container(
      key: const Key('mic.track'),
      // The same width as the bars take.
      width: widget.bars * (_barWidth + _gap),
      height: 10,
      decoration: BoxDecoration(
        color: colors.stroke,
        borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        key: const Key('mic.level'),
        widthFactor: _history.last,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.brand,
            borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}
