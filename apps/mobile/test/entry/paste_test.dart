import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/entry/code_input.dart';
import 'package:lukitas/ui/pressable.dart' show RingBox;
import 'package:lukitas/ui/web_text_field.dart';

import '../support/ui_app.dart';

/// A long press on the fields of the entry screens shows the phone's own menu, with "Pegar": the
/// person copies the code from their mail app and pastes it here. (The old Material text fields
/// gave this for free; the web-styled ones are bare `EditableText`s and ask for it.)
void main() {
  late TextEditingController controller;
  late FocusNode focus;

  setUp(() {
    controller = TextEditingController();
    focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
  });

  /// The phone's clipboard, holding [text].
  void clipboardHolds(WidgetTester tester, String text) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      switch (call.method) {
        case 'Clipboard.getData':
          return <String, Object?>{'text': text};
        case 'Clipboard.hasStrings':
          return <String, Object?>{'value': true};
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  Future<void> pump(WidgetTester tester, Widget field) async {
    tester.view
      ..physicalSize = const Size(412, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      uiApp(Padding(padding: const EdgeInsets.fromLTRB(16, 200, 16, 16), child: field)),
    );
  }

  Future<void> longPressAndPaste(WidgetTester tester, Finder where) async {
    await tester.longPressAt(tester.getCenter(where));
    await tester.pumpAndSettle();
    expect(find.text('Pegar'), findsOneWidget);
    await tester.tap(find.text('Pegar'));
    await tester.pumpAndSettle();
  }

  testWidgets('the code field: a long press shows "Pegar", and a pasted code fills the boxes', (
    tester,
  ) async {
    clipboardHolds(tester, 'Tu código: 482 913');
    await pump(
      tester,
      CodeInput(
        fieldKey: const Key('code'),
        controller: controller,
        focusNode: focus,
        label: 'Código de 6 dígitos',
      ),
    );

    await longPressAndPaste(tester, find.byType(RingBox).at(2));

    expect(controller.text, '482913');
    for (final digit in ['4', '8', '2', '9', '1', '3']) {
      expect(find.text(digit), findsOneWidget);
    }
  });

  testWidgets('the code field: a pasted code replaces digits already typed', (tester) async {
    clipboardHolds(tester, '135790');
    await pump(
      tester,
      CodeInput(
        fieldKey: const Key('code'),
        controller: controller,
        focusNode: focus,
        label: 'Código de 6 dígitos',
      ),
    );
    await tester.enterText(find.byKey(const Key('code')), '12');

    await longPressAndPaste(tester, find.byType(RingBox).at(2));

    expect(controller.text, '135790');
  });

  testWidgets('the email field: a long press shows "Pegar", and the address is pasted', (
    tester,
  ) async {
    clipboardHolds(tester, 'ana@correo.com');
    await pump(
      tester,
      WebTextField(
        fieldKey: const Key('email'),
        controller: controller,
        focusNode: focus,
        label: 'Tu correo',
        placeholder: 'ana@correo.com',
      ),
    );

    await longPressAndPaste(tester, find.byType(WebTextField));

    expect(controller.text, 'ana@correo.com');
  });
}
