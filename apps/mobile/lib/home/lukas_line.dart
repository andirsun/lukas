// What Lukitas says on home. A port of core's `lukasMessage` (packages/core/src/lukas-message.ts)
// and the web's `homeLukasLine` (apps/web/app/features/home/home-model.ts): the rule picks a line
// and its figures; the copy belongs to the ARB catalogs (home_screen.dart picks the variant).

import '../api/gen/lukitas_api.dart';

enum LukasKey {
  firstOfDay,
  onTrack,
  nearLimit,
  overBudget,
  incomeReceived,
  pendingPaid,
  monthLastDay,
  monthClosedGreen,

  // Single lines (no variants) for the cases core cannot know about.
  /// An empty month without budgets: invites the first entry.
  empty,

  /// Without any budget there is nothing "left": he talks about what was spent.
  noBudget,

  /// A month over its total budget is never "on track", even if each category alone is fine.
  overTotal;

  /// Whether the catalog has three variants of the line.
  bool get varied => index < LukasKey.empty.index;
}

enum LukasEventKind { saved, paid }

/// The save or payment Lukitas is reacting to.
class LukasEvent {
  const LukasEvent({
    required this.kind,
    required this.categoryId,
    required this.amount,
    this.name = '',
  });

  final LukasEventKind kind;
  final String categoryId;

  /// Signed cents, as stored.
  final int amount;

  /// The movement's own name (empty: the line says its category).
  final String name;
}

/// A line to say: its [key] and the figures it uses (cents are unformatted, so the screen writes
/// them in the person's currency and language).
class LukasLine {
  const LukasLine(
    this.key, {
    this.name = '',
    this.category = '',
    this.amount = 0,
    this.remaining = 0,
    this.over = 0,
    this.spent = 0,
    this.daysLeft = 0,
  });

  final LukasKey key;
  final String name;
  final String category;
  final int amount;
  final int remaining;
  final int over;
  final int spent;
  final int daysLeft;
}

String _lastDay(String month) {
  final p = month.split('-').map(int.parse).toList();
  final last = DateTime.utc(p[0], p[1] + 1, 0).day;
  return '$month-${last.toString().padLeft(2, '0')}';
}

int _utcDay(String date) {
  final p = date.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}

/// Days from [today] to the last day of [month], both included. Never negative.
int _daysLeft(String today, String month) {
  final left = _utcDay(_lastDay(month)) - _utcDay(today) + 1;
  return left < 0 ? 0 : left;
}

/// The line Lukitas says on home. [summary] is the month's AFTER the [event] (if any) was applied;
/// [todayCount] counts the transactions of today, the event's included. [categoryName] gives a
/// category's name by id.
LukasLine lukasLine({
  required Summary summary,
  required String today,
  required int todayCount,
  required String Function(String categoryId) categoryName,
  LukasEvent? event,
}) {
  SummaryCategoriesInner? eventCategory;
  if (event != null) {
    for (final c in summary.categories) {
      if (c.categoryId == event.categoryId) eventCategory = c;
    }
  }
  final name = event?.name.trim() ?? '';
  // A movement without a name is called by its category.
  String movementName() => name.isEmpty ? categoryName(event!.categoryId) : name;

  LukasLine nearLimit(SummaryCategoriesInner c) => LukasLine(
    LukasKey.nearLimit,
    category: categoryName(c.categoryId),
    remaining: c.remaining ?? 0,
  );
  LukasLine overBudget(SummaryCategoriesInner c) => LukasLine(
    LukasKey.overBudget,
    category: categoryName(c.categoryId),
    over: -(c.remaining ?? 0),
  );

  // Core's rules, top to bottom: the first match wins.
  LukasLine? picked;
  LukasKey? aboutTheMonth;
  if (event != null && event.kind == LukasEventKind.paid && event.amount < 0) {
    picked = LukasLine(
      LukasKey.pendingPaid,
      name: movementName(),
      category: categoryName(event.categoryId),
      amount: -event.amount,
    );
  } else if (event != null &&
      event.amount > 0 &&
      (event.kind == LukasEventKind.paid || eventCategory == null)) {
    // A pending income marked paid was received, not paid.
    picked = LukasLine(
      LukasKey.incomeReceived,
      name: movementName(),
      category: categoryName(event.categoryId),
      amount: event.amount,
    );
  } else if (eventCategory?.state == SummaryCategoriesInnerStateEnum.over) {
    picked = overBudget(eventCategory!);
  } else if (eventCategory?.state == SummaryCategoriesInnerStateEnum.near) {
    picked = nearLimit(eventCategory!);
  } else if (event != null && todayCount == 1) {
    picked = LukasLine(
      LukasKey.firstOfDay,
      name: movementName(),
      category: categoryName(event.categoryId),
    );
  } else if (summary.month.compareTo(today.substring(0, 7)) < 0 && summary.remaining >= 0) {
    aboutTheMonth = LukasKey.monthClosedGreen;
  } else if (today == _lastDay(summary.month)) {
    aboutTheMonth = LukasKey.monthLastDay;
  } else if (event == null) {
    SummaryCategoriesInner? worst;
    SummaryCategoriesInner? least;
    for (final c in summary.categories) {
      if (c.state == SummaryCategoriesInnerStateEnum.over &&
          (worst == null || (c.remaining ?? 0) < (worst.remaining ?? 0))) {
        worst = c;
      }
      if (c.state == SummaryCategoriesInnerStateEnum.near &&
          (least == null || (c.remaining ?? 0) < (least.remaining ?? 0))) {
        least = c;
      }
    }
    if (worst != null) {
      picked = overBudget(worst);
    } else if (least != null) {
      picked = nearLimit(least);
    }
  }

  if (picked != null) return picked;

  // What is left of the month's lines: core cannot know the budgets' total, so two cases get their
  // own line and Lukitas never says something false.
  if (summary.budgetTotal == 0) {
    return summary.spent == 0
        ? const LukasLine(LukasKey.empty)
        : LukasLine(LukasKey.noBudget, spent: summary.spent);
  }
  if (summary.remaining < 0) return LukasLine(LukasKey.overTotal, over: -summary.remaining);
  return switch (aboutTheMonth) {
    LukasKey.monthClosedGreen ||
    LukasKey.monthLastDay => LukasLine(aboutTheMonth!, remaining: summary.remaining),
    _ => LukasLine(
      LukasKey.onTrack,
      remaining: summary.remaining,
      daysLeft: _daysLeft(today, summary.month),
    ),
  };
}
