import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/theme/theme.dart';
import 'package:lukitas/ui/toast.dart';

import '../support/fonts.dart';

/// `ToastHost`'s behaviour, as apps/web/app/ui/Toast.tsx and its stories define it. How it looks
/// is test/parity/toast_parity_test.dart's job.
/// [dismissAfter] is an hour unless a test is about the time a toast stays: a settled test would
/// otherwise run its countdown out.
Widget _app({
  Duration? dismissAfter = const Duration(hours: 1),
  bool disableAnimations = false,
  double lift = 0,
}) => MaterialApp(
  theme: nightTheme,
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, home) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
    child: ToastHost(dismissAfter: dismissAfter, lift: lift, child: home!),
  ),
  home: const Scaffold(body: SizedBox.expand()),
);

ToastController _toasts(WidgetTester t) => ToastHost.of(t.element(find.byType(Scaffold)));

ToastAction _action(String label, [VoidCallback? run]) =>
    ToastAction(label: label, onPressed: run ?? () {});

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'a toast shows at the bottom, 16px from the edges, and its action runs and dismisses it',
    (t) async {
      // A phone: 412 × 915.
      t.view
        ..physicalSize = const Size(824, 1830)
        ..devicePixelRatio = 2;
      addTearDown(t.view.reset);
      var undone = 0;
      await t.pumpWidget(_app());
      _toasts(t).show(
        ToastOptions.text('Supermercado · −6,08 €', actions: [_action('Deshacer', () => undone++)]),
      );
      await t.pumpAndSettle();
      expect(find.text('Supermercado · −6,08 €'), findsOneWidget);
      final box = t.getRect(find.byType(ToastLayer));
      expect(box.left, 16);
      expect(box.right, 412 - 16);
      expect(915 - box.bottom, 16);
      await t.tap(find.text('Deshacer'));
      await t.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Supermercado · −6,08 €'), findsNothing);
    },
  );

  testWidgets('the actions are 44px targets', (t) async {
    await t.pumpWidget(_app());
    _toasts(t).show(ToastOptions.text('Hecho', actions: [_action('Deshacer')]));
    await t.pumpAndSettle();
    expect(t.getSize(find.text('Deshacer')).height, lessThan(44));
    final target = t.getRect(
      find.ancestor(of: find.text('Deshacer'), matching: find.byType(AnimatedContainer)),
    );
    expect(target.height, greaterThanOrEqualTo(44));
  });

  testWidgets('a newer toast replaces the current one instead of stacking', (t) async {
    await t.pumpWidget(_app());
    final toasts = _toasts(t);
    toasts.show(ToastOptions.text('Uno'));
    await t.pumpAndSettle();
    toasts.show(ToastOptions.text('Dos'));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Dos'), findsNothing, reason: 'the first leaves before the second comes');
    await t.pumpAndSettle();
    expect(find.text('Uno'), findsNothing);
    expect(find.text('Dos'), findsOneWidget);
  });

  testWidgets('without an action it stays 5 seconds; with one, 8', (t) async {
    await t.pumpWidget(_app(dismissAfter: null));
    final toasts = _toasts(t);
    toasts.show(ToastOptions.text('Sin acción'));
    await t.pump(const Duration(milliseconds: 4900));
    expect(find.text('Sin acción'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 200));
    await t.pumpAndSettle();
    expect(find.text('Sin acción'), findsNothing);

    toasts.show(ToastOptions.text('Con acción', actions: [_action('Deshacer')]));
    await t.pump(const Duration(milliseconds: 7900));
    expect(find.text('Con acción'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 200));
    await t.pumpAndSettle();
    expect(find.text('Con acción'), findsNothing);
  });

  testWidgets('a thin bar shows the time left, and a persistent toast has none', (t) async {
    await t.pumpWidget(_app());
    final toasts = _toasts(t);
    toasts.show(ToastOptions.text('Hecho', actions: [_action('Deshacer')]));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    ColoredBox bar() => t.widget<ColoredBox>(
      find.descendant(of: find.byType(FractionallySizedBox), matching: find.byType(ColoredBox)),
    );
    final fraction = t.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor!;
    expect(fraction, closeTo(1 - 0.4 / 8, 0.03));
    expect(bar().color, isNotNull);
    toasts.show(ToastOptions.text('Error', persistent: true, tone: ToastTone.error));
    await t.pumpAndSettle();
    expect(find.byType(FractionallySizedBox), findsNothing);
    await t.pump(const Duration(seconds: 30));
    expect(find.text('Error'), findsOneWidget);
  });

  testWidgets('a finger on the toast stops its countdown, and lifting it resumes where it was', (
    t,
  ) async {
    await t.pumpWidget(_app(dismissAfter: const Duration(milliseconds: 400)));
    _toasts(t).show(ToastOptions.text('Pausa'));
    await t.pump(const Duration(milliseconds: 300));
    final finger = await t.startGesture(t.getCenter(find.text('Pausa')));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Pausa'), findsOneWidget);
    await finger.up();
    await t.pumpAndSettle();
    expect(find.text('Pausa'), findsNothing);
  });

  testWidgets('the pointer over it stops the countdown; leaving resumes it', (t) async {
    await t.pumpWidget(_app(dismissAfter: const Duration(milliseconds: 400)));
    _toasts(t).show(ToastOptions.text('Pausa'));
    await t.pump(const Duration(milliseconds: 300));
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(t.getCenter(find.text('Pausa')));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('Pausa'), findsOneWidget);
    await mouse.moveTo(const Offset(5, 5));
    await t.pumpAndSettle();
    expect(find.text('Pausa'), findsNothing);
  });

  testWidgets('an action that shows another toast leaves that one on screen', (t) async {
    await t.pumpWidget(_app());
    final toasts = _toasts(t);
    toasts.show(
      ToastOptions.text(
        'Guardado',
        actions: [_action('Deshacer', () => toasts.show(ToastOptions.text('Restaurado')))],
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Deshacer'));
    await t.pumpAndSettle();
    expect(find.text('Restaurado'), findsOneWidget);
  });

  testWidgets('swiped down, or sideways, it goes; a short drag springs back', (t) async {
    await t.pumpWidget(_app());
    final toasts = _toasts(t);
    toasts.show(ToastOptions.text('Uno'));
    await t.pumpAndSettle();
    final short = await t.startGesture(t.getCenter(find.text('Uno')));
    await short.moveBy(const Offset(0, 24));
    await short.moveBy(const Offset(0, 24));
    await t.pump(const Duration(milliseconds: 300));
    await short.up();
    await t.pumpAndSettle();
    expect(find.text('Uno'), findsOneWidget, reason: 'too short: it comes back');

    await t.timedDrag(find.text('Uno'), const Offset(0, 90), const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    expect(find.text('Uno'), findsNothing);

    toasts.show(ToastOptions.text('Dos'));
    await t.pumpAndSettle();
    await t.timedDrag(find.text('Dos'), const Offset(140, 0), const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    expect(find.text('Dos'), findsNothing);
  });

  testWidgets('it sits above a bottom bar by the lift', (t) async {
    await t.pumpWidget(_app(lift: 92));
    _toasts(t).show(ToastOptions.text('Hecho'));
    await t.pumpAndSettle();
    final bottom = t.getRect(find.byType(ToastLayer)).bottom;
    expect(t.view.physicalSize.height / t.view.devicePixelRatio - bottom, 16 + 92);
  });

  testWidgets('an error toast is outlined in over and announced; reduced motion only fades it', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(_app(disableAnimations: true));
    _toasts(t).show(ToastOptions.text('Sin conexión', tone: ToastTone.error));
    await t.pump();
    await t.pump(const Duration(milliseconds: 130));
    final mid = t.getTopLeft(find.text('Sin conexión')).dy;
    await t.pumpAndSettle();
    expect(t.getTopLeft(find.text('Sin conexión')).dy, mid, reason: 'it never rises');
    expect(find.bySemanticsLabel('Sin conexión'), findsWidgets);
    handle.dispose();
  });

  testWidgets('say: a message with up to two actions, the extra one first; an error is outlined', (
    t,
  ) async {
    await t.pumpWidget(_app());
    var named = 0;
    var undone = 0;
    _toasts(t).say(
      'Supermercado · −6,08 €',
      actionLabel: 'Deshacer',
      onAction: () => undone++,
      extraLabel: 'Ponerle nombre',
      onExtra: () => named++,
    );
    await t.pumpAndSettle();
    expect(
      t.getTopLeft(find.text('Ponerle nombre')).dx,
      lessThan(t.getTopLeft(find.text('Deshacer')).dx),
    );
    await t.tap(find.text('Ponerle nombre'));
    await t.pumpAndSettle();
    expect((named, undone), (1, 0));
    expect(find.text('Supermercado · −6,08 €'), findsNothing, reason: 'an action takes it away');

    _toasts(t).say('Sin conexión', error: true);
    await t.pumpAndSettle();
    expect(find.text('Sin conexión'), findsOneWidget);
  });

  testWidgets(
    'a toast with no time bar running leaves on its timer alone, with no frames waiting',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: nightTheme,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, home) => ToastHost(animateBar: false, child: home!),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );
      _toasts(t).say('Hecho');
      // Settling does not run the five seconds out, as it would with the bar moving.
      await t.pumpAndSettle();
      expect(find.text('Hecho'), findsOneWidget);
      await t.pump(const Duration(seconds: 4));
      expect(find.text('Hecho'), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      expect(find.text('Hecho'), findsNothing);
    },
  );
}
