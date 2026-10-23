import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/page_header.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

/// `PageHeader`'s behaviour, as apps/web/app/ui/PageHeader.tsx defines it (it has no story, so no
/// parity pair yet).
Widget _header(VoidCallback onBack, {Widget? aside}) =>
    PageHeader(backLabel: 'Volver a Inicio', backShort: 'Inicio', onBack: onBack, aside: aside);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the back link reads "‹ INICIO" and goes back', (t) async {
    var back = 0;
    await t.pumpWidget(uiApp(_header(() => back++)));
    expect(find.text('INICIO'), findsOneWidget);
    expect(find.text('‹'), findsOneWidget);
    await t.tap(find.text('INICIO'));
    expect(back, 1);
  });

  testWidgets('it is a link named by its label', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(uiApp(_header(() {})));
    expect(find.bySemanticsLabel('Volver a Inicio'), findsOneWidget);
    expect(find.bySemanticsLabel('‹'), findsNothing);
    handle.dispose();
  });

  testWidgets('from 400px wide the aside sits beside the link', (t) async {
    await t.pumpWidget(uiApp(_header(() {}, aside: const Text('Octubre')), width: 412));
    final link = t.getRect(find.text('INICIO'));
    final aside = t.getRect(find.text('Octubre'));
    expect(aside.center.dy, closeTo(link.center.dy, 4));
    expect(aside.left, greaterThan(link.right));
  });

  testWidgets('under 400px the aside gets its own row, centred', (t) async {
    t.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 640);
    addTearDown(t.view.reset);
    await t.pumpWidget(uiApp(_header(() {}, aside: const Text('Octubre')), width: 360));
    final link = t.getRect(find.text('INICIO'));
    final aside = t.getRect(find.text('Octubre'));
    expect(aside.top, greaterThan(link.bottom));
    expect(aside.center.dx, closeTo(180, 1));
  });
}
