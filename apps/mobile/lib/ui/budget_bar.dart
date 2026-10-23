// The web's BudgetBar (apps/web/app/ui/BudgetBar.tsx) and the CSS it uses: app.css `.lk-bar`,
// `.lk-bar-sm`, `.lk-bar > span`, `.is-near`, `.is-over`.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';
import 'lk_theme.dart';
import 'pixel_snap.dart';

/// How the API rates a category this month (`MonthSummary.categories[].state`): the bar never
/// recomputes it.
enum BudgetState { ok, near, over }

/// The bar's height: 12px, or 7px inside rows.
enum BudgetBarSize { md, sm }

/// A track that fills with what was spent (never with what is left), coloured by [state]. It is a
/// meter named by [label]; over budget the value is clamped to the maximum so the meter stays
/// valid, and the label carries the overflow in words. Without a budget there is nothing to
/// measure: the track stays empty and is hidden from assistive technology.
///
/// The fill follows a change of [spent] over `--count-up` (ease-out), or at once with the system's
/// "remove animations".
class BudgetBar extends StatelessWidget {
  const BudgetBar({
    super.key,
    required this.spent,
    required this.budget,
    required this.state,
    this.size = BudgetBarSize.md,
    required this.label,
  });

  /// Cents spent this month in the category.
  final int spent;

  /// Cents budgeted, or null when the category has no budget.
  final int? budget;

  final BudgetState state;
  final BudgetBarSize size;

  /// Names the meter; pair the bar with the same status in words (`Quedan 46,33 €`).
  final String label;

  /// Share of the budget spent, capped at full, as the web's `fillWidth`: rounded to a tenth of a
  /// percent.
  static double fillFraction(int spent, int budget) {
    final ratio = budget > 0 ? math.min(math.max(spent, 0) / budget, 1.0) : (spent > 0 ? 1.0 : 0.0);
    return (ratio * 1000).round() / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lkColors;
    final budget = this.budget;
    final fill = switch (state) {
      BudgetState.ok => colors.good,
      BudgetState.near => colors.near,
      BudgetState.over => colors.over,
    };
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : LukitasTokens.durationCountUp;
    final height = size == BudgetBarSize.sm ? 7.0 : 12.0;

    final bar = SizedBox(
      width: double.infinity,
      height: height,
      child: SnappedDecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
        ),
        child: ClipRect(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: budget == null ? 0.0 : fillFraction(spent, budget)),
            duration: duration,
            curve: Curves.easeOut,
            builder: (context, fraction, _) => Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                heightFactor: 1,
                child: SnappedDecoratedBox(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(LukitasTokens.radiusPill),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (budget == null) return ExcludeSemantics(child: bar);
    final max = math.max(budget, 0);
    final now = math.min(math.max(spent, 0), max);
    return Semantics(
      label: label,
      value: max == 0 ? '0%' : '${(now / max * 100).round()}%',
      excludeSemantics: true,
      child: bar,
    );
  }
}
