import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import '../l10n/app_localizations.dart';
import '../notices/notice_sync.dart';
import 'recurring_repository.dart';

/// The recurring payments the screen shows: the list, or why it could not be read.
class RecurringState {
  const RecurringState({this.rules, this.failure});

  /// Oldest first, as the API sends them; null while they load for the first time.
  final List<Recurrence>? rules;

  /// Why the first load failed (the web's page throws and shows its error screen).
  final HomeFailure? failure;
}

/// The list on the recurring payments' page. It loads when the page opens and is kept up to date by
/// [RecurringActions]: what the server answered to a change is put in its place at once.
class RecurringList extends Notifier<RecurringState> {
  var _alive = true;
  var _seq = 0;

  @override
  RecurringState build() {
    ref.watch(recurringRepositoryProvider);
    _alive = true;
    _seq = 0;
    ref.onDispose(() => _alive = false);
    scheduleMicrotask(refresh);
    return const RecurringState();
  }

  /// Reads the list again. What is on screen stays when it fails, unless there was nothing yet.
  Future<void> refresh() async {
    if (!_alive) return;
    final request = ++_seq;
    try {
      final rules = await ref.read(recurringRepositoryProvider).list();
      if (_alive && request == _seq) state = RecurringState(rules: rules);
    } on Object catch (error) {
      if (!_alive || request != _seq) return;
      final failure = error is HomeFailure ? error : const HomeFailure(0);
      if (failure.unauthorized) {
        unawaited(ref.read(sessionProvider.notifier).signOut(discardGuest: true));
      }
      if (state.rules == null) state = RecurringState(failure: failure);
    }
  }

  /// A change the server accepted, applied to what is shown (a read still on its way is dropped:
  /// it may have been made before the change).
  void apply(List<Recurrence> Function(List<Recurrence> rules) change) {
    if (!_alive) return;
    _seq++;
    state = RecurringState(rules: change(state.rules ?? const []));
  }
}

final recurringListProvider = NotifierProvider.autoDispose<RecurringList, RecurringState>(
  RecurringList.new,
);

/// What the form and the sheets say when a change fails: the web's `problemMessage`
/// (`errors.<code>`, the generic text for a code with none).
String recurringFailureMessage(AppLocalizations l10n, HomeFailure failure) {
  if (failure.offline) return l10n.errorNetwork;
  return switch (failure.code) {
    'category_not_found' => l10n.addErrorCategory,
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

/// Creating, changing and deleting recurring payments, and telling everything that depends on them
/// (the web's `settleRecurrences`, apps/web/app/api/queries.ts).
///
/// A recurring payment makes pending rows in this month and the next, so every change reaches home
/// before it returns: the month is loaded again (its pending rows, Te quedan and the saved month)
/// and the widget's snapshot follows. It also asks the notices to look again: "Hoy vence…" is
/// scheduled only while a recurring payment is running, and the server drops a deleted (or edited)
/// payment's unpaid rows from this month on, so what the 9:00 notice finds due today is what is
/// left. A failure is thrown as a [HomeFailure] and changes nothing.
class RecurringActions {
  RecurringActions(this._ref);

  final Ref _ref;

  RecurringRepository get _repo => _ref.read(recurringRepositoryProvider);

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
  /// change may have been made all the same, the list, home and the notices look again, so a rule
  /// made by a request whose answer was lost shows up (instead of being made twice by the next try)
  /// and a deleted one goes.
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
      if (_ref.exists(recurringListProvider)) {
        await _ref.read(recurringListProvider.notifier).refresh();
      }
      await _settle();
    } on Object {
      // Still offline: what is on screen stays, and nothing breaks.
    }
  }

  void _apply(List<Recurrence> Function(List<Recurrence> rules) change) {
    if (_ref.exists(recurringListProvider)) {
      _ref.read(recurringListProvider.notifier).apply(change);
    }
  }

  Future<void> _settle() async {
    await _ref.read(homeProvider.notifier).reloaded();
    _ref.read(noticeSyncProvider).request();
  }

  /// "Nuevo recurrente".
  Future<void> create(NewRecurrence values) async {
    final made = await _call(() => _repo.create(values));
    _apply((rules) => [...rules, made]);
    await _settle();
  }

  /// Saves [values] over [editing].
  Future<void> save(Recurrence editing, NewRecurrence values) async {
    final saved = await _call(
      () => _repo.update(
        editing.id,
        values,
        categoryChanged: values.categoryId != editing.categoryId,
      ),
    );
    _apply((rules) => [for (final r in rules) r.id == saved.id ? saved : r]);
    await _settle();
  }

  /// Deletes [rule], after the question: it is no longer made pending, and its unpaid pending rows
  /// from this month on go.
  Future<void> remove(Recurrence rule) async {
    await _call(() => _repo.delete(rule.id));
    _apply(
      (rules) => [
        for (final r in rules)
          if (r.id != rule.id) r,
      ],
    );
    await _settle();
  }
}

final recurringActionsProvider = Provider<RecurringActions>(RecurringActions.new);
