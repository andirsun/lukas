import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/entry/code_input.dart';
import 'package:lukitas/ui/pressable.dart';

import '../support/ui_app.dart';

/// `CodeInput` (the web's CodeInput.tsx): six boxes over one field.
void main() {
  late TextEditingController controller;
  late FocusNode focus;

  setUp(() {
    controller = TextEditingController();
    focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
  });

  Future<void> pumpInput(
    WidgetTester tester, {
    bool invalid = false,
    bool readOnly = false,
    Size size = const Size(412, 800),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      uiApp(
        width: size.width,
        Padding(
          padding: const EdgeInsets.all(16),
          child: CodeInput(
            fieldKey: const Key('code'),
            controller: controller,
            focusNode: focus,
            label: 'Código de 6 dígitos',
            invalid: invalid,
            readOnly: readOnly,
          ),
        ),
      ),
    );
  }

  /// The boxes that wear the focus ring, by position.
  List<int> ringed(WidgetTester tester) {
    final rings = tester.widgetList<RingBox>(find.byType(RingBox)).toList();
    return [
      for (var i = 0; i < rings.length; i++)
        if (rings[i].radius != null) i,
    ];
  }

  testWidgets('the boxes show the digits typed, left to right, one each', (tester) async {
    await pumpInput(tester);
    await tester.enterText(find.byKey(const Key('code')), '48');
    await tester.pump();

    for (final digit in ['4', '8']) {
      expect(find.text(digit), findsOneWidget);
    }
    expect(find.byType(RingBox), findsNWidgets(6));
  });

  testWidgets('only digits count, and a seventh is not taken', (tester) async {
    await pumpInput(tester);
    final field = find.byKey(const Key('code'));
    await tester.enterText(field, 'a1b2');
    expect(controller.text, '12');
    await tester.enterText(field, '1234567');
    expect(controller.text, '123456');
  });

  testWidgets('a whole code pasted over digits already typed replaces them', (tester) async {
    await pumpInput(tester);
    final field = find.byKey(const Key('code'));
    await tester.enterText(field, '12');
    await tester.enterText(field, '12987-654');
    expect(controller.text, '987654');
    await tester.enterText(field, 'Tu código: 135 790');
    expect(controller.text, '135790');
  });

  testWidgets('a tap on the boxes focuses the field and opens the keyboard', (tester) async {
    await pumpInput(tester);
    expect(focus.hasFocus, isFalse);
    expect(ringed(tester), isEmpty);

    await tester.tapAt(tester.getCenter(find.byType(RingBox).at(2)));
    await tester.pump();

    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    // The first box is the next to type.
    expect(ringed(tester), [0]);
  });

  testWidgets('the ring moves to the next box as digits come, and stays on the last', (
    tester,
  ) async {
    await pumpInput(tester);
    await tester.tapAt(tester.getCenter(find.byType(RingBox).at(2)));
    final field = find.byKey(const Key('code'));
    await tester.enterText(field, '1');
    await tester.pump();
    expect(ringed(tester), [1]);
    await tester.enterText(field, '12345');
    await tester.pump();
    expect(ringed(tester), [5]);
    await tester.enterText(field, '123456');
    await tester.pump();
    expect(ringed(tester), [5]);
  });

  testWidgets('while the code is checked, typing is ignored', (tester) async {
    controller.text = '123456';
    await pumpInput(tester, readOnly: true);
    await tester.enterText(find.byKey(const Key('code')), '654321');
    await tester.pump();
    expect(controller.text, '123456');
  });

  testWidgets('the field has one name for assistive technology, and the boxes are hidden', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpInput(tester);
    expect(find.bySemanticsLabel('Código de 6 dígitos'), findsWidgets);
    // Six drawn boxes are not six fields.
    expect(find.byType(EditableText), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a box is at least 44px wide on a phone 320px wide, and at most 56px on a big one', (
    tester,
  ) async {
    await pumpInput(tester, size: const Size(320, 640));
    final narrow = tester.getSize(find.byType(RingBox).first).width;
    expect(narrow, greaterThanOrEqualTo(44));
    // The six fit the width with 4px between them under 360px.
    final row = tester.getRect(find.byType(RingBox).first);
    final last = tester.getRect(find.byType(RingBox).last);
    expect(last.right - row.left, lessThanOrEqualTo(320 - 32 + 0.01));

    await pumpInput(tester, size: const Size(1000, 800));
    expect(tester.getSize(find.byType(RingBox).first).width, 56);
  });
}
