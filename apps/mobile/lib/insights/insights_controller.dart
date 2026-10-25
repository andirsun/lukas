import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import 'insights_model.dart';
import 'insights_repository.dart';

/// What the donut shows: spending or income.
enum InsightsKind {
  expense,
  income;

  /// What the API's `kind` parameter calls it.
  String get wire => name;
}

/// Which movements the donut counts: all, the paid ones or the pending ones (`StatusFilter`).
enum InsightsStatus {
  all,
  paid,
  pending;

  /// The API's `status` parameter; absent (null) for all.
  String? get wire => this == all ? null : name;
}

/// What a by-category answer is for: the web's `ByCategoryRange`. Every label on the donut and its
/// legend is written from the answer's own range, never from what is being asked for.
typedef ByCategoryRange = ({Period period, InsightsKind kind, InsightsStatus status});

/// One report the screen reads, as the web's react-query holds it: the last answer ([data], and
/// [dataKey] of what it answers), what is being asked for now ([wanted]), and why the last request
/// failed. While another answer loads the old one stays ([stale]): the web's `keepPreviousData`.
class Slot<T> {
  const Slot({this.data, this.dataKey, this.wanted, this.loading = false, this.error});

  final T? data;
  final Object? dataKey;
  final Object? wanted;
  final bool loading;
  final HomeFailure? error;

  /// An older answer is on screen while the new one loads (or could not load): the web's
  /// `isPlaceholderData`.
  bool get stale => data != null && dataKey != wanted;

  /// The request failed and there is nothing of an earlier one to show: the web's
  /// `query.error && !query.data`, which throws to its `ScreenError`.
  bool get failed => error != null && data == null;

  Slot<T> copyWith({
    T? data,
    Object? dataKey,
    Object? wanted,
    bool? loading,
    HomeFailure? Function()? error,
  }) => Slot(
    data: data ?? this.data,
    dataKey: data != null ? dataKey : this.dataKey,
    wanted: wanted ?? this.wanted,
    loading: loading ?? this.loading,
    error: error == null ? this.error : error(),
  );
}

class InsightsState {
  const InsightsState({
    this.end,
    this.span = 1,
    this.kind = InsightsKind.expense,
    this.status = InsightsStatus.all,
    this.byCategory = const Slot(),
    this.spending = const Slot(),
    this.trend = const Slot(),
    this.history = const Slot(),
    this.living = const Slot(),
  });

  /// The month the period ends at (`YYYY-MM`); null before the screen has started.
  final String? end;

  /// How many months the period has: one of [spans].
  final int span;

  /// What the donut shows.
  final InsightsKind kind;
  final InsightsStatus status;

  /// The donut's totals ([ByCategoryRange] answered).
  final Slot<CategoryReport> byCategory;

  /// The period's spending, which Lukitas talks about whatever the donut shows.
  final Slot<CategoryReport> spending;

  /// Income, expenses and budget per month over the period ([Period] answered).
  final Slot<TrendReport> trend;

  /// The months "¿Cuánto me cuesta vivir?" may average ([livingPeriod] answered).
  final Slot<TrendReport> history;

  /// The averages over [livingMonths] months (the number answered).
  final Slot<CostOfLivingReport> living;

  /// How many complete months have anything in them: how many "¿Cuánto me cuesta vivir?"
  /// averages. Null until [history] is known; 0 when there are none.
  int? get livingMonths {
    final months = history.data?.months;
    return months == null
        ? null
        : livingWindow([for (final m in months) (income: m.income, expenses: m.expenses)]);
  }

  /// The period the screen asks about.
  Period? get period => end == null ? null : periodOf(end!, span);

  /// The first request that failed with nothing to show: the screen is its error then.
  HomeFailure? get failure {
    for (final Slot<Object> slot in [byCategory, spending, trend, history, living]) {
      if (slot.failed) return slot.error;
    }
    return null;
  }

  /// An earlier answer is on screen and a newer request failed: the figures may be old.
  HomeFailure? get staleFailure {
    for (final Slot<Object> slot in [byCategory, spending, trend, history, living]) {
      if (slot.error != null && slot.data != null) return slot.error;
    }
    return null;
  }

  InsightsState copyWith({
    String? end,
    int? span,
    InsightsKind? kind,
    InsightsStatus? status,
    Slot<CategoryReport>? byCategory,
    Slot<CategoryReport>? spending,
    Slot<TrendReport>? trend,
    Slot<TrendReport>? history,
    Slot<CostOfLivingReport>? living,
  }) => InsightsState(
    end: end ?? this.end,
    span: span ?? this.span,
    kind: kind ?? this.kind,
    status: status ?? this.status,
    byCategory: byCategory ?? this.byCategory,
    spending: spending ?? this.spending,
    trend: trend ?? this.trend,
    history: history ?? this.history,
    living: living ?? this.living,
  );
}

/// Análisis' state and what changes it, as the web's `Insights` does (apps/web/app/features/
/// insights/Insights.tsx): the month the period ends at, its span, and what the donut shows; each
/// report loads as its own request, and only the latest request for it may land, however late an
/// older answer arrives. While another answer loads the old one stays on screen, labelled as what it
/// answers. A failure is a [HomeFailure], the same mapping home uses.
///
/// The figures come from the server every time: there is no cache of the reports, so offline the
/// screen says so. The profile and the categories are home's ([homeProvider]).
class InsightsController extends Notifier<InsightsState> {
  InsightsRepository get _repo => ref.read(insightsRepositoryProvider);

  var _alive = true;

  /// Counts the requests of each report: only the latest may touch the screen.
  final _seq = <String, int>{};

  @override
  InsightsState build() {
    // A new session (another person signing in) starts from nothing.
    ref.watch(insightsRepositoryProvider);
    _alive = true;
    _seq.clear();
    ref.onDispose(() => _alive = false);
    return const InsightsState();
  }

  void _set(InsightsState next) {
    if (_alive) state = next;
  }

  /// The current month (`YYYY-MM`) in the profile's time zone, asked of the clock; null before
  /// home knows the profile.
  String? get _current {
    final data = ref.read(homeProvider).data;
    return data?.todayAt(ref.read(clockProvider)()).substring(0, 7);
  }

  /// A month no later than the current one: the person cannot look ahead.
  String _clamp(String month, String current) => month.compareTo(current) > 0 ? current : month;

  /// Opens on [month] (`YYYY-MM`) or, without one, the current month, and loads everything. Called
  /// once the profile is known.
  Future<void> start(String? month) {
    final current = _current;
    if (current == null) return Future.value();
    _set(state.copyWith(end: _clamp(month ?? current, current)));
    return _loadAll();
  }

  /// Moves the period to end at [month] (never past the current month).
  Future<void> showMonth(String month) {
    final current = _current;
    if (current == null) return Future.value();
    final end = _clamp(month, current);
    if (end == state.end) return Future.value();
    _set(state.copyWith(end: end));
    return _loadAll();
  }

  /// The period has [span] months (one of [spans]).
  Future<void> setSpan(int span) {
    if (!isSpan(span) || span == state.span) return Future.value();
    _set(state.copyWith(span: span));
    return _loadAll();
  }

  Future<void> setKind(InsightsKind kind) {
    if (kind == state.kind) return Future.value();
    _set(state.copyWith(kind: kind));
    return _loadAll();
  }

  Future<void> setStatus(InsightsStatus status) {
    if (status == state.status) return Future.value();
    _set(state.copyWith(status: status));
    return _loadAll();
  }

  /// Asks for everything again (a pull to refresh, Reintentar, a movement added from the ＋).
  /// What is on screen stays while it is on its way, and when it fails.
  Future<void> refresh() => _loadAll(force: true);

  /// A failure that means the session is over: the server does not know the token any more.
  HomeFailure _failure(Object error) {
    final failure = error is HomeFailure ? error : const HomeFailure(0);
    if (_alive && failure.unauthorized) {
      unawaited(ref.read(sessionProvider.notifier).signOut(discardGuest: true));
    }
    return failure;
  }

  Future<void> _loadAll({bool force = false}) {
    final end = state.end;
    final current = _current;
    if (end == null || current == null) return Future.value();
    final period = periodOf(end, state.span);
    final range = (period: period, kind: state.kind, status: state.status);
    final spendingRange = (period: period, kind: InsightsKind.expense, status: InsightsStatus.all);
    // Lukitas talks about the period's spending, whatever the donut shows. When the donut shows
    // that too, it is one request, as the web's shared query key makes it.
    final same = range == spendingRange;
    return Future.wait([
      _fetch<CategoryReport>(
        'byCategory',
        range,
        force,
        (s) => s.byCategory,
        (s, slot) => s.copyWith(
          byCategory: slot,
          spending: same ? _mirror(s.spending, slot, spendingRange) : null,
        ),
        () => _repo.byCategory(
          from: period.from,
          to: period.to,
          kind: range.kind.wire,
          status: range.status.wire,
        ),
      ),
      if (!same)
        _fetch<CategoryReport>(
          'spending',
          spendingRange,
          force,
          (s) => s.spending,
          (s, slot) => s.copyWith(spending: slot),
          () => _repo.byCategory(from: period.from, to: period.to, kind: 'expense'),
        ),
      _fetch<TrendReport>(
        'trend',
        period,
        force,
        (s) => s.trend,
        (s, slot) => s.copyWith(trend: slot),
        () => _repo.trend(from: period.from, to: period.to),
      ),
      _loadLiving(current, force),
    ]);
  }

  /// The spending slot of a period the donut shows too: what the donut's slot holds when that is a
  /// spending answer, and what is asked and why it failed as the donut's request is.
  Slot<CategoryReport> _mirror(
    Slot<CategoryReport> own,
    Slot<CategoryReport> of,
    ByCategoryRange key,
  ) {
    final range = of.dataKey;
    final spending =
        of.data != null &&
        range is ByCategoryRange &&
        range.kind == InsightsKind.expense &&
        range.status == InsightsStatus.all;
    return Slot(
      data: spending ? of.data : own.data,
      dataKey: spending ? of.dataKey : own.dataKey,
      wanted: key,
      loading: of.loading,
      error: of.error,
    );
  }

  /// The last six complete months' trend, then the average over the months that have anything.
  Future<void> _loadLiving(String current, bool force) async {
    final period = livingPeriod(current);
    await _fetch<TrendReport>(
      'history',
      period,
      force,
      (s) => s.history,
      (s, slot) => s.copyWith(history: slot),
      () => _repo.trend(from: period.from, to: period.to),
    );
    final months = state.livingMonths;
    if (!_alive || months == null || months == 0) return;
    await _fetch<CostOfLivingReport>(
      'living',
      months,
      force,
      (s) => s.living,
      (s, slot) => s.copyWith(living: slot),
      () => _repo.costOfLiving(months),
    );
  }

  /// Asks for one report: the slot wants [key] now, the request goes out (unless that is what it
  /// holds and [force] is off), and its answer lands only if no later request for the slot went
  /// out meanwhile.
  Future<void> _fetch<T extends Object>(
    String name,
    Object key,
    bool force,
    Slot<T> Function(InsightsState) read,
    InsightsState Function(InsightsState, Slot<T>) write,
    Future<T> Function() fetch,
  ) async {
    final slot = read(state);
    if (!force && slot.dataKey == key && slot.data != null && slot.error == null) {
      _seq[name] = (_seq[name] ?? 0) + 1;
      _set(write(state, slot.copyWith(wanted: key, loading: false)));
      return;
    }
    final seq = _seq[name] = (_seq[name] ?? 0) + 1;
    _set(write(state, slot.copyWith(wanted: key, loading: true, error: () => null)));
    try {
      final data = await fetch();
      if (!_alive || _seq[name] != seq) return;
      _set(
        write(
          state,
          read(state).copyWith(data: data, dataKey: key, loading: false, error: () => null),
        ),
      );
    } on Object catch (error) {
      final failure = _failure(error);
      if (!_alive || _seq[name] != seq) return;
      _set(write(state, read(state).copyWith(loading: false, error: () => failure)));
    }
  }
}

/// Análisis' state, kept while the screen is on show. Leaving it drops it, so the next person never
/// sees it and nothing is fetched for a screen nobody sees.
final insightsProvider = NotifierProvider.autoDispose<InsightsController, InsightsState>(
  InsightsController.new,
);
