import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/categories/category_model.dart';
import 'package:lukitas/home/category_look.dart';

import '../home/fixtures.dart';

Recurrence rule(String categoryId, {String? endDate, String id = 'r'}) => Recurrence(
  (b) => b
    ..id = id
    ..name = 'Spotify'
    ..amount = -3500
    ..categoryId = categoryId
    ..frequency = RecurrenceFrequencyEnum.monthly
    ..dayOfMonth = 2
    ..startDate = '2026-01-01'
    ..endDate = endDate,
);

void main() {
  group('the form of a category', () {
    test('a new one starts blank: spending, the first emoji and the first tint', () {
      final blank = NewCategory.blank();
      expect(blank.name, '');
      expect(blank.kind, CategoryKindEnum.expense);
      expect(blank.glyph, '🏷️');
      expect(blank.tint, '#ff9f1c');
    });

    test('an existing one starts from its own name, look and kind', () {
      final form = NewCategory.of(
        category('cat-fun', 'Ocio', kind: 'income', icon: '⭐', color: '#a66bff'),
      );
      expect(
        (form.name, form.glyph, form.tint, form.kind),
        ('Ocio', '⭐', '#a66bff', CategoryKindEnum.income),
      );
    });

    test('an importer\'s category is shown with the emoji and the hex it stands for', () {
      final form = NewCategory.of(category('c', 'Súper', icon: 'cart', color: 'orange'));
      expect(form.glyph, '🛒');
      expect(form.tint, '#ff9f1c');
    });

    test(
      'a colour that is nothing becomes gray; an upper case hex stays as it is, as on the web',
      () {
        expect(NewCategory.of(category('c', 'A', color: 'nope')).tint, '#8e87b8');
        expect(NewCategory.of(category('c', 'A', color: '#FF9F1C')).tint, '#FF9F1C');
      },
    );

    test('each pickable tint is the hex the web saves', () {
      expect(
        [for (final name in categoryTintNames) categoryTintHex(name)],
        [
          '#ff9f1c',
          '#ff5c7a',
          '#a66bff',
          '#6d6bff',
          '#3fa7ff',
          '#5ac8fa',
          '#ff8fd8',
          '#ffb547',
          '#ffe66d',
          '#2fd388',
          '#2ec4b6',
          '#8e87b8',
        ],
      );
    });

    test('the emoji offered start with the category\'s own, each once', () {
      expect(glyphChoices('🏷️').length, categoryGlyphs.length);
      expect(glyphChoices('🏷️').first, '🏷️');
      final own = glyphChoices('🦄');
      expect(own.first, '🦄');
      expect(own.length, categoryGlyphs.length + 1);
      expect(glyphChoices('⭐').first, '⭐');
      expect(glyphChoices('⭐').where((g) => g == '⭐'), hasLength(1));
    });
  });

  group('the recurring payments archiving stops', () {
    test('counts the category\'s own rules not ended before today', () {
      final rules = [
        rule('a', id: '1'),
        rule('a', endDate: '2026-10-22', id: '2'),
        rule('a', endDate: '2026-10-21', id: '3'),
        rule('b', id: '4'),
      ];
      expect(activeRecurrencesIn(rules, 'a', '2026-10-22'), 2);
      expect(activeRecurrencesIn(rules, 'b', '2026-10-22'), 1);
      expect(activeRecurrencesIn(rules, 'c', '2026-10-22'), 0);
    });
  });
}
