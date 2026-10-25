@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/name_field.dart';

import '../support/parity.dart';

/// `NameField` against apps/web/app/ui/NameField.stories.tsx (`ui-namefield--*`), each story as
/// Storybook shows it after its `play` function, in night and in day (`DayEnglish` pins day).
///
/// `TwoRowsAtMost` has no pair: the web measures its rows before the fonts have loaded, so the
/// story shows six of the ten shortcuts where the fonts' widths would show seven. The cap is a
/// behaviour test (test/ui/name_field_test.dart).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// Name, category name, category id.
const _recent = [
  ('continente', 'Supermercado', 'super'),
  ('pingo doce', 'Supermercado', 'super'),
  ('lidl', 'Supermercado', 'super'),
  ('café', 'Restaurante', 'food'),
  ('pintura', 'Casa', 'home'),
];

/// The stories' `NameFieldHarness`: typing filters the shortcuts (a prefix-then-contains filter),
/// picking one fills the name. `flex max-w-[340px] flex-col gap-2`.
class _Harness extends StatefulWidget {
  const _Harness({this.initial = ''});

  final String initial;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late final _controller = TextEditingController(text: widget.initial);
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// The `<output aria-label="category">` under the field: the picked category's id.
  String? _picked;

  List<(String, String, String)> get _suggestions {
    final query = _controller.text.trim().toLowerCase();
    final exact = _recent.any((s) => s.$1.toLowerCase() == query);
    if (query.isEmpty || exact) return _recent;
    return [
      ..._recent.where((s) => s.$1.toLowerCase().startsWith(query)),
      ..._recent.where(
        (s) => !s.$1.toLowerCase().startsWith(query) && s.$1.toLowerCase().contains(query),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => ParityStoryFrame(
    block: true,
    child: cssBlock(
      maxWidth: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          NameField(
            controller: _controller,
            focusNode: _focus,
            placeholder: 'Supermercado',
            suggestions: [
              for (final (name, category, _) in _suggestions)
                NameChoice(name: name, categoryName: category, source: name),
            ],
            onChanged: (_) => setState(() {}),
            onPick: (choice) {
              // As the add sheet does: a shortcut takes the keyboard away from the field.
              _focus.unfocus();
              setState(() {
                _controller.text = choice.name;
                _picked = _recent.firstWhere((s) => s.$1 == choice.name).$3;
              });
            },
          ),
          if (_picked != null) Text(_picked!),
        ],
      ),
    ),
  );
}

Future<void> _tab(WidgetTester t, int times) async {
  for (var i = 0; i < times; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('name field parity: empty ($theme)', (t) async {
      await parityGolden(t, 'name-field-empty', const _Harness(), theme: theme);
    });

    testWidgets('name field parity: continente picked ($theme)', (t) async {
      await parityGolden(
        t,
        'name-field-pick-shortcut',
        const _Harness(),
        theme: theme,
        act: (t) async {
          await t.tap(find.byKey(const Key('shortcut.continente')));
          await t.pumpAndSettle();
          // The click leaves the focus on the shortcut: the input, then the shortcut.
          await _tab(t, 2);
        },
      );
    });

    testWidgets('name field parity: pin typed, pintura picked ($theme)', (t) async {
      await parityGolden(
        t,
        'name-field-typing',
        const _Harness(),
        theme: theme,
        act: (t) async {
          await t.enterText(find.byKey(const Key('add.name')), 'pin');
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('shortcut.pintura')));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('name field parity: focus ring on the field, then on a shortcut ($theme)', (
      t,
    ) async {
      await parityGolden(
        t,
        'name-field-focus-and-press',
        const _Harness(),
        theme: theme,
        act: (t) => _tab(t, 2),
      );
    });
  }

  testWidgets('name field parity: lidl, day, English (day)', (t) async {
    await parityGolden(
      t,
      'name-field-day-english',
      const _Harness(initial: 'lidl'),
      theme: 'day',
      locale: const Locale('en'),
    );
  });
}
