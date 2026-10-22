import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/device.dart';
import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../capture/parser/dates.dart';
import 'home_repository.dart';
import 'lukas_line.dart';
import 'widget_snapshot.dart';

/// How long Lukitas talks about a save or a payment before going back to the month's line (the
/// web's `EVENT_LINE_MS`, founder feedback 2026-10-22: a line that stayed for ages).
const eventLineDuration = Duration(seconds: 10);

/// The clock, replaced in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Writes the widget's snapshot after the month's figures load (replaced in tests).
final widgetSnapshotWriterProvider =
    Provider<
      Future<void> Function(Summary summary, {required String currency, required String locale})
    >(
      (ref) =>
          (summary, {required currency, required locale}) => writeWidgetSnapshot(
            summary,
            currency: currency,
            locale: locale,
            store: ref.read(widgetStoreProvider),
          ),
    );

/// The language amounts and dates are written in: English when the phone asks for it, Spanish
/// otherwise (the same rule as the app's `localeResolutionCallback`).
String languageOfTag(String tag) => tag.toLowerCase().startsWith('en') ? 'en' : 'es';

/// The month on screen: its summary and movements.
class HomeData {
  const HomeData({
    required this.month,
    required this.today,
    required this.currency,
    required this.summary,
    required this.categories,
    required this.items,
    required this.nextCursor,
  });

  /// `YYYY-MM`.
  final String month;

  /// `YYYY-MM-DD`, in the profile's time zone.
  final String today;
  final String currency;
  final Summary summary;

  /// Every category (archived ones too) by id.
  final Map<String, Category> categories;

  /// The movements loaded so far, newest first.
  final List<Transaction> items;

  /// Where the next page starts; null when everything is loaded.
  final String? nextCursor;

  HomeData copyWith({
    Summary? summary,
    Map<String, Category>? categories,
    List<Transaction>? items,
    String? Function()? nextCursor,
  }) => HomeData(
    month: month,
    today: today,
    currency: currency,
    summary: summary ?? this.summary,
    categories: categories ?? this.categories,
    items: items ?? this.items,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
  );
}

/// The save or payment Lukitas is talking about.
class HomeEvent {
  const HomeEvent(this.id, this.event);

  /// Grows with each event, so the same kind of event twice still counts as new.
  final int id;
  final LukasEvent event;
}

class HomeState {
  const HomeState({
    this.data,
    this.loading = true,
    this.failure,
    this.stale = false,
    this.loadingMore = false,
    this.event,
    this.restored = const {},
    this.paidHere = const {},
  });

  /// The last month loaded. Kept while a refresh fails: offline, it stays on screen (spec 6.3).
  final HomeData? data;

  /// The first load is under way (nothing to show yet).
  final bool loading;

  /// Why the first load failed, with nothing to show.
  final HomeFailure? failure;

  /// The last refresh failed: [data] is from an earlier load.
  final bool stale;
  final bool loadingMore;

  /// While Lukitas should still talk about it.
  final HomeEvent? event;

  /// Rows brought back by Deshacer, which slide in.
  final Set<String> restored;

  /// Pending rows paid from home: their badge says "Pagado" although the row is already paid.
  final Set<String> paidHere;

  HomeState copyWith({
    HomeData? data,
    bool? loading,
    HomeFailure? Function()? failure,
    bool? stale,
    bool? loadingMore,
    HomeEvent? Function()? event,
    Set<String>? restored,
    Set<String>? paidHere,
  }) => HomeState(
    data: data ?? this.data,
    loading: loading ?? this.loading,
    failure: failure == null ? this.failure : failure(),
    stale: stale ?? this.stale,
    loadingMore: loadingMore ?? this.loadingMore,
    event: event == null ? this.event : event(),
    restored: restored ?? this.restored,
    paidHere: paidHere ?? this.paidHere,
  );
}

/// Orders by date then id, newest first: the API's order.
int _newestFirst(Transaction a, Transaction b) {
  final byDate = b.date.compareTo(a.date);
  return byDate != 0 ? byDate : b.id.compareTo(a.id);
}

/// Home's state and what changes it: the month's summary and movements (loaded, paged, refreshed),
/// deleting with Deshacer, marking a pending movement paid, and the event Lukitas talks about.
///
/// Changes show at once (optimistic) and roll back when the server refuses; a failure is thrown as
/// a [HomeFailure] for the screen to say. Every load of the summary also writes the widget's
/// snapshot (spec section 7.1: every app load or save updates the widget).
class HomeController extends Notifier<HomeState> {
  HomeRepository get _repo => ref.read(homeRepositoryProvider);

  var _alive = true;
  Timer? _eventTimer;
  var _eventId = 0;
  Future<void>? _loading;
  HomeProfile? _profile;

  @override
  HomeState build() {
    // A new session (another person signing in) starts from nothing.
    ref.watch(homeRepositoryProvider);
    _alive = true;
    _loading = null;
    _profile = null;
    _eventTimer?.cancel();
    ref.onDispose(() {
      _alive = false;
      _eventTimer?.cancel();
    });
    // The first load starts once the provider is built.
    scheduleMicrotask(refresh);
    return const HomeState();
  }

  void _set(HomeState next) {
    if (_alive) state = next;
  }

  /// A failure that means the session is over: the server does not know the token any more.
  void _checkSession(Object error) {
    if (error is HomeFailure && error.unauthorized) {
      unawaited(ref.read(sessionProvider.notifier).signOut());
    }
  }

  HomeFailure _failure(Object error) {
    _checkSession(error);
    return error is HomeFailure ? error : const HomeFailure(0);
  }

  /// Loads the month again: the profile, the summary, the categories and the first page. Offline
  /// (or on any failure) what is on screen stays, marked stale.
  Future<void> refresh() => _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    if (state.data == null && !state.loading) {
      _set(const HomeState());
    }
    try {
      final profile = _profile ??= await _repo.profile();
      final today = todayIn(profile.timezone, ref.read(clockProvider)().toUtc());
      final month = today.substring(0, 7);
      final (summary, categories, page) = await (
        _repo.summary(month),
        _repo.categories(),
        _repo.transactions(month),
      ).wait;
      final data = HomeData(
        month: month,
        today: today,
        currency: profile.currency,
        summary: summary,
        categories: {for (final c in categories) c.id: c},
        items: page.items,
        nextCursor: page.nextCursor,
      );
      _set(
        HomeState(
          data: data,
          loading: false,
          event: state.event,
          restored: state.restored,
          paidHere: state.paidHere,
        ),
      );
      unawaited(_writeSnapshot(summary, data.currency));
    } on ParallelWaitError<dynamic, dynamic> catch (error) {
      // The first of the three that failed.
      final errors = error.errors as (Object?, Object?, Object?);
      _loadFailed(errors.$1 ?? errors.$2 ?? errors.$3 ?? const HomeFailure(0));
    } on Object catch (error) {
      _loadFailed(error);
    }
  }

  void _loadFailed(Object error) {
    final failure = _failure(error);
    if (state.data != null) {
      _set(state.copyWith(loading: false, stale: true));
    } else {
      _set(HomeState(loading: false, failure: failure));
    }
  }

  Future<void> _writeSnapshot(Summary summary, String currency) async {
    final locale = languageOfTag(ref.read(deviceHintsProvider).locale);
    await ref.read(widgetSnapshotWriterProvider)(summary, currency: currency, locale: locale);
  }

  /// Brings the next page ("Ver más movimientos") below the rows shown. Throws a [HomeFailure] and
  /// keeps the list as it is when it fails.
  Future<void> loadMore() async {
    final data = state.data;
    if (data == null || data.nextCursor == null || state.loadingMore) return;
    _set(state.copyWith(loadingMore: true));
    try {
      final page = await _repo.transactions(data.month, cursor: data.nextCursor);
      final current = state.data ?? data;
      final known = {for (final tx in current.items) tx.id};
      _set(
        state.copyWith(
          loadingMore: false,
          data: current.copyWith(
            items: [...current.items, ...page.items.where((tx) => !known.contains(tx.id))],
            nextCursor: () => page.nextCursor,
          ),
        ),
      );
    } on Object catch (error) {
      _set(state.copyWith(loadingMore: false));
      throw _failure(error);
    }
  }

  /// The summary again, after a change (silently: the rows already show the change).
  Future<void> _refreshSummary() async {
    final data = state.data;
    if (data == null) return;
    try {
      final summary = await _repo.summary(data.month);
      final current = state.data;
      if (current == null) return;
      _set(state.copyWith(data: current.copyWith(summary: summary)));
      unawaited(_writeSnapshot(summary, current.currency));
    } on Object catch (error) {
      _checkSession(error);
      _set(state.copyWith(stale: true));
    }
  }

  /// A row brought back by Deshacer has slid in: it is a plain row again.
  void settleRestored(String id) {
    if (!state.restored.contains(id)) return;
    _set(state.copyWith(restored: {...state.restored}..remove(id)));
  }

  void _replaceItems(List<Transaction> items) {
    final data = state.data;
    if (data != null) _set(state.copyWith(data: data.copyWith(items: items)));
  }

  /// Deletes [tx]: the row goes at once, and comes back if the server refuses (then a
  /// [HomeFailure] is thrown).
  Future<void> remove(Transaction tx) async {
    final data = state.data;
    if (data == null) return;
    _replaceItems([
      for (final t in data.items)
        if (t.id != tx.id) t,
    ]);
    try {
      await _repo.delete(tx.id);
    } on Object catch (error) {
      final current = state.data;
      if (current != null && !current.items.any((t) => t.id == tx.id)) {
        _replaceItems([...current.items, tx]..sort(_newestFirst));
      }
      throw _failure(error);
    }
    await _refreshSummary();
  }

  /// Brings a deleted [tx] back (Deshacer): the same row, in its place, sliding in.
  Future<void> restore(Transaction tx) async {
    try {
      final back = await _repo.restore(tx.id);
      final data = state.data;
      if (data == null) return;
      _set(
        state.copyWith(
          restored: {...state.restored, back.id},
          data: data.copyWith(
            items: [
              for (final t in data.items)
                if (t.id != back.id) t,
              back,
            ]..sort(_newestFirst),
          ),
        ),
      );
    } on Object catch (error) {
      throw _failure(error);
    }
    await _refreshSummary();
  }

  /// Marks a pending [tx] paid. Lukitas talks about it for [eventLineDuration]. A refusal puts the
  /// row back to pending and throws a [HomeFailure].
  Future<void> markPaid(Transaction tx) async {
    final data = state.data;
    if (data == null || state.paidHere.contains(tx.id)) return;
    final paid = tx.rebuild((b) => b.status = TransactionStatusEnum.paid);
    _set(state.copyWith(paidHere: {...state.paidHere, tx.id}));
    _replaceItems([for (final t in data.items) t.id == tx.id ? paid : t]);
    try {
      await _repo.markPaid(tx.id);
    } on Object catch (error) {
      final current = state.data;
      if (current != null) {
        _replaceItems([for (final t in current.items) t.id == tx.id ? tx : t]);
      }
      _set(state.copyWith(paidHere: {...state.paidHere}..remove(tx.id)));
      throw _failure(error);
    }
    // The figures after the payment first, so the line says the truth.
    await _refreshSummary();
    report(
      LukasEvent(
        kind: LukasEventKind.paid,
        categoryId: tx.categoryId,
        amount: tx.amount,
        name: tx.name,
      ),
    );
  }

  /// Lukitas talks about [event] for [eventLineDuration], then goes back to the month's line.
  /// Also for a save (the add sheet reports it).
  void report(LukasEvent event) {
    _eventTimer?.cancel();
    final id = ++_eventId;
    _set(state.copyWith(event: () => HomeEvent(id, event)));
    _eventTimer = Timer(eventLineDuration, () {
      if (_eventId == id) _set(state.copyWith(event: () => null));
    });
  }
}

/// Home's state, kept while home is on screen. Leaving it (signing out, say) drops it, so the next
/// person never sees it and nothing is fetched for a screen nobody sees.
final homeProvider = NotifierProvider.autoDispose<HomeController, HomeState>(HomeController.new);
