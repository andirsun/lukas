import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_form.dart';
import 'package:lukitas/add/idempotency_key.dart';
import 'package:lukitas/add/keypad_input.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';

import '../home/fixtures.dart';

final groceries = category('cat-groceries', 'Supermercado');
final home = category('cat-home', 'Hogar');
final fun = category('cat-fun', 'Ocio');
final salary = category('cat-salary', 'Nómina', kind: 'income');
final oldGym = category('cat-gym', 'Gimnasio', archived: true);

int _keys = 0;

AddForm form({
  String locale = 'es',
  String currency = 'COP',
  Transaction? editing,
  Kind kind = Kind.expense,
  List<Category>? categories,
  List<Transaction> recent = const [],
}) => AddForm(
  locale: locale,
  currency: currency,
  today: '2026-10-22',
  editing: editing,
  kind: kind,
  newKey: () => 'key-${++_keys}',
)..updateChoices(categories ?? [groceries, home, fun, salary, oldGym], recent);

void type(AddForm f, String keys) {
  for (final key in keys.split('')) {
    // A thousands separator is no key: it is ignored, as typing it is.
    final pressed = keyFromKeyboard(key, AmountFormat(f.locale, f.currency));
    if (pressed != null) f.press(pressed);
  }
}

void main() {
  test('a new key is a version 4 UUID, and never the same twice', () {
    final keys = {for (var i = 0; i < 50; i++) newIdempotencyKey()};
    expect(keys.length, 50);
    for (final key in keys) {
      expect(
        key,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
      );
    }
  });

  group('the amount', () {
    test('typing 6,08 in es and 6.08 in en both store 608', () {
      final es = form(locale: 'es', currency: 'EUR');
      type(es, '6,08');
      expect(es.raw, '6,08');
      expect(es.cents, 608);
      final en = form(locale: 'en', currency: 'EUR');
      type(en, '6.08');
      expect(en.raw, '6.08');
      expect(en.cents, 608);
      expect(es.input()!.amount, -608);
      expect(en.input()!.amount, -608);
    });

    test('in pesos the decimal separator only ends the amount', () {
      final f = form();
      type(f, '15.000,5');
      expect(f.cents, 1500000);
      expect(f.input()!.amount, -1500000);
    });

    test('nothing is valid until there is an amount', () {
      final f = form();
      expect(f.valid, isFalse);
      expect(f.input(), isNull);
      type(f, '0');
      expect(f.valid, isFalse);
      type(f, '5');
      expect(f.valid, isTrue);
    });

    test('an income is stored positive', () {
      final f = form(kind: Kind.income);
      type(f, '100');
      expect(f.selected!.id, 'cat-salary');
      expect(f.input()!.amount, 10000);
    });
  });

  group('the category', () {
    test('only active categories of the kind, the most used first, then in their own order', () {
      final recent = [tx('a', '2026-10-01', -1, categoryId: 'cat-fun')];
      final f = form(recent: recent);
      expect(f.ofKind.map((c) => c.id), ['cat-fun', 'cat-groceries', 'cat-home']);
      expect(f.selected!.id, 'cat-fun');
    });

    test('switching the kind drops the chosen category for the new kind\'s first', () {
      final f = form()..select('cat-home');
      expect(f.selected!.id, 'cat-home');
      f.setKind(Kind.income);
      expect(f.selected!.id, 'cat-salary');
      expect(f.kind, Kind.income);
    });

    test('with seven or fewer categories every chip shows; more fold behind Más', () {
      final many = [for (var i = 0; i < 12; i++) category('c$i', 'Cat $i')];
      final f = form(categories: many);
      expect(f.chips(visible: 7).length, 7);
      expect(f.overflow(visible: 7), isTrue);
      f.select('c10');
      // The selected one is always among the visible chips.
      expect(f.chips(visible: 7).map((c) => c.id), contains('c10'));
      f.allChips = true;
      expect(f.chips(visible: 7).length, 12);
      expect(form(categories: many.take(8).toList()).overflow(visible: 7), isFalse);
    });

    test('an edited movement keeps offering its archived category, first', () {
      final f = form(editing: tx('t', '2026-10-01', -500, categoryId: 'cat-gym'));
      expect(f.ofKind.first.id, 'cat-gym');
      expect(f.selected!.id, 'cat-gym');
    });
  });

  group('what saving sends', () {
    test('an unnamed movement takes its category\'s name', () {
      final f = form();
      type(f, '2500');
      f.select('cat-home');
      expect(f.input()!.name, 'Hogar');
      f.setName('  Arriendo ');
      expect(f.input()!.name, 'Arriendo');
    });

    test('date, pending and note go along; a blank note does not', () {
      final f = form();
      type(f, '100');
      f.setDate('2026-10-20');
      f.pending = true;
      f.setNote('   ');
      var input = f.input()!;
      expect(input.date, '2026-10-20');
      expect(input.status, CreateTransactionStatusEnum.pending);
      expect(input.note, isNull);
      expect(input.source_, CreateTransactionSource_Enum.app);
      f.setNote(' con Ana ');
      input = f.input()!;
      expect(input.note, 'con Ana');
    });

    test('picking a suggestion fills the name, the kind and the category', () {
      final f = form();
      f.pick(
        TransactionSuggestion(
          (b) => b
            ..name = 'Nómina de octubre'
            ..categoryId = 'cat-salary',
        ),
      );
      expect(f.name, 'Nómina de octubre');
      expect(f.kind, Kind.income);
      expect(f.selected!.id, 'cat-salary');
      // After a pick the full list stays: the API filters only while the person types.
      expect(f.suggestionQuery, '');
      f.setName('Nómina de octubre 2');
      expect(f.suggestionQuery, 'Nómina de octubre 2');
    });
  });

  group('the idempotency key', () {
    test('one key per attempt: made at the first save, the same for a retry', () {
      final f = form();
      type(f, '100');
      expect(f.keyForSave(), 'key-$_keys');
      final first = f.keyForSave();
      expect(f.keyForSave(), first);
    });

    test('any edit of the input after a failure makes a new key', () {
      void edits(AddForm f, List<void Function()> changes) {
        for (final change in changes) {
          final before = f.keyForSave();
          change();
          expect(f.keyForSave(), isNot(before));
        }
      }

      final f = form(currency: 'EUR');
      type(f, '100');
      edits(f, [
        () => type(f, '5'),
        () => f.press(const BackspaceKey()),
        () => f.setName('Cena'),
        () => f.select('cat-home'),
        () => f.setKind(Kind.income),
        () => f.setKind(Kind.expense),
        () => f.setDate('2026-10-19'),
        () => f.pending = true,
        () => f.setNote('x'),
        () => f.pick(
          TransactionSuggestion(
            (b) => b
              ..name = 'Cafe'
              ..categoryId = 'cat-fun',
          ),
        ),
      ]);
    });

    test('a key that did nothing (a refused key press) stays', () {
      final f = form(currency: 'EUR');
      type(f, '6,08');
      final key = f.keyForSave();
      type(f, '9');
      expect(f.raw, '6,08');
      expect(f.keyForSave(), key);
    });
  });

  group('editing', () {
    final original = tx('t1', '2026-10-20', -2800000, name: 'Almuerzo', categoryId: 'cat-home');

    test('starts from the movement', () {
      final f = form(editing: original);
      expect(f.raw, '28000');
      expect(f.name, 'Almuerzo');
      expect(f.kind, Kind.expense);
      expect(f.date, '2026-10-20');
      expect(f.selected!.id, 'cat-home');
      expect(f.pending, isFalse);
    });

    test('an income reads as an income', () {
      final f = form(editing: tx('t', '2026-10-01', 500000, categoryId: 'cat-salary'));
      expect(f.kind, Kind.income);
    });

    test('a name that is only its category\'s shows as the placeholder', () {
      final f = form(
        editing: tx('t', '2026-10-01', -500, name: 'Hogar', categoryId: 'cat-home'),
      );
      expect(f.name, '');
    });

    test('what is typed is kept exactly, even passing through the category\'s own name', () {
      final f = form(
        editing: tx('t', '2026-10-01', -500, name: 'Supermercado', categoryId: 'cat-groceries'),
      );
      expect(f.name, '');
      var typed = '';
      for (final char in 'Supermercado Éxito'.split('')) {
        typed += char;
        f.setName(typed);
        // What the field shows is what was typed, at every step (the sheet writes it back).
        expect(f.name, typed);
      }
      expect(f.input()!.name, 'Supermercado Éxito');
      expect(f.patch().name, 'Supermercado Éxito');
    });

    test('a touched name that is cleared falls back to the category again', () {
      final f = form(
        editing: tx('t', '2026-10-01', -500, name: 'Supermercado', categoryId: 'cat-groceries'),
      );
      f.setName('Mercado');
      f.setName('');
      expect(f.name, '');
      expect(f.input()!.name, 'Supermercado');
    });

    test('the patch has only what changed', () {
      final f = form(editing: original);
      expect(f.patch().isEmpty, isTrue);
      type(f, '5');
      f.setName('Cena');
      f.pending = true;
      final patch = f.patch();
      expect(patch.amount, -28000500);
      expect(patch.name, 'Cena');
      expect(patch.pending, isTrue);
      expect(patch.categoryId, isNull);
      expect(patch.date, isNull);
      expect(patch.setNote, isFalse);
    });

    test('the category goes in the patch only when the person picked one', () {
      final f = form(editing: original);
      f.select('cat-home');
      expect(f.patch().categoryId, isNull);
      f.select('cat-fun');
      expect(f.patch().categoryId, 'cat-fun');
    });

    test('flipping to income flips the sign of the stored amount', () {
      final f = form(editing: original)..setKind(Kind.income);
      expect(f.patch().amount, 2800000);
      expect(f.patch().categoryId, 'cat-salary');
    });

    test('clearing the note sends a null; leaving it alone sends nothing', () {
      final withNote = tx('t', '2026-10-01', -500, name: 'x').rebuild((b) => b.note = 'con Ana');
      final f = form(editing: withNote);
      expect(f.patch().setNote, isFalse);
      f.setNote('');
      final patch = f.patch();
      expect(patch.setNote, isTrue);
      expect(patch.note, isNull);
    });
  });
}
