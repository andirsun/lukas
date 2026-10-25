import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/category_chip.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

/// `CategoryChip`'s behaviour, as apps/web/app/ui/CategoryChip.tsx and its stories define it. How it
/// looks is test/parity/category_chip_parity_test.dart's job.
const _forty = 'Supermercado, farmacia y cosas del hogar';

Widget _picker({required void Function(String) onSelect, String selected = 'super'}) => uiApp(
  SizedBox(
    width: 320,
    child: CategoryChipGrid(
      children: [
        for (final (id, glyph, label) in [
          ('super', '🛒', 'Supermercado'),
          ('food', '🍽️', 'Restaurante'),
          ('fun', '⭐', 'Ocio'),
          ('car', '🚗', 'Transporte'),
        ])
          CategoryChip(
            glyph: glyph,
            label: label,
            selected: selected == id,
            onSelect: () => onSelect(id),
          ),
      ],
    ),
  ),
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('tapping a chip selects it', (t) async {
    final chosen = <String>[];
    await t.pumpWidget(_picker(onSelect: chosen.add));
    await t.tap(find.text('Ocio'));
    expect(chosen, ['fun']);
  });

  testWidgets('Space on the focused chip selects it', (t) async {
    final chosen = <String>[];
    await t.pumpWidget(_picker(onSelect: chosen.add));
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    expect(chosen, ['food']);
  });

  testWidgets('each chip is a toggle named by its label; the glyph is not read', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(_picker(onSelect: (_) {}));
    expect(
      t.getSemantics(find.byType(CategoryChip).first),
      matchesSemantics(
        label: 'Supermercado',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    expect(
      t.getSemantics(find.byType(CategoryChip).at(2)).flagsCollection.isSelected,
      Tristate.isFalse,
    );
    handle.dispose();
  });

  testWidgets('the note is part of the chip\'s name', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(
      uiApp(
        SizedBox(
          width: 80,
          child: CategoryChip(
            glyph: '⭐',
            label: 'Ocio',
            note: 'archivada',
            selected: false,
            onSelect: () {},
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Ocio\narchivada'), findsOneWidget);
    handle.dispose();
  });

  // Review Focus 1 and 2: a 40-character name is cut off, whatever the width and font size.
  for (final scale in [1.0, 1.3]) {
    testWidgets('a 40-character name is cut off with an ellipsis at font size $scale, with no '
        'overflow', (t) async {
      await t.pumpWidget(
        uiApp(
          SizedBox(
            width: 360,
            child: CategoryChipGrid(
              children: [
                CategoryChip(
                  glyph: '🛒',
                  label: _forty,
                  note: _forty,
                  selected: true,
                  onSelect: () {},
                ),
                CategoryChip(glyph: '⭐', label: 'Ocio', selected: false, onSelect: () {}),
              ],
            ),
          ),
          width: 360,
          textScale: scale,
        ),
      );
      expect(t.takeException(), isNull);
      final cell = t.getSize(find.byType(CategoryChip).first).width;
      expect(cell, (360 - 3 * 8) / 4);
      final name = t.renderObject<RenderParagraph>(find.text(_forty).first);
      expect(name.didExceedMaxLines, isTrue);
      expect(t.getSize(find.text(_forty).first).width, lessThanOrEqualTo(cell));
    });
  }

  testWidgets('the grid lays chips out four to a row with an 8px gap', (t) async {
    await t.pumpWidget(
      uiApp(
        CategoryChipGrid(
          children: [
            for (var i = 0; i < 5; i++)
              CategoryChip(glyph: '⭐', label: 'C$i', selected: false, onSelect: () {}),
          ],
        ),
        width: 320,
      ),
    );
    final first = t.getTopLeft(find.byType(CategoryChip).at(0));
    final second = t.getTopLeft(find.byType(CategoryChip).at(1));
    final fifth = t.getTopLeft(find.byType(CategoryChip).at(4));
    expect(second.dx - first.dx, 74 + 8);
    expect(fifth.dx, first.dx);
    expect(fifth.dy, greaterThan(first.dy));
  });
}
