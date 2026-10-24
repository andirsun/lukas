import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/import/budget_input.dart';

/// The web's budget-input tests (apps/web/app/features/onboarding/onboarding.test.ts:
/// `parseBudgetInput`, `formatBudgetTyping`), one for one, plus `draftFromCents`, which the import
/// page uses to fill the fields.
void main() {
  group('parseBudgetInput', () {
    test("reads amounts in hundredths, with the locale's decimal separator", () {
      expect(parseBudgetInput('300', 'es'), 30000);
      expect(parseBudgetInput('120,50', 'es'), 12050);
      expect(parseBudgetInput('120.50', 'en'), 12050);
    });

    test('accepts thousands separators, as people write pesos', () {
      expect(parseBudgetInput('300.000', 'es'), 30000000);
      expect(parseBudgetInput('1.250.000,5', 'es'), 125000050);
      expect(parseBudgetInput('300,000', 'en'), 30000000);
      expect(parseBudgetInput(' \$ 300.000 ', 'es'), 30000000);
    });

    test('is null when empty', () {
      expect(parseBudgetInput('', 'es'), isNull);
      expect(parseBudgetInput('   ', 'en'), isNull);
    });

    test('rejects what is not an amount', () {
      for (final text in ['abc', '-5', '1.5', '12,345,6', '1,2,3']) {
        expect(
          () => parseBudgetInput(text, text == '12,345,6' ? 'en' : 'es'),
          throwsA(isA<InvalidAmountException>()),
          reason: text,
        );
      }
    });

    test('rejects an amount too big to count', () {
      expect(
        () => parseBudgetInput('99999999999999999999', 'es'),
        throwsA(isA<InvalidAmountException>()),
      );
    });

    test('gives an example that parses', () {
      for (final currency in ['COP', 'EUR', 'CLP', 'USD']) {
        for (final locale in ['es', 'en']) {
          expect(
            parseBudgetInput(budgetExample(currency, locale), locale),
            greaterThan(0),
            reason: '$currency $locale',
          );
        }
      }
      expect(budgetExample('COP', 'es'), '300.000');
      expect(budgetExample('EUR', 'es'), '300');
    });
  });

  group('formatBudgetTyping', () {
    const cop = BudgetFormat('es', 'COP');
    const eurEs = BudgetFormat('es', 'EUR');
    const eurEn = BudgetFormat('en', 'EUR');

    test("groups thousands while typing, like the keypad's amount", () {
      expect(formatBudgetTyping('300000', 6, cop), const Typed('300.000', 7));
      expect(formatBudgetTyping('1250000', 7, cop), const Typed('1.250.000', 9));
      expect(formatBudgetTyping('1250,5', 6, eurEs).text, '1250,5');
      expect(formatBudgetTyping('12500,5', 7, eurEs).text, '12.500,5');
      expect(formatBudgetTyping('1250.5', 6, eurEn).text, '1,250.5');
    });

    test('reads the separators already there as grouping, and keeps the decimal one', () {
      expect(formatBudgetTyping('300.0000', 8, cop).text, '3.000.000');
      expect(formatBudgetTyping('12,', 3, eurEs).text, '12,');
      expect(formatBudgetTyping('12,345', 6, eurEs).text, '12,34');
    });

    test('drops what is not a digit, and pesos take no decimals', () {
      expect(formatBudgetTyping(r'$ 50.000', 8, cop).text, '50.000');
      expect(formatBudgetTyping('50000,5', 7, cop).text, '50.000');
      expect(formatBudgetTyping('abc', 3, cop), const Typed('', 0));
    });

    test('keeps the caret after the same digit when a separator appears before it', () {
      // "30|0000" with a digit typed at 2: "300000" → "300.000", the caret after the third digit.
      expect(formatBudgetTyping('300000', 3, cop), const Typed('300.000', 3));
      expect(formatBudgetTyping('3000000', 2, cop), const Typed('3.000.000', 3));
    });

    test('parses back to the same amount', () {
      final typed = formatBudgetTyping('1250000', 7, cop);
      expect(parseBudgetInput(typed.text, 'es'), 125000000);
    });
  });

  group('draftFromCents', () {
    test('a stored amount as the field shows it', () {
      expect(draftFromCents(30000000, 'es'), '300.000');
      expect(draftFromCents(3589, 'es'), '35,89');
      expect(draftFromCents(30000000, 'en'), '300,000');
      expect(draftFromCents(3589, 'en'), '35.89');
      expect(draftFromCents(6225, 'es'), '62,25');
      expect(draftFromCents(500, 'es'), '5');
      expect(draftFromCents(550, 'es'), '5,50');
    });

    test("groups the way the browser's Spanish does: four digits stay together", () {
      expect(draftFromCents(123400, 'es'), '1234');
      expect(draftFromCents(123400, 'en'), '1,234');
      expect(draftFromCents(1234500, 'es'), '12.345');
    });

    test('what it writes parses back', () {
      for (final cents in [3589, 30000000, 12050, 100, 99]) {
        for (final locale in ['es', 'en']) {
          expect(parseBudgetInput(draftFromCents(cents, locale), locale), cents);
        }
      }
    });
  });
}
