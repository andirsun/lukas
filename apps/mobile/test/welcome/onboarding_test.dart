import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/welcome/category_chips.dart';
import 'package:lukitas/welcome/onboarding_api.dart';
import 'package:lukitas/welcome/steps.dart';
import 'package:lukitas/welcome/suggested_categories.dart';

import '../home/fixtures.dart';
import 'fakes.dart';

/// The web's onboarding tests (apps/web/app/features/onboarding/onboarding.test.ts), one for one.
/// `defaultCurrency` and `timeZoneToSave` are in test/profile; `parseBudgetInput`,
/// `formatBudgetTyping` and `draftFromCents` are in test/import/budget_input_test.dart, where the
/// import page ported them first.
void main() {
  group('steps', () {
    test('are the welcome and the four setup steps, budgets last', () {
      // The import comes before the categories, so they can start from what the file brought.
      expect(StepId.values.map((s) => s.id), [
        'welcome',
        'currency',
        'import',
        'categories',
        'budgets',
      ]);
    });

    test('map to /welcome paths and back', () {
      expect(stepPath(StepId.welcome), '/welcome');
      expect(stepPath(StepId.currency), '/welcome/currency');
      expect(stepFromParam(null), StepId.welcome);
      expect(stepFromParam('import'), StepId.import);
      expect(stepFromParam('welcome'), isNull);
      expect(stepFromParam('passkey'), isNull);
      expect(stepFromParam('done'), isNull);
    });

    test('go forward and back in order', () {
      expect(nextStep(StepId.welcome), StepId.currency);
      expect(nextStep(StepId.currency), StepId.import);
      expect(nextStep(StepId.import), StepId.categories);
      expect(nextStep(StepId.categories), StepId.budgets);
      expect(nextStep(StepId.budgets), isNull);
      expect(previousStep(StepId.currency), StepId.welcome);
      expect(previousStep(StepId.welcome), isNull);
    });

    test('count the four setup steps, not the welcome', () {
      expect(setupSteps, [StepId.currency, StepId.import, StepId.categories, StepId.budgets]);
    });
  });

  group('suggestedCategories', () {
    test("has the spec's eight, with one income", () {
      expect(suggestedCategories.map((c) => c.names['es']), [
        'Supermercado',
        'Restaurante',
        'Casa',
        'Transporte',
        'Ocio',
        'Suscripciones',
        'Vida',
        'Salario',
      ]);
      expect(
        suggestedCategories.where((c) => c.kind == CategoryKindEnum.income).map((c) => c.key),
        ['salary'],
      );
      expect(suggestedCategories.map((c) => c.key).toSet().length, 8);
    });

    test('finds the suggestion behind a name, in either language, ignoring case and accents', () {
      expect(suggestionFor('supermercado')?.key, 'groceries');
      expect(suggestionFor('Eating out')?.key, 'eating_out');
      expect(suggestionFor('Salário')?.key, 'salary');
      expect(suggestionFor('Taxes'), isNull);
    });
  });

  group('categoryChips', () {
    Category server(String name, {String kind = 'expense', bool archived = false}) =>
        category('id-$name', name, kind: kind, icon: 'cart', color: 'orange', archived: archived);

    test('is the suggestions, in order, when the person has no categories', () {
      final chips = categoryChips([], 'es');
      expect(chips.map((c) => c.name), suggestedCategories.map((s) => s.names['es']));
      expect(chips.every((c) => c.source == ChipSource.suggestion), isTrue);
      expect(chips.first.id, 's:groceries');
      expect(chips.first.glyph, '🛒');
      expect(chips.first.kind, CategoryKindEnum.expense);
    });

    test(
      'puts what they have (an import\'s categories) first, then the suggestions not covered',
      () {
        final chips = categoryChips([
          server('Taxes'),
          server('supermercado'),
          server('Salário', kind: 'income'),
          server('Ocio'),
        ], 'es');
        expect(chips.map((c) => c.name), [
          'Taxes',
          'supermercado',
          'Salário',
          'Ocio',
          'Restaurante',
          'Casa',
          'Transporte',
          'Suscripciones',
          'Vida',
        ]);
        // The importer's icon names are shown as emoji.
        expect(chips.first.id, 'id-Taxes');
        expect(chips.first.source, ChipSource.category);
        expect(chips.first.glyph, '🛒');
      },
    );

    test('treats names that differ in case or accents as the same', () {
      final chips = categoryChips([server('SUPERMERCADO'), server('Suscripcíones')], 'es');
      expect(chips.where((c) => normalizeName(c.name) == 'supermercado'), hasLength(1));
      expect(chips.where((c) => normalizeName(c.name) == 'suscripciones'), hasLength(1));
    });

    test('covers a suggestion by its English name too, and leaves out archived categories', () {
      final chips = categoryChips([server('Groceries'), server('Casa', archived: true)], 'es');
      expect(chips.map((c) => c.name), isNot(contains('Supermercado')));
      expect(chips.map((c) => c.name), contains('Casa'));
      expect(chips.firstWhere((c) => c.name == 'Casa').source, ChipSource.suggestion);
    });

    test("names the suggestions in the person's language", () {
      expect(categoryChips([], 'en').first.name, 'Groceries');
    });
  });

  group('createSuggestions', () {
    final every = suggestedCategories.map((s) => s.key).toSet();

    test('brings back suggestions that exist only archived, instead of skipping them', () async {
      final api = _FakeCategories([
        for (final s in suggestedCategories) (name: s.names['es']!, archived: true),
      ]);
      await createSuggestions(api, every, 'es');
      expect(api.writes, hasLength(8));
      expect(
        api.writes.every(
          (w) => w.startsWith('PATCH /v1/categories/') && w.endsWith('{"archived":false}'),
        ),
        isTrue,
      );
    });

    test('leaves active ones alone, restores archived ones and makes the missing ones', () async {
      final api = _FakeCategories([
        (name: 'Supermercado', archived: false),
        (name: 'restaurante', archived: true),
      ]);
      await createSuggestions(api, every, 'es');
      expect(api.writes.where((w) => w.startsWith('PATCH')), [
        'PATCH /v1/categories/cat-1 {"archived":false}',
      ]);
      expect(api.writes.where((w) => w.startsWith('POST')), hasLength(6));
      expect(api.writes.any((w) => w.contains('"name":"Supermercado"')), isFalse);
    });

    test('counts a 409 "name taken" as created, so a retry finishes the job', () async {
      final api = _FakeCategories([], taken: {'Ocio'});
      await createSuggestions(api, every, 'es');
      expect(api.writes.where((w) => w.startsWith('POST')), hasLength(8));
    });

    test('numbers the suggestions in order, as the web does', () async {
      final api = _FakeCategories([]);
      await createSuggestions(api, every, 'es');
      final first = jsonDecode(api.writes.first.substring(api.writes.first.indexOf('{')));
      expect(first, {
        'name': 'Supermercado',
        'kind': 'expense',
        'icon': '🛒',
        'color': '#ff9f1c',
        'sortOrder': 0,
      });
    });
  });

  group('countCategoryTransactions', () {
    test('counts across pages', () async {
      final api = _PagedTransactions(450);
      expect(await countCategoryTransactions(api, 'c1'), (count: 450, capped: false));
      expect(api.requests, hasLength(3));
      expect(api.requests.first, startsWith('c1'));
    });

    test('stops at the cap and says so', () async {
      final api = _PagedTransactions(5000);
      expect(await countCategoryTransactions(api, 'c1', cap: 400), (count: 400, capped: true));
      expect(api.requests, hasLength(2));
    });

    test('throws when a page fails (the sheet then offers only Archivar)', () async {
      final api = _PagedTransactions(10)..failure = const HomeFailure(503, code: 'internal_error');
      await expectLater(
        countCategoryTransactions(api, 'c1'),
        throwsA(isA<HomeFailure>().having((f) => f.code, 'code', 'internal_error')),
      );
    });
  });
}

/// A backend for the categories, in memory, that records the writes (the web's `fakeApi`).
class _FakeCategories extends OnboardingRepositoryStub {
  _FakeCategories(List<({String name, bool archived})> start, {this.taken = const {}}) {
    for (var i = 0; i < start.length; i++) {
      categories.add(
        category(
          'cat-$i',
          start[i].name,
          archived: start[i].archived,
          icon: '🏷️',
          color: '#8e87b8',
        ),
      );
    }
  }

  final categories = <Category>[];
  final Set<String> taken;
  final writes = <String>[];

  @override
  Future<List<Category>> allCategories() async => categories.toList();

  @override
  Future<Category> updateCategory(
    String id, {
    String? name,
    String? icon,
    String? color,
    CategoryKindEnum? kind,
    bool? archived,
  }) async {
    writes.add('PATCH /v1/categories/$id {"archived":$archived}');
    final at = categories.indexWhere((c) => c.id == id);
    categories[at] = categories[at].rebuild((b) => b.archived = archived ?? b.archived);
    return categories[at];
  }

  @override
  Future<Category> createCategory({
    required String name,
    required CategoryKindEnum kind,
    required String icon,
    required String color,
    int? sortOrder,
  }) async {
    writes.add(
      'POST /v1/categories ${jsonEncode({'name': name, 'kind': kind.name, 'icon': icon, 'color': color, 'sortOrder': ?sortOrder})}',
    );
    if (taken.contains(name)) throw const HomeFailure(409, code: 'category_name_taken');
    final created = category('cat-${categories.length}', name);
    categories.add(created);
    return created;
  }
}

/// A client whose transaction list has [total] rows for the category, 200 per page.
class _PagedTransactions extends OnboardingRepositoryStub {
  _PagedTransactions(this.total);

  final int total;
  final requests = <String>[];
  Object? failure;

  @override
  Future<TransactionsPage> categoryTransactions(String categoryId, {String? cursor}) async {
    requests.add('$categoryId ${cursor ?? ''}');
    final failure = this.failure;
    if (failure != null) throw failure;
    final page = int.parse(cursor ?? '0');
    final left = total - page * 200;
    return TransactionsPage([
      for (var i = 0; i < left.clamp(0, 200); i++) tx('t-$i', '2026-10-01', -100),
    ], left > 200 ? '${page + 1}' : null);
  }
}
