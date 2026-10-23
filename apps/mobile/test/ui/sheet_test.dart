import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/press_button.dart';
import 'package:lukitas/ui/sheet.dart';
import 'package:lukitas/ui/toast.dart';

import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/theme/theme.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

/// `LkSheet`'s behaviour, as apps/web/app/ui/Sheet.tsx and its stories define it. How it looks is
/// test/parity/sheet_parity_test.dart's job.
class _Opener extends StatelessWidget {
  const _Opener({this.footer, this.onSave, this.pinned = const []});

  final List<Widget>? footer;
  final List<Widget> pinned;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) => PressButton.text(
    'Abrir',
    onPressed: () => LkSheet.show<void>(
      context,
      title: 'Agregar gasto',
      pinned: pinned,
      footer: footer,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: PressButton.text('Cancelar', tone: PressTone.secondary, onPressed: () {}),
            ),
            Expanded(child: PressButton.text('Guardar', onPressed: onSave)),
          ],
        ),
      ],
    ),
  );
}

Future<void> _open(WidgetTester t, {Widget? opener, bool disableAnimations = false}) async {
  await t.pumpWidget(uiApp(opener ?? const _Opener(), disableAnimations: disableAnimations));
  await t.tap(find.text('ABRIR'));
  await t.pumpAndSettle();
}

/// How far the sheet's top is from where it rests.
double _top(WidgetTester t) => t.getTopLeft(find.text('Agregar gasto')).dy;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('it opens as a dialog named by its title, with Cerrar', (t) async {
    final handle = t.ensureSemantics();
    await _open(t);
    expect(find.text('Agregar gasto'), findsOneWidget);
    expect(find.text('CERRAR'), findsOneWidget);
    expect(find.bySemanticsLabel('Agregar gasto'), findsWidgets);
    handle.dispose();
  });

  testWidgets('Cerrar closes it', (t) async {
    await _open(t);
    await t.tap(find.text('CERRAR'));
    await t.pumpAndSettle();
    expect(find.text('Agregar gasto'), findsNothing);
  });

  testWidgets('Escape closes it', (t) async {
    await _open(t);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(find.text('Agregar gasto'), findsNothing);
  });

  testWidgets('a tap on the backdrop closes it', (t) async {
    await _open(t);
    await t.tapAt(const Offset(200, 100));
    await t.pumpAndSettle();
    expect(find.text('Agregar gasto'), findsNothing);
  });

  testWidgets('a tap inside it does not close it, and a button inside it is pressed', (t) async {
    var saved = 0;
    await _open(t, opener: _Opener(onSave: () => saved++));
    await t.tap(find.text('GUARDAR'));
    await t.pumpAndSettle();
    expect(saved, 1);
    expect(find.text('Agregar gasto'), findsOneWidget);
  });

  testWidgets('it slides in over 260 ms and out again', (t) async {
    await t.pumpWidget(uiApp(const _Opener()));
    await t.tap(find.text('ABRIR'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 10));
    final early = _top(t);
    await t.pumpAndSettle();
    final rest = _top(t);
    expect(early, greaterThan(rest + 50), reason: 'still on its way up after 10 ms');
    await t.tap(find.text('CERRAR'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 130));
    expect(find.text('Agregar gasto'), findsOneWidget, reason: 'still sliding out');
    expect(_top(t), greaterThan(rest));
    await t.pumpAndSettle();
    expect(find.text('Agregar gasto'), findsNothing);
  });

  testWidgets('dragged down past a quarter of its height it closes on release', (t) async {
    await _open(t);
    final height = t.getSize(find.byType(Material).last).height;
    await t.timedDrag(
      find.text('GUARDAR'),
      Offset(0, height * 0.5),
      const Duration(milliseconds: 400),
    );
    await t.pumpAndSettle();
    expect(find.text('Agregar gasto'), findsNothing);
  });

  testWidgets('a drag that starts on a button never presses it', (t) async {
    var saved = 0;
    await _open(t, opener: _Opener(onSave: () => saved++));
    await t.timedDrag(
      find.text('GUARDAR'),
      const Offset(0, 120),
      const Duration(milliseconds: 400),
    );
    await t.pumpAndSettle();
    expect(saved, 0);
  });

  testWidgets('a short drag follows the finger and springs back', (t) async {
    await _open(t);
    final rest = _top(t);
    final gesture = await t.startGesture(t.getCenter(find.text('GUARDAR')));
    await gesture.moveBy(const Offset(0, 12));
    await gesture.moveBy(const Offset(0, 20));
    await t.pump();
    expect(_top(t), closeTo(rest + 32, 1), reason: 'it follows the finger 1:1 downward');
    await gesture.up();
    await t.pumpAndSettle();
    expect(_top(t), closeTo(rest, 0.5));
    expect(find.text('Agregar gasto'), findsOneWidget);
  });

  testWidgets('dragged up it resists: 0.3 of the finger', (t) async {
    await _open(t);
    final rest = _top(t);
    final gesture = await t.startGesture(t.getCenter(find.text('GUARDAR')));
    await gesture.moveBy(const Offset(0, -12));
    await gesture.moveBy(const Offset(0, -88));
    await t.pump();
    expect(rest - _top(t), closeTo(100 * 0.3, 4));
    await gesture.up();
    await t.pumpAndSettle();
    expect(_top(t), closeTo(rest, 0.5));
  });

  testWidgets('flicked down it closes even a short way', (t) async {
    await _open(t);
    await t.fling(find.text('GUARDAR'), const Offset(0, 60), 1500);
    await t.pumpAndSettle();
    expect(find.text('Agregar gasto'), findsNothing);
  });

  testWidgets('a sideways drag is not the sheet\'s', (t) async {
    await _open(t);
    final rest = _top(t);
    await t.drag(find.text('Agregar gasto'), const Offset(120, 10));
    await t.pumpAndSettle();
    expect(_top(t), closeTo(rest, 0.5));
    expect(find.text('Agregar gasto'), findsOneWidget);
  });

  testWidgets('under "remove animations" it only fades: no slide, no following the finger', (
    t,
  ) async {
    await _open(t, disableAnimations: true);
    final rest = _top(t);
    final gesture = await t.startGesture(t.getCenter(find.text('GUARDAR')));
    await gesture.moveBy(const Offset(0, 12));
    await gesture.moveBy(const Offset(0, 40));
    await t.pump();
    expect(_top(t), rest, reason: 'it does not follow');
    await gesture.moveBy(const Offset(0, 120));
    await gesture.up();
    await t.pumpAndSettle();
    expect(find.text('Agregar gasto'), findsNothing, reason: 'but a drag down still closes it');
  });

  testWidgets('with a footer: the pinned part and the footer stay, the middle scrolls', (t) async {
    await _open(
      t,
      opener: _Opener(pinned: const [Text('FIJO')], footer: const [Text('PIE')]),
    );
    expect(find.text('FIJO'), findsOneWidget);
    expect(find.text('PIE'), findsOneWidget);
    expect(find.text('GUARDAR'), findsOneWidget);
    // The footer is under the middle, at the bottom of the sheet.
    expect(t.getTopLeft(find.text('PIE')).dy, greaterThan(t.getTopLeft(find.text('GUARDAR')).dy));
    expect(t.getTopLeft(find.text('FIJO')).dy, lessThan(t.getTopLeft(find.text('GUARDAR')).dy));
  });

  testWidgets('it hosts the toasts while it is open and gives them back when it closes', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: nightTheme,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The host sits above the Navigator, as the app puts it.
        builder: (context, home) => ToastHost(dismissAfter: const Duration(hours: 1), child: home!),
        home: const Scaffold(
          body: Align(alignment: Alignment.topLeft, child: _Opener()),
        ),
      ),
    );
    final toasts = ToastHost.of(t.element(find.byType(_Opener)));
    await t.tap(find.text('ABRIR'));
    await t.pumpAndSettle();
    toasts.show(ToastOptions.text('Sin conexión'));
    await t.pumpAndSettle();
    // Inside the sheet: under its content, in the sheet's bottom (a bottom-of-the-screen toast would
    // sit lower than the sheet's own bottom padding).
    final guardar = t.getTopLeft(find.text('GUARDAR')).dy;
    expect(t.getTopLeft(find.text('Sin conexión')).dy, greaterThan(guardar));
    final sheetBottom = t.getBottomLeft(find.byType(Material).last).dy;
    expect(t.getBottomLeft(find.text('Sin conexión')).dy, lessThan(sheetBottom - 8));
    await t.tap(find.text('CERRAR'));
    await t.pumpAndSettle();
    expect(find.text('Sin conexión'), findsOneWidget, reason: 'back on the page');
  });
}
