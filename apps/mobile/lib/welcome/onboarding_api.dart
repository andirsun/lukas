// What the welcome writes, and how it decides what to write: a port of the functions of
// apps/web/app/features/onboarding/onboarding-api.ts. They take an [OnboardingRepository], so a
// test can stand in for the server.
import 'dart:async';

import '../api/gen/lukitas_api.dart';
import '../home/home_repository.dart';
import '../import/budget_input.dart';
import 'category_chips.dart';
import 'onboarding_repository.dart';
import 'suggested_categories.dart';

bool _nameTaken(Object problem) => problem is HomeFailure && problem.code == 'category_name_taken';

/// Creates the suggestion [s] named in [locale]. A 409 `category_name_taken` counts as created.
Future<void> _create(OnboardingRepository repo, SuggestedCategory s, String locale) async {
  try {
    await repo.createCategory(
      name: s.names[locale] ?? s.names['es']!,
      kind: s.kind,
      icon: s.glyph,
      color: s.tint,
      sortOrder: suggestedCategories.indexOf(s),
    );
  } on Object catch (problem) {
    if (!_nameTaken(problem)) rethrow;
  }
}

/// Brings back the archived category [id].
Future<void> _restore(OnboardingRepository repo, String id) =>
    repo.updateCategory(id, archived: false);

/// Makes sure the suggestions in [keys] are active categories: one they have active stays as it is,
/// one that exists only archived is brought back (so "Entrar directo" works after every suggestion
/// was deselected), and the missing ones are created. It reads the categories first and a 409
/// `category_name_taken` counts as created, so after a partial failure (a lost connection halfway)
/// running it again finishes the job instead of failing on the ones already there.
Future<void> createSuggestions(OnboardingRepository repo, Set<String> keys, String locale) async {
  final all = await repo.allCategories();
  final active = {
    for (final c in all)
      if (!c.archived) suggestionFor(c.name)?.key,
  };
  await Future.wait([
    for (final s in suggestedCategories)
      if (keys.contains(s.key) && !active.contains(s.key))
        () async {
          final archived = all
              .where((c) => c.archived && suggestionFor(c.name)?.key == s.key)
              .firstOrNull;
          if (archived != null) {
            await _restore(repo, archived.id);
            return;
          }
          await _create(repo, s, locale);
        }(),
  ]);
}

/// How many transactions a category has, counting up to [cap] (pages of 200); `capped` when there
/// are at least that many. It decides whether the category can be deleted here.
Future<({int count, bool capped})> countCategoryTransactions(
  OnboardingRepository repo,
  String categoryId, {
  int cap = 2000,
}) async {
  var count = 0;
  String? cursor;
  do {
    final page = await repo.categoryTransactions(categoryId, cursor: cursor);
    count += page.items.length;
    cursor = page.nextCursor;
  } while (cursor != null && count < cap);
  return (count: count, capped: cursor != null);
}

/// What can be changed on one of the person's categories from the edit sheet.
class CategoryEdit {
  const CategoryEdit({
    required this.name,
    required this.glyph,
    required this.tint,
    required this.kind,
  });

  final String name;
  final String glyph;
  final String tint;
  final CategoryKindEnum kind;
}

/// Saves an edit of one of the person's categories, in one PATCH: name, emoji, tint, and the kind
/// when it changed. The API refuses a kind change (409 `category_has_transactions`) while the
/// category has transactions, so the count the sheet shows is only a hint.
Future<void> saveCategoryEdit(OnboardingRepository repo, Category category, CategoryEdit edit) =>
    repo.updateCategory(
      category.id,
      name: edit.name,
      icon: edit.glyph,
      color: edit.tint,
      kind: edit.kind != category.kind ? edit.kind : null,
    );

/// Archives one of the person's categories ("Eliminar" with no transactions, or "Archivar").
Future<void> archiveCategory(OnboardingRepository repo, String id) =>
    repo.updateCategory(id, archived: true);

/// Applies the categories step: the chosen suggestions are made (or brought back, when an archived
/// category already has that name), and with [archive] the person's categories they deselected are
/// archived. SALTAR passes `archive: false`: skipping never takes anything away.
Future<void> applyCategorySelection(
  OnboardingRepository repo,
  List<CategoryChipModel> chips,
  Set<String> selected,
  String locale, {
  required bool archive,
}) async {
  final all = await repo.allCategories();
  final writes = <Future<void>>[];
  for (final chip in chips) {
    final chosen = selected.contains(chip.id);
    if (chip.source == ChipSource.category) {
      if (archive && !chosen) writes.add(archiveCategory(repo, chip.id));
      continue;
    }
    final suggestion = suggestedCategories.where((s) => s.key == chip.suggestionKey).firstOrNull;
    if (!chosen || suggestion == null) continue;
    final archived = all
        .where((c) => c.archived && suggestionFor(c.name)?.key == suggestion.key)
        .firstOrNull;
    if (archived != null) {
      writes.add(_restore(repo, archived.id));
      continue;
    }
    writes.add(_create(repo, suggestion, locale));
  }
  await Future.wait(writes);
}

/// Saves the budgets typed or prefilled, from [month] (`YYYY-MM`, this month in the profile's time
/// zone) on: each valid amount that differs from what the category already has. Empty fields write
/// nothing.
Future<void> saveBudgets(
  OnboardingRepository repo,
  Iterable<Category> categories,
  Map<String, String> drafts,
  String locale,
  String month,
) async {
  await Future.wait([
    for (final c in categories)
      if (c.kind == CategoryKindEnum.expense && !c.archived)
        () async {
          final int? amount;
          try {
            amount = parseBudgetInput(drafts[c.id] ?? '', locale);
          } on InvalidAmountException {
            return;
          }
          if (amount == null || c.currentBudget == amount) return;
          await repo.setBudget(c.id, amount, month: month);
        }(),
  ]);
}
