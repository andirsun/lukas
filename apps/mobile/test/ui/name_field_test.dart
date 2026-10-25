import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/name_field.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

/// `NameField`'s behaviour, as apps/web/app/ui/NameField.tsx and its stories define it. How it looks
/// is test/parity/name_field_parity_test.dart's job. The rules of how many shortcuts fit are
/// test/add/shortcuts_fit_test.dart's.
const _recent = [
  ('continente', 'Supermercado'),
  ('pingo doce', 'Supermercado'),
  ('lidl', 'Supermercado'),
  ('café', 'Restaurante'),
  ('pintura', 'Casa'),
];

class _Field extends StatefulWidget {
  const _Field({this.names = _recent, this.initial = '', this.picked});

  final List<(String, String)> names;
  final String initial;
  final List<String>? picked;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final _controller = TextEditingController(text: widget.initial);
  final _focus = FocusNode();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 340,
    child: NameField(
      controller: _controller,
      focusNode: _focus,
      placeholder: 'Supermercado',
      suggestions: [
        for (final (name, category) in widget.names)
          NameChoice(name: name, categoryName: category, source: name),
      ],
      onChanged: (_) => setState(() {}),
      onPick: (choice) {
        widget.picked?.add(choice.name);
        setState(() => _controller.text = choice.name);
      },
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'empty: the placeholder is the name that will be used, and the shortcuts show names only',
    (t) async {
      await t.pumpWidget(uiApp(const _Field()));
      expect(
        find.text('Supermercado'),
        findsOneWidget,
        reason: 'the placeholder, not a category label',
      );
      for (final (name, _) in _recent) {
        expect(find.byKey(Key('shortcut.$name')), findsOneWidget);
      }
      expect(find.textContaining('·'), findsNothing);
    },
  );

  testWidgets('picking a shortcut calls onPick and fills the name; the matching one is marked', (
    t,
  ) async {
    final picked = <String>[];
    await t.pumpWidget(uiApp(_Field(picked: picked)));
    await t.tap(find.byKey(const Key('shortcut.continente')));
    await t.pumpAndSettle();
    expect(picked, ['continente']);
    expect(t.widget<EditableText>(find.byKey(const Key('add.name'))).controller.text, 'continente');
    expect(find.textContaining('✓'), findsOneWidget);
  });

  testWidgets(
    'typing reports each change; shortcuts are labelled with their category while typing',
    (t) async {
      await t.pumpWidget(
        uiApp(
          const _Field(
            names: [('pingo doce', 'Supermercado'), ('pintura', 'Casa')],
            initial: 'pin',
          ),
        ),
      );
      final handle = t.ensureSemantics();
      expect(find.bySemanticsLabel('pingo doce · Supermercado'), findsOneWidget);
      expect(find.bySemanticsLabel('pintura · Casa'), findsOneWidget);
      expect(find.textContaining('✓'), findsNothing);
      handle.dispose();
    },
  );

  testWidgets('each shortcut is a button named by its text, a toggle marked when it matches', (
    t,
  ) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(uiApp(const _Field(initial: 'lidl')));
    expect(find.bySemanticsLabel('Nombre (opcional)'), findsOneWidget);
    expect(find.bySemanticsLabel('Nombres recientes'), findsOneWidget);
    expect(find.bySemanticsLabel('lidl'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the field is at least 44px high and its shortcuts are 44px targets', (t) async {
    await t.pumpWidget(uiApp(const _Field()));
    expect(t.getSize(find.byKey(const Key('add.name'))).height, lessThan(44));
    final field = find
        .ancestor(of: find.byKey(const Key('add.name')), matching: find.byType(ConstrainedBox))
        .first;
    expect(t.getSize(find.byKey(const Key('shortcut.lidl'))).height, greaterThanOrEqualTo(44));
    expect(field, findsOneWidget);
  });

  testWidgets(
    'only the two rows that fit show: the rest are out of sight and out of the tab order',
    (t) async {
      const many = [
        'lidl',
        'desayuno',
        'filtro cafetera delonghi',
        'continente',
        'contador octubre',
        'gas y luz',
        'super',
        'almuerzo con papás Rita',
        'farmacia',
        'gasolina',
      ];
      await t.pumpWidget(uiApp(_Field(names: [for (final name in many) (name, 'Casa')])));
      final shown = [
        for (final name in many)
          if (find.byKey(Key('shortcut.$name')).evaluate().isNotEmpty) name,
      ];
      expect(shown.length, inInclusiveRange(5, 9));
      expect(shown, many.take(shown.length).toList(), reason: 'the first ones are kept, in order');
      final rows = {for (final name in shown) t.getTopLeft(find.byKey(Key('shortcut.$name'))).dy};
      expect(rows.length, 2);
    },
  );

  testWidgets('the field takes a ring while it has focus, and Tab then reaches the shortcuts', (
    t,
  ) async {
    await t.pumpWidget(uiApp(const _Field()));
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(find.byKey(const Key('add.name')), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.context?.widget,
      isA<Focus>().or(isA<EditableText>()),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(find.textContaining('✓'), findsOneWidget, reason: 'Enter picked the first shortcut');
  });

  testWidgets('a name longer than 120 characters is cut', (t) async {
    await t.pumpWidget(uiApp(const _Field()));
    await t.enterText(find.byKey(const Key('add.name')), 'x' * 130);
    await t.pump();
    final text = t.widget<EditableText>(find.byKey(const Key('add.name'))).controller.text;
    expect(text.length, 120);
  });
}

extension on TypeMatcher<Focus> {
  Matcher or(Matcher other) => anyOf(this, other);
}
