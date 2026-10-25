import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/theme/theme.dart';
import 'package:lukitas/ui/app_shell.dart';
import 'package:lukitas/ui/toast.dart';

import '../support/fonts.dart';
import '../support/screen_pixels.dart';

/// The page background of the signed-in screens: on the web `.lk-screen` carries the radial
/// gradient and is as tall as the page (and at least as the viewport: `min-h-dvh`), so the glow
/// scrolls away with the content. The shell paints it from its screen's scroll metrics.

const _screen = Size(390, 844);

/// A screen of [height] px in the shell, as the real ones are: one scroll view, with what the shell
/// asks of a screen's content (the frame's top, the room under it for the bottom bar).
Widget _app({required double height, EdgeInsets? frame}) {
  final shell = AppShell(
    current: 'home',
    onAdd: () {},
    onMic: () {},
    onNavigate: (_) {},
    child: Builder(
      builder: (context) {
        final sides = ShellRoom.sides(context);
        return SingleChildScrollView(
          child: Column(
            children: [
              ShellRoom.leading(context),
              Padding(
                padding: EdgeInsets.fromLTRB(sides.left, 0, sides.right, ShellRoom.of(context)),
                child: SizedBox(height: height, child: const Placeholder()),
              ),
            ],
          ),
        );
      },
    ),
  );
  return MaterialApp(
    theme: nightTheme,
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: frame == null ? shell : ShellFrame(padding: frame, child: shell),
  );
}

/// Where the gradient is now, on a screen of [_screen].
Rect _gradient(WidgetTester t) {
  final paint = t.widget<CustomPaint>(find.byKey(const Key('shell.gradient')));
  return (paint.painter! as PageGradientPainter).rectIn(_screen);
}

void main() {
  setUpAll(loadAppFonts);

  Future<void> pump(WidgetTester t, Widget app) async {
    t.view
      ..physicalSize = _screen
      ..devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app);
    await t.pumpAndSettle();
  }

  testWidgets('a short page: the gradient fills the screen, as min-h-dvh does', (t) async {
    await pump(t, _app(height: 200));
    expect(_gradient(t), Offset.zero & _screen);
  });

  testWidgets('a long page: the gradient is as tall as the page, from its top', (t) async {
    await pump(t, _app(height: 2000));
    // The page is its content and the room under it for the bottom bar.
    final room = 112.0;
    expect(_gradient(t), Rect.fromLTWH(0, 0, 390, 2000 + room));
  });

  testWidgets('scrolling moves the gradient with the content', (t) async {
    await pump(t, _app(height: 2000));
    await t.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await t.pumpAndSettle();
    final rect = _gradient(t);
    expect(rect.top, -600, reason: 'the glow went up by what the page did');
    expect(rect.height, 2000 + 112.0, reason: 'and the page is as tall as it was');

    await t.drag(find.byType(SingleChildScrollView), const Offset(0, 600));
    await t.pumpAndSettle();
    expect(_gradient(t).top, 0);
  });

  testWidgets('the story frame: the gradient is the page inside Storybook\'s 16px', (t) async {
    await pump(t, _app(height: 2000, frame: const EdgeInsets.all(16)));
    // The box is inset 16px at the sides and starts 16px down; 16px more under it (the frame's
    // padding) is part of the document, and not of the gradient.
    expect(_gradient(t), Rect.fromLTWH(16, 16, 390 - 32, 2000 + 112.0));
    await t.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await t.pumpAndSettle();
    expect(_gradient(t).top, 16 - 600);
  });

  testWidgets('the toasts sit above the bar while the shell is on screen, and drop back after', (
    t,
  ) async {
    t.view
      ..physicalSize = _screen
      ..devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final navigator = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: nightTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => ToastHost(animateBar: false, child: child!),
        home: AppShell(
          current: 'home',
          onAdd: () {},
          onMic: () {},
          onNavigate: (_) {},
          child: const SizedBox.expand(),
        ),
      ),
    );
    final toasts = ToastHost.of(navigator.currentContext!);
    toasts.say('Hecho');
    await t.pumpAndSettle();
    // `--toast-lift: 92px` under 64rem: 16 + 92 from the bottom.
    expect(_screen.height - t.getRect(find.byType(ToastLayer)).bottom, 16 + 92);

    await t.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: nightTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => ToastHost(animateBar: false, child: child!),
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );
    await t.pumpAndSettle();
    ToastHost.of(navigator.currentContext!).say('Otra vez');
    await t.pumpAndSettle();
    expect(_screen.height - t.getRect(find.byType(ToastLayer)).bottom, 16);
  });

  testWidgets(
    'with gesture navigation the bar\'s background goes down through the inset: no content shows under it',
    (t) async {
      t.view
        ..physicalSize = _screen
        ..devicePixelRatio = 1
        ..viewPadding = const FakeViewPadding(bottom: 48)
        ..padding = const FakeViewPadding(bottom: 48);
      addTearDown(t.view.reset);
      // A list of bright rows, long enough to scroll under the bar.
      await t.pumpWidget(
        MaterialApp(
          theme: nightTheme,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppShell(
            current: 'home',
            onAdd: () {},
            onMic: () {},
            onNavigate: (_) {},
            child: ListView(
              children: [
                for (var i = 0; i < 40; i++)
                  Container(
                    height: 60,
                    margin: const EdgeInsets.all(4),
                    color: const Color(0xFFFF0000),
                  ),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final sunken = nightTheme.extension<LukitasTheme>()!.colors.surfaceSunken.toARGB32();
      for (final scrolled in [0.0, 130.0, 777.0]) {
        await t.drag(find.byType(ListView), Offset(0, -scrolled));
        await t.pumpAndSettle();
        final pixels = await ScreenPixels.capture(t);
        final inset = _screen.height - 48;
        // Every pixel of the strip under the bar, from its top to the screen's bottom edge.
        for (var y = inset; y < _screen.height; y += 4) {
          for (var x = 1.0; x < _screen.width; x += 13) {
            expect(
              pixels.at(x, y),
              sunken,
              reason:
                  'the strip at ($x, $y) shows the bar\'s background, not the list (scrolled $scrolled)',
            );
          }
        }
      }
    },
  );
}
