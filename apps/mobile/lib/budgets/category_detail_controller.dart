import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import 'budgets_repository.dart';

/// A category's detail for one month: the month's summary (its budget and what was spent), its
/// movements that month, and, for an income category, what came in.
class CategoryDetailState {
  const CategoryDetailState({
    this.month = '',
    this.summary,
    this.items,
    this.nextCursor,
    this.income,
    this.loadingMore = false,
    this.failure,
    this.paidHere = const {},
    this.restored = const {},
  });

  /// The month on screen (`YYYY-MM`); empty before the first load is asked for.
  final String month;

  /// [month]'s summary. Null while it loads: never another month's.
  final Summary? summary;

  /// The category's movements of [month] loaded so far, newest first; null while they load.
  final List<Transaction>? items;

  /// Where the next page starts; null when everything is loaded.
  final String? nextCursor;

  /// What came in to an income category in [month], in hundredths; null for the others, and while
  /// it loads.
  final int? income;
  final bool loadingMore;

  /// Why the load failed with nothing to show (the web's `ScreenError`).
  final HomeFailure? failure;

  /// Pending rows paid from here: their badge says "Pagado" although the row is already paid.
  final Set<String> paidHere;

  /// Rows brought back by Deshacer, which slide in.
  final Set<String> restored;

  /// [month]'s line in the summary for [categoryId], or null.
  SummaryCategoriesInner? line(String categoryId) =>
      summary?.categories.where((c) => c.categoryId == categoryId).firstOrNull;

  CategoryDetailState copyWith({
    Summary? summary,
    List<Transaction>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    Set<String>? paidHere,
    Set<String>? restored,
  }) => CategoryDetailState(
    month: month,
    summary: summary ?? this.summary,
    items: items ?? this.items,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    income: income,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure,
    paidHere: paidHere ?? this.paidHere,
    restored: restored ?? this.restored,
  );
}

/// Orders by date then id, newest first: the API's order.
int _newestFirst(Transaction a, Transaction b) {
  final byDate = b.date.compareTo(a.date);
  return byDate != 0 ? byDate : b.id.compareTo(a.id);
}

/// What a category's detail loads and changes: the month on screen (never more than one at a time:
/// only the latest month asked for may arrive), its movements, a budget set from it, and the rows'
/// swipes (delete with Deshacer, pay).
///
/// A budget that is saved reaches home through home's controller ([HomeController.budgetChanged]),
/// so Te quedan, the Presupuestos bars and the widget follow; a change to a movement tells home too.
class CategoryDetailController extends Notifier<CategoryDetailState> {
  CategoryDetailController(this.categoryId);

  final String categoryId;

  HomeRepository get _home => ref.read(homeRepositoryProvider);
  BudgetsRepository get _repo => ref.read(budgetsRepositoryProvider);

  var _alive = true;

  /// Counts the loads of a month: only the latest one may put its month on screen.
  var _loadSeq = 0;

  /// Counts the summary requests: only the latest one may touch the screen, so an old answer that
  /// lands late cannot undo a newer one.
  var _summarySeq = 0;

  @override
  CategoryDetailState build() {
    ref.watch(homeRepositoryProvider);
    ref.watch(budgetsRepositoryProvider);
    _alive = true;
    _loadSeq = 0;
    _summarySeq = 0;
    _ended = false;
    ref.onDispose(() => _alive = false);
    return const CategoryDetailState();
  }

  void _set(CategoryDetailState next) {
    if (_alive) state = next;
  }

  /// The session was ended once already (several requests of a load may each be refused).
  var _ended = false;

  /// Passes a failure on, ending the session (once) when the server no longer knows it.
  HomeFailure _failure(Object error) {
    if (error is! HomeFailure) return const HomeFailure(0);
    if (error.unauthorized && _alive && !_ended) {
      _ended = true;
      unawaited(ref.read(sessionProvider.notifier).signOut(discardGuest: true));
    }
    return error;
  }

  /// A request, noting a refused session whatever else the others say.
  Future<T> _watch<T>(Future<T> request) =>
      request.catchError((Object error) => throw _failure(error));

  bool get _isIncome =>
      ref.read(homeProvider).data?.categories[categoryId]?.kind == CategoryKindEnum.income;

  /// Moves to [month] (`YYYY-MM`): its summary and this category's movements load and replace what
  /// is on screen. Nothing of the month before stays as this one's while it loads.
  Future<void> showMonth(String month) {
    _set(CategoryDetailState(month: month, paidHere: state.paidHere, restored: state.restored));
    return _load(month);
  }

  /// Loads the month on screen again (silently: what is there stays while it is on its way, or when
  /// it fails). With nothing there, a failure shows.
  Future<void> refresh() => _load(state.month, keep: state.items != null);

  Future<void> _load(String month, {bool keep = false}) async {
    if (month.isEmpty) return;
    final seq = ++_loadSeq;
    final income = _isIncome;
    try {
      final results = await Future.wait<Object?>([
        _watch(_home.summary(month)),
        _watch(_repo.categoryTransactions(month, categoryId)),
        income ? _watch(_repo.incomeTotal(month, categoryId)) : Future<int?>.value(),
      ]);
      if (!_alive || seq != _loadSeq) return;
      // This load is the latest word: an older summary still on its way is dropped.
      _summarySeq++;
      final page = results[1]! as TransactionsPage;
      _set(
        CategoryDetailState(
          month: month,
          summary: results[0]! as Summary,
          items: page.items,
          nextCursor: page.nextCursor,
          income: results[2] as int?,
          paidHere: state.paidHere,
          restored: state.restored,
        ),
      );
    } on Object catch (error) {
      if (!_alive || seq != _loadSeq) return;
      final failure = _failure(error);
      // What is on screen of this month stays; with nothing, the failure is shown.
      if (keep && state.month == month && state.items != null) return;
      _set(
        CategoryDetailState(
          month: month,
          failure: failure,
          paidHere: state.paidHere,
          restored: state.restored,
        ),
      );
    }
  }

  /// Brings the next page ("Ver más movimientos") below the rows shown. Throws a [HomeFailure] and
  /// keeps the list as it is when it fails.
  Future<void> loadMore() async {
    final month = state.month;
    final cursor = state.nextCursor;
    if (state.items == null || cursor == null || state.loadingMore) return;
    _set(state.copyWith(loadingMore: true));
    try {
      final page = await _watch(_repo.categoryTransactions(month, categoryId, cursor: cursor));
      // Another month was chosen while the page was on its way: its rows are that month's.
      if (!_alive || state.month != month || state.items == null) {
        if (_alive) _set(state.copyWith(loadingMore: false));
        return;
      }
      final known = {for (final tx in state.items!) tx.id};
      _set(
        state.copyWith(
          loadingMore: false,
          items: [...state.items!, ...page.items.where((tx) => !known.contains(tx.id))],
          nextCursor: () => page.nextCursor,
        ),
      );
    } on Object catch (error) {
      if (_alive) _set(state.copyWith(loadingMore: false));
      throw _failure(error);
    }
  }

  /// Sets this category's budget to [cents] from the month on screen on, then brings the month's
  /// summary here and at home up to date. A failure is thrown as a [HomeFailure] and changes
  /// nothing: the old budget stays.
  Future<void> setBudget(int cents) async {
    final month = state.month;
    try {
      await _repo.setBudget(categoryId, cents, month: month);
    } on Object catch (error) {
      throw _failure(error);
    }
    if (!_alive) return;
    unawaited(ref.read(homeProvider.notifier).budgetChanged());
    await _refreshSummary(month);
  }

  /// The month's summary again, silently (only the latest answer counts).
  Future<void> _refreshSummary(String month) async {
    final request = ++_summarySeq;
    try {
      final summary = await _watch(_home.summary(month));
      if (!_alive || request != _summarySeq || state.month != month) return;
      _set(state.copyWith(summary: summary));
    } on Object {
      // The figures stay as they were: the bar does not lie about what it last knew.
    }
  }

  void _replaceItems(List<Transaction> items) {
    if (state.items != null) _set(state.copyWith(items: items));
  }

  /// A row brought back by Deshacer has slid in: it is a plain row again.
  void settleRestored(String id) {
    if (!state.restored.contains(id)) return;
    _set(state.copyWith(restored: {...state.restored}..remove(id)));
  }

  /// Home catches up with a change made here to a movement.
  void _tellHome() => unawaited(ref.read(homeProvider.notifier).refresh());

  /// Deletes [tx]: the row goes at once, and comes back if the server refuses (then a [HomeFailure]
  /// is thrown).
  Future<void> remove(Transaction tx) async {
    final month = state.month;
    final items = state.items;
    if (items == null) return;
    _replaceItems([
      for (final t in items)
        if (t.id != tx.id) t,
    ]);
    try {
      await _home.delete(tx.id);
    } on Object catch (error) {
      if (_alive && state.month == month && state.items != null) {
        _replaceItems([...state.items!.where((t) => t.id != tx.id), tx]..sort(_newestFirst));
      }
      throw _failure(error);
    }
    _tellHome();
    unawaited(_refreshSummary(month));
  }

  /// Brings a deleted [tx] back (Deshacer): the same row, in its place, sliding in.
  Future<void> restore(Transaction tx) async {
    final Transaction back;
    try {
      back = await _home.restore(tx.id);
    } on Object catch (error) {
      throw _failure(error);
    }
    if (!_alive) return;
    // It shows only where it belongs: Deshacer outlives a change of month.
    if (state.items != null && back.date.startsWith(state.month)) {
      _set(
        state.copyWith(
          restored: {...state.restored, back.id},
          items: [...state.items!.where((t) => t.id != back.id), back]..sort(_newestFirst),
        ),
      );
    }
    _tellHome();
    unawaited(_refreshSummary(state.month));
  }

  /// Marks a pending [tx] paid. A refusal puts the row back to pending and throws a [HomeFailure].
  Future<void> markPaid(Transaction tx) async {
    final items = state.items;
    if (items == null || state.paidHere.contains(tx.id)) return;
    final month = state.month;
    final paid = tx.rebuild((b) => b.status = TransactionStatusEnum.paid);
    _set(
      state.copyWith(
        paidHere: {...state.paidHere, tx.id},
        items: [for (final t in items) t.id == tx.id ? paid : t],
      ),
    );
    try {
      await _home.markPaid(tx.id);
    } on Object catch (error) {
      if (_alive && state.items != null) {
        _set(
          state.copyWith(
            paidHere: {...state.paidHere}..remove(tx.id),
            items: [for (final t in state.items!) t.id == tx.id ? tx : t],
          ),
        );
      }
      throw _failure(error);
    }
    _tellHome();
    await _refreshSummary(month);
  }
}

/// A category's detail, kept while its screen is on screen.
final categoryDetailProvider = NotifierProvider.autoDispose
    .family<CategoryDetailController, CategoryDetailState, String>(CategoryDetailController.new);
