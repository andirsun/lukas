import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/web_text_field.dart';

import '../support/ui_app.dart';

/// What the phone's keyboard is told about a field: autocorrect never (a code, an address, a
/// sentence of amounts must not be "fixed"), and the suggestion strip only where a field asks.
void main() {
  Future<EditableText> pump(WidgetTester tester, {bool? enableSuggestions}) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      uiApp(
        WebTextField(
          fieldKey: const Key('field'),
          controller: controller,
          focusNode: focus,
          label: 'Campo',
          enableSuggestions: enableSuggestions ?? false,
        ),
      ),
    );
    return tester.widget<EditableText>(find.byKey(const Key('field')));
  }

  testWidgets('by default the keyboard offers neither suggestions nor autocorrect', (tester) async {
    final field = await pump(tester);

    expect(field.enableSuggestions, isFalse);
    expect(field.autocorrect, isFalse);
  });

  testWidgets('a field can keep the suggestion strip, and autocorrect stays off', (tester) async {
    final field = await pump(tester, enableSuggestions: true);

    expect(field.enableSuggestions, isTrue);
    expect(field.autocorrect, isFalse);
  });
}
