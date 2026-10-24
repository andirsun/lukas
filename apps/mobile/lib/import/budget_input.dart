// A budget as it is typed in a field, and the other way round: a port of the web's
// apps/web/app/features/onboarding/budget-input.ts (its tests run in test/import/budget_input_test.dart).
import '../add/keypad_input.dart' show decimalSeparator, maxWhole, takesDecimals;
import '../money/format.dart' show formatAmountInput;

/// What a typed amount was not: the web's `InvalidAmountError`.
class InvalidAmountException implements Exception {
  const InvalidAmountException(this.text);

  final String text;

  @override
  String toString() => 'InvalidAmountException($text)';
}

/// Whole numbers grouped by thousands, with optional decimals: es `1.250.000,50`, en `1,250,000.50`.
final _grouped = {
  'es': RegExp(r'^\d{1,3}(\.\d{3})+(,\d{1,2})?$'),
  'en': RegExp(r'^\d{1,3}(,\d{3})+(\.\d{1,2})?$'),
};

/// JavaScript's `Number.MAX_SAFE_INTEGER`: the web's amounts never pass it.
final _maxSafe = BigInt.from(9007199254740991);

/// The web's `parseAmountInput` (apps/web/app/i18n/format.ts): the locale's decimal separator
/// only, at most two decimals, in hundredths.
int _parseAmount(String text, String locale) {
  final trimmed = text.trim();
  final decimal = locale == 'es' ? ',' : '.';
  final other = locale == 'es' ? '.' : ',';
  if (trimmed.contains(other)) throw InvalidAmountException(text);
  final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$')
      .firstMatch(trimmed.replaceFirst(decimal, '.'));
  if (match == null) throw InvalidAmountException(text);
  final sign = match.group(1);
  final fraction = (match.group(3) ?? '').padRight(2, '0');
  final minor = BigInt.parse(match.group(2)!) * BigInt.from(100) + BigInt.parse(fraction);
  if (minor > _maxSafe) throw InvalidAmountException(text);
  return sign == '-' ? -minor.toInt() : minor.toInt();
}

/// A budget as typed, in hundredths like every stored amount (`300.000` pesos → 30.000.000), or
/// null when the field is empty (no budget). Besides what the amount field takes, it accepts
/// thousands separators (people write pesos as `300.000`) and a currency sign or spaces around the
/// number. Anything else, negatives included, throws [InvalidAmountException].
int? parseBudgetInput(String text, String locale) {
  final bare = text.replaceAll(RegExp(r'[\s$€]'), '');
  if (bare.isEmpty) return null;
  final grouping = locale == 'es' ? '.' : ',';
  final ungrouped = _grouped[locale]!.hasMatch(bare) ? bare.replaceAll(grouping, '') : bare;
  if (ungrouped.startsWith('-')) throw InvalidAmountException(text);
  return _parseAmount(ungrouped, locale);
}

/// Currencies people count in thousands; the example shows a round thousand amount.
const _thousands = {'COP', 'CLP', 'ARS'};

/// A valid example for the "type just the number" hint, in the way people write that currency.
String budgetExample(String currency, String locale) {
  if (!_thousands.contains(currency)) return '300';
  return locale == 'es' ? '300.000' : '300,000';
}

/// A stored amount as the field shows it: `300.000`, `35,89` (es) or `300,000`, `35.89` (en).
/// Grouped as the browser's `Intl.NumberFormat` does: Spanish leaves four digits together
/// (`1234`), English groups them (`1,234`).
String draftFromCents(int cents, String locale) {
  final spanish = locale == 'es';
  final whole = cents % 100 == 0;
  final units = (cents ~/ 100).toString();
  final digits = units.length <= 3 || (spanish && units.length == 4)
      ? units
      : [
          if (units.length % 3 != 0) units.substring(0, units.length % 3),
          for (var i = units.length % 3; i < units.length; i += 3) units.substring(i, i + 3),
        ].join(spanish ? '.' : ',');
  if (whole) return digits;
  return '$digits${spanish ? ',' : '.'}${(cents % 100).toString().padLeft(2, '0')}';
}

/// How a budget field writes its amount.
class BudgetFormat {
  const BudgetFormat(this.locale, this.currency);

  /// `es` or `en`.
  final String locale;
  final String currency;
}

/// A field's text and where its cursor is.
class Typed {
  const Typed(this.text, this.caret);

  final String text;
  final int caret;

  @override
  bool operator ==(Object other) => other is Typed && other.text == text && other.caret == caret;

  @override
  int get hashCode => Object.hash(text, caret);

  @override
  String toString() => 'Typed($text, $caret)';
}

String _digitsOf(String text) => text.replaceAll(RegExp(r'\D'), '');

/// A budget field as it is typed, formatted like the keypad's amount (`300000` → `300.000` in
/// es-CO, `1250.5` → `1,250.5` in en): the thousands separators are put in for the person, any
/// they typed are read as grouping, the locale's decimal separator starts at most two decimals
/// (none for pesos), and anything else is dropped, as on the keypad. [caret] is the cursor in the
/// typed text; the result's caret sits after the same digit in the formatted text.
Typed formatBudgetTyping(String text, int caret, BudgetFormat format) {
  final separator = decimalSeparator(format.locale);
  final cut = text.indexOf(separator);
  final decimal = cut >= 0 && takesDecimals(format.currency);
  var wholeDigits = _digitsOf(cut >= 0 ? text.substring(0, cut) : text)
      .replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final cap = maxWhole.toString().length;
  if (wholeDigits.length > cap) wholeDigits = wholeDigits.substring(0, cap);
  if (wholeDigits.isEmpty && !decimal) return const Typed('', 0);
  String? decimals;
  if (decimal) {
    final typed = _digitsOf(text.substring(cut + 1));
    decimals = typed.length > 2 ? typed.substring(0, 2) : typed;
  }
  final raw = decimals == null
      ? wholeDigits
      : '${wholeDigits.isEmpty ? '0' : wholeDigits}$separator$decimals';
  // The keypad's own formatting, without the currency sign and spaces.
  final formatted = formatAmountInput(
    raw,
    format.currency,
    format.locale,
  ).replaceAll(RegExp(r'[^\d.,]'), '');

  // The caret goes after as many digits as were before it (and after the decimal separator if it
  // was right after it).
  final before = text.substring(0, caret.clamp(0, text.length));
  final digitsBefore = _digitsOf(before).length;
  var seen = 0;
  var at = 0;
  if (digitsBefore > 0) {
    for (; at < formatted.length; at++) {
      if (RegExp(r'\d').hasMatch(formatted[at])) seen += 1;
      if (seen == digitsBefore) {
        at += 1;
        break;
      }
    }
  }
  if (before.endsWith(separator) && at < formatted.length && formatted[at] == separator) at += 1;
  return Typed(formatted, at < formatted.length ? at : formatted.length);
}
