import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/parser/parse.dart';
import 'package:lukitas/capture/preview/capture_preview.dart';

const _food = Category(id: 'food', name: 'Comida', kind: Kind.expense);
const _transport = Category(id: 'uber', name: 'Uber', kind: Kind.expense);
const _salary = Category(id: 'salary', name: 'Salario', kind: Kind.income);

const _ctx = ParseContext(
  locale: 'es',
  currency: 'COP',
  today: '2026-10-22',
  timeZone: 'America/Bogota',
  categories: [_food, _transport, _salary],
);

CapturePreview _preview(String sentence) =>
    CapturePreview(today: _ctx.today)..read(sentence, parseSentence(sentence, _ctx));

void main() {
  test('one card per draft, plus the unread fragments', () {
    final p = _preview('gasté 15 mil en almuerzo y 3 lukas en uber');
    expect(p.cards, hasLength(2));
    expect(p.cards[0].amount, 1500000);
    expect(p.cards[0].name, 'almuerzo');
    expect(p.cards[0].categoryId, isNull);
    expect(p.cards[1].categoryId, 'uber');
    expect(p.unread, isEmpty);
    expect(p.sentence, 'gasté 15 mil en almuerzo y 3 lukas en uber');
  });

  test('ready only when every card has an amount and a category', () {
    final p = _preview('gasté 15 mil en almuerzo y 3 lukas en uber');
    expect(p.ready, isFalse);
    p.update(p.cards[0].id, categoryId: 'food');
    expect(p.ready, isTrue);
    p.update(p.cards[1].id, amount: 0);
    expect(p.ready, isFalse);
  });

  test('no cards is not ready', () {
    final p = _preview('hola');
    expect(p.cards, isEmpty);
    expect(p.ready, isFalse);
  });

  test('an unread fragment becomes a card to complete by hand', () {
    final p = _preview('gasté 15 mil en almuerzo y 9,50 en café');
    expect(p.unread, ['9,50 en café']);
    p.complete(0);
    expect(p.unread, isEmpty);
    final card = p.cards.last;
    expect(card.amount, isNull);
    expect(card.name, '9,50 en café');
    expect(card.kind, Kind.expense);
    expect(card.date, '2026-10-22');
    expect(p.ready, isFalse);
  });

  test('a removed card is gone; a kind change drops a category of the other kind', () {
    final p = _preview('gasté 15 mil en almuerzo y 3 lukas en uber');
    p.remove(p.cards[0].id);
    expect(p.cards.single.name, 'uber');
    p.update(p.cards.single.id, kind: Kind.income);
    expect(p.cards.single.categoryId, isNull);
  });

  test('every change moves the version on (a new idempotency key)', () {
    final p = _preview('gasté 15 mil en almuerzo');
    final before = p.version;
    p.update(p.cards.single.id, name: 'almuerzo rico');
    expect(p.version, greaterThan(before));
  });

  test('drafts to save: names start with a capital, or are the category\'s when empty', () {
    final p = _preview('gasté 15 mil en almuerzo y 3 lukas en uber');
    p.update(p.cards[0].id, categoryId: 'food', name: '');
    final drafts = p.drafts(categoryName: (id) => {'food': 'Comida', 'uber': 'Uber'}[id]!);
    expect(drafts, const [
      Draft(
        amount: 1500000,
        kind: Kind.expense,
        name: 'Comida',
        categoryId: 'food',
        date: '2026-10-22',
      ),
      Draft(
        amount: 300000,
        kind: Kind.expense,
        name: 'Uber',
        categoryId: 'uber',
        date: '2026-10-22',
      ),
    ]);
  });

  test('the total adds up the cards', () {
    final p = _preview('gasté 15 mil en almuerzo y 3 lukas en uber');
    expect(p.total, 1800000);
  });
}
