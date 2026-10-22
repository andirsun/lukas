import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_sheet.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/home/home_screen.dart';

import '../home/fakes.dart';
import '../home/fixtures.dart';
import '../home/home_harness.dart';
import 'fakes.dart';

/// Home in front of a server whose money is [currency], with the add sheet's repository on top of
/// the same movements.
Future<({FakeHomeRepository server, FakeAddRepository add})> pump(
  WidgetTester tester, {
  String currency = 'COP',
  List<Transaction>? items,
  List<Category>? categories,
  Locale locale = const Locale('es'),
  Size size = const Size(390, 844),
}) async {
  final server = FakeHomeRepository(
    currency: currency,
    categoryList:
        categories ??
        [
          category('cat-groceries', 'Supermercado', icon: '🛒'),
          category('cat-home', 'Hogar', icon: '🏠', color: 'orange'),
          category('cat-fun', 'Ocio', icon: '🎬'),
          category('cat-salary', 'Nómina', kind: 'income', icon: '💰'),
        ],
    items: items ?? [tx('coffee', '2026-10-22', -450000, name: 'Café')],
  );
  final add = FakeAddRepository(server);
  await pumpHome(tester, server, addRepo: add, locale: locale, size: size);
  return (server: server, add: add);
}

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home.add')));
  await tester.pumpAndSettle();
}

Future<void> tapKeys(WidgetTester tester, String keys) async {
  for (final key in keys.split('')) {
    final name = switch (key) {
      ',' || '.' => 'keypad.decimal',
      '<' => 'keypad.backspace',
      _ => 'keypad.$key',
    };
    await tester.tap(find.byKey(Key(name)));
    await tester.pump();
  }
}

String amountShown(WidgetTester tester) => tester
    .widget<RichText>(
      find.descendant(of: find.byKey(const Key('add.amount')), matching: find.byType(RichText)),
    )
    .text
    .toPlainText();

/// The one create call the fake server got (the sheet's other calls are the suggestions').
String createCall(FakeAddRepository add) => add.calls.singleWhere((c) => c.startsWith('create'));

/// Lets the 8 s of a Deshacer toast and the 10 s of an event line pass.
Future<void> letTimersEnd(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 12));
  await tester.pumpAndSettle();
}

void main() {
  group('the amount', () {
    testWidgets('typing 6,08 in es and 6.08 in en both store 608', (tester) async {
      var env = await pump(tester, currency: 'EUR');
      await openSheet(tester);
      await tapKeys(tester, '6,08');
      expect(amountShown(tester), contains('6,08'));
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(createCall(env.add), endsWith('Supermercado -608'));
      await letTimersEnd(tester);
      // Home goes away, and Riverpod lets its state go, before the next one is shown.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);

      env = await pump(tester, currency: 'EUR', locale: const Locale('en'));
      await openSheet(tester);
      await tapKeys(tester, '6.08');
      expect(amountShown(tester), contains('6.08'));
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(createCall(env.add), endsWith('Supermercado -608'));
      await letTimersEnd(tester);
    });

    testWidgets('in COP the keypad has no decimal key, and pesos are stored as cents', (
      tester,
    ) async {
      final env = await pump(tester);
      await openSheet(tester);
      expect(find.byKey(const Key('keypad.decimal')), findsNothing);
      for (final digit in '0123456789'.split('')) {
        expect(find.byKey(Key('keypad.$digit')), findsOneWidget);
      }
      await tapKeys(tester, '25000');
      expect(amountShown(tester), contains(r'$25.000'));
      expect(amountShown(tester), contains('25 lukas'));
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(createCall(env.add), endsWith('Supermercado -2500000'));
      await letTimersEnd(tester);
    });

    testWidgets('Guardar waits for an amount; Borrar takes the last digit away', (tester) async {
      await pump(tester);
      await openSheet(tester);
      FilledButton save() => tester.widget<FilledButton>(find.byKey(const Key('add.save')));
      expect(save().onPressed, isNull);
      await tapKeys(tester, '12');
      expect(save().onPressed, isNotNull);
      await tapKeys(tester, '<<');
      expect(save().onPressed, isNull);
    });
  });

  group('the name and its suggestions', () {
    List<Transaction> manyNames() => [
      // Eight names, used 8, 7, ... 1 times.
      for (var n = 0; n < 8; n++)
        for (var i = 0; i <= 7 - n; i++)
          tx('n$n-$i', '2026-10-${10 + (i % 10)}', -1000, name: 'Nombre${n + 1}'),
    ];

    testWidgets('suggestions show at most two rows, the most used first', (tester) async {
      await pump(tester, items: manyNames(), size: const Size(360, 800));
      await openSheet(tester);
      final shown = [
        for (var n = 1; n <= 8; n++)
          if (find.byKey(Key('shortcut.Nombre$n')).evaluate().isNotEmpty) n,
      ];
      // Whatever shows is a prefix of the most used first, and not all eight fit in two rows.
      expect(shown, [for (var i = 1; i <= shown.length; i++) i]);
      expect(shown.length, inInclusiveRange(2, 7));
      final tops = {
        for (final n in shown) tester.getTopLeft(find.byKey(Key('shortcut.Nombre$n'))).dy,
      };
      expect(tops.length, lessThanOrEqualTo(2));
      // Most used first reads left to right, then down.
      final positions = [
        for (final n in shown) tester.getTopLeft(find.byKey(Key('shortcut.Nombre$n'))),
      ];
      for (var i = 1; i < positions.length; i++) {
        final before = positions[i - 1];
        final after = positions[i];
        expect(after.dy > before.dy || (after.dy == before.dy && after.dx > before.dx), isTrue);
      }
    });

    testWidgets('a shortcut fills the name and goes to its usual category', (tester) async {
      final env = await pump(
        tester,
        items: [tx('a', '2026-10-20', -5000, name: 'Cine', categoryId: 'cat-fun')],
      );
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('shortcut.Cine')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byKey(const Key('add.name'))).controller!.text, 'Cine');
      await tapKeys(tester, '5');
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(createCall(env.add), 'create ${env.add.keys.last} Cine -500');
      expect(env.server.items.first.categoryId, 'cat-fun');
      await letTimersEnd(tester);
    });

    testWidgets('typing asks for the matching names, after a short pause', (tester) async {
      final env = await pump(
        tester,
        items: [
          tx('a', '2026-10-20', -5000, name: 'Cine', categoryId: 'cat-fun'),
          tx('b', '2026-10-19', -5000, name: 'Cena', categoryId: 'cat-fun'),
        ],
      );
      await openSheet(tester);
      expect(env.add.calls, ['suggestions ']);
      await tester.enterText(find.byKey(const Key('add.name')), 'ce');
      await tester.pump(const Duration(milliseconds: 50));
      expect(env.add.calls, ['suggestions ']);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(env.add.calls.last, 'suggestions ce');
      expect(find.byKey(const Key('shortcut.Cena')), findsOneWidget);
      expect(find.byKey(const Key('shortcut.Cine')), findsNothing);
      // While typing, each shortcut says where it goes.
      expect(find.textContaining('Ocio'), findsWidgets);
    });

    testWidgets('a name left empty is the category\'s', (tester) async {
      final env = await pump(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('category.cat-home')));
      await tester.pump();
      await tapKeys(tester, '9');
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(createCall(env.add), endsWith('Hogar -900'));
      await letTimersEnd(tester);
    });
  });

  group('saving', () {
    testWidgets('closes the sheet, shows the row, and offers Deshacer and Ponerle nombre', (
      tester,
    ) async {
      final env = await pump(tester);
      await openSheet(tester);
      await tapKeys(tester, '25000');
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add.sheet')), findsNothing);
      expect(find.text(r'Gasto en Supermercado: $25.000 (25 lukas)'), findsOneWidget);
      expect(find.text('Deshacer'), findsOneWidget);
      expect(find.text('Ponerle nombre'), findsOneWidget);
      // The row is on home, called by its category.
      expect(find.text('Supermercado'), findsWidgets);
      expect(env.server.items.length, 2);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(env.server.items.length, 1);
      expect(find.text('Quitado: Supermercado'), findsOneWidget);
      await letTimersEnd(tester);
    });

    testWidgets('a named movement has no Ponerle nombre; an income reads Ingreso de', (
      tester,
    ) async {
      final env = await pump(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('add.kind.income')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('add.name')), 'Quincena');
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKeys(tester, '100');
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(find.text(r'Ingreso de Nómina: $100'), findsOneWidget);
      expect(find.text('Ponerle nombre'), findsNothing);
      expect(createCall(env.add), endsWith('Quincena 10000'));
      await letTimersEnd(tester);
    });

    testWidgets('Ponerle nombre opens the movement to edit, on its name', (tester) async {
      await pump(tester);
      await openSheet(tester);
      await tapKeys(tester, '7');
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ponerle nombre'));
      await tester.pumpAndSettle();
      expect(find.text('Editar movimiento'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(const Key('add.name'))).focusNode!.hasFocus,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('add.close')));
      await tester.pumpAndSettle();
      await letTimersEnd(tester);
    });

    testWidgets('home catches up: the figures and the list change without a reload', (
      tester,
    ) async {
      final env = await pump(tester);
      await openSheet(tester);
      await tapKeys(tester, '10000');
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(env.server.calls.where((c) => c.startsWith('summary')).length, 2);
      expect(find.text(r'$14.500'), findsWidgets); // 4.500 + 10.000 spent
      await letTimersEnd(tester);
    });

    testWidgets('more options: the date, pending and a note go along', (tester) async {
      final env = await pump(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('add.more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add.pending')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('add.note')), 'con Ana');
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKeys(tester, '3000');
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      final saved = env.server.items.firstWhere((t) => t.id == 'new-1');
      expect(saved.status, TransactionStatusEnum.pending);
      expect(saved.note, 'con Ana');
      expect(saved.date, '2026-10-22');
      await letTimersEnd(tester);
    });
  });

  group('a failed save', () {
    testWidgets('keeps the input and Reintentar resends with the same Idempotency-Key', (
      tester,
    ) async {
      final env = await pump(tester);
      await openSheet(tester);
      await tapKeys(tester, '25000');
      env.add.loseNextAnswer = true;
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();

      // The sheet stays, with what was typed, and says why; the server already has the movement.
      expect(find.byKey(const Key('add.sheet')), findsOneWidget);
      expect(amountShown(tester), contains(r'$25.000'));
      expect(find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'), findsOneWidget);
      expect(env.server.items.length, 2);

      await tester.tap(find.byKey(const Key('add.retry')));
      await tester.pumpAndSettle();
      expect(env.add.keys.length, 2);
      expect(env.add.keys[0], env.add.keys[1]);
      // One row, not two.
      expect(env.server.items.where((t) => t.name == 'Supermercado').length, 1);
      expect(find.byKey(const Key('add.sheet')), findsNothing);
      expect(find.text(r'Gasto en Supermercado: $25.000 (25 lukas)'), findsOneWidget);
      await letTimersEnd(tester);
    });

    testWidgets('any edit after a failure makes a new key', (tester) async {
      final env = await pump(tester);
      await openSheet(tester);
      await tapKeys(tester, '25000');
      env.add.failures['create'] = const HomeFailure(503);
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add.retry')), findsOneWidget);

      await tapKeys(tester, '0');
      await tester.tap(find.byKey(const Key('add.retry')));
      await tester.pumpAndSettle();
      expect(env.add.keys.length, 2);
      expect(env.add.keys[0], isNot(env.add.keys[1]));
      await letTimersEnd(tester);
    });

    testWidgets('a refusal says what is wrong and keeps the input, with no Reintentar', (
      tester,
    ) async {
      final env = await pump(tester);
      await openSheet(tester);
      await tapKeys(tester, '25000');
      env.add.failures['create'] = const HomeFailure(422, code: 'category_not_found');
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(find.text('Elige una de tus categorías activas.'), findsOneWidget);
      expect(find.byKey(const Key('add.retry')), findsNothing);
      expect(amountShown(tester), contains(r'$25.000'));
      // Guardar is there to try again.
      expect(tester.widget<FilledButton>(find.byKey(const Key('add.save'))).onPressed, isNotNull);
    });

    testWidgets('a second tap while saving sends nothing more', (tester) async {
      final env = await pump(tester);
      await openSheet(tester);
      await tapKeys(tester, '25000');
      env.add.hold = Completer<void>();
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add.save')), warnIfMissed: false);
      await tester.pump();
      expect(env.add.keys.length, 1);
      env.add.hold!.complete();
      await tester.pumpAndSettle();
      await letTimersEnd(tester);
    });
  });

  group('editing', () {
    testWidgets('a tap on a row opens it filled in; Guardar cambios sends only what changed', (
      tester,
    ) async {
      final env = await pump(
        tester,
        items: [tx('lunch', '2026-10-22', -2800000, name: 'Almuerzo', categoryId: 'cat-home')],
      );
      await tester.tap(find.text('Almuerzo'));
      await tester.pumpAndSettle();
      expect(find.text('Editar movimiento'), findsOneWidget);
      expect(amountShown(tester), contains(r'$28.000'));
      expect(
        tester.widget<TextField>(find.byKey(const Key('add.name'))).controller!.text,
        'Almuerzo',
      );

      await tapKeys(tester, '<5');
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(
        env.add.calls.singleWhere((c) => c.startsWith('update')),
        'update lunch {amount: -2800500}',
      );
      expect(find.text('Cambios guardados: Almuerzo'), findsOneWidget);
      expect(find.byKey(const Key('add.sheet')), findsNothing);
      // The row shows the new amount.
      expect(find.textContaining('28.005'), findsWidgets);
      await letTimersEnd(tester);
    });

    testWidgets('closing without changes saves nothing', (tester) async {
      final env = await pump(
        tester,
        items: [tx('lunch', '2026-10-22', -2800000, name: 'Almuerzo')],
      );
      await tester.tap(find.text('Almuerzo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(env.add.calls.where((c) => c.startsWith('update')), isEmpty);
      expect(find.byKey(const Key('add.sheet')), findsNothing);
    });
  });

  group('from home', () {
    testWidgets('a swipe right on a paid row opens it for editing', (tester) async {
      await pump(tester, items: [tx('lunch', '2026-10-22', -2800000, name: 'Almuerzo')]);
      await tester.timedDrag(
        find.text('Almuerzo'),
        const Offset(250, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();
      expect(find.text('Editar movimiento'), findsOneWidget);
    });

    testWidgets('there is no ＋ until home has loaded, and the sheet then says why', (tester) async {
      final server = FakeHomeRepository();
      server.failures['profile'] = const HomeFailure(0);
      final add = FakeAddRepository(server);
      await pumpHome(tester, server, addRepo: add);
      expect(find.byKey(const Key('home.add')), findsNothing);

      // Opened from elsewhere (the widget's link) before the figures are there.
      unawaited(openAddSheet(tester.element(find.byType(HomeScreen))));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo gasto'), findsOneWidget);
      expect(find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'), findsWidgets);
      expect(find.byKey(const Key('keypad.5')), findsNothing);

      // Reintentar loads home; the sheet then shows its form.
      await tester.tap(find.text('Reintentar').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('keypad.5')), findsOneWidget);
    });
  });

  group('the sheet', () {
    testWidgets('dragging down from the keypad area closes the sheet and enters no digit', (
      tester,
    ) async {
      final env = await pump(tester);
      await openSheet(tester);
      await tapKeys(tester, '4');
      // The finger goes down on the 5 and drags down: nothing is typed on the way, or at the end.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('keypad.5'))),
      );
      // Held past the press timeout, as a finger is: a key that typed on touch-down would have.
      await tester.pump(const Duration(milliseconds: 150));
      expect(amountShown(tester), contains(r'$4'));
      expect(amountShown(tester), isNot(contains('45')));
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      expect(amountShown(tester), isNot(contains('45')));
      await gesture.moveBy(const Offset(0, 450));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add.sheet')), findsNothing);
      expect(env.add.calls.where((c) => c.startsWith('create')), isEmpty);
    });

    testWidgets('a quick flick down from a key closes it too', (tester) async {
      await pump(tester);
      await openSheet(tester);
      await tester.fling(find.byKey(const Key('keypad.5')), const Offset(0, 500), 2000);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add.sheet')), findsNothing);
    });

    testWidgets('a slow drag that stops short springs back and still enters no digit', (
      tester,
    ) async {
      await pump(tester);
      await openSheet(tester);
      await tester.drag(find.byKey(const Key('keypad.7')), const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add.sheet')), findsOneWidget);
      expect(amountShown(tester), contains(r'$0'));
    });

    testWidgets('at 360x640 every key and Guardar are visible and reachable', (tester) async {
      final env = await pump(tester, size: const Size(360, 640));
      await openSheet(tester);
      final screen = const Offset(0, 0) & const Size(360, 640);
      for (final name in [
        for (var d = 0; d <= 9; d++) 'keypad.$d',
        'keypad.backspace',
        'add.save',
      ]) {
        final rect = tester.getRect(find.byKey(Key(name)));
        expect(
          screen.contains(rect.topLeft) && screen.contains(rect.bottomRight),
          isTrue,
          reason: name,
        );
        expect(rect.height, greaterThanOrEqualTo(40), reason: '$name is a touch target');
      }
      // Every key answers a tap, Guardar included.
      await tapKeys(tester, '1234567890');
      expect(amountShown(tester), contains(r'$123.456.789'));
      await tester.tap(find.byKey(const Key('add.save')));
      await tester.pumpAndSettle();
      expect(env.add.keys.length, 1);
      await letTimersEnd(tester);
    });

    testWidgets('the name field up, the keyboard replaces the keypad and Guardar stays', (
      tester,
    ) async {
      await pump(tester, size: const Size(360, 640));
      await openSheet(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('keypad.5')), findsNothing);
      final save = tester.getRect(find.byKey(const Key('add.save')));
      expect(save.bottom, lessThanOrEqualTo(640 - 280));
    });

    testWidgets('the close button closes without saving', (tester) async {
      final env = await pump(tester);
      await openSheet(tester);
      await tapKeys(tester, '5');
      await tester.tap(find.byKey(const Key('add.close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add.sheet')), findsNothing);
      expect(env.add.calls.where((c) => c.startsWith('create')), isEmpty);
    });

    testWidgets('openAddSheet opens on the kind asked for, from anywhere', (tester) async {
      await pump(tester);
      final context = tester.element(find.byType(HomeScreen));
      unawaited(openAddSheet(context, kind: Kind.income));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo ingreso'), findsOneWidget);
      expect(find.byKey(const Key('category.cat-salary')), findsOneWidget);
      expect(find.byKey(const Key('category.cat-home')), findsNothing);
    });

    testWidgets('in English: the words and the decimal point', (tester) async {
      await pump(tester, currency: 'EUR', locale: const Locale('en'));
      await openSheet(tester);
      expect(find.text('New expense'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      await tapKeys(tester, '6.5');
      expect(amountShown(tester), contains('€6.5'));
    });

    testWidgets('no categories of the kind says so', (tester) async {
      await pump(tester, categories: [category('cat-salary', 'Nómina', kind: 'income')]);
      await openSheet(tester);
      expect(find.text('Aún no tienes categorías de gasto.'), findsOneWidget);
      await tapKeys(tester, '5');
      expect(tester.widget<FilledButton>(find.byKey(const Key('add.save'))).onPressed, isNull);
    });

    testWidgets('categories fold behind Más, and the chosen one stays in view', (tester) async {
      await pump(
        tester,
        categories: [for (var i = 0; i < 12; i++) category('c$i', 'Cat $i')],
        size: const Size(360, 800),
      );
      await openSheet(tester);
      expect(find.byKey(const Key('category.c0')), findsOneWidget);
      expect(find.byKey(const Key('category.c11')), findsNothing);
      await tester.tap(find.byKey(const Key('add.moreCategories')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category.c11')), findsOneWidget);
      await tester.tap(find.byKey(const Key('category.c11')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('add.moreCategories')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category.c11')), findsOneWidget);
    });
  });
}
