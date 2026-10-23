// The web's Celebration (apps/web/app/feedback/Celebration.tsx and Celebration.css): confetti and a
// celebrating Lukitas, shown when `feedback()` reports something worth celebrating.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/lukitas_face.dart';
import '../theme/tokens.g.dart';
import '../ui/lk_theme.dart';
import 'feedback_event.dart';

/// The events worth a party: a save of an expense or an income, and a payment. Near the limit, over
/// budget, undo and plain taps are not (the web's `CELEBRATED_EVENTS`).
const celebratedEvents = {FeedbackEvent.saved, FeedbackEvent.incomeSaved, FeedbackEvent.paid};

/// Counts the celebrations the feedback asked for: each is a new number, so two in a row both
/// count. [feedbackProvider] bumps it for [celebratedEvents]; the [CelebrationHost] shows them.
class CelebrationBursts extends Notifier<int> {
  @override
  int build() => 0;

  void burst() => state++;
}

final celebrationBurstsProvider = NotifierProvider<CelebrationBursts, int>(CelebrationBursts.new);

/// px between Lukitas's feet and the element he stands above (`ABOVE_GAP`).
const _aboveGap = 4.0;

/// How long to wait for a landing spot to appear (a screen still arriving, as after onboarding).
const _findSpotFor = Duration(milliseconds: 800);

/// A little over the stay, so the last frame is shown (the web's `ms + 50`).
const _lingers = Duration(milliseconds: 50);

/// Where Lukitas lands: the middle of the spot, the top of his box, and his size.
class _Spot {
  const _Spot(this.x, this.top, this.size);

  final double x;
  final double top;
  final double size;

  _Spot withTop(double top) => _Spot(x, top, size);

  Rect get box => Rect.fromLTWH(x - size / 2, top, size, size);
}

/// Where the celebration may land and what it keeps clear of: the web's `data-celebration-anchor`
/// and `data-celebration-avoid`, as widgets ([CelebrationAnchor], [CelebrationAvoid]).
class CelebrationSpots {
  final _anchors = <_AnchorEntry>[];
  final _avoid = <GlobalKey>[];

  void _addAnchor(_AnchorEntry entry) => _anchors.add(entry);
  void _removeAnchor(_AnchorEntry entry) => _anchors.remove(entry);
  void _addAvoid(GlobalKey key) => _avoid.add(key);
  void _removeAvoid(GlobalKey key) => _avoid.remove(key);

  static Rect? _rectIn(GlobalKey key, RenderBox? ancestor) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero, ancestor: ancestor) & box.size;
    return rect.width <= 0 || rect.height <= 0 ? null : rect;
  }

  /// The first landing spot on screen, or null while there is none (`findSpot`).
  _Spot? _find(RenderBox? ancestor) {
    for (final anchor in _anchors) {
      final rect = _rectIn(anchor.key, ancestor);
      if (rect == null) continue;
      return _Spot(rect.center.dx, rect.top - anchor.size - _aboveGap, anchor.size);
    }
    return null;
  }

  /// Moves [spot] up until Lukitas's box clears every avoided box on screen (`clearOfObstacles`).
  _Spot _clear(_Spot spot, RenderBox? ancestor) {
    final obstacles = [for (final key in _avoid) ?_rectIn(key, ancestor)];
    var current = spot;
    // Each step only moves him up, so a few passes settle it (he can't bounce between two).
    for (var pass = 0; pass < obstacles.length + 1; pass++) {
      final box = current.box;
      final hit = obstacles
          .where(
            (rect) =>
                box.left < rect.right &&
                rect.left < box.right &&
                box.top < rect.bottom + _aboveGap &&
                rect.top < box.bottom + _aboveGap,
          )
          .firstOrNull;
      if (hit == null) return current;
      current = current.withTop(hit.top - current.size - _aboveGap);
    }
    return current;
  }
}

class _AnchorEntry {
  _AnchorEntry(this.key, this.size);

  final GlobalKey key;
  final double size;
}

/// Marks where Lukitas may land: the element he stands just above (the ＋ of the bottom bar, which
/// stays in view and tappable), [size] being his size. The first one on screen wins.
class CelebrationAnchor extends StatefulWidget {
  const CelebrationAnchor({super.key, required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  State<CelebrationAnchor> createState() => _CelebrationAnchorState();
}

class _CelebrationAnchorState extends State<CelebrationAnchor> {
  final _key = GlobalKey();
  late _AnchorEntry _entry = _AnchorEntry(_key, widget.size);
  CelebrationSpots? _spots;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final spots = CelebrationHost.maybeOf(context);
    if (spots == _spots) return;
    _spots?._removeAnchor(_entry);
    _spots = spots;
    spots?._addAnchor(_entry);
  }

  @override
  void didUpdateWidget(CelebrationAnchor old) {
    super.didUpdateWidget(old);
    if (old.size == widget.size) return;
    _spots?._removeAnchor(_entry);
    _entry = _AnchorEntry(_key, widget.size);
    _spots?._addAnchor(_entry);
  }

  @override
  void dispose() {
    _spots?._removeAnchor(_entry);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}

/// Marks what Lukitas must never cover besides his spot: the toasts (with their Deshacer), which a
/// save shows at the same moment. Its box is its layout box (an entering toast's slide is ignored).
class CelebrationAvoid extends StatefulWidget {
  const CelebrationAvoid({super.key, required this.child});

  final Widget child;

  @override
  State<CelebrationAvoid> createState() => _CelebrationAvoidState();
}

class _CelebrationAvoidState extends State<CelebrationAvoid> {
  final _key = GlobalKey();
  CelebrationSpots? _spots;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final spots = CelebrationHost.maybeOf(context);
    if (spots == _spots) return;
    _spots?._removeAvoid(_key);
    _spots = spots;
    spots?._addAvoid(_key);
  }

  @override
  void dispose() {
    _spots?._removeAvoid(_key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}

/// Confetti and a celebrating Lukitas over the app, when `feedback()` reports something worth
/// celebrating ([celebratedEvents]). Lukitas lands in free space, never over text or figures: just
/// above the ＋ of the bottom bar (never on it: it stays visible and tappable), and above the undo
/// toast while one is up ([CelebrationAvoid]); the confetti bursts from there. Purely decorative
/// (hidden from assistive technology: the toast or screen already says what happened) and it never
/// takes a tap. Under reduced motion there is no confetti: Lukitas shows as his still celebrating
/// frame and only fades in and out. Put one above the app's Navigator.
class CelebrationHost extends ConsumerStatefulWidget {
  const CelebrationHost({super.key, required this.child});

  final Widget child;

  /// Where the celebration may land and what it avoids, or null without a host above [context].
  static CelebrationSpots? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SpotsScope>()?.spots;

  @override
  ConsumerState<CelebrationHost> createState() => _CelebrationHostState();
}

class _SpotsScope extends InheritedWidget {
  const _SpotsScope({required this.spots, required super.child});

  final CelebrationSpots spots;

  @override
  bool updateShouldNotify(_SpotsScope old) => old.spots != spots;
}

class _Placed {
  const _Placed(this.id, this.spot);

  final int id;
  final _Spot spot;
}

class _CelebrationHostState extends ConsumerState<CelebrationHost> {
  final _spots = CelebrationSpots();
  final _hostKey = GlobalKey();
  _Placed? _placed;
  var _id = 0;
  Timer? _hide;

  RenderBox? get _host {
    final box = _hostKey.currentContext?.findRenderObject();
    return box is RenderBox && box.attached ? box : null;
  }

  @override
  void dispose() {
    _id++;
    _hide?.cancel();
    super.dispose();
  }

  /// A celebration asked for: look for a spot one frame on (the toast a save shows with it is on
  /// the page by then), for a moment if need be.
  void _onBurst() {
    final mine = ++_id;
    _hide?.cancel();
    Duration? since;
    void place() {
      if (!mounted || mine != _id) return;
      final host = _host;
      final found = _spots._find(host);
      // The frames' own clock, which a test's fake time moves too.
      final now = WidgetsBinding.instance.currentSystemFrameTimeStamp;
      since ??= now;
      if (found == null && now - since! < _findSpotFor) {
        WidgetsBinding.instance
          ..addPostFrameCallback((_) => place())
          ..scheduleFrame();
        return;
      }
      final spot = _spots._clear(found ?? _fallback(), host);
      setState(() => _placed = _Placed(mine, spot));
      _hide = Timer(LukitasTokens.durationCelebrate + _lingers, () {
        if (mounted && mine == _id) setState(() => _placed = null);
      });
    }

    WidgetsBinding.instance
      ..addPostFrameCallback((_) => place())
      ..scheduleFrame();
  }

  /// No spot at all (a screen without a bottom bar): the top of the screen.
  _Spot _fallback() {
    final width = _host?.size.width ?? MediaQuery.sizeOf(context).width;
    return _Spot(width / 2, 8, 72);
  }

  /// A toast that shows a moment later (or grows) pushes him up; he never moves down.
  void _follow(int id) {
    final placed = _placed;
    if (placed == null || placed.id != id || !mounted) return;
    final next = _spots._clear(placed.spot, _host);
    if (next.top < placed.spot.top - 0.5) setState(() => _placed = _Placed(id, next));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(celebrationBurstsProvider, (_, _) => _onBurst());
    final placed = _placed;
    return _SpotsScope(
      spots: _spots,
      child: Stack(
        key: _hostKey,
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (placed != null)
            Positioned.fill(
              child: IgnorePointer(
                key: const Key('celebration'),
                child: ExcludeSemantics(
                  // The key restarts the animation when another event arrives mid-celebration.
                  child: _Celebration(
                    key: ValueKey(placed.id),
                    spot: placed.spot,
                    onFrame: () => _follow(placed.id),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// -- the burst ---------------------------------------------------------------------------------

/// One piece of confetti (the web's `Piece`).
class ConfettiPiece {
  const ConfettiPiece({
    required this.tone,
    required this.round,
    required this.dx,
    required this.rise,
    required this.fall,
    required this.spin,
  });

  /// 0 gold, 1 candy, 2 good.
  final int tone;
  final bool round;
  final double dx;
  final double rise;
  final double fall;

  /// Degrees.
  final double spin;
}

/// JavaScript's `Math.round`: halves go up.
double _jsRound(double x) => (x + 0.5).floorToDouble();

/// Evenly fanned (golden angle) so the same burst always looks the same, with no randomness: the
/// web's `BURST`, piece for piece.
final List<ConfettiPiece> confettiBurst = List.generate(28, (index) {
  final angle = index * 2.399963;
  final reach = 70 + ((index * 37) % 90);
  final dx = _jsRound(math.cos(angle) * reach * 1.5);
  final rise = -_jsRound(60 + ((index * 53) % 110).toDouble());
  return ConfettiPiece(
    tone: index % 3,
    round: index % 4 == 3,
    dx: dx,
    rise: rise,
    fall: _jsRound(rise + 150 + ((index * 29) % 90)),
    spin: (index.isEven ? 1 : -1) * (240 + ((index * 61) % 300)).toDouble(),
  );
});

/// The confetti's easing (`cubic-bezier(0.2, 0.7, 0.4, 1)`), the pop's and the fade's (`ease-out`).
const _confettiCurve = Cubic(0.2, 0.7, 0.4, 1);
const _easeOut = Curves.easeOut;

/// Where a piece is `t` (0 to 1) of the way through `lk-confetti-burst`: out and up fast to 45%,
/// then gravity takes it down while it spins and fades. Each half eases on its own, as CSS eases
/// between keyframes.
({Offset offset, double angle, double opacity}) confettiAt(ConfettiPiece piece, double t) {
  if (t <= 0.45) {
    final p = _confettiCurve.transform(t / 0.45);
    return (
      offset: Offset(piece.dx * 0.8 * p, piece.rise * p),
      angle: piece.spin * 0.5 * p,
      opacity: 1,
    );
  }
  final p = _confettiCurve.transform((t - 0.45) / 0.55);
  return (
    offset: Offset(
      piece.dx * 0.8 + (piece.dx - piece.dx * 0.8) * p,
      piece.rise + (piece.fall - piece.rise) * p,
    ),
    angle: piece.spin * 0.5 + (piece.spin - piece.spin * 0.5) * p,
    opacity: 1 - p,
  );
}

/// Lukitas' look `t` of the way through `lk-celebration-pop`: grows up from his feet, bounces once
/// and shrinks back down; or, under reduced motion, `lk-celebration-fade`.
({double scale, double opacity}) lukitasAt(double t, {required bool reduced}) {
  if (reduced) {
    // 0%: 0, 15% to 80%: 1, 100%: 0.
    if (t < 0.15) return (scale: 1, opacity: _easeOut.transform(t / 0.15));
    if (t <= 0.8) return (scale: 1, opacity: 1);
    return (scale: 1, opacity: 1 - _easeOut.transform((t - 0.8) / 0.2));
  }
  double lerp(double a, double b, double p) => a + (b - a) * p;
  if (t < 0.2) {
    final p = _easeOut.transform(t / 0.2);
    return (scale: lerp(0.4, 1.06, p), opacity: lerp(0, 1, p));
  }
  if (t < 0.35) {
    final p = _easeOut.transform((t - 0.2) / 0.15);
    return (scale: lerp(1.06, 1, p), opacity: 1);
  }
  if (t <= 0.8) return (scale: 1, opacity: 1);
  final p = _easeOut.transform((t - 0.8) / 0.2);
  return (scale: lerp(1, 0.85, p), opacity: lerp(1, 0, p));
}

class _Celebration extends StatefulWidget {
  const _Celebration({super.key, required this.spot, required this.onFrame});

  final _Spot spot;
  final VoidCallback onFrame;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: LukitasTokens.durationCelebrate,
    // Under reduced motion the web still fades him in and out over the same stay: the controller
    // must not cut the stay short, as the default does for the system's "remove animations".
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(widget.onFrame);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final colors = context.lkColors;
    final spot = widget.spot;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final look = lukitasAt(t, reduced: reduced);
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (!reduced)
              Positioned.fill(
                child: CustomPaint(
                  key: const Key('celebration.confetti'),
                  painter: _ConfettiPainter(
                    origin: Offset(spot.x, spot.top),
                    t: t,
                    colors: [colors.gold, colors.candy, colors.good],
                  ),
                ),
              ),
            Positioned(
              left: spot.x - spot.size / 2,
              top: spot.top,
              width: spot.size,
              height: spot.size,
              child: Opacity(
                opacity: look.opacity,
                child: Transform.scale(
                  scale: look.scale,
                  alignment: Alignment.bottomCenter,
                  child: LukitasFace(
                    mood: LukitasMood.celebrating,
                    size: spot.size,
                    decorative: true,
                    endless: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.origin, required this.t, required this.colors});

  final Offset origin;
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in confettiBurst) {
      final at = confettiAt(piece, t);
      // `.lk-confetti`: 8 × 14 with a 2px radius; round: 10 × 10 and a pill. It turns about its
      // middle, from the burst's origin.
      final width = piece.round ? 10.0 : 8.0;
      final height = piece.round ? 10.0 : 14.0;
      final radius = piece.round ? 5.0 : 2.0;
      canvas
        ..save()
        ..translate(origin.dx + at.offset.dx, origin.dy + at.offset.dy)
        ..translate(width / 2, height / 2)
        ..rotate(at.angle * math.pi / 180)
        ..translate(-width / 2, -height / 2)
        ..drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, height), Radius.circular(radius)),
          Paint()..color = colors[piece.tone].withValues(alpha: at.opacity),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t || old.origin != origin;
}
