import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/files/files_channel.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/import/import_flow.dart';
import 'package:lukitas/import/import_repository.dart';
import 'package:lukitas/import/import_state.dart';

import '../budgets/budgets_test.dart' show Env, pumpBudgets;
import '../budgets/fakes.dart';
import 'fakes.dart';

/// The import page, in the whole app (the real router) against fakes of the server and of the
/// phone's document picker: the web's `ImportPage*` and `Flow*Import*` stories
/// (Onboarding.stories.tsx), and Review Focus 3. How it looks is the parity pairs' business
/// (test/parity/import_parity_test.dart); here is what it does. "Today" is 22 October 2026, in
/// Bogota.

class ImportEnv {
  ImportEnv(this.app, this.home, this.budgets, this.server, this.files);

  final Env app;
  final ImportHome home;
  final FakeBudgetsRepository budgets;
  final FakeImportServer server;
  final FakeFilesChannel files;

  ProviderContainer get container => app.settings.container;
}

Future<ImportEnv> pumpImport(
  WidgetTester tester, {
  String currency = 'EUR',
  bool budgeted = false,
  bool hasTransactions = false,
  bool oldExport = false,
  Locale locale = const Locale('es'),
  Map<String, Object?>? fileStats,
  PickedFile? file,
  List<Override> overrides = const [],
}) async {
  final world = importWorld(
    currency: currency,
    budgeted: budgeted,
    hasTransactions: hasTransactions,
    oldExport: oldExport,
    fileStats: fileStats,
  );
  final files = FakeFilesChannel()..next = file ?? PickedFile('budge.csv', budgeCsv());
  final app = await pumpBudgets(
    tester,
    home: world.home,
    budgets: world.budgets,
    locale: locale,
    location: '/import',
    overrides: [
      importRepositoryProvider.overrideWithValue(world.server),
      filesChannelProvider.overrideWithValue(files),
      ...overrides,
    ],
  );
  return ImportEnv(app, world.home, world.budgets, world.server, files);
}

Future<void> reveal(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await reveal(tester, key);
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// Budge, then the picker, which gives the file the test chose.
Future<void> pickFile(WidgetTester tester) async {
  await tapKey(tester, 'import.source.budge');
  await tapKey(tester, 'import.choose');
}

String shown(WidgetTester tester, String key) {
  final field = tester.widget<EditableText>(find.byKey(Key(key)));
  return field.controller.text;
}

void main() {
  group('the page', () {
    testWidgets('opens on the sources, with its title and lead, and no back link', (tester) async {
      await pumpImport(tester);
      expect(find.text('Trae tu historial'), findsOneWidget);
      expect(find.text('Trae tus movimientos de otra app.'), findsOneWidget);
      expect(find.text('Desde dónde'), findsOneWidget);
      // The web's page has no back link: nothing says INICIO but the bottom bar.
      expect(find.text('‹'), findsNothing);
      // Nothing to skip to here: it is the page on its own, not the welcome's step.
      expect(find.byKey(const Key('import.fresh')), findsNothing);
    });

    testWidgets('the lead is only over the sources', (tester) async {
      await pumpImport(tester);
      await tapKey(tester, 'import.source.budge');
      expect(find.text('Trae tus movimientos de otra app.'), findsNothing);
      expect(find.text('Exporta tus movimientos de Budge'), findsOneWidget);
    });

    testWidgets('asks the picker for a CSV, within the API\'s 5 MB', (tester) async {
      final env = await pumpImport(tester);
      await pickFile(tester);
      final asked = env.files.asked.single;
      expect(asked.mimeTypes, contains('text/csv'));
      expect(asked.maxBytes, 5 * 1024 * 1024);
    });
  });

  group('/app/import ends with the budgets, as onboarding does', () {
    testWidgets('prefilled from the recent months, shown as a form, written only by Guardar', (
      tester,
    ) async {
      final env = await pumpImport(tester);
      await pickFile(tester);
      expect(env.server.calls, ['POST /v1/imports']);
      expect(find.text('IMPORTAR 22 MOVIMIENTOS'), findsOneWidget);

      await tapKey(tester, 'import.confirm');
      expect(find.text('Tus presupuestos'), findsOneWidget);
      expect(find.textContaining('Llenamos tus presupuestos'), findsNothing);
      expect(find.text('Basado en lo que gastaste en tus últimos 3 meses'), findsOneWidget);
      expect(shown(tester, 'budget.field.cat-groceries'), '35,89');
      // Nothing is written until the person says so.
      expect(env.budgets.calls.where((c) => c.startsWith('setBudget')), isEmpty);

      await tapKey(tester, 'import.budgets.save');
      expect(find.text('Guardamos tus presupuestos.'), findsOneWidget);
      expect(env.budgets.calls, contains('setBudget cat-groceries 3589 2026-10'));
      // Ocio is made by the import and prefilled with its average.
      expect(
        env.budgets.calls.any((c) => c.startsWith('setBudget') && c.endsWith(' 6225 2026-10')),
        isTrue,
      );

      await tapKey(tester, 'import.home');
      expect(find.byKey(const Key('import.page')), findsNothing);
    });

    testWidgets('the total follows what is typed', (tester) async {
      await pumpImport(tester);
      await pickFile(tester);
      await tapKey(tester, 'import.confirm');
      // 35,89 + 62,25
      expect(find.text('98,14\u00A0€', findRichText: true), findsOneWidget);
      await tester.enterText(find.byKey(const Key('budget.field.cat-groceries')), '100');
      await tester.pumpAndSettle();
      expect(find.text('162,25\u00A0€', findRichText: true), findsOneWidget);
      expect(shown(tester, 'budget.field.cat-groceries'), '100');
    });

    testWidgets('a field takes only an amount, grouped as it is typed', (tester) async {
      await pumpImport(tester);
      await pickFile(tester);
      await tapKey(tester, 'import.confirm');
      await tester.enterText(find.byKey(const Key('budget.field.cat-groceries')), '12500,5x');
      await tester.pumpAndSettle();
      expect(shown(tester, 'budget.field.cat-groceries'), '12.500,5');
    });

    testWidgets('a COP account with budgets, a EUR file: the preview warns before the switch', (
      tester,
    ) async {
      final env = await pumpImport(tester, currency: 'COP', budgeted: true);
      await pickFile(tester);
      expect(find.text('Tus presupuestos en COP se borrarán al cambiar a EUR.'), findsOneWidget);
      // Dropping the preview (or leaving) changes nothing: only the DELETE of the preview.
      await tapKey(tester, 'import.otherFile');
      expect(env.server.calls, ['POST /v1/imports', 'DELETE /v1/imports/preview-1']);
      expect(env.home.live, 'COP');
      expect(env.budgets.budgets, {'cat-groceries': 30000000});
    });

    testWidgets('the confirm fails: the preview stays with the reason, and importing again works', (
      tester,
    ) async {
      final env = await pumpImport(tester);
      env.server.failures['confirm'] = const HomeFailure(503, code: 'internal_error');
      await pickFile(tester);
      await tapKey(tester, 'import.confirm');
      expect(
        find.text('Tuvimos un problema de nuestro lado. Inténtalo de nuevo en un momento.'),
        findsOneWidget,
      );
      expect(find.text('Tus presupuestos'), findsNothing);
      expect(find.byKey(const Key('import.confirm')), findsOneWidget);
      await tapKey(tester, 'import.confirm');
      expect(find.text('Tus presupuestos'), findsOneWidget);
      expect(find.byKey(const Key('import.error')), findsNothing);
    });

    testWidgets('saving the budgets fails: nothing claims they were saved, and trying again does', (
      tester,
    ) async {
      final env = await pumpImport(tester);
      await pickFile(tester);
      await tapKey(tester, 'import.confirm');
      env.budgets.saveFailure = const HomeFailure(503, code: 'internal_error');
      await tapKey(tester, 'import.budgets.save');
      expect(
        find.text('Tuvimos un problema de nuestro lado. Inténtalo de nuevo en un momento.'),
        findsOneWidget,
      );
      expect(find.text('Guardamos tus presupuestos.'), findsNothing);
      await tapKey(tester, 'import.budgets.save');
      expect(find.text('Guardamos tus presupuestos.'), findsOneWidget);
    });

    testWidgets(
      'a re-import keeps the saved budget, prefills the rest, and saving writes only those',
      (tester) async {
        final env = await pumpImport(tester, budgeted: true);
        await pickFile(tester);
        await tapKey(tester, 'import.confirm');
        // Saved 300.000 € stays; the file's 35,89 doesn't replace it.
        expect(shown(tester, 'budget.field.cat-groceries'), '300.000');
        // Ocio (made by the import) had none: prefilled with its average.
        final ocio = env.home.categoryList.firstWhere((c) => c.name == 'Ocio');
        expect(shown(tester, 'budget.field.${ocio.id}'), '62,25');
        await tapKey(tester, 'import.budgets.save');
        expect(find.text('Guardamos tus presupuestos.'), findsOneWidget);
        final puts = env.budgets.calls.where((c) => c.startsWith('setBudget')).toList();
        expect(puts.any((c) => c.contains('cat-groceries')), isFalse);
        expect(puts, hasLength(1));
        expect(puts.single, contains(' 6225 '));
      },
    );

    testWidgets('in English the amounts and the copy follow the language', (tester) async {
      await pumpImport(tester, locale: const Locale('en'));
      await pickFile(tester);
      expect(find.text('IMPORT 22 TRANSACTIONS'), findsOneWidget);
      await tapKey(tester, 'import.confirm');
      expect(find.text('Your budgets'), findsOneWidget);
      expect(shown(tester, 'budget.field.cat-groceries'), '35.89');
      expect(find.text('Based on what you spent in your last 3 months'), findsOneWidget);
    });
  });

  group('the import flow', () {
    testWidgets(
      'a COP account uploads a EUR file: the preview says it will switch; nothing changes until the confirm',
      (tester) async {
        final env = await pumpImport(tester, currency: 'COP');
        await pickFile(tester);
        expect(
          find.text('Tu archivo está en EUR: al importarlo, tu cuenta pasará a usar EUR.'),
          findsOneWidget,
        );
        // Reading the file changed nothing.
        expect(env.server.calls, ['POST /v1/imports']);
        expect(env.home.live, 'COP');

        await tapKey(tester, 'import.confirm');
        expect(find.text('Importamos 22 movimientos.'), findsOneWidget);
        expect(env.server.calls, [
          'POST /v1/imports',
          'POST /v1/imports/preview-1/confirm {"adoptFileCurrency":true}',
        ]);
        expect(
          find.text('Tu archivo está en EUR, así que tu cuenta ahora usa EUR.'),
          findsOneWidget,
        );
        // The budgets that follow are prefilled from the recent months, in euros; home follows.
        expect(shown(tester, 'budget.field.cat-groceries'), '35,89');
        expect(env.container.read(homeProvider).data?.currency, 'EUR');
        expect(env.app.snapshots, isNotEmpty);
      },
    );

    testWidgets('"Usar otro archivo" drops the preview; the currency was never touched', (
      tester,
    ) async {
      final env = await pumpImport(tester, currency: 'COP');
      await pickFile(tester);
      await tapKey(tester, 'import.otherFile');
      expect(env.server.calls, ['POST /v1/imports', 'DELETE /v1/imports/preview-1']);
      // Back to the picker.
      expect(find.byKey(const Key('import.choose')), findsOneWidget);
      expect(env.home.live, 'COP');
    });

    testWidgets(
      'the import went in but reading the categories again failed: it says so and offers a retry',
      (tester) async {
        final env = await pumpImport(tester);
        await pickFile(tester);
        env.home.failures['categories'] = const HomeFailure(503, code: 'internal_error');
        await tapKey(tester, 'import.confirm');
        expect(find.text('Importamos 22 movimientos.'), findsOneWidget);
        expect(
          find.text('Tuvimos un problema de nuestro lado. Inténtalo de nuevo en un momento.'),
          findsOneWidget,
        );
        // Pressing Importar again could only fail: it is gone.
        expect(find.byKey(const Key('import.confirm')), findsNothing);
        expect(find.text('Tus presupuestos'), findsNothing);
        await tapKey(tester, 'import.retry');
        expect(find.byKey(const Key('import.error')), findsNothing);
        expect(find.text('Tus presupuestos'), findsOneWidget);
        expect(shown(tester, 'budget.field.cat-groceries'), '35,89');
        expect(env.server.calls.where((c) => c.contains('confirm')), hasLength(1));
      },
    );

    testWidgets('an old export says the amounts come from its last months with activity', (
      tester,
    ) async {
      await pumpImport(tester, oldExport: true);
      await pickFile(tester);
      await tapKey(tester, 'import.confirm');
      expect(find.text('Basado en tus últimos 3 meses con movimientos'), findsOneWidget);
    });

    testWidgets('while a confirm runs, SALTAR waits: nobody leaves or reverts an import halfway', (
      tester,
    ) async {
      final env = await pumpImport(tester);
      await pickFile(tester);
      env.server.holdConfirm = Completer<void>();
      await tester.tap(find.byKey(const Key('import.confirm')));
      await tester.pump();
      expect(find.text('IMPORTANDO…'), findsOneWidget);
      final flow = env.container.read(importFlowProvider.notifier);
      expect(env.container.read(importFlowProvider).locked, isTrue);
      expect(await flow.skip(), isFalse);
      expect(await flow.discard(), isFalse);
      env.server.holdConfirm!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Importamos 22 movimientos.'), findsOneWidget);
      expect(env.server.calls.any((c) => c.startsWith('DELETE')), isFalse);
      expect(env.container.read(importFlowProvider).locked, isFalse);
    });

    testWidgets(
      'skipping with a preview open drops it and moves on; the currency stays as it was',
      (tester) async {
        final env = await pumpImport(tester, currency: 'COP');
        await pickFile(tester);
        final flow = env.container.read(importFlowProvider.notifier);
        expect(await flow.skip(), isTrue);
        await tester.pumpAndSettle();
        expect(env.server.calls, ['POST /v1/imports', 'DELETE /v1/imports/preview-1']);
        expect(env.home.live, 'COP');
      },
    );

    testWidgets('a skip whose discard fails keeps the step, with the reason', (tester) async {
      final env = await pumpImport(tester);
      await pickFile(tester);
      env.server.failures['discard'] = const HomeFailure(503, code: 'internal_error');
      final flow = env.container.read(importFlowProvider.notifier);
      expect(await flow.skip(), isFalse);
      await tester.pumpAndSettle();
      expect(
        find.text('Tuvimos un problema de nuestro lado. Inténtalo de nuevo en un momento.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('import.confirm')), findsOneWidget);
    });

    testWidgets('with no preview open, skipping just leaves', (tester) async {
      final env = await pumpImport(tester);
      expect(await env.container.read(importFlowProvider.notifier).skip(), isTrue);
      expect(env.server.calls, isEmpty);
    });

    testWidgets('an account with movements keeps its currency: the rows are not imported', (
      tester,
    ) async {
      await pumpImport(tester, currency: 'COP', hasTransactions: true);
      await pickFile(tester);
      expect(
        find.text('Tu archivo está en EUR, pero tu cuenta ya usa COP: esas filas no se importan.'),
        findsOneWidget,
      );
      // Nothing to import: no confirm.
      expect(find.byKey(const Key('import.confirm')), findsNothing);
    });
  });

  group('everything the import changed reaches the rest of the app', () {
    testWidgets('home\'s figures, the saved month and the widget\'s snapshot follow', (
      tester,
    ) async {
      final env = await pumpImport(tester);
      final before = env.app.snapshots.length;
      await pickFile(tester);
      await tapKey(tester, 'import.confirm');
      final data = env.container.read(homeProvider).data!;
      expect(data.items.map((t) => t.name), containsAll(['Café', 'Cine']));
      expect(data.categories.values.map((c) => c.name), containsAll(['Ocio', 'Taxes']));
      expect(env.app.snapshots.length, greaterThan(before));
    });

    testWidgets('a cancelled import changes nothing', (tester) async {
      final env = await pumpImport(tester);
      env.files.next = null;
      final items = List.of(env.home.items);
      final homeCalls = List.of(env.home.calls);
      await pickFile(tester);
      expect(env.server.calls, isEmpty);
      expect(env.home.items, items);
      expect(env.home.calls, homeCalls);
      // The picker is still there for another try.
      expect(find.byKey(const Key('import.choose')), findsOneWidget);
      expect(find.byKey(const Key('import.error')), findsNothing);
      expect(env.container.read(importFlowProvider).phase, isA<ImportIdle>());
    });

    testWidgets(
      'leaving the page while a confirm is on its way: home, the profile and the widget still follow',
      (tester) async {
        final env = await pumpImport(tester, currency: 'COP');
        await pickFile(tester);
        env.server.holdConfirm = Completer<void>();
        await tester.tap(find.byKey(const Key('import.confirm')));
        await tester.pump();
        expect(env.container.read(importFlowProvider).locked, isTrue);

        // Away from the page (the bottom bar's Inicio) before the server answers.
        final snapshots = env.app.snapshots.length;
        await tester.tap(find.text('Inicio'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('import.page')), findsNothing);

        env.server.holdConfirm!.complete();
        await tester.pumpAndSettle();
        // The rows are in, the account took the file's currency, and the app knows both.
        expect(env.home.live, 'EUR');
        final data = env.container.read(homeProvider).data!;
        expect(data.currency, 'EUR');
        expect(data.items.map((t) => t.name), containsAll(['Café', 'Cine']));
        expect(env.app.snapshots.length, greaterThan(snapshots));
        // And the flow is let go once it is done.
        expect(env.container.exists(importFlowProvider), isFalse);
      },
    );

    testWidgets('leaving with a preview open confirms nothing', (tester) async {
      final env = await pumpImport(tester);
      await pickFile(tester);
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('import.page')), findsNothing);
      expect(env.server.calls, ['POST /v1/imports']);
      expect(env.home.items, isEmpty);
    });
  });

  group('large and malformed files (Review Focus 3)', () {
    testWidgets(
      'a 2,000-row file goes to the API whole, with the web\'s preview and no more work here',
      (tester) async {
        final csv = budgeCsv(rows: 2000);
        final env = await pumpImport(
          tester,
          file: PickedFile('big.csv', csv),
          fileStats: {
            ...sampleStats(),
            'transactions': 2000,
            'duplicates': 0,
            'rejected': [
              for (var i = 0; i < 45; i++) {'line': 7 + i, 'reason': 'invalid_amount'},
            ],
          },
        );
        await pickFile(tester);
        // The app parses nothing: the bytes reach the API as they are.
        expect(env.server.uploads.single, csv);
        expect(csv.length, lessThan(5 * 1024 * 1024));
        expect(find.text('IMPORTAR 2000 MOVIMIENTOS'), findsOneWidget);
        await tester.tap(find.byKey(const Key('import.rejected.toggle')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Línea'), findsNWidgets(20));
        expect(find.text('y 25 más'), findsOneWidget);
        await tapKey(tester, 'import.confirm');
        expect(find.text('Tus presupuestos'), findsOneWidget);
      },
    );

    testWidgets('a file over the API\'s 5 MB says so, without sending it', (tester) async {
      final env = await pumpImport(
        tester,
        file: PickedFile('huge.csv', Uint8List(5 * 1024 * 1024 + 1)),
      );
      await pickFile(tester);
      expect(find.text('El archivo es demasiado grande. El límite es de 5 MB.'), findsOneWidget);
      expect(env.server.calls, isEmpty);
      expect(find.byKey(const Key('import.choose')), findsOneWidget);
    });

    testWidgets('a file the API refuses as too large (a proxy\'s 413) says the same', (
      tester,
    ) async {
      final env = await pumpImport(tester);
      env.server.failures['upload'] = const HomeFailure(413);
      await pickFile(tester);
      expect(find.text('El archivo es demasiado grande. El límite es de 5 MB.'), findsOneWidget);
    });

    testWidgets('a malformed file gets the API\'s refusal, and another can be tried', (
      tester,
    ) async {
      final env = await pumpImport(
        tester,
        file: PickedFile('notes.csv', Uint8List.fromList([0, 1, 2])),
      );
      env.server.failures['upload'] = const HomeFailure(422, code: 'import_unrecognized_format');
      await pickFile(tester);
      expect(
        find.text('No reconocemos este archivo. Usa una exportación de Budge.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('import.choose')), findsOneWidget);
      // The next file reads.
      env.files.next = PickedFile('budge.csv', budgeCsv());
      await tapKey(tester, 'import.choose');
      expect(find.byKey(const Key('import.error')), findsNothing);
      expect(find.text('IMPORTAR 22 MOVIMIENTOS'), findsOneWidget);
    });

    testWidgets('a file already imported says so', (tester) async {
      final env = await pumpImport(tester);
      env.server.failures['upload'] = const HomeFailure(409, code: 'import_duplicate_file');
      await pickFile(tester);
      expect(find.text('Ya importaste este archivo.'), findsOneWidget);
    });

    testWidgets('an offline phone says so', (tester) async {
      final env = await pumpImport(tester);
      env.server.failures['upload'] = const HomeFailure(0);
      await pickFile(tester);
      expect(find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'), findsOneWidget);
    });

    testWidgets('a document the phone cannot read says something went wrong', (tester) async {
      final env = await pumpImport(tester);
      env.files.failure = const FilesFailure(FilesFailureKind.unreadable);
      await pickFile(tester);
      expect(find.text('Algo salió mal. Inténtalo de nuevo en un momento.'), findsOneWidget);
      expect(env.server.calls, isEmpty);
    });

    testWidgets('the picker stays usable while a file reads: a second tap sends one file', (
      tester,
    ) async {
      final env = await pumpImport(tester);
      await tapKey(tester, 'import.source.budge');
      env.files.hold = Completer<void>();
      await tester.tap(find.byKey(const Key('import.choose')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('import.choose')));
      await tester.pump();
      env.files.hold!.complete();
      await tester.pumpAndSettle();
      expect(env.server.uploads, hasLength(1));
    });
  });
}
