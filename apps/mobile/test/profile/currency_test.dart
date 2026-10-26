import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/profile/currency.dart';

/// The web's `defaultCurrency` tests (apps/web/app/features/onboarding/onboarding.test.ts), one for
/// one, and the rule behind them (`defaultCurrencyFor`, packages/core/src/default-currency.ts).
void main() {
  group('defaultCurrency', () {
    // The rule (founder, 2026-10-21): Colombia -> COP; Europe -> EUR; anywhere else -> USD.
    final cases = <(List<String>, String?, String)>[
      (['es-CO'], 'America/Bogota', 'COP'),
      (['es-CO'], 'Europe/Madrid', 'COP'),
      (['en-US', 'es-CO'], 'America/New_York', 'COP'),
      (['es'], 'America/Bogota', 'COP'),
      (['en-US'], 'America/Bogota', 'COP'),
      (['es-ES'], 'Europe/Madrid', 'EUR'),
      (['pt-PT'], 'Europe/Lisbon', 'EUR'),
      (['it-IT'], 'America/New_York', 'EUR'),
      (['it'], 'America/New_York', 'EUR'),
      (['pt'], 'America/New_York', 'EUR'),
      (['pt-PT'], 'America/New_York', 'EUR'),
      (['pt-BR'], 'America/Sao_Paulo', 'USD'),
      (['it', 'es-CO'], 'America/New_York', 'COP'),
      (['en-GB'], 'Europe/London', 'EUR'),
      (['de-CH'], 'Europe/Zurich', 'EUR'),
      (['es'], 'Europe/Madrid', 'EUR'),
      (['en-US'], 'Europe/Berlin', 'EUR'),
      (['fr-FR'], null, 'EUR'),
      (['en-US'], 'America/New_York', 'USD'),
      (['es-MX'], 'America/Mexico_City', 'USD'),
      (['es-AR'], 'America/Argentina/Buenos_Aires', 'USD'),
      (['es-CL'], 'America/Santiago', 'USD'),
      (['es-PE'], 'America/Lima', 'USD'),
      (['es'], 'America/Mexico_City', 'USD'),
      (['es'], null, 'USD'),
      (<String>[], null, 'USD'),
      (['not a tag'], 'Asia/Tokyo', 'USD'),
    ];
    for (final (languages, timeZone, expected) in cases) {
      test('${languages.isEmpty ? '(none)' : languages.join(',')} in '
          '${timeZone ?? '(no zone)'} -> $expected', () {
        expect(defaultCurrency(languages, timeZone), expected);
      });
    }
  });

  group('regionOf', () {
    test('is the region of a language tag, upper case', () {
      expect(regionOf('es-CO'), 'CO');
      expect(regionOf('ES-co'), 'CO');
      expect(regionOf('zh-Hant-TW'), 'TW');
      expect(regionOf('es-419'), '419');
      expect(regionOf('es-CO-x-foo'), 'CO');
    });

    test('is null for a tag with none, or that is not a tag', () {
      expect(regionOf('es'), isNull);
      expect(regionOf('english'), isNull);
      expect(regionOf('en-u-ca-gregory'), isNull);
      expect(regionOf('not a tag'), isNull);
      expect(regionOf('pt_PT'), isNull);
      expect(regionOf(''), isNull);
    });
  });

  group('defaultCurrencyFor', () {
    test('Colombia by region or by zone, Europe by region or zone, else dollars', () {
      expect(defaultCurrencyFor('UTC', 'co'), 'COP');
      expect(defaultCurrencyFor('America/Bogota'), 'COP');
      expect(defaultCurrencyFor('UTC', 'DE'), 'EUR');
      expect(defaultCurrencyFor('Europe/Paris'), 'EUR');
      expect(defaultCurrencyFor('UTC', 'XK'), 'EUR');
      expect(defaultCurrencyFor('UTC'), 'USD');
      expect(defaultCurrencyFor('Asia/Tokyo', 'JP'), 'USD');
    });
  });

  group('isSupportedCurrency', () {
    test('is COP, USD and EUR', () {
      expect(supportedCurrencies, ['COP', 'USD', 'EUR']);
      for (final code in supportedCurrencies) {
        expect(isSupportedCurrency(code), isTrue);
      }
      expect(isSupportedCurrency('CLP'), isFalse);
      expect(isSupportedCurrency('cop'), isFalse);
      expect(isSupportedCurrency(null), isFalse);
      expect(isSupportedCurrency(''), isFalse);
    });
  });

  group('currencyName', () {
    test("is the currency's name in the person's language, capitalized", () {
      expect(currencyName('COP', 'es'), 'Peso colombiano');
      expect(currencyName('USD', 'es'), 'Dólar estadounidense');
      expect(currencyName('EUR', 'es'), 'Euro');
      expect(currencyName('COP', 'en'), 'Colombian Peso');
      expect(currencyName('USD', 'en'), 'US Dollar');
      expect(currencyName('EUR', 'en'), 'Euro');
    });

    test('is the code for one it has no name for', () {
      expect(currencyName('CLP', 'es'), 'CLP');
    });
  });
}
