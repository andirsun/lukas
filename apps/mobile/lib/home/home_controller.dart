import 'dart:async';
import 'dart:async' as dart_async show AsyncError;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../capture/parser/dates.dart';
import 'home_cache.dart';
import 'home_repository.dart';
import 'lukas_line.dart';
import 'widget_sync.dart';

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
          (summary, {required currency, required locale}) =>
              ref.read(widgetSyncProvider).summaryLoaded(summary, currency: currency, locale: locale),
    );

/// The language amounts and dates are written in: English when the phone asks for it, Spanish
/// otherwise (the same rule as the app's `localeResolutionCallback`).
String languageOfTag(String tag) => tag.toLowerCase().startsWith('en') ? 'en' : 'es';

/// The month on screen: its summary and movements.
class HomeData {
  const HomeData({
    required this.month,
    required this.timezone,
    required this.currency,
    required this.summary,
    required this.categories,
    required this.items,
    required this.nextCursor,
  });

  /// `YYYY-MM`.
  final String month;

  /// The profile's time zone (an IANA name): "today" is read in it.
  final String timezone;
  final String currency;
  final Summary summary;

  /// Every category (archived ones too) by id.
  final Map<String, Category> categories;

  /// The movements loaded so far, newest first.
  final List<Transaction> items;

  /// Where the next page starts; null when everything is loaded.
  final String? nextCursor;

  /// Today (`YYYY-MM-DD`) in the profile's time zone at [now]. Always asked of the clock, never
  /// kept: the app can sit in the background past midnight, and what is "this month" changes with
  /// it.
  String todayAt(DateTime now) => todayIn(timezone, now.toUtc());

  HomeData copyWith({
    Summary? summary,
    Map<String, Category>? categories,
    List<Transaction>? items,
    String? Function()? nextCursor,
  }) => HomeData(
    month: month,
    timezone: timezone,
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
    this.staleOffline = false,
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

  /// With [stale]: the failure was no answer at all (offline), not a server error.
  final bool staleOffline;
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
    bool? staleOffline,
    bool? loadingMore,
    HomeEvent? Function()? event,
    Set<String>? restored,
    Set<String>? paidHere,
  }) => HomeState(
    data: data ?? this.data,
    loading: loading ?? this.loading,
    failure: failure == null ? this.failure : failure(),
    stale: stale ?? this.stale,
    staleOffline: staleOffline ?? this.staleOffline,
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
  HomeCache get _cache => ref.read(homeCacheProvider);

  var _alive = true;
  Timer? _eventTimer;
  var _eventId = 0;
  Future<void>? _loading;

  /// Counts the summary requests: only the latest one may touch the screen, the cache and the
  /// widget, so an old answer that lands late cannot undo a newer one.
  var _summarySeq = 0;
  HomeProfile? _profile;

  @override
  HomeState build() {
    // A new session (another person signing in) starts from nothing.
    ref.watch(homeRepositoryProvider);
    ref.watch(homeCacheProvider);
    _alive = true;
    _loading = null;
    _summarySeq = 0;
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
    if (!_alive) return;
    if (error is HomeFailure && error.unauthorized) {
      unawaited(ref.read(sessionProvider.notifier).signOut(discardGuest: true));
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
      if (!_alive) return;
      final today = todayIn(profile.timezone, ref.read(clockProvider)().toUtc());
      final month = today.substring(0, 7);
      final (summary, categories, page) = await (
        _repo.summary(month),
        _repo.categories(),
        _repo.transactions(month),
      ).wait;
      // Home was left (signed out, say) while this was on its way: nobody is waiting for it.
      if (!_alive) return;
      // This load is the latest word: an older summary still on its way is dropped.
      _summarySeq++;
      final data = HomeData(
        month: month,
        timezone: profile.timezone,
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
      unawaited(_persist());
    } on ParallelWaitError<dynamic, dynamic> catch (error) {
      // What each of the three failed with (a record of dart:async AsyncError, null for the ones that
      // worked; not Riverpod's AsyncError, which shares the name).
      final failed = error.errors as (Object?, Object?, Object?);
      final errors = [
        for (final e in [failed.$1, failed.$2, failed.$3])
          if (e != null) e is dart_async.AsyncError ? e.error : e,
      ];
      // A refused session wins over any other failure: it ends the session.
      await _loadFailed(
        errors.firstWhere(
          (e) => e is HomeFailure && e.unauthorized,
          orElse: () => errors.firstOrNull ?? const HomeFailure(0),
        ),
      );
    } on Object catch (error) {
      await _loadFailed(error);
    }
  }

  /// A load failed. What is on screen stays, stale; with nothing on screen (a cold start with no
  /// network) the last good month saved on this phone shows instead, stale; and with neither, the
  /// failure.
  Future<void> _loadFailed(Object error) async {
    if (!_alive) return;
    final failure = _failure(error);
    if (state.data != null) {
      _set(state.copyWith(loading: false, stale: true, staleOffline: failure.offline));
      return;
    }
    // A refused session shows nothing: signing out wipes the cache.
    final cached = failure.unauthorized ? null : await _cache.read();
    if (!_alive) return;
    // Never another user's month (the cache is also bound to the session that wrote it).
    final known = _profile?.id;
    if (cached == null || (known != null && known != cached.userId)) {
      _set(HomeState(loading: false, failure: failure));
      return;
    }
    _set(
      HomeState(
        loading: false,
        stale: true,
        staleOffline: failure.offline,
        data: HomeData(
          month: cached.month,
          timezone: cached.timezone,
          currency: cached.currency,
          summary: cached.summary,
          categories: {for (final c in cached.categories) c.id: c},
          items: cached.items,
          nextCursor: null,
        ),
      ),
    );
  }

  /// Saves what is on screen (its first page of movements) for a start with no network. Best
  /// effort, and never after home was left.
  Future<void> _persist() async {
    if (!_alive) return;
    final data = state.data;
    final profile = _profile;
    if (data == null || profile == null) return;
    await _cache.write(
      CachedHome(
        userId: profile.id,
        currency: data.currency,
        timezone: profile.timezone,
        month: data.month,
        summary: data.summary,
        categories: data.categories.values.toList(),
        items: data.items.take(transactionsPageSize).toList(),
      ),
    );
  }

  Future<void> _writeSnapshot(Summary summary, String currency) async {
    if (!_alive) return;
    try {
      final locale = widgetLanguage(ref);
      await ref.read(widgetSnapshotWriterProvider)(summary, currency: currency, locale: locale);
    } catch (_) {
      // The widget keeps its last figure; this never breaks home (nor, after home was left, the app).
    }
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
    if (!_alive) return;
    final data = state.data;
    if (data == null) return;
    final request = ++_summarySeq;
    try {
      final summary = await _repo.summary(data.month);
      // Dropped when it is not the latest request (see [_summarySeq]).
      if (!_alive || request != _summarySeq) return;
      final current = state.data;
      if (current == null) return;
      _set(state.copyWith(data: current.copyWith(summary: summary)));
      unawaited(_writeSnapshot(summary, current.currency));
      unawaited(_persist());
    } on Object catch (error) {
      if (!_alive) return;
      // One mapping of an error to what it means, as in a load; and a refused session ends the
      // session even when the request was an older one whose answer is dropped.
      final failure = _failure(error);
      if (request != _summarySeq) return;
      _set(state.copyWith(stale: true, staleOffline: failure.offline));
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
    // The row is already gone: what is saved for a start with no network follows it at once, and
    // the summary in the background, so Deshacer shows as soon as the server has the delete,
    // however slow the summary is.
    unawaited(_persist());
    unawaited(_refreshSummary());
  }

  /// Brings a deleted [tx] back (Deshacer): the same row, in its place, sliding in.
  Future<void> restore(Transaction tx) async {
    try {
      final back = await _repo.restore(tx.id);
      if (!_alive) return;
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
    unawaited(_persist());
    unawaited(_refreshSummary());
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

  /// Puts [tx] among the rows when it belongs to the month on screen (replacing its earlier
  /// version), or takes it off when it does not (an edit moved it to another month).
  void _place(Transaction tx) {
    final data = state.data;
    if (data == null) return;
    final rest = [
      for (final t in data.items)
        if (t.id != tx.id) t,
    ];
    final here = tx.date.startsWith(data.month);
    // A page boundary hides what is below it: a row older than the last one loaded would sit at
    // the end of a list that has more to come, so it waits for "Ver más movimientos".
    final last = rest.isEmpty ? null : rest.last;
    final beyond =
        data.nextCursor != null && last != null && _newestFirst(tx, last) > 0 && tx.id != last.id;
    _replaceItems(here && !beyond ? ([...rest, tx]..sort(_newestFirst)) : rest);
  }

  /// A movement the add sheet just saved: its row is there at once, what is saved for a start with
  /// no network follows, and the summary is asked again (only the latest answer counts). Lukitas
  /// talks about it once the figures are in, unless a newer event has taken over meanwhile.
  Future<void> saved(Transaction tx) async {
    if (state.data == null) return;
    final eventBefore = _eventId;
    _place(tx);
    unawaited(_persist());
    await _refreshSummary();
    if (!_alive || _eventId != eventBefore) return;
    report(
      LukasEvent(
        kind: LukasEventKind.saved,
        categoryId: tx.categoryId,
        amount: tx.amount,
        name: tx.name,
      ),
    );
  }

  /// Movements a quick capture just saved together: their rows are there at once, what is saved
  /// for a start with no network follows, and the summary is asked once (only the latest answer
  /// counts). No Lukitas event: capture shows its own celebration for the batch.
  Future<void> savedBatch(List<Transaction> saved) async {
    if (state.data == null) return;
    for (final tx in saved) {
      _place(tx);
    }
    unawaited(_persist());
    await _refreshSummary();
  }

  /// Takes the rows [ids] off at once, after the server deleted them (a capture's Deshacer), and
  /// asks for the summary again.
  Future<void> forget(List<String> ids) async {
    final data = state.data;
    if (data == null) return;
    final gone = ids.toSet();
    _replaceItems([
      for (final t in data.items)
        if (!gone.contains(t.id)) t,
    ]);
    unawaited(_persist());
    await _refreshSummary();
  }

  /// A movement the add sheet just edited: its row is replaced where it belongs, and the summary
  /// follows. No event: an edit is no celebration.
  Future<void> updated(Transaction tx) async {
    if (state.data == null) return;
    _place(tx);
    unawaited(_persist());
    await _refreshSummary();
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
