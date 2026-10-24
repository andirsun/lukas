import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_form.dart';

import '../home/fixtures.dart';
import 'add_form_test.dart' show form;

void main() {
  test('a category can be preselected (from its detail), and that is no typed input', () {
    final f = AddForm(locale: 'es', currency: 'COP', today: '2026-10-22', categoryId: 'cat-home')
      ..updateChoices([
        category('cat-groceries', 'Supermercado'),
        category('cat-home', 'Hogar'),
      ], []);
    expect(f.selected!.id, 'cat-home');
    expect(f.hasInput, isFalse, reason: 'a widget link may still replace the sheet');
  });

  test('a preselected category of another kind than the sheet\'s falls back to the first', () {
    final f = AddForm(locale: 'es', currency: 'COP', today: '2026-10-22', categoryId: 'cat-salary')
      ..updateChoices([
        category('cat-groceries', 'Supermercado'),
        category('cat-salary', 'Nómina', kind: 'income'),
      ], []);
    expect(f.selected!.id, 'cat-groceries');
  });

  test('without one the first category is selected, as before', () {
    expect(form().selected!.id, 'cat-groceries');
  });
}
