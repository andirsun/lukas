import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../add/add_sheet.dart';
import '../api/gen/lukitas_api.dart';
import '../budgets/budgets_tab.dart';
import '../capture/capture_sheet.dart';
import '../feedback/feedback.dart';
import '../l10n/app_localizations.dart';
import '../money/format.dart';
import '../theme/surfaces.dart';
import '../theme/text_styles.dart';
import '../theme/theme.dart';
import '../theme/tokens.g.dart';
import '../ui/app_shell.dart';
import '../ui/lk_theme.dart';
import '../ui/lukas_bubble.dart';
import '../ui/press_button.dart';
import '../ui/segmented_control.dart';
import '../ui/swipe_row.dart';
import '../ui/transaction_row.dart';
import 'category_look.dart';
import 'day_groups.dart';
import 'home_controller.dart';
import 'home_format.dart';
import 'home_header.dart';
import 'home_repository.dart';
import 'home_widgets.dart';
import 'lukas_line.dart';
import 'lukitas_face.dart';
import 'nudges.dart';
import 'screen_error.dart';
import 'toast.dart';

/// Picks which of Lukitas' three phrasings a line uses (1 to 3). Replaced in tests.
final lukasVariantProvider = Provider<int Function()>((ref) {
  final random = math.Random();
  return () => 1 + random.nextInt(3);
});

/// How long Lukitas celebrates a save or a payment (the web's `CELEBRATE_MS`).
const _celebrateFor = Duration(milliseconds: 2500);

/// The widest the content grows on a big screen (the web's `max-w-[480px]`, padding included).
const _maxContentWidth = 480.0;

/// The two lists under the hero: Movimientos first.
enum HomeView { transactions, budgets }

/// Home (spec section 6.1.2), as the web draws it (apps/web/app/features/home/Home.tsx): the
/// header (the wordmark, the month with ‹ ›, the face button), Lukitas' line, "Te quedan" (or,
/// without budgets, "Gastado este mes") in large type, a card or two for an account that skipped
/// the setup, and under the Movimientos | Presupuestos tabs the movements by day, with the web's
/// gestures: swipe left deletes (with an 8 s Deshacer), swipe right edits, or marks a pending row
/// paid. Lukitas names a save or a payment for 10 s, then goes back to the month's line. The last
/// figures stay on screen while offline. The bottom bar has Inicio, ＋ (the add sheet), the 🎤
/// (quick capture, listening) and Análisis.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onEdit, this.menu, this.initialMonth});

  /// What the face button's menu holds, as [HomeMenuLink]s: Ajustes, and a guest's "Guarda tu
  /// progreso". Null (tests, goldens): no menu.
  final Widget Function(BuildContext context, VoidCallback close)? menu;

  /// Opens a movement to edit (a tap on its row, or a swipe right on a paid one). Null: the edit
  /// sheet. Tests pass their own to see what was asked for.
  final void Function(Transaction transaction)? onEdit;

  /// The month to open on (`YYYY-MM`, the route's `?month=`); null: the current one. A new value
  /// moves home to that month.
  final String? initialMonth;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// Events up to this one happened before home opened: they are old news.
  late final int _since = ref.read(homeProvider).event?.id ?? 0;

  /// The phrasing picked for the line on screen, picked again only when the situation changes.
  int _variant = 1;
  Object? _variantFor;

  bool _celebrating = false;
  Timer? _celebrateTimer;

  var _view = HomeView.transactions;

  /// Where the tabs' thumb is, in tabs: 0 Movimientos, 1 Presupuestos.
  late final AnimationController _thumb = AnimationController(
    vsync: this,
    duration: LukitasTokens.durationSheet,
  );

  HomeController get _controller => ref.read(homeProvider.notifier);

  static final _monthFormat = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final month = widget.initialMonth;
    if (month != null && _monthFormat.hasMatch(month)) {
      // Not while the tree builds: the controller changes state.
      scheduleMicrotask(() {
        if (mounted) unawaited(_controller.showMonth(month));
      });
    }
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    if (old.initialMonth == widget.initialMonth) return;
    final month = widget.initialMonth;
    if (month == null) {
      unawaited(_controller.showCurrentMonth());
    } else if (_monthFormat.hasMatch(month)) {
      unawaited(_controller.showMonth(month));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _celebrateTimer?.cancel();
    _thumb.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back in the app: the figures (and the widget) catch up.
    if (state == AppLifecycleState.resumed) unawaited(_controller.refresh());
  }

  void _selectView(HomeView view) {
    if (view == _view) return;
    setState(() => _view = view);
    final target = view.index.toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _thumb.value = target;
    } else {
      unawaited(_thumb.animateTo(target, curve: Curves.easeOut));
    }
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

  ({String message, LukitasMood mood}) _lukitas(
    AppLocalizations l10n,
    HomeState home,
    HomeData data,
    String today,
  ) {
    final locale = l10n.localeName;
    final current = today.substring(0, 7);
    String money(int cents) => formatMoney(cents, data.currency, locale);
    final worried = data.summary.categories.any(
      (c) => c.state != SummaryCategoriesInnerStateEnum.ok,
    );
    // Figures of an earlier month that could not be brought up to date (a cache opened after the
    // month changed): Lukitas says so, and never talks about "this month" or a month that just
    // closed as if it were live.
    if (home.stale && data.month != current) {
      return (
        message: l10n.lukasOtherMonth(monthInSentence(data.month, locale)),
        mood: worried ? LukitasMood.worried : LukitasMood.happy,
      );
    }
    // The event is about its own month: Lukitas speaks of it only while that month is on screen.
    final fresh = home.event;
    final event = fresh != null && fresh.month == data.month && fresh.event.categoryId.isNotEmpty
        ? fresh
        : null;
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
    // A month closed in green gets a celebration of its own (the web's `closedGreen`).
    final closedGreen =
        data.month.compareTo(current) < 0 &&
        data.summary.budgetTotal > 0 &&
        data.summary.remaining >= 0;
    return (
      message: lukasLineText(l10n, line, _variant, money),
      mood: _celebrating || closedGreen
          ? LukitasMood.celebrating
          : (worried ? LukitasMood.worried : LukitasMood.happy),
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

    // Nothing to add to until the categories are known: no bar, and the screen alone.
    if (data == null) {
      return DecoratedBox(
        decoration: BoxDecoration(gradient: LkSurface.background(colors)),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: home.failure != null
                ? ScreenError(
                    message: _failureMessage(l10n, home.failure!),
                    retryLabel: l10n.retry,
                    onRetry: () => unawaited(_controller.refresh()),
                  )
                : _LoadingView(label: l10n.homeLoading),
          ),
        ),
      );
    }

    return AppShell(
      current: 'home',
      addKey: const Key('home.add'),
      micKey: const Key('home.capture'),
      onAdd: () => unawaited(openAddSheet(context)),
      // The same path the widget's 🎤 takes: quick capture, listening.
      onMic: () => unawaited(openCapture(context, listen: true)),
      // Análisis comes with its own route (a later task): until then the tab leads nowhere.
      onNavigate: (_) {},
      child: SafeArea(bottom: false, child: _content(context, home, data, l10n)),
    );
  }

  Widget _content(BuildContext context, HomeState home, HomeData data, AppLocalizations l10n) {
    final locale = l10n.localeName;
    // Asked of the clock on every build: after a night in the background, what was this month is
    // last month, whether or not the refresh worked.
    final today = data.todayAt(ref.read(clockProvider)());
    final current = today.substring(0, 7);
    final shown = home.shown;
    final lukitas = shown == null ? null : _lukitas(l10n, home, shown, today);
    final entries = shown == null ? const <_Entry>[] : _entries(home, shown, l10n, today);
    final colors = context.lkColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Read here, below the `AppShell` that provides it: 112px plus the system's bottom inset.
        final room = ShellRoom.of(context);
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
                  // `px-4 pt-3`; the tabs' strip reaches 8px up into the gap above it, so the
                  // gap is 12 - 8.
                  padding: EdgeInsets.fromLTRB(inset, LukitasTokens.space3, inset, 4),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: LukitasTokens.space3,
                      children: [
                        HomeHeader(
                          month: home.month ?? data.month,
                          onMonth: (month) => unawaited(_controller.showMonth(month)),
                          max: current,
                          menu: widget.menu,
                        ),
                        if (shown != null) ...[
                          if (home.stale)
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _staleNote(l10n, home, shown, today),
                                style: LkText.caption.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colors.near,
                                ),
                              ),
                            ),
                          LukasBubble(
                            message: lukitas!.message,
                            mood: lukitas.mood,
                            quietKey: home.quietKey,
                          ),
                          HomeHero(
                            summary: shown.summary,
                            currency: shown.currency,
                            pastMonth: shown.month.compareTo(current) < 0
                                ? monthInSentence(shown.month, locale)
                                : null,
                          ),
                          ?_nudges(shown, l10n),
                        ] else
                          const HomeHeroPlaceholder(),
                      ],
                    ),
                  ),
                ),
                PinnedHeaderSliver(
                  child: HomeTabsStrip(
                    bleed: inset,
                    child: SegmentedControl<HomeView>(
                      label: l10n.homeViewLabel,
                      value: _view,
                      position: _thumb,
                      options: [
                        SegmentOption(HomeView.transactions, l10n.homeMovements),
                        SegmentOption(HomeView.budgets, l10n.homeBudgetsTab),
                      ],
                      onChanged: _selectView,
                    ),
                  ),
                ),
                if (shown == null)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(inset, LukitasTokens.space2, inset, room),
                    sliver: SliverToBoxAdapter(
                      child: _MonthUnavailable(
                        failure: home.failure,
                        message: home.failure == null ? null : _failureMessage(l10n, home.failure!),
                        retryLabel: l10n.retry,
                        onRetry: () => unawaited(_controller.refresh()),
                      ),
                    ),
                  )
                else if (_view == HomeView.budgets)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(inset, LukitasTokens.space2, inset, room),
                    sliver: SliverToBoxAdapter(
                      child: BudgetsTab(
                        summary: shown.summary,
                        categories: shown.categories,
                        currency: shown.currency,
                        // Its detail, in the month on screen.
                        onOpen: (id) =>
                            unawaited(context.push<void>('/categories/$id?month=${shown.month}')),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(inset, LukitasTokens.space2, inset, room),
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

  /// The cards for an account without budgets (the web's `Nudges`): not for an account with a
  /// budget on any category, nor one put away.
  Widget? _nudges(HomeData data, AppLocalizations l10n) {
    final categories = data.categories.values.where((c) => !c.archived).toList();
    final noBudgets =
        data.summary.budgetTotal == 0 &&
        categories.any((c) => c.kind == CategoryKindEnum.expense) &&
        categories.every((c) => c.currentBudget == null);
    final key = nudgeKey(data.userId, Nudge.budgets);
    if (!noBudgets || ref.watch(nudgeDismissedProvider(key)) != false) return null;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.homeNudgesLabel,
      child: NudgeCard(
        title: l10n.homeNudgeBudgetsTitle,
        lead: l10n.homeNudgeBudgetsLead,
        actionLabel: l10n.homeNudgeBudgetsAction,
        onAction: () => _selectView(HomeView.budgets),
        onDismiss: () => unawaited(ref.read(nudgeDismissedProvider(key).notifier).dismiss()),
      ),
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
    final colors = context.lkColors;
    if (data.items.isEmpty) {
      return [
        _Entry(
          'empty',
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: LukitasTokens.space3,
            children: [
              Text(
                l10n.homeEmptyTransactions(formatMonthName(data.month, locale)),
                style: LkText.bodySm.copyWith(color: colors.inkMuted),
              ),
              PressButton.text(
                l10n.addFabLabel,
                tone: PressTone.secondary,
                onPressed: () => unawaited(openAddSheet(context)),
              ),
            ],
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
            child: PressButton.text(
              l10n.homeMoreTransactions,
              tone: PressTone.secondary,
              onPressed: home.loadingMore ? null : _loadMore,
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
      child: _txRow(data, tx, home.paidHere.contains(tx.id), onEdit, () => _pay(tx)),
    );
  }
}

/// The web's `TransactionRow` for [tx]: its category's glyph and name, and the row's actions.
Widget _txRow(
  HomeData data,
  Transaction tx,
  bool paidHere,
  void Function(Transaction) onEdit,
  Future<void> Function() onPay,
) {
  final category = data.categories[tx.categoryId];
  return TransactionRow(
    name: tx.name,
    categoryName: category?.name ?? '',
    glyph: category == null
        ? '🏷️'
        : categoryLook(icon: category.icon, color: category.color).glyph,
    amount: tx.amount,
    currency: data.currency,
    status: tx.status == TransactionStatusEnum.pending
        ? TransactionRowStatus.pending
        : TransactionRowStatus.paid,
    paidHere: paidHere,
    onOpen: () => onEdit(tx),
    onPay: onPay,
  );
}

class _Entry {
  const _Entry(this.key, this.build);

  final String key;
  final Widget Function() build;
}

/// What the lists show while another month loads (the web's `min-h-[120px]`, busy), or why it is not
/// there: never another month's figures.
class _MonthUnavailable extends StatelessWidget {
  const _MonthUnavailable({
    required this.failure,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final HomeFailure? failure;
  final String? message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final message = this.message;
    if (message == null) return const SizedBox(height: 120);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: LukitasTokens.space3,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(message, style: LkText.bodySm.copyWith(color: colors.inkMuted)),
        ),
        PressButton.text(retryLabel, tone: PressTone.secondary, onPressed: onRetry),
      ],
    );
  }
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
