import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/categories/normalize_name.dart';

/// `normalizeName` (apps/web/app/features/onboarding/suggested-categories.ts): lowercase and
/// without accents, `ñ` included, as `normalize("NFD")` and dropping the marks does.
void main() {
  test('lowercases and drops accents, in either language', () {
    expect(normalizeName('Salário'), 'salario');
    expect(normalizeName('Supermercado'), 'supermercado');
    expect(normalizeName('  Ocio  '), 'ocio');
    expect(normalizeName('ÁÉÍÓÚ Ü'), 'aeiou u');
    expect(normalizeName('Compañía'), 'compania');
    expect(normalizeName('Niño'), 'nino');
    expect(normalizeName('Zürich ç'), 'zurich c');
  });

  test('drops accents that arrive decomposed', () {
    expect(normalizeName('Salário'), 'salario');
    expect(normalizeName('Ñ'), 'n');
  });

  test('leaves what has no accent alone', () {
    expect(normalizeName('Taxes'), 'taxes');
    expect(normalizeName('Café 2'), 'cafe 2');
    expect(normalizeName('日本'), '日本');
  });
}
