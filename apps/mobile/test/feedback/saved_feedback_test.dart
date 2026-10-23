// Which feedback a save gets (the web's feedbackForSave, apps/web/app/features/home/home-model.ts):
// income is income, an expense that leaves its category near or over its limit says so, and
// otherwise it is a plain save. A batch takes the state after the whole batch.
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/feedback/feedback.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/home/saved_feedback.dart';

import '../home/fixtures.dart';

HomeData data({List<String> states = const []}) => HomeData(
  month: '2026-10',
  timezone: 'America/Bogota',
  currency: 'COP',
  summary: summary(
    categories: [
      categorySummary(
        'cat-food',
        budget: 100000,
        spent: 50000,
        state: states.elementAtOrNull(0) ?? 'ok',
      ),
      categorySummary(
        'cat-fun',
        budget: 100000,
        spent: 50000,
        state: states.elementAtOrNull(1) ?? 'ok',
      ),
    ],
  ),
  categories: {
    'cat-food': category('cat-food', 'Comida'),
    'cat-fun': category('cat-fun', 'Ocio'),
    'cat-salary': category('cat-salary', 'Nómina', kind: 'income'),
  },
  items: const [],
  nextCursor: null,
);

void main() {
  final food = tx('a', '2026-10-22', -1000, categoryId: 'cat-food');
  final fun = tx('b', '2026-10-22', -1000, categoryId: 'cat-fun');
  final salary = tx('c', '2026-10-22', 5000, categoryId: 'cat-salary');

  test('an expense within its limit is a plain save', () {
    expect(savedFeedbackFor(data(), [food]), FeedbackEvent.saved);
  });

  test('an income is an income, whatever the other categories are doing', () {
    expect(savedFeedbackFor(data(states: ['over', 'over']), [salary]), FeedbackEvent.incomeSaved);
  });

  test('an expense that leaves its category near its limit says so', () {
    expect(savedFeedbackFor(data(states: ['near']), [food]), FeedbackEvent.nearLimit);
  });

  test('an expense that leaves its category over its limit says so', () {
    expect(savedFeedbackFor(data(states: ['over']), [food]), FeedbackEvent.overBudget);
  });

  test('only the saved category counts: another one over does not spoil the save', () {
    expect(savedFeedbackFor(data(states: ['ok', 'over']), [food]), FeedbackEvent.saved);
  });

  test('a batch takes the worst state after the whole batch', () {
    expect(savedFeedbackFor(data(states: ['near', 'over']), [food, fun]), FeedbackEvent.overBudget);
    expect(savedFeedbackFor(data(states: ['near', 'ok']), [food, fun]), FeedbackEvent.nearLimit);
    expect(savedFeedbackFor(data(states: ['ok', 'ok']), [food, fun]), FeedbackEvent.saved);
  });

  test('a batch of incomes only is an income save; a mix is a plain save', () {
    expect(savedFeedbackFor(data(), [salary, salary]), FeedbackEvent.incomeSaved);
    expect(savedFeedbackFor(data(), [food, salary]), FeedbackEvent.saved);
  });

  test('a mixed batch still warns about its expenses', () {
    expect(savedFeedbackFor(data(states: ['over']), [food, salary]), FeedbackEvent.overBudget);
  });

  test('with no figures yet it is a plain save, or an income', () {
    expect(savedFeedbackFor(null, [food]), FeedbackEvent.saved);
    expect(savedFeedbackFor(null, [salary]), FeedbackEvent.saved, reason: 'no categories known');
  });

  test('only a save that is not a warning is a celebration', () {
    expect(celebrates(FeedbackEvent.saved), isTrue);
    expect(celebrates(FeedbackEvent.incomeSaved), isTrue);
    expect(celebrates(FeedbackEvent.nearLimit), isFalse);
    expect(celebrates(FeedbackEvent.overBudget), isFalse);
  });
}
