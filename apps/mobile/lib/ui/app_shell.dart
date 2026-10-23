// The web's AppShell frame (apps/web/app/features/home/AppShell.tsx, `Frame`) on a phone: the
// screen's background (app.css `.lk-screen`) with the bottom bar fixed to the bottom of it.
import 'package:flutter/material.dart';

import '../theme/surfaces.dart';
import 'bottom_bar.dart';
import 'lk_theme.dart';

/// How much room a screen leaves under its content for the bottom bar, as the web's
/// `pb-[calc(112px+env(safe-area-inset-bottom))]`: the content scrolls under the bar, and its end
/// stops above it.
class ShellRoom extends InheritedWidget {
  const ShellRoom({super.key, required this.bottom, required super.child});

  /// 112px plus the system's bottom inset.
  final double bottom;

  /// The room under the content; 112 when there is no shell around (a test, a golden).
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellRoom>()?.bottom ?? 112;

  @override
  bool updateShouldNotify(ShellRoom old) => old.bottom != bottom;
}

/// Space around the screen's content that the bottom bar ignores. Zero in the app. Storybook pads
/// every story by 16px (`.storybook/preview.tsx`, `<div className="p-(--space-4)">`) while the bar
/// stays fixed to the viewport, so the parity pictures of home (test/parity) set it to compare like
/// with like: the screen is inset, the page's colour shows around it, and the bar is full width.
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
    this.screenHeight,
    required super.child,
  });

  /// How tall the web's screen is (its page's height: `min-h-dvh`, or as long as its content),
  /// which is how tall its background gradient is. Null: as tall as the viewport.
  final double? screenHeight;

  final EdgeInsets padding;
  final Widget? banner;
  final bool showMic;

  static ShellFrame? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellFrame>();

  @override
  bool updateShouldNotify(ShellFrame old) =>
      old.padding != padding ||
      old.banner != banner ||
      old.showMic != showMic ||
      old.screenHeight != screenHeight;
}

/// The frame of the signed-in screens on a phone: the screen's background gradient, the screen
/// ([child]) over all of it, and the bottom bar (Inicio · ＋ · Análisis, and the 🎤) fixed under it,
/// above the system's navigation bar (`pb-[env(safe-area-inset-bottom)]`). Toasts show above the
/// bar, as the web's `--toast-lift` does.
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
    final colors = context.lkColors;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final shellFrame = ShellFrame.maybeOf(context);
    final frame = shellFrame?.padding ?? EdgeInsets.zero;
    final banner = shellFrame?.banner;
    final gradient = BoxDecoration(gradient: LkSurface.background(colors));
    final content = ShellRoom(bottom: 112 + safeBottom, child: child);
    final scaffold = Scaffold(
      backgroundColor: frame == EdgeInsets.zero ? Colors.transparent : colors.bg,
      // The content runs under the bar: what scrolls past it is hidden by it, not cut off above.
      extendBody: true,
      body: frame == EdgeInsets.zero
          ? content
          // The screen is `min-h-dvh` from its padding down: as tall as the viewport.
          : LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Positioned(
                    left: frame.left,
                    top: frame.top,
                    right: frame.right,
                    height: shellFrame?.screenHeight ?? constraints.maxHeight,
                    child: DecoratedBox(
                      decoration: gradient,
                      child: banner == null
                          ? content
                          : Column(
                              children: [
                                banner,
                                Expanded(child: content),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: safeBottom),
        child: BottomBar(
          current: current,
          onAdd: onAdd,
          onMic: onMic,
          onNavigate: onNavigate,
          showMic: shellFrame?.showMic ?? true,
          addKey: addKey,
          micKey: micKey,
        ),
      ),
    );
    return frame == EdgeInsets.zero
        ? DecoratedBox(decoration: gradient, child: scaffold)
        : scaffold;
  }
}
