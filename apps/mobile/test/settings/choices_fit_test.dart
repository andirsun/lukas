// The language row has five choices in the app (the web's four and "Automático"). On a 360 px phone
// with the font at 130% they do not fit one line: no label may spill out of its box onto the next.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/settings/settings_parts.dart';
import 'package:lukitas/ui/pressable.dart';

import '../support/fonts.dart';
import '../support/ui_app.dart';

const _languages = ['Automático', 'Español', 'English', 'Italiano', 'Português'];

Widget _row(List<String> labels) => Choices<String>(
  legend: 'Idioma',
  value: labels.first,
  options: [for (final label in labels) Choice(label, label, key: ValueKey(label))],
  onChanged: (_) {},
);

Rect _box(WidgetTester t, String label) => t.getRect(
  find.ancestor(of: find.byKey(ValueKey(label)), matching: find.byType(Pressable)).first,
);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('at 360 px and 130%, every language label stays inside its own box', (t) async {
    await t.pumpWidget(uiApp(_row(_languages), width: 360, textScale: 1.3));
    for (final label in _languages) {
      final box = _box(t, label);
      final text = t.getRect(find.byKey(ValueKey(label)));
      expect(text.left, greaterThanOrEqualTo(box.left), reason: '$label spills left');
      expect(text.right, lessThanOrEqualTo(box.right), reason: '$label spills right');
    }
    for (var i = 0; i < _languages.length; i++) {
      for (var j = i + 1; j < _languages.length; j++) {
        final a = _box(t, _languages[i]);
        final b = _box(t, _languages[j]);
        expect(a.overlaps(b), isFalse, reason: '${_languages[i]} and ${_languages[j]} overlap');
      }
    }
  });

  testWidgets('where they fit, the choices stay on one line of equal boxes', (t) async {
    const theme = ['Automático', 'Noche', 'Día'];
    await t.pumpWidget(uiApp(_row(theme), width: 360, textScale: 1.3));
    final boxes = [for (final label in theme) _box(t, label)];
    expect(boxes.map((b) => b.top).toSet(), hasLength(1));
    expect(boxes.map((b) => b.width.round()).toSet(), hasLength(1));
  });
}
