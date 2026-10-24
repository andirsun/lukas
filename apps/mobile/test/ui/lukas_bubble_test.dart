import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/lukitas_face.dart';
import 'package:lukitas/ui/lukas_bubble.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

/// `LukasBubble`'s behaviour, as apps/web/app/ui/LukasBubble.tsx and its stories define it. How it
/// looks is test/parity/lukas_bubble_parity_test.dart's job.
const _month = 'Vas muy bien: te quedan 501,13 € para 11 días.';
const _paid = 'Pagaste «gym»: 32,00 €. Vas cumpliendo.';

double _opacity(WidgetTester t) => t
    .widget<FadeTransition>(
      find.descendant(of: find.byType(LukasBubble), matching: find.byType(FadeTransition)),
    )
    .opacity
    .value;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('it shows Lukas\'s line beside him', (t) async {
    await t.pumpWidget(
      uiApp(const LukasBubble(message: _month, mood: LukitasMood.happy), width: 390),
    );
    expect(find.text(_month), findsOneWidget);
    expect(find.byType(LukitasFace), findsOneWidget);
  });

  testWidgets('Lukas is decorative: the line is what screen readers get', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(
      uiApp(const LukasBubble(message: _month, mood: LukitasMood.worried), width: 390),
    );
    expect(find.bySemanticsLabel('Lukitas'), findsNothing);
    final line = t.getSemantics(find.text(_month));
    expect(line.flagsCollection.isLiveRegion, isTrue);
    expect(line.label, _month);
    handle.dispose();
  });

  testWidgets('a new line fades in from faint over --fade (160 ms)', (t) async {
    Widget bubble(String message) =>
        uiApp(LukasBubble(message: message, mood: LukitasMood.happy), width: 390);
    await t.pumpWidget(bubble(_month));
    expect(_opacity(t), 1);
    await t.pumpWidget(bubble(_paid));
    await t.pump();
    expect(_opacity(t), closeTo(0.25, 0.01), reason: 'from faint, never from nothing');
    await t.pump(const Duration(milliseconds: 80));
    expect(_opacity(t), inExclusiveRange(0.25, 1));
    await t.pump(const Duration(milliseconds: 100));
    expect(_opacity(t), 1);
  });

  testWidgets('with "remove animations" a new line just shows', (t) async {
    Widget bubble(String message) => uiApp(
      LukasBubble(message: message, mood: LukitasMood.happy),
      width: 390,
      disableAnimations: true,
    );
    await t.pumpWidget(bubble(_month));
    await t.pumpWidget(bubble(_paid));
    await t.pump();
    expect(_opacity(t), 1);
  });

  testWidgets('the same line again does not fade', (t) async {
    Widget bubble() =>
        uiApp(const LukasBubble(message: _month, mood: LukitasMood.happy), width: 390);
    await t.pumpWidget(bubble());
    await t.pumpWidget(bubble());
    await t.pump();
    expect(_opacity(t), 1);
  });

  testWidgets('a new quietKey makes a new live region, so the line is not read out again', (
    t,
  ) async {
    Widget bubble(String message, int quietKey) => uiApp(
      LukasBubble(message: message, mood: LukitasMood.happy, quietKey: quietKey),
      width: 390,
    );
    await t.pumpWidget(bubble(_month, 0));
    final first = t.element(find.text(_month));
    await t.pumpWidget(bubble(_paid, 0));
    expect(t.element(find.text(_paid)), first, reason: 'the same region: announced');
    await t.pumpAndSettle();
    await t.pumpWidget(bubble(_month, 1));
    await t.pumpAndSettle();
    expect(t.element(find.text(_month)), isNot(first), reason: 'a new region: not announced');
  });

  testWidgets('a long line at 130% on a 360px phone wraps and does not overflow', (t) async {
    await t.pumpWidget(
      uiApp(
        const LukasBubble(
          message: '¡Vas bien! Te quedan 11 días y aún tienes margen para casi todo el mes.',
          mood: LukitasMood.happy,
        ),
        width: 360,
        textScale: 1.3,
      ),
    );
    expect(t.takeException(), isNull);
  });
}
