// Money the way the web writes it (apps/web/app/i18n/format.ts), and the COP "lukas" hint.
//
// Done by hand rather than with `intl`'s NumberFormat: the web gets its output from the browser's
// ICU (CLDR) data, which `intl` does not carry, and the two differ in small ways that would show
// (the minimum grouping digits of Spanish, the spacing around a currency code).

/// Every amount is stored in hundredths of the currency, whatever the currency's own ISO exponent
/// (the web, the API and the importers all use 100). So 50.000 COP is stored as 5.000.000.
const _minorUnit = 100;

/// Currencies shown without decimals; stored in hundredths like the rest.
const _wholeUnitCurrencies = {'COP', 'CLP'};

const _minus = '−';
const _nbsp = ' ';

/// Whether [locale] writes the decimal comma, the symbol after the figure and groups four digits
/// only from five (CLDR's minimum grouping digits of 2): Spanish, Italian and Portuguese. English
/// is the other way round.
bool _commaLocale(String locale) => locale != 'en';

/// Whether a currency is counted in whole units only (no cents to type or show): COP, CLP.
bool isWholeUnit(String currency) => _wholeUnitCurrencies.contains(currency);

/// When [formatMoney] writes a plus sign.
enum MoneySign {
  /// Only a minus on negatives.
  auto,

  /// A plus on positives too (zero has none).
  always,
}

/// Where a currency's symbol goes and what it is, per language.
class _Style {
  const _Style(this.symbol, {required this.attached});

  final String symbol;

  /// Written right before the figure with nothing between (`€562.92`, `$50.000`); otherwise
  /// separated by a no-break space (`COP 50,000`, `562,92 €`).
  final bool attached;
}

_Style _style(String currency, String locale) {
  final spanish = _commaLocale(locale);
  switch (currency) {
    // Colombians write pesos as "$50.000". In English the code stays: "$50,000" would read as
    // dollars.
    case 'COP':
      return locale == 'es'
          ? const _Style(r'$', attached: true)
          : const _Style('COP', attached: false);
    case 'EUR':
      return _Style('€', attached: !spanish);
    case 'USD':
      // CLDR writes Italian dollars as the code ("1234,00 USD"), Spanish and Portuguese as "US$".
      if (locale == 'it') return const _Style('USD', attached: false);
      return spanish ? const _Style(r'US$', attached: false) : const _Style(r'$', attached: true);
    default:
      return _Style(currency, attached: false);
  }
}

/// [digits] (a run of 0-9) with [separator] between groups of three. Spanish, Italian and
/// Portuguese (outside Colombian pesos) do not group four-digit numbers (CLDR's minimum grouping
/// digits is 2): `1234,56 €`, `12.345,00 €`.
String _grouped(String digits, String separator, {required bool minTwo}) {
  if (digits.length <= 3 || (minTwo && digits.length == 4)) return digits;
  final out = StringBuffer();
  final first = digits.length % 3;
  if (first > 0) out.write(digits.substring(0, first));
  for (var i = first; i < digits.length; i += 3) {
    if (out.isNotEmpty) out.write(separator);
    out.write(digits.substring(i, i + 3));
  }
  return out.toString();
}

/// Formats integer minor units (hundredths). Negatives use the real minus sign (U+2212) rather
/// than a hyphen, so "−6,08 €" never breaks or reads as a dash.
String formatMoney(int cents, String currency, String locale, {MoneySign sign = MoneySign.auto}) {
  final spanish = _commaLocale(locale);
  final style = _style(currency, locale);
  final whole = isWholeUnit(currency);
  final abs = cents.abs();
  // Whole currencies round half away from zero, as Intl does.
  final units = whole ? (abs + _minorUnit ~/ 2) ~/ _minorUnit : abs ~/ _minorUnit;
  final fraction = (abs % _minorUnit).toString().padLeft(2, '0');
  final colombian = currency == 'COP' && locale == 'es';
  // Italian groups with a point, Portuguese (Portugal) with a no-break space, as `Intl` does.
  final group = locale == 'pt' ? _nbsp : (spanish ? '.' : ',');
  final figure = StringBuffer(_grouped(units.toString(), group, minTwo: spanish && !colombian));
  if (!whole) figure.write('${spanish ? ',' : '.'}$fraction');

  final zero = whole ? units == 0 : abs == 0;
  final prefix = zero
      ? ''
      : cents < 0
      ? _minus
      : sign == MoneySign.always
      ? '+'
      : '';
  // Spanish, Italian and Portuguese put the symbol after the figure, except the Colombian peso's
  // "$".
  if (spanish && !colombian) return '$prefix$figure$_nbsp${style.symbol}';
  return '$prefix${style.symbol}${style.attached ? '' : _nbsp}$figure';
}

/// What is being typed on the add sheet's keypad (`6,0`, raw, in the language's decimal separator)
/// shown as money, the way [formatMoney] writes it (`6,0 €`, `$50.000`, `€6.5`): the whole part is
/// grouped and the decimals stay exactly as typed, a trailing separator or zero included. Empty is
/// 0. Whole-unit currencies show no decimals (a separator there only ended the amount).
String formatAmountInput(String raw, String currency, String locale) {
  final separator = _commaLocale(locale) ? ',' : '.';
  final parts = raw.split(separator);
  final whole = int.tryParse(parts.first.isEmpty ? '0' : parts.first) ?? 0;
  final money = formatMoney(whole * _minorUnit, currency, locale);
  if (isWholeUnit(currency)) return money;
  final decimals = parts.length > 1 ? parts[1] : null;
  // [formatMoney] wrote two zero decimals after the first separator: put what was typed there.
  return money.replaceFirst('${separator}00', decimals == null ? '' : '$separator$decimals');
}

String _number(double value, String locale) {
  // At most two decimals, none when whole: 15,5 / 15.5, 1,25 / 1.25, 50.
  var text = value.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return _commaLocale(locale) ? text.replaceFirst('.', ',') : text;
}

/// The "lukas hint" for COP: 1 luka = $1.000 and 1 palo = $1.000.000 (es), "k" and "M" (en),
/// written in parentheses, as the web shows it after an amount: `(50 lukas)`, `(4,3 palos)`.
/// [cents] is the stored amount, as [formatMoney] takes it. Null for any other [currency] and under
/// 1.000 pesos. Lukas show at most one decimal, palos at most two; the palos threshold applies
/// after rounding, so 999.990 pesos is "1 palo". The sign is ignored.
String? lukasHint(int cents, String locale, {String currency = 'COP'}) {
  // The slang is Colombian Spanish (and its k/M in English); Italian and Portuguese have none.
  if (currency != 'COP' || locale == 'it' || locale == 'pt') return null;
  final abs = cents.abs();
  if (abs < 1000 * _minorUnit) return null;

  final spanish = locale == 'es';
  // Integer divisions only: tenths of a luka (pesos / 100) and hundredths of a palo (pesos / 10.000).
  final lukaTenths = (abs / (100 * _minorUnit)).round();
  if (lukaTenths < 10000) {
    final lukas = lukaTenths / 10;
    final text = _number(lukas, locale);
    return spanish ? '($text ${lukas == 1 ? 'luka' : 'lukas'})' : '(${text}k)';
  }
  final palos = (abs / (10000 * _minorUnit)).round() / 100;
  final text = _number(palos, locale);
  return spanish ? '($text ${palos == 1 ? 'palo' : 'palos'})' : '(${text}M)';
}
