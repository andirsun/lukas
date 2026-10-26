import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/settings/locale_resolution.dart';

void main() {
  // What the app will list once the Italian and Portuguese ARB files exist.
  const all = [Locale('es'), Locale('en'), Locale('it'), Locale('pt')];
  // What it lists today.
  const today = [Locale('es'), Locale('en')];

  group('resolveAppLocale', () {
    test('Italian reads it, whatever the region', () {
      expect(resolveAppLocale(const Locale('it'), all), const Locale('it'));
      expect(resolveAppLocale(const Locale('it', 'IT'), all), const Locale('it'));
      expect(resolveAppLocale(const Locale('it', 'CH'), all), const Locale('it'));
    });

    test('Portuguese reads pt, Brazil included', () {
      expect(resolveAppLocale(const Locale('pt'), all), const Locale('pt'));
      expect(resolveAppLocale(const Locale('pt', 'PT'), all), const Locale('pt'));
      expect(resolveAppLocale(const Locale('pt', 'BR'), all), const Locale('pt'));
    });

    test('Spanish and English keep their own', () {
      expect(resolveAppLocale(const Locale('es', 'CO'), all), const Locale('es'));
      expect(resolveAppLocale(const Locale('en', 'GB'), all), const Locale('en'));
    });

    test('anything else, or nothing, reads Spanish', () {
      expect(resolveAppLocale(const Locale('fr', 'FR'), all), const Locale('es'));
      expect(resolveAppLocale(const Locale('de'), all), const Locale('es'));
      expect(resolveAppLocale(null, all), const Locale('es'));
    });

    test('a language the app has no catalog for yet reads Spanish', () {
      expect(resolveAppLocale(const Locale('it', 'IT'), today), const Locale('es'));
      expect(resolveAppLocale(const Locale('pt', 'PT'), today), const Locale('es'));
      expect(resolveAppLocale(const Locale('en'), today), const Locale('en'));
    });
  });
}
