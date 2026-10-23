import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../feedback/feedback.dart';
import 'home_controller.dart';

/// The feedback after a save, from the month's summary once the save is in it (the web's
/// `feedbackForSave`, apps/web/app/features/home/home-model.ts): income is [FeedbackEvent.incomeSaved];
/// an expense that leaves its category over or near its limit says so instead of celebrating;
/// otherwise [FeedbackEvent.saved].
///
/// For a batch the state is the one after the whole batch: the worst of its expenses' categories
/// (over before near), and it is an income save only when every row is an income. Without the
/// month's figures it is a plain save.
FeedbackEvent savedFeedbackFor(HomeData? data, Iterable<Transaction> saved) {
  if (data == null) return FeedbackEvent.saved;
  var incomes = 0;
  var total = 0;
  var near = false;
  var over = false;
  for (final tx in saved) {
    total++;
    if (data.categories[tx.categoryId]?.kind == CategoryKindEnum.income) {
      incomes++;
      continue;
    }
    final state = data.summary.categories
        .where((c) => c.categoryId == tx.categoryId)
        .map((c) => c.state)
        .firstOrNull;
    if (state == SummaryCategoriesInnerStateEnum.over) over = true;
    if (state == SummaryCategoriesInnerStateEnum.near) near = true;
  }
  if (over) return FeedbackEvent.overBudget;
  if (near) return FeedbackEvent.nearLimit;
  return total > 0 && incomes == total ? FeedbackEvent.incomeSaved : FeedbackEvent.saved;
}

/// Whether a save's feedback is a celebration (Lukitas, confetti-style): not when it is a warning
/// about a limit, like home's own rule for a single save.
bool celebrates(FeedbackEvent event) =>
    event != FeedbackEvent.nearLimit && event != FeedbackEvent.overBudget;

/// How long a save's feel waits for the month's figures before going with what it has: on a slow
/// connection the haptic must not trail the save by half a minute.
const savedFeelWait = Duration(seconds: 2);

/// [figures] (the home update after a save), but never for longer than [savedFeelWait], and never
/// failing: the feel goes with the last figures if they do not come.
Future<void> afterFigures(Future<void> figures) async {
  try {
    await figures.timeout(savedFeelWait, onTimeout: () {});
  } on Object {
    // The last figures will do.
  }
}

/// Gives the feel of a save once the month's [figures] are in (the web reads them from the
/// refreshed summary): picks the event by [savedFeedbackFor] and fires it. Returns the event.
Future<FeedbackEvent> feelSaved(
  ProviderContainer container,
  Future<void> figures,
  List<Transaction> saved,
) async {
  await afterFigures(figures);
  final data = container.exists(homeProvider) ? container.read(homeProvider).data : null;
  final event = savedFeedbackFor(data, saved);
  container.read(feedbackProvider)(event);
  return event;
}
