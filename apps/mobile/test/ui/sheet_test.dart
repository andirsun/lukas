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
  const _Opener({this.footer, this.onSave, this.pinned = const [], this.rows = 0});

  final List<Widget>? footer;

  /// Lines under the buttons, to make the content taller than the sheet.
  final int rows;
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
        for (var i = 0; i < rows; i++) SizedBox(height: 48, child: Text('Fila $i')),
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

  testWidgets(
    'it leaves the way the web does: fast first, decelerating (the curve flipped on exit)',
    (t) async {
      await _open(t);
      final panel = find.byType(Material).last;
      final rest = t.getTopLeft(panel).dy;
      final height = t.getSize(panel).height;
      await t.tap(find.text('CERRAR'));
      await t.pump();
      // The first frame starts the animation; a quarter of the 260 ms later it has covered what the web's
      // `cubic-bezier(0.32, 0.72, 0, 1)` covers a quarter of the way through: more than half the way out.
      await t.pump(const Duration(milliseconds: 65));
      const web = Cubic(0.32, 0.72, 0, 1);
      final out = (t.getTopLeft(panel).dy - rest) / height;
      expect(out, closeTo(web.transform(0.25), 0.05));
      expect(
        out,
        greaterThan(0.4),
        reason: 'a sheet that dawdled before leaving would be near 0.05',
      );
      await t.pumpAndSettle();
    },
  );

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

  testWidgets('with a footer, a drag up on content taller than the sheet scrolls it', (t) async {
    await _open(t, opener: const _Opener(rows: 40, footer: [Text('PIE')]));
    final top = _top(t);
    final before = t.getTopLeft(find.text('Fila 3')).dy;
    await t.drag(find.text('Fila 3'), const Offset(0, -300));
    await t.pumpAndSettle();
    expect(
      t.getTopLeft(find.text('Fila 3')).dy,
      lessThan(before - 200),
      reason: 'the middle scrolls',
    );
    expect(_top(t), top, reason: 'the sheet stays where it is');
  });

  // On a phone frames are drawn between the finger's moves, so whatever the sheet does on the touch
  // going down is laid out before the drag decides its axis (`t.drag` sends the moves at once).
  for (final footer in [true, false]) {
    testWidgets('a drag up scrolls it with frames between the moves, as on a phone '
        '(${footer ? 'with' : 'without'} a footer)', (t) async {
      await _open(t, opener: _Opener(rows: 40, footer: footer ? const [Text('PIE')] : null));
      final top = _top(t);
      final before = t.getTopLeft(find.text('Fila 3')).dy;
      final finger = await t.startGesture(t.getCenter(find.text('Fila 3')));
      await t.pump(const Duration(milliseconds: 16));
      for (var i = 0; i < 15; i++) {
        await finger.moveBy(const Offset(0, -20));
        await t.pump(const Duration(milliseconds: 16));
      }
      await finger.up();
      await t.pumpAndSettle();
      expect(
        t.getTopLeft(find.text('Fila 3')).dy,
        lessThan(before - 200),
        reason: 'the content scrolls',
      );
      // Without a footer the title scrolls with the rest.
      if (footer) expect(_top(t), top, reason: 'the sheet stays where it is');
    });
  }

  testWidgets('without a footer, a drag up on content taller than the sheet scrolls it', (t) async {
    await _open(t, opener: const _Opener(rows: 40));
    final before = t.getTopLeft(find.text('Fila 3')).dy;
    await t.drag(find.text('Fila 3'), const Offset(0, -300));
    await t.pumpAndSettle();
    expect(t.getTopLeft(find.text('Fila 3')).dy, lessThan(before - 200));
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

  group('not dismissible', () {
    final answers = <bool?>[];

    Widget opener({bool Function()? backResult}) => Builder(
      builder: (context) => PressButton.text(
        'Abrir',
        onPressed: () async => answers.add(
          await LkSheet.show<bool>(
            context,
            title: 'Avisos',
            dismissible: false,
            backResult: backResult,
            children: [PressButton.text('Sí', onPressed: () => Navigator.of(context).pop(true))],
          ),
        ),
      ),
    );

    setUp(answers.clear);

    testWidgets('no Cerrar, and Escape, the backdrop and a drag leave it open', (t) async {
      await _open(t, opener: opener());
      expect(find.text('Avisos'), findsOneWidget);
      expect(find.text('CERRAR'), findsNothing);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      await t.tapAt(const Offset(200, 100));
      await t.pumpAndSettle();
      final height = t.getSize(find.byType(Material).last).height;
      await t.timedDrag(find.text('SÍ'), Offset(0, height), const Duration(milliseconds: 300));
      await t.pumpAndSettle();
      expect(find.text('Avisos'), findsOneWidget);
      expect(answers, isEmpty);
    });

    testWidgets('its own button closes it with the answer', (t) async {
      await _open(t, opener: opener());
      await t.tap(find.text('SÍ'));
      await t.pumpAndSettle();
      expect(find.text('Avisos'), findsNothing);
      expect(answers, [true]);
    });

    testWidgets('the back button does nothing without a backResult', (t) async {
      await _open(t, opener: opener());
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('Avisos'), findsOneWidget);
    });

    testWidgets('the back button closes it with the backResult', (t) async {
      await _open(t, opener: opener(backResult: () => false));
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('Avisos'), findsNothing);
      expect(answers, [false]);
    });

    testWidgets('a pop from the app itself closes it with a null answer', (t) async {
      await _open(t, opener: opener(backResult: () => false));
      Navigator.of(t.element(find.text('Avisos'))).pop();
      await t.pumpAndSettle();
      expect(find.text('Avisos'), findsNothing);
      expect(answers, [null]);
    });
  });
}
