// The web's AppShell frame (apps/web/app/features/home/AppShell.tsx, `Frame`) on a phone: the
// screen's background (app.css `.lk-screen`) with the bottom bar fixed to the bottom of it.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../theme/surfaces.dart';
import '../theme/tokens.g.dart';
import 'bottom_bar.dart';
import 'lk_theme.dart';
import 'toast.dart';

/// What the shell asks of a screen's content, inside its scroll view:
///
/// - [of]: the room under the content for the bottom bar, as the web's
///   `pb-[calc(112px+env(safe-area-inset-bottom))]`: the content scrolls under the bar, and its end
///   stops above it.
/// - [leading]: what goes first in the scroll content, above the screen's own padding: nothing in
///   the app. Under a [ShellFrame] it is Storybook's padding above the screen, and the notice the
///   web's `AppShell` puts above every screen.
/// - [sides]: the padding the frame adds at the sides of everything.
///
/// The page's background gradient is the shell's: the page is the scroll content, so it is as tall
/// as the content and its glow scrolls away with it, as the web's `.lk-screen` does.
class ShellRoom extends InheritedWidget {
  const ShellRoom({
    super.key,
    required this.bottom,
    this.frameSides = EdgeInsets.zero,
    this.frameLeading,
    required super.child,
  });

  /// 112px plus the system's bottom inset (and the frame's padding under the page).
  final double bottom;

  /// The frame's padding at the left and the right.
  final EdgeInsets frameSides;

  /// What goes first in the scroll content.
  final Widget? frameLeading;

  /// The room under the content; 112 when there is no shell around (a test, a golden).
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellRoom>()?.bottom ?? 112;

  /// The frame's padding at the sides: zero in the app.
  static EdgeInsets sides(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellRoom>()?.frameSides ?? EdgeInsets.zero;

  /// What goes first in the scroll content (zero-sized in the app).
  static Widget leading(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellRoom>()?.frameLeading ??
      const SizedBox.shrink();

  @override
  bool updateShouldNotify(ShellRoom old) =>
      old.bottom != bottom || old.frameSides != frameSides || old.frameLeading != frameLeading;
}

/// Space around the screen's content that the bottom bar ignores. Zero in the app. Storybook pads
/// every story by 16px (`.storybook/preview.tsx`, `<div className="p-(--space-4)">`) while the bar
/// stays fixed to the viewport, so the parity pictures of the screens (test/parity) set it to
/// compare like with like: the page's colour shows around the screen, the page scrolls with that
/// padding in it, and the bar is full width.
///
/// [showMic] false leaves out the 🎤, which the web has not (spec §5): the parity pair compares
/// everything else.
///
/// [banner] is what the web's `AppShell` puts above every screen, beside the sidebar (the demo's
/// notice); the app has none, and the pair of the demo's home draws a stand-in of the same size.
class ShellFrame extends InheritedWidget {
  const ShellFrame({
    super.key,
    required this.padding,
    this.banner,
    this.showMic = true,
    required super.child,
  });

  final EdgeInsets padding;
  final Widget? banner;
  final bool showMic;

  static ShellFrame? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellFrame>();

  @override
  bool updateShouldNotify(ShellFrame old) =>
      old.padding != padding || old.banner != banner || old.showMic != showMic;
}

/// What the shell knows of the page: where its scroll view is, how far it has scrolled and how
/// long its content is. Told by the screen's scroll notifications.
class PageMetrics {
  const PageMetrics({this.top = 0, this.pixels = 0, this.viewport = 0, this.extent = 0});

  /// Where the scroll view starts, from the top of the shell (the status bar's inset).
  final double top;

  /// How far it has scrolled.
  final double pixels;

  /// The scroll view's height, and the length of everything in it (the content and its padding).
  final double viewport;
  final double extent;

  @override
  bool operator ==(Object other) =>
      other is PageMetrics &&
      other.top == top &&
      other.pixels == pixels &&
      other.viewport == viewport &&
      other.extent == extent;

  @override
  int get hashCode => Object.hash(top, pixels, viewport, extent);
}

/// The screen's background (app.css `.lk-screen`): the page's colour, and over the page the radial
/// gradient, as tall as the page and at least as tall as the screen (`min-h-dvh`), scrolling with
/// it. [frame] is the story frame's padding: the gradient is the page inside it, and the page's
/// colour shows around it. In the app the frame is zero and the gradient has no edge of its own.
class PageGradientPainter extends CustomPainter {
  PageGradientPainter({required this.colors, required this.frame, required this.metrics})
    : super(repaint: metrics);

  final LukitasColors colors;
  final EdgeInsets frame;
  final ValueListenable<PageMetrics> metrics;

  /// The page's box on a shell of [size]: from the top of the scroll content, down as far as the
  /// content goes.
  Rect rectIn(Size size) {
    final m = metrics.value;
    // The content's padding at the top and the bottom of the frame is the document's, not the
    // gradient's (`.lk-screen` sits inside Storybook's padding).
    final viewport = m.viewport == 0 ? size.height - m.top : m.viewport;
    final height = math.max(viewport, m.extent - frame.top - frame.bottom);
    return Rect.fromLTWH(
      frame.left,
      m.top - m.pixels + frame.top,
      size.width - frame.horizontal,
      height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.bg);
    final rect = rectIn(size);
    final paint = Paint()..shader = LkSurface.background(colors).createShader(rect);
    if (frame == EdgeInsets.zero) {
      // The glow goes on above the page's top, under the status bar, as it does below it.
      canvas.drawRect(Offset.zero & size, paint);
    } else {
      canvas.drawRect(rect.intersect(Offset.zero & size), paint);
    }
  }

  @override
  bool shouldRepaint(PageGradientPainter old) =>
      old.colors != colors || old.frame != frame || old.metrics != metrics;
}

/// The page's background, as the web's `.lk-screen` paints it, behind [child]: the page's colour
/// and the radial gradient over it, as tall as the page ([child]'s scroll content, a screen at
/// least) and scrolling with it. It listens to the scroll notifications of [child]'s main scroll
/// view (a vertical one that is not inside another) to know how far it has gone and how long it is.
/// The frame of a parity picture ([ShellFrame]) is the page's padding.
class PageBackground extends StatefulWidget {
  const PageBackground({super.key, required this.child});

  final Widget child;

  @override
  State<PageBackground> createState() => _PageBackgroundState();
}

class _PageBackgroundState extends State<PageBackground> {
  final _page = ValueNotifier<PageMetrics>(const PageMetrics());

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  /// The screen's main scroll view moved or changed its length.
  void _measure(ScrollMetrics metrics, BuildContext? scrollable) {
    if (metrics.axis != Axis.vertical) return;
    final shell = context.findRenderObject();
    final box = scrollable?.findRenderObject();
    var top = 0.0;
    if (shell is RenderBox && box is RenderBox && box.attached && shell.attached) {
      top = box.localToGlobal(Offset.zero, ancestor: shell).dy;
    }
    final next = PageMetrics(
      top: top,
      pixels: metrics.pixels,
      viewport: metrics.viewportDimension,
      extent: metrics.maxScrollExtent + metrics.viewportDimension,
    );
    if (next != _page.value) _page.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final frame = ShellFrame.maybeOf(context)?.padding ?? EdgeInsets.zero;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            key: const Key('shell.gradient'),
            painter: PageGradientPainter(colors: colors, frame: frame, metrics: _page),
          ),
        ),
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (n) {
            if (n.depth == 0) _measure(n.metrics, n.context);
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.depth == 0) _measure(n.metrics, n.context);
              return false;
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// The frame of the signed-in screens on a phone: the page's background gradient, the screen
/// ([child]) over all of it, and the bottom bar (Inicio · ＋ · Análisis, and the 🎤) fixed under
/// it, above the system's navigation bar (`pb-[env(safe-area-inset-bottom)]`). Toasts show above
/// the bar, as the web's `--toast-lift` does.
///
/// The screen is one scroll view whose content leaves [ShellRoom] under it. Its scrolling moves the
/// gradient, which is the page's, not the screen's: on the web it is as tall as the page and the
/// glow scrolls away ([PageBackground]).
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.current,
    required this.onAdd,
    required this.onMic,
    required this.onNavigate,
    required this.child,
    this.addKey,
    this.micKey,
  });

  /// The current section: `home` or `insights`.
  final String current;
  final VoidCallback onAdd;
  final VoidCallback onMic;
  final ValueChanged<String> onNavigate;
  final Widget child;
  final Key? addKey;
  final Key? micKey;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final shellFrame = ShellFrame.maybeOf(context);
    final frame = shellFrame?.padding ?? EdgeInsets.zero;
    final banner = shellFrame?.banner;
    final leading = frame.top == 0 && banner == null
        ? null
        : Padding(
            padding: EdgeInsets.fromLTRB(frame.left, frame.top, frame.right, 0),
            child: banner,
          );
    final content = ShellRoom(
      bottom: 112 + safeBottom + frame.bottom,
      frameSides: EdgeInsets.fromLTRB(frame.left, 0, frame.right, 0),
      frameLeading: leading,
      child: child,
    );
    return _ToastLift(
      child: PageBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // The content runs under the bar: what scrolls past it is hidden by it, not cut off above.
          extendBody: true,
          // Tight: a short screen is as tall as the page, as `min-h-dvh` makes it.
          body: SizedBox.expand(child: content),
          // The bar, and under it the system's inset (`pb-[env(safe-area-inset-bottom)]`) in the
          // bar's own background: the list scrolls under the bar, and nothing may show through the
          // strip the gesture bar leaves under it.
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BottomBar(
                current: current,
                onAdd: onAdd,
                onMic: onMic,
                onNavigate: onNavigate,
                showMic: shellFrame?.showMic ?? true,
                addKey: addKey,
                micKey: micKey,
              ),
              ColoredBox(
                key: const Key('shell.bottomInset'),
                color: context.lkColors.surfaceSunken,
                child: SizedBox(height: safeBottom),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// While the bottom bar is on screen the toasts sit above it: `--toast-lift: 92px` under 64rem,
/// set by the shell (app.css, `:root:has(.lk-app-shell)`).
class _ToastLift extends StatefulWidget {
  const _ToastLift({required this.child});

  final Widget child;

  @override
  State<_ToastLift> createState() => _ToastLiftState();
}

class _ToastLiftState extends State<_ToastLift> {
  static const _lift = 92.0;

  ToastController? _toasts;
  VoidCallback? _release;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final toasts = ToastHost.maybeOf(context);
    if (toasts == _toasts) return;
    _release?.call();
    _toasts = toasts;
    _release = toasts?.liftBy(_lift);
  }

  @override
  void dispose() {
    _release?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
