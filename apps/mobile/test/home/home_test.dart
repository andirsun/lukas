import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/home/home_repository.dart';

import 'fakes.dart';
import 'fixtures.dart';
import 'home_harness.dart';

/// A swipe: the finger down on [row], moved by [dx] over [ms] (a flick is fast).
Future<void> swipe(WidgetTester tester, Finder row, double dx, {int ms = 300}) async {
  await tester.timedDrag(row, Offset(dx, 0), Duration(milliseconds: ms));
  await tester.pumpAndSettle();
}

/// Lets the 10 s of an event line pass, so no timer outlives the test.
Future<void> endEvent(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 11));
  await tester.pumpAndSettle();
}

void main() {
  group('the month', () {
    testWidgets('home shows Te quedan with budgets and Gastado este mes without', (tester) async {
      await pumpHome(tester, monthWithBudgets());
      expect(find.text('Te quedan este mes'), findsOneWidget);
      expect(find.text('Gastado este mes'), findsNothing);
      // 2.000.000 of budget, 212.500 spent (the pending rent and the income do not count).
      expect(find.text(r'$1.787.500'), findsOneWidget);
      expect(find.text(r'Gastado $212.500'), findsOneWidget);
      expect(find.text(r'de $2.000.000'), findsOneWidget);
      expect(find.text('Octubre'), findsOneWidget);
    });

    testWidgets('without budgets it says what was spent, and that there are none', (tester) async {
      final repo = monthWithBudgets()..budgetTotal = 0;
      await pumpHome(tester, repo);
      expect(find.text('Gastado este mes'), findsOneWidget);
      expect(find.text('Te quedan este mes'), findsNothing);
      expect(find.text('Sin presupuestos todavía'), findsOneWidget);
      expect(find.text(r'$212.500'), findsOneWidget);
    });

    testWidgets('over the budgets it says Te pasaste', (tester) async {
      final repo = monthWithBudgets()..budgetTotal = 10000000;
      await pumpHome(tester, repo);
      expect(find.text('Te pasaste este mes'), findsOneWidget);
    });

    testWidgets('in English: the same figures with the code and the English copy', (tester) async {
      await pumpHome(tester, monthWithBudgets(), locale: const Locale('en'));
      expect(find.text('Left this month'), findsOneWidget);
      expect(find.text('October'), findsOneWidget);
      expect(find.text('TODAY · THU 22'), findsOneWidget);
      expect(find.text('Show more'), findsNothing);
    });

    testWidgets('writes the widget snapshot with the loaded summary', (tester) async {
      final harness = await pumpHome(tester, monthWithBudgets());
      expect(harness.snapshots, hasLength(1));
      expect(harness.snapshots.single.summary.month, '2026-10');
      expect(harness.snapshots.single.currency, 'COP');
    });
  });

  group('the movements', () {
    testWidgets('are listed by day: today first, the pending ones due next, then the past', (
      tester,
    ) async {
      await pumpHome(tester, monthWithBudgets());
      expect(find.text('HOY · JUE 22'), findsOneWidget);
      expect(find.text('AYER · MIÉ 21'), findsOneWidget);
      expect(find.text('DOM 25 · PRÓXIMO'), findsOneWidget);
      double y(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(y('Café'), lessThan(y('Arriendo')));
      expect(y('Arriendo'), lessThan(y('Mercado')));
      expect(y('Mercado'), lessThan(y('Nómina')));
      // Money: expenses with the real minus, income with a plus.
      expect(find.text('−\$4.500'), findsOneWidget);
      // The income, and the day's total (income only).
      expect(find.text(r'+$3.000.000'), findsNWidgets(2));
      expect(find.text('PENDIENTE'), findsOneWidget);
    });

    testWidgets('an empty month invites the first entry', (tester) async {
      await pumpHome(tester, FakeHomeRepository());
      expect(
        find.text('Aún no hay movimientos en Octubre. Toca ＋ y anota el primero.'),
        findsOneWidget,
      );
    });

    testWidgets('a list longer than one page shows Ver más movimientos and loads the rest', (
      tester,
    ) async {
      final repo = FakeHomeRepository(
        pageSize: 3,
        items: [
          for (var i = 9; i >= 1; i--) tx('t$i', '2026-10-0$i', -100000 * i, name: 'Gasto $i'),
        ],
      );
      await pumpHome(tester, repo, size: const Size(390, 1800));
      expect(find.text('Gasto 9'), findsOneWidget);
      expect(find.text('Gasto 7'), findsOneWidget);
      expect(find.text('Gasto 6'), findsNothing);
      expect(find.text('Ver más movimientos'), findsOneWidget);

      await tester.tap(find.text('Ver más movimientos'));
      await tester.pumpAndSettle();
      expect(find.text('Gasto 6'), findsOneWidget);
      expect(find.text('Gasto 4'), findsOneWidget);
      expect(find.text('Gasto 3'), findsNothing);
      expect(find.text('Ver más movimientos'), findsOneWidget);

      await tester.tap(find.text('Ver más movimientos'));
      await tester.pumpAndSettle();
      expect(find.text('Gasto 1'), findsOneWidget);
      expect(find.text('Ver más movimientos'), findsNothing);
      expect(repo.calls.where((c) => c.startsWith('transactions')), [
        'transactions 2026-10',
        'transactions 2026-10 3',
        'transactions 2026-10 6',
      ]);
    });

    testWidgets('a page that fails keeps the list and says so', (tester) async {
      final repo = FakeHomeRepository(
        pageSize: 1,
        items: [
          tx('a', '2026-10-02', -100, name: 'Uno'),
          tx('b', '2026-10-01', -100, name: 'Dos'),
        ],
      );
      await pumpHome(tester, repo);
      repo.failures['transactions'] = const HomeFailure(0);
      await tester.tap(find.text('Ver más movimientos'));
      await tester.pumpAndSettle();
      expect(find.text('Uno'), findsOneWidget);
      expect(find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'), findsOneWidget);
      expect(find.text('Ver más movimientos'), findsOneWidget);
    });

    testWidgets('the Movimientos tab sticks under the top while the list scrolls', (tester) async {
      final repo = FakeHomeRepository(
        items: [
          for (var i = 20; i >= 1; i--) tx('t$i', '2026-10-${i.toString().padLeft(2, '0')}', -100),
        ],
      );
      await pumpHome(tester, repo);
      final tab = find.text('Movimientos');
      expect(tab, findsOneWidget);
      final before = tester.getTopLeft(tab).dy;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tab, findsOneWidget);
      final after = tester.getTopLeft(tab).dy;
      expect(after, lessThan(before), reason: 'it moved up under the top…');
      expect(after, lessThan(60), reason: '…and stayed there');
    });
  });

  group('swipes', () {
    testWidgets('swipe left deletes and Deshacer within 8 s restores the same row', (tester) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      final top = tester.getTopLeft(find.text('Café')).dy;

      await swipe(tester, find.text('Café'), -250);
      expect(find.text('Café'), findsNothing);
      expect(repo.deleted.map((t) => t.id), ['coffee']);
      expect(find.text('Eliminado: Café'), findsOneWidget);
      // The summary follows: 4.500 less spent.
      expect(find.text(r'Gastado $208.000'), findsOneWidget);

      // Seven seconds in, Deshacer is still there.
      await tester.pump(const Duration(seconds: 7));
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('restore coffee'));
      expect(find.text('Café'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Café')).dy, top, reason: 'the same row, in its place');
      expect(find.text('De vuelta: Café'), findsOneWidget);
      expect(find.text(r'Gastado $212.500'), findsOneWidget);
      expect(repo.deleted, isEmpty);
    });

    testWidgets('after 8 s Deshacer is gone', (tester) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      await swipe(tester, find.text('Café'), -250);
      expect(find.text('Deshacer'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      expect(find.text('Deshacer'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Deshacer'), findsNothing);
      expect(find.text('Café'), findsNothing);
    });

    testWidgets('a delete the server refuses brings the row back and says why', (tester) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      repo.failures['delete'] = const HomeFailure(500);
      await swipe(tester, find.text('Café'), -250);
      expect(find.text('Café'), findsOneWidget);
      expect(find.text('Algo salió mal. Inténtalo de nuevo en un momento.'), findsOneWidget);
      expect(find.text('Deshacer'), findsNothing);
    });

    testWidgets('swipe right on a pending row marks it paid', (tester) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      expect(find.text('PENDIENTE'), findsOneWidget);

      await swipe(tester, find.text('Arriendo'), 250);
      expect(repo.calls, contains('markPaid rent'));
      expect(repo.items.firstWhere((t) => t.id == 'rent').status, TransactionStatusEnum.paid);
      expect(find.text('PENDIENTE'), findsNothing);
      expect(find.text('✓ PAGADO'), findsOneWidget);
      expect(find.textContaining('Pagado: Arriendo'), findsOneWidget);
      // The row is where it was: a swipe is not a move.
      expect(find.text('Arriendo'), findsWidgets);
      await endEvent(tester);
    });

    testWidgets('tapping the Pendiente badge pays it too', (tester) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      await tester.tap(find.text('PENDIENTE'));
      await tester.pumpAndSettle();
      expect(repo.calls.where((c) => c.startsWith('markPaid')), ['markPaid rent']);
      expect(find.text('✓ PAGADO'), findsOneWidget);
      await endEvent(tester);
    });

    testWidgets('a payment the server refuses puts the badge back to Pendiente', (tester) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      repo.failures['markPaid'] = const HomeFailure(0);
      await tester.tap(find.text('PENDIENTE'));
      await tester.pumpAndSettle();
      expect(find.text('PENDIENTE'), findsOneWidget);
      expect(find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'), findsOneWidget);
    });

    testWidgets('swipe right on a paid row edits it, when there is an editor', (tester) async {
      final harness = await pumpHome(tester, monthWithBudgets(), withEdit: true);
      await swipe(tester, find.text('Café'), 250);
      expect(harness.edited.map((t) => t.id), ['coffee']);
      expect(find.text('Café'), findsOneWidget);
    });

    testWidgets('a tap on a row opens it for editing', (tester) async {
      final harness = await pumpHome(tester, monthWithBudgets(), withEdit: true);
      await tester.tap(find.text('Almuerzo'));
      await tester.pumpAndSettle();
      expect(harness.edited.map((t) => t.id), ['lunch']);
    });

    testWidgets('a vertical drag scrolls and never swipes a row (axis lock)', (tester) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      // Far enough left to delete a row, but more up than left: the list's.
      await tester.drag(find.text('Café'), const Offset(-150, -160));
      await tester.pumpAndSettle();
      // A perfect diagonal also scrolls.
      await tester.drag(find.text('Almuerzo'), const Offset(-150, -150));
      await tester.pumpAndSettle();
      expect(repo.calls.where((c) => c.startsWith('delete')), isEmpty);
      expect(find.text('BORRAR'), findsNothing);
    });

    testWidgets('a short swipe leaves the action open; only one row is open at a time', (
      tester,
    ) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);

      await swipe(tester, find.text('Café'), -100);
      expect(find.text('BORRAR'), findsOneWidget);
      expect(repo.calls.where((c) => c.startsWith('delete')), isEmpty);
      final open = tester.getTopLeft(find.text('Café')).dx;

      // Another row opens: the first closes.
      await swipe(tester, find.text('Almuerzo'), -100);
      expect(find.text('BORRAR'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Café')).dx, greaterThan(open));

      // A tap anywhere else closes it.
      await tester.tap(find.text('Octubre'));
      await tester.pumpAndSettle();
      expect(find.text('BORRAR'), findsNothing);
    });

    testWidgets('a tap on an open row closes it instead of opening it', (tester) async {
      final harness = await pumpHome(tester, monthWithBudgets(), withEdit: true);
      await swipe(tester, find.text('Café'), -100);
      expect(find.text('BORRAR'), findsOneWidget);
      await tester.tap(find.text('Café'));
      await tester.pumpAndSettle();
      expect(find.text('BORRAR'), findsNothing);
      expect(harness.edited, isEmpty);
    });

    testWidgets('tapping the opened action runs it', (tester) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      await swipe(tester, find.text('Café'), -100);
      await tester.tap(find.text('BORRAR'));
      await tester.pumpAndSettle();
      expect(repo.deleted.map((t) => t.id), ['coffee']);
      expect(find.text('Café'), findsNothing);
    });

    testWidgets('a flick deletes even after a short distance', (tester) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      await swipe(tester, find.text('Café'), -60, ms: 40);
      expect(repo.deleted.map((t) => t.id), ['coffee']);
    });

    testWidgets('a swipe that is too small closes again', (tester) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      final at = tester.getTopLeft(find.text('Café')).dx;
      await swipe(tester, find.text('Café'), -20);
      expect(tester.getTopLeft(find.text('Café')).dx, at);
      expect(find.text('BORRAR'), findsNothing);
    });

    testWidgets('with "remove animations" a deleted row just fades away', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      await swipe(tester, find.text('Café'), -250);
      expect(find.text('Café'), findsNothing);
      expect(repo.deleted.map((t) => t.id), ['coffee']);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(find.text('Café'), findsOneWidget);
    });
  });

  group('Lukitas', () {
    testWidgets('says the month\'s line: what is left and the days to go', (tester) async {
      await pumpHome(tester, monthWithBudgets());
      expect(find.textContaining('Vas muy bien: te quedan'), findsOneWidget);
      expect(find.textContaining('10 días'), findsOneWidget);
    });

    testWidgets('without budgets he talks about what was spent', (tester) async {
      await pumpHome(tester, monthWithBudgets()..budgetTotal = 0);
      expect(find.textContaining('Este mes llevas'), findsOneWidget);
    });

    testWidgets('the event line names the movement and returns to the month\'s line after 10 s', (
      tester,
    ) async {
      await pumpHome(tester, monthWithBudgets());
      expect(find.textContaining('Vas muy bien'), findsOneWidget);

      await swipe(tester, find.text('Arriendo'), 250);
      expect(find.textContaining('«Arriendo»'), findsOneWidget);
      expect(find.textContaining('Pagaste «Arriendo»: \$500.000'), findsOneWidget);
      expect(find.textContaining('Vas muy bien'), findsNothing);

      await tester.pump(const Duration(seconds: 9));
      expect(find.textContaining('Pagaste «Arriendo»'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pagaste «Arriendo»'), findsNothing);
      expect(find.textContaining('Vas muy bien'), findsOneWidget);
    });

    testWidgets('in English the event line is English too', (tester) async {
      await pumpHome(tester, monthWithBudgets(), locale: const Locale('en'));
      await swipe(tester, find.text('Arriendo'), 250);
      expect(find.textContaining('You paid “Arriendo”: COP\u00a0500,000'), findsOneWidget);
      await endEvent(tester);
    });
  });

  group('offline and errors', () {
    testWidgets('a first load that fails offers Reintentar, and works once back online', (
      tester,
    ) async {
      final repo = monthWithBudgets()..failures['profile'] = const HomeFailure(0);
      await pumpHome(tester, repo);
      expect(find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Te quedan este mes'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('pulling down refreshes; offline, the last figures stay with a note', (
      tester,
    ) async {
      final repo = monthWithBudgets();
      await pumpHome(tester, repo);
      repo.failures['summary'] = const HomeFailure(0);
      await tester.fling(find.byType(CustomScrollView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Te quedan este mes'), findsOneWidget);
      expect(find.text('Café'), findsOneWidget);
      expect(find.text('Sin conexión. Te mostramos lo último que cargó.'), findsOneWidget);

      await tester.fling(find.byType(CustomScrollView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión. Te mostramos lo último que cargó.'), findsNothing);
    });
  });
}
