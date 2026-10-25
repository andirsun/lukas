@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/category_chip.dart';

import '../support/parity.dart';

/// `CategoryChip` against apps/web/app/ui/CategoryChip.stories.tsx (`ui-categorychip--*`), each
/// story as Storybook shows it after its `play` function, in night and in day (`Day` pins day).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

const _categories = [
  ('super', '🛒', 'Supermercado'),
  ('food', '🍽️', 'Restaurante'),
  ('fun', '⭐', 'Ocio'),
  ('car', '🚗', 'Transporte'),
];

/// The story's `Picker`: the add sheet's picker, `lk-chips max-w-[320px]`, with one selected.
class _Picker extends StatefulWidget {
  const _Picker();

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  var _selected = 'super';

  @override
  Widget build(BuildContext context) => cssBlock(
    maxWidth: 320,
    child: CategoryChipGrid(
      children: [
        for (final (id, glyph, label) in _categories)
          CategoryChip(
            glyph: glyph,
            label: label,
            selected: _selected == id,
            onSelect: () => setState(() => _selected = id),
          ),
      ],
    ),
  );
}

Widget _picker() => const ParityStoryFrame(block: true, child: _Picker());

/// `LongName`: a 40-character name, and a note under another chip.
Widget _longName() => ParityStoryFrame(
  block: true,
  child: cssBlock(
    maxWidth: 320,
    child: CategoryChipGrid(
      children: [
        CategoryChip(
          glyph: '🛒',
          label: 'Supermercado, farmacia y cosas del hogar',
          selected: true,
          onSelect: () {},
        ),
        CategoryChip(
          glyph: '⭐',
          label: 'Ocio',
          note: 'archivada',
          selected: false,
          onSelect: () {},
        ),
        CategoryChip(glyph: '🚗', label: 'Transporte', selected: false, onSelect: () {}),
      ],
    ),
  ),
);

Future<void> _tab(WidgetTester t, int times) async {
  for (var i = 0; i < times; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('category chip parity: picker, Ocio tapped ($theme)', (t) async {
      await parityGolden(
        t,
        'category-chip-picker',
        _picker(),
        theme: theme,
        act: (t) async {
          await t.tap(find.text('Ocio'));
          await t.pumpAndSettle();
          await _tab(t, 3);
        },
      );
    });

    testWidgets('category chip parity: pressed and focused, Restaurante chosen by keys ($theme)', (
      t,
    ) async {
      await parityGolden(
        t,
        'category-chip-press-and-focus',
        _picker(),
        theme: theme,
        act: (t) async {
          await _tab(t, 2);
          await t.sendKeyEvent(LogicalKeyboardKey.space);
        },
      );
    });

    testWidgets('category chip parity: a 40-character name is cut off ($theme)', (t) async {
      await parityGolden(t, 'category-chip-long-name', _longName(), theme: theme);
    });
  }

  testWidgets('category chip parity: day (day)', (t) async {
    await parityGolden(t, 'category-chip-day', _picker(), theme: 'day');
  });
}
