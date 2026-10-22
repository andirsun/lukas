import 'package:flutter/material.dart';

import '../api/gen/lukitas_api.dart';
import '../l10n/app_localizations.dart';
import '../money/format.dart';
import '../theme/theme.dart';
import '../theme/tokens.g.dart';
import 'lukitas_face.dart';

/// Where a spent amount stands against its budget: near from 80 % of it, over past it (core's
/// `NEAR_LIMIT_RATIO`, the web's `overallState`).
enum BudgetState { ok, near, over }

BudgetState overallState(int budgetTotal, int spent) {
  if (budgetTotal <= 0) return spent > 0 ? BudgetState.over : BudgetState.ok;
  final ratio = spent / budgetTotal;
  return ratio > 1
      ? BudgetState.over
      : ratio >= 0.8
      ? BudgetState.near
      : BudgetState.ok;
}

/// Lukitas beside his speech bubble. The line carries the meaning, so Lukitas is decorative; the
/// bubble is a polite live region, so a new line after a payment is read out. A new line fades in
/// (`--fade`), from faint, never from nothing; with "remove animations" it just shows.
class LukitasBubble extends StatelessWidget {
  const LukitasBubble({
    super.key,
    required this.message,
    required this.mood,
    required this.announce,
  });

  final String message;
  final LukitasMood mood;

  /// Whether a screen reader reads the line out when it changes: true for a line about a save or a
  /// payment, false for the month's line, so going back to it after an event is not announced a
  /// second time.
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Row(
      children: [
        ExcludeSemantics(child: LukitasFace(mood: mood, size: 72)),
        const SizedBox(width: LukitasTokens.space3),
        Expanded(
          child: Semantics(
            liveRegion: announce,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(message),
              tween: Tween(begin: reduce ? 1 : 0.25, end: 1),
              duration: reduce ? Duration.zero : LukitasTokens.durationFade,
              curve: Curves.easeOut,
              builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceRow,
                  border: Border.all(color: colors.stroke, width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A month's money against its budget: a pill bar that fills with what was spent.
class BudgetBar extends StatelessWidget {
  const BudgetBar({
    super.key,
    required this.spent,
    required this.budget,
    required this.state,
    required this.semanticsLabel,
  });

  final int spent;
  final int budget;
  final BudgetState state;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final fill = budget <= 0 ? 1.0 : (spent / budget).clamp(0.0, 1.0);
    final color = switch (state) {
      BudgetState.ok => colors.good,
      BudgetState.near => colors.near,
      BudgetState.over => colors.over,
    };
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
          child: Container(
            height: 12,
            color: colors.surfaceSunken,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fill),
              duration: reduce ? Duration.zero : LukitasTokens.durationCountUp,
              curve: Curves.easeOut,
              builder: (context, value, _) => FractionallySizedBox(
                widthFactor: value,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An amount in the person's currency that counts from the previous value to the new one over
/// `--count-up` whenever it changes (not on first show). The counting figure is hidden from
/// assistive technology, which reads the final amount right away. With "remove animations" the
/// value just changes.
class CountUpMoney extends StatelessWidget {
  const CountUpMoney({
    super.key,
    required this.cents,
    required this.currency,
    required this.locale,
    required this.style,
  });

  final int cents;
  final String currency;
  final String locale;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: formatMoney(cents, currency, locale),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<int>(
          tween: IntTween(end: cents),
          duration: reduce ? Duration.zero : LukitasTokens.durationCountUp,
          curve: Curves.easeOut,
          builder: (context, value, _) => Text(
            formatMoney(value, currency, locale),
            maxLines: 1,
            style: style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ),
    );
  }
}

/// What is left of the month (or, without budgets, what was spent), in large type: the label, the
/// amount, and a bar with what was spent against the budgets. The web's `Hero`.
class MonthHero extends StatelessWidget {
  const MonthHero({
    super.key,
    required this.summary,
    required this.currency,
    required this.locale,
    this.pastMonth,
  });

  final Summary summary;
  final String currency;
  final String locale;

  /// The month's name (mid-sentence) when the figures are not this month's, so the labels never
  /// say "este mes" about another one. Null: this month.
  final String? pastMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final past = pastMonth;
    String money(int cents) => formatMoney(cents, currency, locale);
    final hasBudget = summary.budgetTotal > 0;
    final over = hasBudget && summary.remaining < 0;
    final label = !hasBudget
        ? (past == null ? l10n.homeSpentLabel : l10n.homeSpentLabelPast(past))
        : over
        ? (past == null ? l10n.homeOverLabel : l10n.homeOverLabelPast(past))
        : (past == null ? l10n.homeRemainingLabel : l10n.homeRemainingLabelPast(past));
    final amountColor = over ? colors.over : (hasBudget ? colors.good : colors.ink);
    final meta = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors.inkMuted);

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          LukitasTokens.space4,
          LukitasTokens.space3,
          LukitasTokens.space4,
          LukitasTokens.space4,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(LukitasTokens.radiusXl),
          boxShadow: [BoxShadow(color: colors.surfaceEdge, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colors.inkMuted),
              ),
            ),
            const SizedBox(height: 2),
            CountUpMoney(
              cents: hasBudget ? summary.remaining.abs() : summary.spent,
              currency: currency,
              locale: locale,
              style: TextStyle(
                fontSize: 38,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
            if (hasBudget) ...[
              const SizedBox(height: LukitasTokens.space2),
              BudgetBar(
                spent: summary.spent,
                budget: summary.budgetTotal,
                state: overallState(summary.budgetTotal, summary.spent),
                semanticsLabel: l10n.homeSpentMeter(
                  money(summary.spent),
                  money(summary.budgetTotal),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      l10n.homeSpent(money(summary.spent)),
                      style: meta,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: LukitasTokens.space2),
                  Flexible(
                    child: Text(
                      l10n.homeOfBudget(money(summary.budgetTotal)),
                      style: meta,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(l10n.homeNoBudgetMeta, style: meta),
            ],
          ],
        ),
      ),
    );
  }
}

/// The month's name in a small pill, at the top.
class MonthPill extends StatelessWidget {
  const MonthPill({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceRow,
        borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
        boxShadow: [BoxShadow(color: colors.surfaceEdge, offset: const Offset(0, 3))],
      ),
      child: Text(
        name,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colors.ink),
      ),
    );
  }
}

/// The day's heading above its rows: "Hoy · mié 21" and the day's total.
class DayHeading extends StatelessWidget {
  const DayHeading({super.key, required this.label, required this.total});

  final String label;
  final String total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.77,
      color: colors.inkMuted,
    );
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: LukitasTokens.space1, bottom: LukitasTokens.space2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label.toUpperCase(), style: style)),
            Text(total, style: style.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      ),
    );
  }
}

/// The "Movimientos" tab, stuck under the top of the screen once the summary scrolls away. The
/// background hides the list scrolling under it.
class MovementsTabHeader extends SliverPersistentHeaderDelegate {
  const MovementsTabHeader({required this.label, required this.background, required this.inset});

  final String label;
  final Color background;

  /// The side padding, so the tab lines up with the content below it.
  final double inset;

  static const _height = 44.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colors = Theme.of(context).extension<LukitasTheme>()!.colors;
    return Container(
      color: background,
      padding: EdgeInsets.symmetric(horizontal: inset, vertical: LukitasTokens.space2),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(LukitasTokens.radiusMd),
        ),
        child: Semantics(
          header: true,
          selected: true,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.brand, borderRadius: BorderRadius.circular(11)),
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colors.onBrand),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(MovementsTabHeader old) =>
      old.label != label || old.background != background || old.inset != inset;
}

/// A spinner that does not move under "remove animations".
class QuietSpinner extends StatelessWidget {
  const QuietSpinner({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        value: MediaQuery.disableAnimationsOf(context) ? 0.25 : null,
      ),
    );
  }
}
