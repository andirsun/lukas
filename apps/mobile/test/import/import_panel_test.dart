import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/import/import_panel.dart';
import 'package:lukitas/import/import_state.dart';

import '../support/ui_app.dart';
import 'fakes.dart';

/// The import panel, one story at a time: the web's `ImportSources`, `ImportPreview`,
/// `ImportManyRejected`, `ImportSwitchedCurrency` and `Imported` (Onboarding.stories.tsx), minus
/// the welcome's frame (its steps and buttons are the welcome's own tests). How the panel looks is
/// the parity pairs' business (test/parity/import_parity_test.dart).

Future<List<String>> pumpPanel(
  WidgetTester tester,
  ImportState state, {
  VoidCallback? onFresh,
  VoidCallback? onConfirm,
  bool showPrefill = true,
  String? prefillBasis,
  Locale locale = const Locale('es'),
  void Function({required bool budge})? onSource,
}) async {
  final events = <String>[];
  var current = state;
  await tester.pumpWidget(
    uiApp(
      StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: ImportPanel(
            state: current,
            onChoose: () => events.add('choose'),
            onDiscard: () => events.add('discard'),
            onSource: ({required budge}) {
              events.add(budge ? 'budge' : 'sources');
              onSource?.call(budge: budge);
              setState(() => current = budge ? const ImportIdle() : const ImportSources());
            },
            onRetry: () => events.add('retry'),
            onFresh: onFresh,
            onConfirm: onConfirm,
            prefillBasis: prefillBasis,
            showPrefill: showPrefill,
          ),
        ),
      ),
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

ImportPreview previewOf(
  Map<String, Object?> stats, {
  CurrencyNote? note,
  bool confirming = false,
  String fileName = 'budge.csv',
}) => ImportPreview(
  fileName: fileName,
  preview: importOf(stats),
  currencyNote: note,
  confirming: confirming,
);

void main() {
  group('the sources', () {
    testWidgets(
      'Budge opens; Excel/CSV, Buddy and other apps are "Pronto"; no empiezo de cero here',
      (tester) async {
        final events = await pumpPanel(tester, const ImportSources());
        expect(find.text('Desde dónde'), findsOneWidget);
        for (final name in ['Excel, Google Sheets o CSV', 'Buddy', 'Otras apps']) {
          final row = find.ancestor(of: find.text(name), matching: find.byType(DecoratedBox)).first;
          expect(
            find.descendant(of: row, matching: find.text('Pronto')),
            findsOneWidget,
            reason: name,
          );
          // A source that is not there yet is no button.
          expect(
            find.ancestor(of: find.text(name), matching: find.byType(GestureDetector)),
            findsNothing,
          );
        }
        expect(find.byKey(const Key('import.fresh')), findsNothing);

        await tester.tap(find.byKey(const Key('import.source.budge')));
        await tester.pumpAndSettle();
        expect(events, ['budge']);
      },
    );

    testWidgets('"No, empiezo de cero" is there when the welcome asks for it', (tester) async {
      var fresh = 0;
      await pumpPanel(tester, const ImportSources(), onFresh: () => fresh++);
      await tester.tap(find.byKey(const Key('import.fresh')));
      expect(fresh, 1);
      expect(find.text('NO, EMPIEZO DE CERO'), findsOneWidget);
    });

    testWidgets("Budge's how-to has three steps, the picker, and a way back; no menu is named", (
      tester,
    ) async {
      final events = await pumpPanel(tester, const ImportIdle());
      expect(find.text('Exporta tus movimientos de Budge'), findsOneWidget);
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('3.'), findsOneWidget);
      // Neutral until the founder confirms Budge's menu path: no menu is named.
      expect(
        find.text('En Budge, busca la opción para exportar tus movimientos en CSV.'),
        findsOneWidget,
      );
      expect(find.textContaining('Ajustes'), findsNothing);
      expect(find.text('SUBIR ARCHIVO DE BUDGE'), findsOneWidget);

      await tester.tap(find.byKey(const Key('import.choose')));
      await tester.tap(find.byKey(const Key('import.otherSource')));
      await tester.pumpAndSettle();
      expect(events, ['choose', 'sources']);
      expect(find.text('Desde dónde'), findsOneWidget);
    });

    testWidgets('a problem with the file shows under the picker', (tester) async {
      await pumpPanel(
        tester,
        const ImportIdle(error: HomeFailure(422, code: 'import_unrecognized_format')),
      );
      expect(
        find.text('No reconocemos este archivo. Usa una exportación de Budge.'),
        findsOneWidget,
      );
    });

    testWidgets('while it reads, it says so', (tester) async {
      await pumpPanel(tester, const ImportReading('budge.csv'));
      expect(find.text('Leyendo tu archivo…'), findsOneWidget);
    });
  });

  group('the preview', () {
    testWidgets('transactions, duplicates, rejected rows (with their lines), new categories', (
      tester,
    ) async {
      await pumpPanel(tester, previewOf(sampleStats()), onConfirm: () {});
      expect(find.text('Esto es lo que vamos a importar'), findsOneWidget);
      Finder value(String term) => find.descendant(
        of: find.ancestor(of: find.text(term), matching: find.byType(DecoratedBox)).first,
        matching: find.byWidgetPredicate(
          (w) => w is Text && RegExp(r'^\d+$').hasMatch(w.data ?? ''),
        ),
      );
      expect((tester.widget(value('Movimientos')) as Text).data, '22');
      expect((tester.widget(value('Repetidos (ya los tienes)')) as Text).data, '3');
      expect((tester.widget(value('Filas con problemas')) as Text).data, '1');
      expect(find.text('Archivo: budge.csv'), findsOneWidget);
      expect(find.text('Del 1 sept 2026 al 30 oct 2026'), findsOneWidget);
      expect(find.textContaining('Investimento'), findsOneWidget);
      expect(find.text('Línea 19: fecha no válida'), findsNothing);
      await tester.tap(find.byKey(const Key('import.rejected.toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Línea 19: fecha no válida'), findsOneWidget);
      // 22 rows, 3 of them already there: 19 to import.
      expect(find.text('IMPORTAR 19 MOVIMIENTOS'), findsOneWidget);
      expect(find.text('USAR OTRO ARCHIVO'), findsOneWidget);
    });

    testWidgets('a file with many bad rows lists 20 and says how many more', (tester) async {
      await pumpPanel(
        tester,
        previewOf({
          ...sampleStats(),
          'rejected': [
            for (var i = 0; i < 45; i++) {'line': 7 + i, 'reason': 'currency_mismatch'},
          ],
        }),
      );
      await tester.tap(find.byKey(const Key('import.rejected.toggle')));
      await tester.pumpAndSettle();
      final list = find.byKey(const Key('import.rejected.list'));
      expect(find.descendant(of: list, matching: find.textContaining('Línea')), findsNWidgets(20));
      expect(
        find.descendant(of: list, matching: find.text('Línea 7: otra moneda')),
        findsOneWidget,
      );
      expect(find.text('y 25 más'), findsOneWidget);
    });

    testWidgets('a reason the app does not know reads "no se pudo leer"', (tester) async {
      await pumpPanel(
        tester,
        previewOf({
          ...sampleStats(),
          'rejected': [
            {'line': 4, 'reason': 'something_new'},
          ],
        }),
      );
      await tester.tap(find.byKey(const Key('import.rejected.toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Línea 4: no se pudo leer'), findsOneWidget);
    });

    testWidgets('the file\'s currency won: one line says the account switched to it', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        previewOf(
          sampleStats(),
          note: const CurrencyNote(kind: CurrencyNoteKind.switched, file: 'EUR', account: 'COP'),
        ),
      );
      expect(find.text('Tu archivo está en EUR, así que tu cuenta ahora usa EUR.'), findsOneWidget);
    });

    testWidgets('a switch to come says so, and warns about the budgets that go', (tester) async {
      await pumpPanel(
        tester,
        previewOf(
          sampleStats(),
          note: const CurrencyNote(
            kind: CurrencyNoteKind.switching,
            file: 'EUR',
            account: 'COP',
            dropsBudgets: true,
          ),
        ),
      );
      expect(
        find.text('Tu archivo está en EUR: al importarlo, tu cuenta pasará a usar EUR.'),
        findsOneWidget,
      );
      expect(find.text('Tus presupuestos en COP se borrarán al cambiar a EUR.'), findsOneWidget);
    });

    testWidgets('a locked account keeps its currency and says the rows are not imported', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        previewOf(
          sampleStats(),
          note: const CurrencyNote(kind: CurrencyNoteKind.locked, file: 'EUR', account: 'COP'),
        ),
      );
      expect(
        find.text('Tu archivo está en EUR, pero tu cuenta ya usa COP: esas filas no se importan.'),
        findsOneWidget,
      );
    });

    testWidgets('nothing to import: no confirm, only another file', (tester) async {
      await pumpPanel(
        tester,
        previewOf({...sampleStats(), 'transactions': 3, 'duplicates': 3}),
        onConfirm: () {},
      );
      expect(find.byKey(const Key('import.confirm')), findsNothing);
      expect(find.byKey(const Key('import.otherFile')), findsOneWidget);
    });

    testWidgets('while it confirms, the button says so and nothing else can be pressed', (
      tester,
    ) async {
      final pressed = <String>[];
      final events = await pumpPanel(
        tester,
        previewOf(sampleStats(), confirming: true),
        onConfirm: () => pressed.add('confirm'),
      );
      expect(find.text('IMPORTANDO…'), findsOneWidget);
      await tester.tap(find.byKey(const Key('import.confirm')), warnIfMissed: false);
      await tester.tap(find.byKey(const Key('import.otherFile')), warnIfMissed: false);
      expect(pressed, isEmpty);
      expect(events, isEmpty);
    });
  });

  group('imported', () {
    ImportImported done({bool prefilled = true, Object? error}) => ImportImported(
      result: importOf({...sampleStats(), 'duplicates': 0, 'inserted': 19}, status: 'confirmed'),
      prefilled: prefilled,
      currencyNote: null,
    );

    testWidgets('says how many came in, and where the prefilled budgets come from', (tester) async {
      await pumpPanel(
        tester,
        done(),
        prefillBasis: 'Basado en lo que gastaste en tus últimos 3 meses',
      );
      expect(find.text('Importamos 19 movimientos.'), findsOneWidget);
      expect(
        find.text('Llenamos tus presupuestos con lo que gastas en promedio cada mes.'),
        findsOneWidget,
      );
      expect(find.text('Basado en lo que gastaste en tus últimos 3 meses'), findsOneWidget);
    });

    testWidgets('the app\'s page shows the budgets itself, so it says nothing of the prefill', (
      tester,
    ) async {
      await pumpPanel(tester, done(), showPrefill: false, prefillBasis: 'Basado en…');
      expect(find.text('Importamos 19 movimientos.'), findsOneWidget);
      expect(find.textContaining('Llenamos'), findsNothing);
      expect(find.text('Basado en…'), findsNothing);
    });

    testWidgets('one transaction is singular', (tester) async {
      await pumpPanel(
        tester,
        ImportImported(
          result: importOf({...sampleStats(), 'inserted': 1}, status: 'confirmed'),
          prefilled: false,
          currencyNote: null,
        ),
      );
      expect(find.text('Importamos 1 movimiento.'), findsOneWidget);
    });

    testWidgets('in English', (tester) async {
      await pumpPanel(tester, done(), locale: const Locale('en'));
      expect(find.text('We imported 19 transactions.'), findsOneWidget);
    });
  });
}
