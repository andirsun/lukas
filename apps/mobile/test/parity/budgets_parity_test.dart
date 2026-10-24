@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/budgets/budgets_repository.dart';
import 'package:lukitas/budgets/category_detail_screen.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/ui/app_shell.dart';

import '../support/parity.dart';
import '../support/parity_home.dart';

/// Categorías, a category's detail and the budget sheet against the stories that show them:
/// `home-home--budgets` (apps/web/app/features/home/Home.stories.tsx) and
/// `manage-categories--detail`, `--budget-sheet-open` and `--budget-sheet-negative`
/// (apps/web/app/features/categories/Categories.stories.tsx), each as Storybook shows it after its
/// `play` function.
///
/// The app reads what the story's fake API answered (test/parity/fixtures): the profile, the
/// summary, the categories, the month's movements and Ocio's own.
///
/// Category management stays on the web (the founder's ruling for Stage 3b): where the web's detail
/// has "Editar", the app has a link to the web. The pairs draw it with the web's word, so that
/// everything else is compared; the link's real label is `settingsWeb`, "Más en la web".
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The story's API for a category's movements.
class _FixtureBudgets implements BudgetsRepository {
  _FixtureBudgets(this.fixture);

  final ParityFixture fixture;

  @override
  Future<TransactionsPage> categoryTransactions(
    String month,
    String categoryId, {
    String? cursor,
  }) async {
    final page =
        fixtureJson(fixture, '/v1/transactions?category=$categoryId&limit=50&month=$month')! as Map;
    return TransactionsPage([
      for (final item in page['items']! as List) readBuilt(Transaction.serializer, item),
    ], null);
  }

  @override
  Future<int> incomeTotal(String month, String categoryId) async => 0;

  @override
  Future<void> setBudget(String categoryId, int cents, {required String month}) async =>
      throw UnimplementedError();
}

/// The detail of Ocio in the story's frame: Storybook's 16px of padding, the bar under it, no 🎤.
Widget _detail() => ShellFrame(
  padding: const EdgeInsets.all(16),
  showMic: false,
  child: const CategoryDetailScreen(categoryId: 'cat-fun', manageLabel: 'Editar'),
);

/// `userEvent.click` on a control, then a key: keyboard mode, where the focused control shows its
/// ring, as Chrome rings what a script's click focused.
Future<void> _keyboardMode(WidgetTester t) => t.sendKeyEvent(LogicalKeyboardKey.shift);

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('budgets parity: home, Categorías tapped ($theme)', (t) async {
      final fixture = ParityFixtures.load('home-home--budgets');
      await parityGolden(
        t,
        'home-budgets',
        ShellFrame(
          padding: const EdgeInsets.all(16),
          showMic: false,
          child: HomeScreen(menu: (context, close) => const SizedBox.shrink()),
        ),
        theme: theme,
        overrides: parityHomeOverrides(FixtureHomeRepository(fixture)),
        act: (t) async {
          await precacheLukitas(t);
          await t.tap(find.text('Categorías'));
          await t.pumpAndSettle();
          await _keyboardMode(t);
        },
      );
    });

    testWidgets('budgets parity: the detail of Ocio ($theme)', (t) async {
      final fixture = ParityFixtures.load('manage-categories--detail');
      await parityGolden(
        t,
        'category-detail',
        _detail(),
        theme: theme,
        overrides: [
          ...parityHomeOverrides(FixtureHomeRepository(fixture)),
          budgetsRepositoryProvider.overrideWithValue(_FixtureBudgets(fixture)),
        ],
      );
    });

    testWidgets('budgets parity: the budget sheet, as it opens ($theme)', (t) async {
      final fixture = ParityFixtures.load('manage-categories--budget-sheet-open');
      await parityGolden(
        t,
        'budget-sheet',
        _detail(),
        theme: theme,
        overrides: [
          ...parityHomeOverrides(FixtureHomeRepository(fixture)),
          budgetsRepositoryProvider.overrideWithValue(_FixtureBudgets(fixture)),
        ],
        act: (t) async {
          await t.tap(find.text('CAMBIAR PRESUPUESTO'));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('budgets parity: the budget sheet refuses a minus ($theme)', (t) async {
      final fixture = ParityFixtures.load('manage-categories--budget-sheet-negative');
      await parityGolden(
        t,
        'budget-sheet-negative',
        _detail(),
        theme: theme,
        overrides: [
          ...parityHomeOverrides(FixtureHomeRepository(fixture)),
          budgetsRepositoryProvider.overrideWithValue(_FixtureBudgets(fixture)),
        ],
        act: (t) async {
          await t.tap(find.text('CAMBIAR PRESUPUESTO'));
          await t.pumpAndSettle();
          await t.sendKeyEvent(LogicalKeyboardKey.minus);
          await t.pumpAndSettle();
        },
      );
    });
  }
}
