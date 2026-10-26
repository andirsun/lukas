import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/home_controller.dart' show languageOfTag;
import 'package:lukitas/settings/locale_resolution.dart';

void main() {
  group('webPagePath', () {
    test('Spanish has no prefix, the others sit under their code', () {
      expect(webPagePath('es'), '/');
      expect(webPagePath('es', roadmap: true), '/roadmap');
      expect(webPagePath('en'), '/en');
      expect(webPagePath('it'), '/it');
      expect(webPagePath('pt', roadmap: true), '/pt/roadmap');
      expect(webPagePath('fr'), '/');
    });
  });

  group('languageOfTag', () {
    test('is the phone\'s language when the app has it, whatever the region', () {
      expect(languageOfTag('es-CO'), 'es');
      expect(languageOfTag('en-GB'), 'en');
      expect(languageOfTag('it-IT'), 'it');
      expect(languageOfTag('it_CH'), 'it');
      expect(languageOfTag('pt-PT'), 'pt');
      expect(languageOfTag('pt-BR'), 'pt');
      expect(languageOfTag('PT'), 'pt');
    });

    test('is Spanish for any other', () {
      expect(languageOfTag('fr-FR'), 'es');
      expect(languageOfTag(''), 'es');
      expect(languageOfTag('italian'), 'es');
    });
  });

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
