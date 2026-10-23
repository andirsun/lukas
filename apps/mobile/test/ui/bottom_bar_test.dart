import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/bottom_bar.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

/// `BottomBar`'s behaviour, as apps/web/app/ui/BottomBar.tsx and its stories define it (and the
/// 🎤 beside the ＋, spec decision 3). How it looks is test/parity/bottom_bar_parity_test.dart's
/// job, and test/ui/bottom_bar_golden_test.dart's for the 🎤.
Widget _bar({
  String current = 'home',
  List<String>? taps,
  VoidCallback? onAdd,
  VoidCallback? onMic,
  bool showMic = true,
  double width = 380,
}) => uiApp(
  BottomBar(
    current: current,
    showMic: showMic,
    onAdd: onAdd ?? () {},
    onMic: onMic ?? () {},
    onNavigate: (key) => taps?.add(key),
  ),
  width: width,
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Inicio and Análisis navigate; the ＋ adds; the 🎤 listens', (t) async {
    final taps = <String>[];
    var added = 0, mic = 0;
    await t.pumpWidget(_bar(taps: taps, onAdd: () => added++, onMic: () => mic++));
    await t.tap(find.text('Inicio'));
    await t.tap(find.text('Análisis'));
    await t.tap(find.text('＋'));
    await t.tap(find.text('🎤'));
    expect(taps, ['home', 'insights']);
    expect(added, 1);
    expect(mic, 1);
  });

  testWidgets('the current tab is marked; the others are not', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(_bar(current: 'insights'));
    expect(t.getSemantics(find.text('Análisis')).flagsCollection.isSelected.name, 'isTrue');
    expect(t.getSemantics(find.text('Inicio')).flagsCollection.isSelected.name, isNot('isTrue'));
    handle.dispose();
  });

  testWidgets('a section the bar has no tab for marks none', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(_bar(current: 'categories'));
    for (final name in ['Inicio', 'Análisis']) {
      expect(t.getSemantics(find.text(name)).flagsCollection.isSelected.name, isNot('isTrue'));
    }
    handle.dispose();
  });

  testWidgets('the bar, the ＋ and the 🎤 are named for screen readers', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(_bar());
    expect(find.bySemanticsLabel('Navegación principal'), findsOneWidget);
    expect(find.bySemanticsLabel('Agregar'), findsOneWidget);
    expect(find.bySemanticsLabel('Decir o escribir un gasto'), findsOneWidget);
    handle.dispose();
  });

  testWidgets(
    'the ＋ is 58px, rises 14px above the tabs and shares their bottom; the 🎤 is smaller, beside it',
    (t) async {
      await t.pumpWidget(_bar());
      final plus = t.getRect(
        find.ancestor(of: find.text('＋'), matching: find.byType(SizedBox)).first,
      );
      final mic = t.getRect(
        find.ancestor(of: find.text('🎤'), matching: find.byType(SizedBox)).first,
      );
      final home = t.getRect(
        find.ancestor(of: find.text('Inicio'), matching: find.byType(AnimatedContainer)).first,
      );
      expect(plus.size, const Size(58, 58));
      expect(home.top - plus.top, 14);
      expect(plus.bottom, home.bottom);
      expect(mic.size, const Size(44, 44));
      expect(mic.left - plus.right, 8);
      expect(mic.bottom, plus.bottom);
      // The ＋ is in the middle of the bar, where the web puts it.
      expect(plus.center.dx, 190);
    },
  );

  testWidgets('the tabs are 76 × 44 and the bar is 66px under its 4px of reach', (t) async {
    await t.pumpWidget(_bar());
    final home = t.getRect(
      find.ancestor(of: find.text('Inicio'), matching: find.byType(AnimatedContainer)).first,
    );
    expect(home.size, const Size(76, 44));
    expect(t.getSize(find.byType(BottomBar)).height, 70);
  });

  testWidgets('without the 🎤 (the parity pair) it is not there', (t) async {
    await t.pumpWidget(_bar(showMic: false));
    expect(find.text('🎤'), findsNothing);
  });

  testWidgets('a touch on the top of the ＋, above the bar\'s drawn box, still adds', (t) async {
    var added = 0;
    await t.pumpWidget(_bar(onAdd: () => added++));
    final plus = t.getRect(
      find.ancestor(of: find.text('＋'), matching: find.byType(SizedBox)).first,
    );
    await t.tapAt(Offset(plus.center.dx, plus.top + 2));
    expect(added, 1);
  });

  testWidgets('Tab goes Inicio, ＋, 🎤, Análisis; Enter presses', (t) async {
    final taps = <String>[];
    var added = 0, mic = 0;
    await t.pumpWidget(_bar(taps: taps, onAdd: () => added++, onMic: () => mic++));
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, ['home', 'insights']);
    expect(added, 1);
    expect(mic, 1);
  });

  testWidgets('at 130% on a 360px phone the labels do not overflow', (t) async {
    await t.pumpWidget(
      uiApp(
        BottomBar(current: 'home', onAdd: () {}, onMic: () {}, onNavigate: (_) {}),
        width: 360,
        textScale: 1.3,
      ),
    );
    expect(t.takeException(), isNull);
  });
}
