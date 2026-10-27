// What the add sheet's amount accepts, as raw text in the language (`6,08` es, `6.08` en), from the
// keypad, a physical keyboard or a paste. A port of the web's apps/web/app/ui/keypad-input.ts, rule
// for rule (its test vectors run in test/add/keypad_input_test.dart). The rule above all: an input
// that could be misread is never saved as a different amount.
//
// Typing:
// - The language's decimal separator (es `,`, en `.`) starts the decimals, at most two.
// - The other separator is a thousands separator and is ignored: in Spanish `15.000` is 15000.
// - Whole-unit currencies (COP, CLP) take no decimals: the decimal separator ends the amount, and
//   nothing typed after it counts (`15.000,5` is 15000). The raw text keeps the separator so
//   Backspace undoes it; [wholeAmount] and the display drop it.
// - The amount is capped by value, at 999.999.999,99 (999.999.999 for whole-unit currencies).
//
// Only the keypad is wired on the phone. The physical-keyboard and paste rules are here too, with
// the web's vectors, because they are the same rules and the tests pin them down.

import '../money/format.dart' show isWholeUnit;

/// The largest whole part an amount can have.
const maxWhole = 999999999;
const _maxDecimals = 2;

/// A key of the keypad.
sealed class KeypadKey {
  const KeypadKey();
}

class DigitKey extends KeypadKey {
  const DigitKey(this.digit);

  /// One character, `0` to `9`.
  final String digit;
}

class DecimalKey extends KeypadKey {
  const DecimalKey();
}

class BackspaceKey extends KeypadKey {
  const BackspaceKey();
}

/// How an amount is written and counted.
class AmountFormat {
  const AmountFormat(this.locale, [this.currency]);

  /// `es` or `en`.
  final String locale;

  /// ISO 4217 code; without one, decimals are allowed.
  final String? currency;
}

String decimalSeparator(String locale) => locale == 'en' ? '.' : ',';

/// Whether this amount takes decimals (and the keypad shows its decimal key).
bool takesDecimals(String? currency) => !(currency != null && isWholeUnit(currency));

/// The raw text as an amount: for whole-unit currencies, what comes before the decimal separator
/// (the separator only ends the amount); otherwise the text itself.
String wholeAmount(String raw, AmountFormat format) =>
    takesDecimals(format.currency) ? raw : raw.split(decimalSeparator(format.locale)).first;

/// The value after pressing [key], or the same value when the key does not apply.
String pressKey(String value, KeypadKey key, AmountFormat format) {
  final separator = decimalSeparator(format.locale);
  if (key is BackspaceKey) return value.isEmpty ? value : value.substring(0, value.length - 1);
  final parts = value.split(separator);
  final whole = parts.first;
  final decimals = parts.length > 1 ? parts[1] : null;
  if (key is DecimalKey) {
    if (decimals != null) return value;
    // Pesos: the separator ends the amount (only after some digits, so it can be undone).
    if (!takesDecimals(format.currency)) return whole.isNotEmpty ? '$whole$separator' : value;
    return '${whole.isEmpty ? '0' : whole}$separator';
  }
  final digit = (key as DigitKey).digit;
  if (decimals != null) {
    if (!takesDecimals(format.currency)) return value;
    return decimals.length < _maxDecimals ? value + digit : value;
  }
  if (whole == '0' || whole.isEmpty) return digit;
  final next = whole + digit;
  return int.parse(next) <= maxWhole ? next : value;
}

/// A physical key (its `KeyboardEvent.key` name) as a keypad key: digits, the language's decimal
/// separator and `Backspace`. Null for anything else, the thousands separator included.
KeypadKey? keyFromKeyboard(String key, AmountFormat format) {
  if (RegExp(r'^[0-9]$').hasMatch(key)) return DigitKey(key);
  if (key == 'Backspace') return const BackspaceKey();
  if (key == decimalSeparator(format.locale)) return const DecimalKey();
  return null;
}

/// The value after typing [key] on a physical keyboard, or null when the key is not for the amount.
String? typeOnKeypad(String value, String key, AmountFormat format) {
  final pressed = keyFromKeyboard(key, format);
  return pressed == null ? null : pressKey(value, pressed, format);
}

/// Digits grouped by thousands separators: the first group 1-3 digits, the rest exactly 3.
bool _wellGrouped(List<String> groups) {
  for (var i = 0; i < groups.length; i++) {
    final ok = i == 0
        ? RegExp(r'^\d{1,3}$').hasMatch(groups[i]) || groups.length == 1
        : RegExp(r'^\d{3}$').hasMatch(groups[i]);
    if (!ok) return false;
  }
  return true;
}

/// A pasted amount (`$50.000`, `6,08 €`, `€1,234.56`, `US$ 1.250,75`) as raw keypad text, or null
/// when it is not one clear amount (no digits, several numbers such as a date, bad grouping, over
/// the cap). A sign, symbols, letters and spaces around the number are dropped.
///
/// - Decimal currencies (EUR, USD), in either language: the last separator is the decimal one when
///   it appears once and is followed by exactly 1-2 digits (`6.08`, `1,234.56`, `1.234,56`);
///   otherwise every `.` and `,` is a thousands separator (`1.234`, `$ 50.000`).
/// - Whole-unit currencies (COP, CLP): the language's decimal separator ends the amount, as when
///   typing (es `50.000,50` is 50000); the other separator is a thousands separator.
String? pasteAmount(String text, AmountFormat format) {
  final numbers = RegExp(r'[\d.,]+')
      .allMatches(text)
      .map((m) => m.group(0)!)
      .where((run) => RegExp(r'\d').hasMatch(run))
      .toList();
  if (numbers.length != 1) return null;
  final run = numbers.first.replaceAll(RegExp(r'^[.,]+|[.,]+$'), '');
  final separator = decimalSeparator(format.locale);

  final String whole;
  String? decimals;
  if (!takesDecimals(format.currency)) {
    whole = run.split(separator).first;
  } else {
    final last = [run.lastIndexOf('.'), run.lastIndexOf(',')].reduce((a, b) => a > b ? a : b);
    final mark = last >= 0 ? run[last] : '';
    final tail = last >= 0 ? run.substring(last + 1) : '';
    final isDecimal =
        mark.isNotEmpty && run.split(mark).length == 2 && RegExp(r'^\d{1,2}$').hasMatch(tail);
    whole = isDecimal ? run.substring(0, last) : run;
    decimals = isDecimal ? tail : null;
  }
  final groups = whole.split(RegExp(r'[.,]'));
  if (!_wellGrouped(groups)) return null;
  final stripped = groups.join().replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final digits = stripped.isEmpty ? '0' : stripped;
  final value = int.tryParse(digits);
  if (value == null || value > maxWhole) return null;
  return decimals == null ? digits : '$digits$separator$decimals';
}

/// Stored cents as keypad text in the language (`26280` becomes `262,80`; `5000` becomes `50`).
/// Whole-unit currencies (COP) are rounded to whole pesos: the keypad never holds fractional pesos.
String keypadText(int cents, String locale, [String? currency]) {
  final abs = cents.abs();
  if (currency != null && isWholeUnit(currency)) return ((abs + 50) ~/ 100).toString();
  final whole = abs ~/ 100;
  final rest = abs % 100;
  return rest == 0
      ? whole.toString()
      : '$whole${decimalSeparator(locale)}${rest.toString().padLeft(2, '0')}';
}

/// The typed text in cents, or 0 while it is empty or not a number yet. The other language's
/// separator is rejected (0), not guessed at: `parseAmountInput` in the web.
int centsOf(String raw, String locale) {
  final text = raw.trim();
  if (text.isEmpty) return 0;
  final decimal = decimalSeparator(locale);
  final other = locale == 'en' ? ',' : '.';
  if (text.contains(other)) return 0;
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(text.replaceFirst(decimal, '.'));
  if (match == null) return 0;
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final whole = int.tryParse(match.group(1)!);
  if (whole == null) return 0;
  return whole * 100 + (fraction.isEmpty ? 0 : int.parse(fraction));
}

/// The keypad's text as the stored x100 integer (unsigned): whole pesos only for whole-unit
/// currencies, and a trailing decimal separator still being typed (`6,`) ignored; 0 while empty.
int amountCents(String raw, AmountFormat format) {
  final text = wholeAmount(raw, format);
  final separator = decimalSeparator(format.locale);
  return centsOf(
    text.endsWith(separator) ? text.substring(0, text.length - 1) : text,
    format.locale,
  );
}

/// Whether pasted text is a negative amount (`-50.000`, `−6,08 €`): a minus sign before the first
/// digit. Forms that take only positive amounts refuse it instead of dropping the sign.
bool pastedNegative(String text) {
  final beforeDigits = text.split(RegExp(r'\d')).first;
  return RegExp('[-−‐‑–]').hasMatch(beforeDigits);
}
