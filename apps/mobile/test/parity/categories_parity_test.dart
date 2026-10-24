@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/budgets/budgets_repository.dart';
import 'package:lukitas/budgets/category_detail_screen.dart';
import 'package:lukitas/categories/categories_repository.dart';
import 'package:lukitas/categories/category_model.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/ui/app_shell.dart';

import '../support/parity.dart';
import '../support/parity_home.dart';

/// Managing categories against the stories that show it, each as Storybook shows it after its
/// `play` function: the Categorías tab's Ingresos and its unfolded Archivadas, the new category
/// sheet (`home-home--categories-income`, `--categories-archived-open`, `--categories-archived-with-spending`,
/// `--new-category-sheet`,
/// apps/web/app/features/home/Home.stories.tsx) and a category's detail with the edit sheet, the
/// archive question and an archived one's note (`manage-categories--edit-category-sheet`,
/// `--archive-sheet-open`, `--archived-detail`, apps/web/app/features/categories/Categories.stories.tsx).
///
/// The app reads what the story's fake API answered (test/parity/fixtures). Update the goldens with
/// `flutter test --update-goldens test/parity`, then compare with `dart run tool/parity/compose.dart`
/// (docs/mobile/parity.md).

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

/// What the category sheet asks: whether the category has movements, and the recurring payments.
class _FixtureCategories implements CategoriesRepository {
  _FixtureCategories(this.fixture);

  final ParityFixture fixture;

  @override
  Future<bool> hasTransactions(String categoryId) async {
    final page = fixtureJson(fixture, '/v1/transactions?category=$categoryId&limit=200')! as Map;
    return (page['items']! as List).isNotEmpty;
  }

  @override
  Future<List<Recurrence>> recurrences() async => [
    for (final rule in fixtureJson(fixture, '/v1/recurrences')! as List)
      readBuilt(Recurrence.serializer, rule),
  ];

  @override
  Future<Category> create(NewCategory values) async => throw UnimplementedError();

  @override
  Future<Category> update(
    String id, {
    String? name,
    String? icon,
    String? color,
    CategoryKindEnum? kind,
    bool? archived,
  }) async => throw UnimplementedError();
}

/// Home in the story's frame: Storybook's 16px of padding, the bar under it, no 🎤.
Widget _home() => ShellFrame(
  padding: const EdgeInsets.all(16),
  showMic: false,
  child: HomeScreen(menu: (context, close) => const SizedBox.shrink()),
);

/// The detail of [id] in the story's frame.
Widget _detail(String id) => ShellFrame(
  padding: const EdgeInsets.all(16),
  showMic: false,
  child: CategoryDetailScreen(categoryId: id),
);

List<Override> _overrides(ParityFixture fixture) => [
  ...parityHomeOverrides(FixtureHomeRepository(fixture)),
  budgetsRepositoryProvider.overrideWithValue(_FixtureBudgets(fixture)),
  categoriesRepositoryProvider.overrideWithValue(_FixtureCategories(fixture)),
];

/// What a story's `userEvent.click` leaves behind: the focus on the control clicked.
void _focus(WidgetTester t, Finder control) {
  final node = Focus.of(
    t.element(find.descendant(of: control, matching: find.byType(GestureDetector)).first),
  );
  node.requestFocus();
}

/// `userEvent.click` on a control, then a key: keyboard mode, where the focused control shows its
/// ring, as Chrome rings what a script's click focused.
Future<void> _keyboardMode(WidgetTester t) => t.sendKeyEvent(LogicalKeyboardKey.shift);

Future<void> _openCategoriesTab(WidgetTester t) async {
  await precacheLukitas(t);
  await t.tap(find.text('Categorías'));
  await t.pumpAndSettle();
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('categories parity: Ingresos ($theme)', (t) async {
      final fixture = ParityFixtures.load('home-home--categories-income');
      await parityGolden(
        t,
        'categories-income',
        _home(),
        theme: theme,
        overrides: _overrides(fixture),
        act: (t) async {
          await _openCategoriesTab(t);
          await t.tap(find.byKey(const Key('categories.kind.income')));
          await t.pumpAndSettle();
          await _keyboardMode(t);
        },
      );
    });

    testWidgets('categories parity: the archived ones unfolded ($theme)', (t) async {
      final fixture = ParityFixtures.load('home-home--categories-archived-open');
      await parityGolden(
        t,
        'categories-archived-open',
        _home(),
        theme: theme,
        overrides: _overrides(fixture),
        act: (t) async {
          await _openCategoriesTab(t);
          await t.tap(find.byKey(const Key('categories.kind.income')));
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('categories.fold')));
          await t.pumpAndSettle();
          _focus(t, find.byKey(const Key('categories.fold')));
          await _keyboardMode(t);
        },
      );
    });

    testWidgets('categories parity: an archived one with spending this month ($theme)', (t) async {
      final fixture = ParityFixtures.load('home-home--categories-archived-with-spending');
      await parityGolden(
        t,
        'categories-archived-with-spending',
        _home(),
        theme: theme,
        overrides: _overrides(fixture),
        act: (t) async {
          await _openCategoriesTab(t);
          await _keyboardMode(t);
        },
      );
    });

    testWidgets('categories parity: the new category sheet ($theme)', (t) async {
      final fixture = ParityFixtures.load('home-home--new-category-sheet');
      await parityGolden(
        t,
        'category-new-sheet',
        _home(),
        theme: theme,
        overrides: _overrides(fixture),
        act: (t) async {
          await _openCategoriesTab(t);
          await t.tap(find.byKey(const Key('categories.add')));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('categories parity: the edit category sheet ($theme)', (t) async {
      final fixture = ParityFixtures.load('manage-categories--edit-category-sheet');
      await parityGolden(
        t,
        'category-edit-sheet',
        _detail('cat-fun'),
        theme: theme,
        overrides: _overrides(fixture),
        act: (t) async {
          await t.tap(find.byKey(const Key('detail.edit')));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('categories parity: the archive question ($theme)', (t) async {
      final fixture = ParityFixtures.load('manage-categories--archive-sheet-open');
      await parityGolden(
        t,
        'category-archive-sheet',
        _detail('cat-fun'),
        theme: theme,
        overrides: _overrides(fixture),
        act: (t) async {
          await t.tap(find.byKey(const Key('detail.edit')));
          await t.pumpAndSettle();
          await t.ensureVisible(find.byKey(const Key('category.archive')));
          await t.tap(find.byKey(const Key('category.archive')));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('categories parity: an archived category\'s detail ($theme)', (t) async {
      final fixture = ParityFixtures.load('manage-categories--archived-detail');
      await parityGolden(
        t,
        'category-detail-archived',
        _detail('cat-casa'),
        theme: theme,
        overrides: _overrides(fixture),
      );
    });
  }
}
