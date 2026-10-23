import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../add/add_sheet.dart';
import '../api/gen/lukitas_api.dart';
import '../capture/capture_sheet.dart';
import '../feedback/feedback.dart';
import '../l10n/app_localizations.dart';
import '../money/format.dart';
import '../theme/theme.dart';
import '../theme/tokens.g.dart';
import 'day_groups.dart';
import 'home_controller.dart';
import 'home_format.dart';
import 'home_repository.dart';
import 'home_widgets.dart';
import 'lukas_line.dart';
import 'lukitas_face.dart';
import 'swipe_row.dart';
import 'toast.dart';
import 'transaction_row.dart';

/// Picks which of Lukitas' three phrasings a line uses (1 to 3). Replaced in tests.
final lukasVariantProvider = Provider<int Function()>((ref) {
  final random = math.Random();
  return () => 1 + random.nextInt(3);
});

/// How long Lukitas celebrates a save or a payment (the web's `CELEBRATE_MS`).
const _celebrateFor = Duration(milliseconds: 2500);

/// Space under the list so the 🎤 and the ＋ never cover the last row.
const _addButtonRoom = 144.0;

/// The widest the content grows on a big screen.
const _maxContentWidth = 480.0;

/// Home (spec section 6.1.2): the month, Lukitas' line, and "Te quedan" (or, without budgets,
/// "Gastado este mes") in large type; then the movements list, by day, with the web's gestures:
/// swipe left deletes (with an 8 s Deshacer), swipe right edits, or marks a pending row paid, under
/// a sticky "Movimientos" tab. Lukitas names a save or a payment for 10 s, then goes back to the
/// month's line. The last figures stay on screen while offline.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onEdit});

  /// Opens a movement to edit (a tap on its row, or a swipe right on a paid one). Null: the edit
  /// sheet. Tests pass their own to see what was asked for.
  final void Function(Transaction transaction)? onEdit;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  /// Events up to this one happened before home opened: they are old news.
  late final int _since = ref.read(homeProvider).event?.id ?? 0;

  /// The phrasing picked for the line on screen, picked again only when the situation changes.
  int _variant = 1;
  Object? _variantFor;

  bool _celebrating = false;
  Timer? _celebrateTimer;

  HomeController get _controller => ref.read(homeProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _celebrateTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back in the app: the figures (and the widget) catch up.
    if (state == AppLifecycleState.resumed) unawaited(_controller.refresh());
  }

  // -- messages ------------------------------------------------------------------------------

  void _toast(
    ScaffoldMessengerState messenger,
    LukitasColors colors,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool error = false,
  }) => showToast(
    messenger,
    colors,
    message,
    actionLabel: actionLabel,
    onAction: onAction,
    error: error,
  );

  String _failureMessage(AppLocalizations l10n, HomeFailure failure) =>
      failure.offline ? l10n.errorNetwork : l10n.errorGeneric;

  Future<void> _delete(Transaction tx) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    // At the gesture, not at the server's answer: the row is already gone (the web does the same).
    ref.read(feedbackProvider)(FeedbackEvent.deleted);
    try {
      await _controller.remove(tx);
    } on HomeFailure catch (failure) {
      _toast(messenger, colors, _failureMessage(l10n, failure), error: true);
      return;
    }
    _toast(
      messenger,
      colors,
      l10n.transactionDeleted(tx.name),
      actionLabel: l10n.undo,
      onAction: () => unawaited(_restore(tx, messenger, l10n, colors)),
    );
  }

  Future<void> _restore(
    Transaction tx,
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    LukitasColors colors,
  ) async {
    try {
      await _controller.restore(tx);
    } on HomeFailure catch (failure) {
      _toast(messenger, colors, _failureMessage(l10n, failure), error: true);
      return;
    }
    if (mounted) ref.read(feedbackProvider)(FeedbackEvent.undo);
    _toast(messenger, colors, l10n.transactionRestored(tx.name));
  }

  /// Marks [tx] paid. Rethrows a failure after saying it, so the badge goes back to "Pendiente".
  Future<void> _pay(Transaction tx) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final data = ref.read(homeProvider).data;
    try {
      await _controller.markPaid(tx);
    } on HomeFailure catch (failure) {
      _toast(messenger, colors, _failureMessage(l10n, failure), error: true);
      rethrow;
    }
    if (mounted) ref.read(feedbackProvider)(FeedbackEvent.paid);
    if (data != null) {
      _toast(
        messenger,
        colors,
        l10n.transactionPaid(tx.name, formatMoney(tx.amount, data.currency, l10n.localeName)),
      );
    }
  }

  // -- Lukitas -------------------------------------------------------------------------------

  /// A new event starts a celebration (not near or over a limit: no party for that).
  void _onEvent(HomeEvent? event) {
    if (event == null || event.id <= _since) return;
    final summary = ref.read(homeProvider).data?.summary;
    final state = summary?.categories
        .where((c) => c.categoryId == event.event.categoryId)
        .map((c) => c.state)
        .firstOrNull;
    if (state == SummaryCategoriesInnerStateEnum.near ||
        state == SummaryCategoriesInnerStateEnum.over) {
      return;
    }
    _celebrate();
  }

  /// Lukitas celebrates for a moment, then goes back to his mood.
  void _celebrate() {
    _celebrateTimer?.cancel();
    setState(() => _celebrating = true);
    _celebrateTimer = Timer(_celebrateFor, () {
      if (mounted) setState(() => _celebrating = false);
    });
  }

  ({String message, LukitasMood mood, bool announce}) _lukitas(
    AppLocalizations l10n,
    HomeData data,
    HomeEvent? fresh,
    String today,
  ) {
    final locale = l10n.localeName;
    String money(int cents) => formatMoney(cents, data.currency, locale);
    final worriedMood = data.summary.categories.any(
      (c) => c.state != SummaryCategoriesInnerStateEnum.ok,
    );
    // Figures of an earlier month (a cache opened after the month changed): Lukitas says so, and
    // never talks about "this month" or a month that just closed as if it were live.
    if (data.month != today.substring(0, 7)) {
      return (
        message: l10n.lukasOtherMonth(monthInSentence(data.month, locale)),
        mood: worriedMood ? LukitasMood.worried : LukitasMood.happy,
        announce: false,
      );
    }
    final event = fresh != null && fresh.event.categoryId.isNotEmpty ? fresh : null;
    final line = lukasLine(
      summary: data.summary,
      today: today,
      todayCount: data.items.where((t) => t.date == today).length,
      event: event?.event,
      categoryName: (id) => data.categories[id]?.name ?? '',
    );
    // One of the line's variants, picked again only when the situation changes.
    final situation = (line.key, event?.id, data.month);
    if (_variantFor != situation) {
      _variantFor = situation;
      _variant = ref.read(lukasVariantProvider)();
    }
    final worried = data.summary.categories.any(
      (c) => c.state != SummaryCategoriesInnerStateEnum.ok,
    );
    return (
      message: lukasLineText(l10n, line, _variant, money),
      mood: _celebrating
          ? LukitasMood.celebrating
          : (worried ? LukitasMood.worried : LukitasMood.happy),
      announce: event != null,
    );
  }

  // -- build ---------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen(homeProvider.select((s) => s.event), (_, next) => _onEvent(next));
    // A batch from quick capture has no event of its own to talk about: he just celebrates.
    ref.listen(celebrationProvider, (_, _) => _celebrate());
    final home = ref.watch(homeProvider);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final l10n = AppLocalizations.of(context);
    final data = home.data;

    final Widget body;
    if (data == null) {
      body = home.failure != null
          ? _FailedView(
              message: _failureMessage(l10n, home.failure!),
              retryLabel: l10n.retry,
              onRetry: () => unawaited(_controller.refresh()),
            )
          : _LoadingView(label: l10n.homeLoading);
    } else {
      body = _content(context, home, data, l10n, colors);
    }

    return Scaffold(
      // Nothing to add to until the categories are known.
      floatingActionButton: data == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🎤: say (or type) a sentence, and save its movements at once.
                FloatingActionButton.small(
                  key: const Key('home.capture'),
                  heroTag: 'home.capture',
                  tooltip: l10n.captureFabLabel,
                  backgroundColor: colors.surface,
                  foregroundColor: colors.brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LukitasTokens.radiusMd),
                    side: BorderSide(color: colors.brand, width: 2),
                  ),
                  onPressed: () => unawaited(openCapture(context)),
                  child: const Icon(Icons.mic),
                ),
                const SizedBox(height: LukitasTokens.space2),
                FloatingActionButton(
                  key: const Key('home.add'),
                  heroTag: 'home.add',
                  tooltip: l10n.addFabLabel,
                  backgroundColor: colors.brand,
                  foregroundColor: colors.onBrand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LukitasTokens.radiusLg),
                  ),
                  onPressed: () => unawaited(openAddSheet(context)),
                  child: const Icon(Icons.add, size: 30),
                ),
              ],
            ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.3,
            colors: [colors.bgGlow, colors.bg],
            stops: const [0, 0.55],
          ),
        ),
        child: SafeArea(child: body),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    HomeState home,
    HomeData data,
    AppLocalizations l10n,
    LukitasColors colors,
  ) {
    final locale = l10n.localeName;
    // Asked of the clock on every build: after a night in the background, what was this month is
    // last month, whether or not the refresh worked.
    final today = data.todayAt(ref.read(clockProvider)());
    final lukitas = _lukitas(l10n, data, home.event, today);
    final monthName = formatMonthName(data.month, locale);
    final entries = _entries(home, data, l10n, today);

    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = math.max(
          LukitasTokens.space4,
          (constraints.maxWidth - _maxContentWidth) / 2 + LukitasTokens.space4,
        );
        return SwipeScope(
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, LukitasTokens.space3, inset, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: MonthPill(name: monthName),
                        ),
                        if (home.stale)
                          Padding(
                            padding: const EdgeInsets.only(top: LukitasTokens.space2),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _staleNote(l10n, home, data, today),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: colors.near,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: LukitasTokens.space3),
                        LukitasBubble(
                          message: lukitas.message,
                          mood: lukitas.mood,
                          announce: lukitas.announce,
                        ),
                        const SizedBox(height: LukitasTokens.space3),
                        MonthHero(
                          summary: data.summary,
                          currency: data.currency,
                          locale: locale,
                          pastMonth: data.month == today.substring(0, 7)
                              ? null
                              : monthInSentence(data.month, locale),
                        ),
                        const SizedBox(height: LukitasTokens.space3),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: MovementsTabHeader(
                    label: l10n.homeMovements,
                    background: colors.bg,
                    inset: inset,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    inset,
                    LukitasTokens.space1,
                    inset,
                    // Room under the last row for the ＋.
                    _addButtonRoom,
                  ),
                  sliver: SliverList.builder(
                    itemCount: entries.length,
                    findChildIndexCallback: (key) {
                      if (key is! ValueKey<String>) return null;
                      final index = entries.indexWhere((e) => e.key == key.value);
                      return index < 0 ? null : index;
                    },
                    itemBuilder: (context, index) => KeyedSubtree(
                      key: ValueKey(entries[index].key),
                      child: entries[index].build(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Why what is on screen may be old: no answer at all, or a failed refresh with the network up;
  /// naming the month when it is not this one.
  String _staleNote(AppLocalizations l10n, HomeState home, HomeData data, String today) {
    final other = data.month != today.substring(0, 7);
    final month = monthInSentence(data.month, l10n.localeName);
    if (home.staleOffline) return other ? l10n.homeOfflineMonth(month) : l10n.homeOffline;
    return other ? l10n.homeRefreshFailedMonth(month) : l10n.homeRefreshFailed;
  }

  /// The movements list as widgets in order: each day's heading and rows, then "Ver más
  /// movimientos" (or the empty state).
  List<_Entry> _entries(HomeState home, HomeData data, AppLocalizations l10n, String today) {
    final locale = l10n.localeName;
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    if (data.items.isEmpty) {
      return [
        _Entry(
          'empty',
          () => Padding(
            padding: const EdgeInsets.symmetric(vertical: LukitasTokens.space2),
            child: Text(
              l10n.homeEmptyTransactions(formatMonthName(data.month, locale)),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.inkMuted),
            ),
          ),
        ),
      ];
    }
    final entries = <_Entry>[];
    for (final group in groupByDay(data.items, today)) {
      final day = formatDay(group.date, locale);
      final label = switch (group.when) {
        DayWhen.today => l10n.homeDayToday(day),
        DayWhen.yesterday => l10n.homeDayYesterday(day),
        DayWhen.upcoming => l10n.homeDayUpcoming(day),
        DayWhen.past => day,
      };
      entries.add(
        _Entry(
          'day-${group.date}',
          () => DayHeading(
            label: label,
            total: formatMoney(
              group.total,
              data.currency,
              locale,
              sign: group.total > 0 ? MoneySign.always : MoneySign.auto,
            ),
          ),
        ),
      );
      for (final tx in group.items) {
        entries.add(_Entry('tx-${tx.id}', () => _row(home, data, tx, l10n)));
      }
    }
    if (data.nextCursor != null) {
      entries.add(
        _Entry(
          'more',
          () => Center(
            child: Padding(
              padding: const EdgeInsets.only(top: LukitasTokens.space2),
              child: OutlinedButton(
                onPressed: home.loadingMore ? null : _loadMore,
                child: home.loadingMore
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const QuietSpinner(),
                          const SizedBox(width: LukitasTokens.space2),
                          Text(l10n.homeMoreTransactions),
                        ],
                      )
                    : Text(l10n.homeMoreTransactions),
              ),
            ),
          ),
        ),
      );
    }
    return entries;
  }

  Future<void> _loadMore() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    try {
      await _controller.loadMore();
    } on HomeFailure catch (failure) {
      _toast(messenger, colors, _failureMessage(l10n, failure), error: true);
    }
  }

  Widget _row(HomeState home, HomeData data, Transaction tx, AppLocalizations l10n) {
    final pending = tx.status == TransactionStatusEnum.pending;
    final onEdit = widget.onEdit ?? (Transaction tx) => unawaited(openEditSheet(context, tx));
    return SwipeRow(
      key: ValueKey(tx.id),
      gap: LukitasTokens.space2,
      enter: home.restored.contains(tx.id),
      onEntered: () => _controller.settleRestored(tx.id),
      deleteLabel: l10n.swipeDelete,
      onDelete: () => unawaited(_delete(tx)),
      right: pending
          ? SwipeRight(
              SwipeRightKind.paid,
              // Paid once: a second quick swipe (or the badge) never pays it again.
              () => unawaited(_pay(tx).then((_) {}, onError: (Object _) {})),
              l10n.swipePaid,
            )
          : SwipeRight(SwipeRightKind.edit, () => onEdit(tx), l10n.swipeEdit),
      child: TransactionRow(
        transaction: tx,
        category: data.categories[tx.categoryId],
        currency: data.currency,
        locale: l10n.localeName,
        paidHere: home.paidHere.contains(tx.id),
        onOpen: () => onEdit(tx),
        onPay: () => _pay(tx),
      ),
    );
  }
}

class _Entry {
  const _Entry(this.key, this.build);

  final String key;
  final Widget Function() build;
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Center(
      child: Semantics(
        label: label,
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const QuietSpinner(size: 28),
            const SizedBox(height: LukitasTokens.space3),
            Text(
              label,
              style: TextStyle(color: colors.inkMuted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.message, required this.retryLabel, required this.onRetry});

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LukitasTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: LukitasTokens.space4),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
