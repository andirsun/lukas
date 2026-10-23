import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/confirm_sheet.dart';
import 'package:lukitas/ui/press_button.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

/// `ConfirmSheet`'s behaviour, as apps/web/app/ui/ConfirmSheet.tsx defines it.
class _Ask extends StatelessWidget {
  const _Ask({required this.onConfirm, this.note, this.result});

  final Future<void> Function() onConfirm;
  final String? note;
  final List<bool>? result;

  @override
  Widget build(BuildContext context) => PressButton.text(
    'Archivar',
    onPressed: () async {
      final done = await ConfirmSheet.show(
        context,
        title: '¿Archivar Ocio?',
        body: 'Ya no saldrá en tus presupuestos.',
        note: note,
        confirmLabel: 'Sí, archivar',
        onConfirm: onConfirm,
      );
      result?.add(done);
    },
  );
}

/// Opens the sheet on a phone [width] logical pixels wide.
Future<void> _open(WidgetTester t, Widget ask, {double width = 412}) async {
  t.view
    ..physicalSize = Size(width * 2, 1830)
    ..devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(uiApp(ask, width: width));
  await t.tap(find.text('ARCHIVAR'));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('it asks: the question, what it means, a note, Cancelar and the action', (t) async {
    await _open(t, _Ask(onConfirm: () async {}, note: 'También se detendrán 2 pagos recurrentes.'));
    expect(find.text('¿Archivar Ocio?'), findsOneWidget);
    expect(find.text('Ya no saldrá en tus presupuestos.'), findsOneWidget);
    expect(find.text('También se detendrán 2 pagos recurrentes.'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);
    expect(find.text('SÍ, ARCHIVAR'), findsOneWidget);
  });

  testWidgets('the action does it, then closes the sheet and answers true', (t) async {
    var done = 0;
    final result = <bool>[];
    await _open(t, _Ask(onConfirm: () async => done++, result: result));
    await t.tap(find.text('SÍ, ARCHIVAR'));
    await t.pumpAndSettle();
    expect(done, 1);
    expect(result, [true]);
    expect(find.text('¿Archivar Ocio?'), findsNothing);
  });

  testWidgets('Cancelar, Escape and the backdrop leave things as they were', (t) async {
    var done = 0;
    final result = <bool>[];
    await _open(t, _Ask(onConfirm: () async => done++, result: result));
    await t.tap(find.text('CANCELAR'));
    await t.pumpAndSettle();
    await t.tap(find.text('ARCHIVAR'));
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    await t.tap(find.text('ARCHIVAR'));
    await t.pumpAndSettle();
    await t.tapAt(const Offset(200, 60));
    await t.pumpAndSettle();
    expect(done, 0);
    expect(result, [false, false, false]);
  });

  testWidgets('a failure keeps the sheet open for another try', (t) async {
    var tries = 0;
    await _open(
      t,
      _Ask(
        onConfirm: () async {
          tries++;
          if (tries == 1) throw StateError('offline');
        },
      ),
    );
    await t.tap(find.text('SÍ, ARCHIVAR'));
    await t.pumpAndSettle();
    expect(find.text('¿Archivar Ocio?'), findsOneWidget);
    await t.tap(find.text('SÍ, ARCHIVAR'));
    await t.pumpAndSettle();
    expect(tries, 2);
    expect(find.text('¿Archivar Ocio?'), findsNothing);
  });

  testWidgets('while it works the action is disabled, so it never runs twice', (t) async {
    final gate = Completer<void>();
    var runs = 0;
    await _open(
      t,
      _Ask(
        onConfirm: () {
          runs++;
          return gate.future;
        },
      ),
    );
    await t.tap(find.text('SÍ, ARCHIVAR'));
    await t.pump();
    await t.tap(find.text('SÍ, ARCHIVAR'));
    await t.pump();
    expect(runs, 1);
    gate.complete();
    await t.pumpAndSettle();
  });

  testWidgets('from 400px the action is on the right; narrower it comes first, above Cancelar', (
    t,
  ) async {
    await _open(t, _Ask(onConfirm: () async {}));
    expect(
      t.getTopLeft(find.text('SÍ, ARCHIVAR')).dx,
      greaterThan(t.getTopLeft(find.text('CANCELAR')).dx),
    );
    await t.tap(find.text('CANCELAR'));
    await t.pumpAndSettle();

    await _open(t, _Ask(onConfirm: () async {}), width: 360);
    expect(
      t.getTopLeft(find.text('SÍ, ARCHIVAR')).dy,
      lessThan(t.getTopLeft(find.text('CANCELAR')).dy),
    );
  });
}
