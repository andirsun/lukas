import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import '../l10n/app_localizations.dart';
import '../notices/notice_sync.dart';
import 'categories_repository.dart';
import 'category_model.dart';

/// What the sheet or a toast says when changing a category fails: the web's `problemMessage`
/// (`errors.<code>`, the generic text for a code with none).
String categoryFailureMessage(AppLocalizations l10n, HomeFailure failure) {
  if (failure.offline) return l10n.errorNetwork;
  return switch (failure.code) {
    'category_name_taken' => l10n.categoryErrorNameTaken,
    'category_has_transactions' => l10n.categoryErrorHasTransactions,
    'validation_failed' => l10n.addErrorInvalid,
    'not_found' => l10n.budgetErrorNotFound,
    _ =>
      failure.status == 404
          ? l10n.budgetErrorNotFound
          : failure.status >= 500
          ? l10n.errorInternal
          : l10n.errorGeneric,
  };
}

/// Creating, changing, archiving and restoring categories, and telling everything that shows them
/// (the web's `useCategorySheets`, apps/web/app/features/categories/use-category-sheets.tsx).
///
/// Every change reaches home before it returns: the categories and the month's summary are asked
/// again, so the Categorías tab, Te quedan and the bars, the widget's snapshot and the saved month
/// follow. Archiving also ends the category's recurring payments on the server and drops their
/// unpaid rows from today on, so it reloads home's month (the pending rows) and asks the notices to
/// look again (they exist only while a recurring payment does). A failure is thrown as a
/// [HomeFailure] and changes nothing.
class CategoriesActions {
  CategoriesActions(this._ref);

  final Ref _ref;

  CategoriesRepository get _repo => _ref.read(categoriesRepositoryProvider);
  HomeController get _home => _ref.read(homeProvider.notifier);

  /// Passes a failure on, ending the session when the server no longer knows it.
  HomeFailure _failure(Object error) {
    if (error is! HomeFailure) return const HomeFailure(0);
    if (error.unauthorized) {
      unawaited(_ref.read(sessionProvider.notifier).signOut(discardGuest: true));
    }
    return error;
  }

  /// Whether a failed request may still have reached the server: no answer at all (offline, a
  /// timeout, a lost response) or a server error. A definite refusal (a 4xx) changed nothing.
  static bool _mayHaveReached(HomeFailure failure) => failure.offline || failure.status >= 500;

  /// A request, settled even when it fails (the web's `onSettled` runs on error too): when the
  /// change may have been made all the same, home's categories and month look again, and so do the
  /// notices (an archive ends recurring payments), so a category made by a request whose answer
  /// was lost shows up instead of being made, and refused as a duplicate, by the next try.
  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on Object catch (error) {
      final failure = _failure(error);
      if (_mayHaveReached(failure)) unawaited(_settleAfterFailure());
      throw failure;
    }
  }

  Future<void> _settleAfterFailure() async {
    try {
      await _home.reloaded();
      _ref.read(noticeSyncProvider).request();
    } on Object {
      // Still offline: what is on screen stays, and nothing breaks.
    }
  }

  /// "Nueva categoría".
  Future<void> create(NewCategory values) async {
    await _call(() => _repo.create(values));
    await _home.categoriesChanged();
  }

  /// Saves [values] over [editing]: the name, emoji and tint in one PATCH, and the kind only when it
  /// changed (the API refuses a change while the category has transactions).
  Future<void> save(Category editing, NewCategory values) async {
    await _call(
      () => _repo.update(
        editing.id,
        name: values.name,
        icon: values.glyph,
        color: values.tint,
        kind: values.kind != editing.kind ? values.kind : null,
      ),
    );
    await _home.categoriesChanged();
  }

  /// Archives [category], after the question. The server ends its recurring payments.
  Future<void> archive(Category category) async {
    await _call(() => _repo.update(category.id, archived: true));
    await _home.reloaded();
    _ref.read(noticeSyncProvider).request();
  }

  /// Brings an archived [category] back. Its recurring payments stay ended.
  Future<void> restore(Category category) async {
    await _call(() => _repo.update(category.id, archived: false));
    await _home.categoriesChanged();
  }

  /// Whether [categoryId] has transactions, so its kind is fixed. A failure counts as "no
  /// transactions": the API still refuses the change.
  Future<bool> hasTransactions(String categoryId) async {
    try {
      return await _repo.hasTransactions(categoryId);
    } on Object {
      return false;
    }
  }

  /// How many recurring payments archiving [categoryId] stops (the sheet says so); zero while they
  /// cannot be read.
  Future<int> recurrencesStopped(String categoryId) async {
    final data = _ref.read(homeProvider).data;
    if (data == null) return 0;
    try {
      final rules = await _repo.recurrences();
      return activeRecurrencesIn(rules, categoryId, data.todayAt(_ref.read(clockProvider)()));
    } on Object {
      return 0;
    }
  }
}

final categoriesActionsProvider = Provider<CategoriesActions>(CategoriesActions.new);
