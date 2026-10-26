// The currencies an account can use and the one a new account starts with: the web's
// apps/web/app/features/onboarding/currency.ts and packages/core (`SUPPORTED_CURRENCIES`,
// `defaultCurrencyFor`). The welcome's currency step and Settings both read it.

/// ISO 4217 codes an account can use: COP first, the launch market (spec section 2.4).
const supportedCurrencies = ['COP', 'USD', 'EUR'];

bool isSupportedCurrency(String? code) => supportedCurrencies.contains(code);

/// Countries of Europe (the EU, the EEA, the UK, Switzerland and the Balkans): their default is EUR.
const _europe = {
  'AD', 'AL', 'AT', 'BA', 'BE', 'BG', 'CH', 'CY', 'CZ', 'DE', 'DK', 'EE', 'ES', 'FI', 'FR', 'GB',
  'GR', 'HR', 'HU', 'IE', 'IS', 'IT', 'LI', 'LT', 'LU', 'LV', 'MC', 'MD', 'ME', 'MK', 'MT', 'NL',
  'NO', 'PL', 'PT', 'RO', 'RS', 'SE', 'SI', 'SK', 'SM', 'UA', 'VA', 'XK', //
};

/// The currency a new account starts with (founder's rule, 2026-10-21), from the device's time zone
/// and, when known, its region (ISO 3166 alpha-2, from the language tag):
/// - Colombia (the region is CO, or the zone is America/Bogota) -> COP;
/// - Europe (the region is European, or the zone is Europe/*) -> EUR;
/// - anywhere else -> USD: the rest of Latin America, the US, and anyone we can't place.
///
/// The account's currency locks at its first transaction, so a wrong euro for a peso earner would
/// stick: USD is the safer unknown.
String defaultCurrencyFor(String timezone, [String? region]) {
  final country = region?.toUpperCase();
  if (country == 'CO' || timezone == 'America/Bogota') return 'COP';
  if ((country != null && _europe.contains(country)) || timezone.startsWith('Europe/')) {
    return 'EUR';
  }
  return 'USD';
}

// A BCP 47 tag, as far as the region goes: a language, an optional script, an optional region,
// then variants, extensions and private use, which are only checked for shape.
final _tag = RegExp(
  r'^[A-Za-z]{2,3}(?:-[A-Za-z]{4})?(?:-([A-Za-z]{2}|\d{3}))?'
  r'(?:-(?:[A-Za-z0-9]{5,8}|\d[A-Za-z0-9]{3}))*'
  r'(?:-[A-WY-Za-wy-z0-9](?:-[A-Za-z0-9]{2,8})+)*(?:-[xX](?:-[A-Za-z0-9]{1,8})+)?$',
);

/// The region of a language tag (`es-CO` -> `CO`), or null when it names none or is not a tag: the
/// web's `new Intl.Locale(tag).region`.
String? regionOf(String tag) => _tag.firstMatch(tag)?.group(1)?.toUpperCase();

/// The currency a new account starts with, from the device's languages and time zone. The rule
/// itself is [defaultCurrencyFor]; this picks the region it reads: CO if any language names
/// Colombia, else the first language's region. So `es-CO` anywhere -> COP, a European first
/// language -> EUR, and a bare `es` in an America/* zone -> USD.
String defaultCurrency(List<String> languages, String? timeZone) {
  final regions = [for (final tag in languages) ?regionOf(tag)];
  // A bare Italian or Portuguese language reads as Italy or Portugal: euros (spec section 2.3).
  final first = languages.firstOrNull?.split(RegExp('[-_]')).first.toLowerCase();
  final home = first == 'it' ? 'IT' : (first == 'pt' ? 'PT' : null);
  final region = regions.contains('CO') ? 'CO' : (regions.firstOrNull ?? home);
  return defaultCurrencyFor(timeZone ?? '', region);
}

const _names = {
  'es': {'COP': 'Peso colombiano', 'USD': 'Dólar estadounidense', 'EUR': 'Euro'},
  'en': {'COP': 'Colombian Peso', 'USD': 'US Dollar', 'EUR': 'Euro'},
};

/// "Peso colombiano": the currency's name in the person's language, capitalized (the web asks
/// `Intl.DisplayNames`; the three currencies' names are the CLDR's).
String currencyName(String code, String locale) => _names[locale]?[code] ?? code;
