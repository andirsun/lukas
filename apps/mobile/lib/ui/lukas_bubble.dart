// The web's LukasBubble (apps/web/app/ui/LukasBubble.tsx) and the CSS it uses: app.css `.lk-bubble`
// and `.lk-bubble-tail`.
import 'package:flutter/material.dart';

import '../home/lukitas_face.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.g.dart';
import 'lk_theme.dart';

/// Lukas beside his speech bubble. The line carries the meaning, so Lukitas is decorative here;
/// the bubble is a polite live region, so a new line after a save or a month change is read out
/// (once). A new line fades in over `--fade`, from faint to full; with "remove animations" it just
/// shows.
class LukasBubble extends StatefulWidget {
  const LukasBubble({super.key, required this.message, required this.mood, this.quietKey});

  /// Lukas's line, already translated and filled with the real figures.
  final String message;

  final LukitasMood mood;

  /// Changing it swaps the line in quietly: the bubble is a new live region, and a live region
  /// that appears with its text is not announced. Home changes it when a line about a save or a
  /// payment ends, so going back to the month's line is never read out a second time.
  final Object? quietKey;

  @override
  State<LukasBubble> createState() => _LukasBubbleState();
}

class _LukasBubbleState extends State<LukasBubble> with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(vsync: this, duration: LukitasTokens.durationFade);

  /// From faint, never from nothing: the line is readable from its first frame.
  late final _opacity = Tween<double>(
    begin: 0.25,
    end: 1,
  ).animate(CurvedAnimation(parent: _fade, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _fade.value = 1;
  }

  @override
  void didUpdateWidget(LukasBubble old) {
    super.didUpdateWidget(old);
    if (old.message == widget.message) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    // `.lk-bubble`: radius 14, a 2px stroke around a `surface-row` fill.
    final radius = BorderRadius.circular(14);
    final border = Border.all(color: colors.stroke, width: 2);

    final bubble = Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: colors.surfaceRow, borderRadius: radius, border: border),
          child: Padding(
            // `padding: 8px 11px` inside the 2px border (a DecoratedBox's border takes no room).
            padding: const EdgeInsets.symmetric(horizontal: 11 + 2, vertical: 8 + 2),
            child: Semantics(
              key: ValueKey(widget.quietKey),
              liveRegion: true,
              child: SizedBox(
                width: double.infinity,
                child: BlinkLine(
                  style: LkText.bubble,
                  child: Text(widget.message, style: LkText.bubble.copyWith(color: colors.ink)),
                ),
              ),
            ),
          ),
        ),
        // `.lk-bubble-tail::before`: a 12px square, turned 45 degrees, 8px out of the padding box
        // (6px out of the border) and centred on the bubble; only its left and bottom edges are
        // drawn, so it points at Lukas, and its fill covers the bubble's border where they meet.
        Positioned(
          left: -6,
          top: 0,
          bottom: 0,
          child: Center(
            child: Transform.rotate(
              angle: 0.7853981633974483,
              child: SizedBox.square(
                dimension: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceRow,
                    border: Border(
                      left: BorderSide(color: colors.stroke, width: 2),
                      bottom: BorderSide(color: colors.stroke, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: LukitasTokens.space3,
      children: [
        LukitasFace(mood: widget.mood, size: 72, decorative: true),
        // The fade is on the whole bubble: the web animates the `<p>` that is the bubble.
        Expanded(
          child: FadeTransition(opacity: _opacity, child: bubble),
        ),
      ],
    );
  }
}
