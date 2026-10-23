// Quick capture (spec section 6.1.4) on home, with a fixed transcript in place of audio.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/capture/capture_repository.dart';
import 'package:lukitas/capture/capture_sheet.dart';
import 'package:lukitas/capture/engine/speech_engine.dart';
import 'package:lukitas/capture/models_download.dart';
import 'package:lukitas/home/home_repository.dart';

import '../home/fakes.dart';
import '../home/fixtures.dart';
import '../home/home_harness.dart';
import 'fakes.dart';

const _sentence = 'gasté 15 mil en almuerzo y 3 lukas en uber';

class _Env {
  _Env(this.server, this.capture, this.engine, this.models, this.harness, this.celebrated);
  final FakeHomeRepository server;
  final FakeCaptureRepository capture;
  final FakeSpeechEngine engine;
  final FakeModelStore models;
  final HomeHarness harness;
  final List<List<Transaction>> celebrated;
}

Future<_Env> _pump(
  WidgetTester tester, {
  List<List<String>> heard = const [
    ['gasté 15 mil', _sentence],
  ],
  SpeechFailure? failure,
  bool available = true,
  Locale locale = const Locale('es'),
}) async {
  final server = FakeHomeRepository(
    categoryList: [
      category('cat-food', 'Comida', icon: '🍽️'),
      category('cat-uber', 'Uber', icon: '🚕'),
      category('cat-salary', 'Nómina', kind: 'income', icon: '💰'),
    ],
    items: [tx('coffee', '2026-10-20', -450000, name: 'Café', categoryId: 'cat-food')],
  );
  final capture = FakeCaptureRepository(server);
  final engine = FakeSpeechEngine(
    transcripts: [...heard],
    failure: failure,
    availableAnswer: available,
  );
  final models = FakeModelStore();
  final celebrated = <List<Transaction>>[];
  final harness = await pumpHome(
    tester,
    server,
    locale: locale,
    overrides: [
      captureRepositoryProvider.overrideWithValue(capture),
      speechEngineProvider.overrideWithValue(engine),
      modelStoreProvider.overrideWithValue(models),
      batchSavedFeedbackProvider.overrideWithValue(celebrated.add),
    ],
  );
  return _Env(server, capture, engine, models, harness, celebrated);
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home.capture')));
  await tester.pumpAndSettle();
}

FilledButton _save(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const Key('capture.save')));

Future<void> _pickCategory(WidgetTester tester, int card, String id) async {
  final pick = find.byKey(Key('capture.card.$card.pick'));
  if (pick.evaluate().isNotEmpty) {
    await tester.tap(pick);
    await tester.pumpAndSettle();
  }
  final chip = find.byKey(Key('capture.card.$card.category.$id'));
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

/// Lets the 8 s of a Deshacer toast pass.
Future<void> _letTimersEnd(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 12));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a fixed transcript "$_sentence" shows two cards and GUARDAR 2', (tester) async {
    final env = await _pump(tester);
    await _open(tester);
    expect(env.engine.listens, 1);
    expect(find.byKey(const Key('capture.card.0')), findsOneWidget);
    expect(find.byKey(const Key('capture.card.1')), findsOneWidget);
    expect(find.byKey(const Key('capture.card.2')), findsNothing);
    expect(find.text(r'$15.000'), findsOneWidget);
    expect(find.text(r'$3.000'), findsOneWidget);
    expect(find.text('GUARDAR 2'), findsOneWidget);
    expect(find.text(_sentence), findsOneWidget);
  });

  testWidgets('GUARDAR is disabled until every card has a category', (tester) async {
    await _pump(tester);
    await _open(tester);
    // "uber" is a category's name; "almuerzo" is no category's.
    expect(find.text('Elige categoría'), findsOneWidget);
    expect(_save(tester).onPressed, isNull);
    await _pickCategory(tester, 0, 'cat-food');
    expect(find.text('Elige categoría'), findsNothing);
    expect(_save(tester).onPressed, isNotNull);
  });

  testWidgets('a removed card is not saved, and GUARDAR counts what is left', (tester) async {
    final env = await _pump(tester);
    await _open(tester);
    await tester.tap(find.byKey(const Key('capture.card.0.remove')));
    await tester.pumpAndSettle();
    expect(find.text('GUARDAR 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('capture.save')));
    await tester.pumpAndSettle();
    expect(env.capture.calls.single, endsWith('Uber:300000'));
    await _letTimersEnd(tester);
  });

  testWidgets('an unread fragment shows "No entendí: «…»" and can be completed by hand', (
    tester,
  ) async {
    final env = await _pump(
      tester,
      heard: [
        ['gasté 15 mil en almuerzo y 9,50 en café'],
      ],
    );
    await _open(tester);
    expect(find.text('No entendí: «9,50 en café»'), findsOneWidget);
    expect(find.text('GUARDAR 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('capture.unread.0.complete')));
    await tester.pumpAndSettle();
    expect(find.text('No entendí: «9,50 en café»'), findsNothing);
    expect(find.text('Falta el monto'), findsOneWidget);
    expect(find.text('GUARDAR 2'), findsOneWidget);
    expect(_save(tester).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('capture.card.1.amount')), '9500');
    await tester.enterText(find.byKey(const Key('capture.card.1.name')), 'café');
    await tester.pumpAndSettle();
    await _pickCategory(tester, 1, 'cat-food');
    await _pickCategory(tester, 0, 'cat-food');
    expect(_save(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('capture.save')));
    await tester.pumpAndSettle();
    expect(env.capture.calls.single, endsWith('Almuerzo:1500000,Café:950000'));
    await _letTimersEnd(tester);
  });

  testWidgets('saving shows one celebration with the total and one Deshacer that removes both', (
    tester,
  ) async {
    final env = await _pump(tester);
    await _open(tester);
    await _pickCategory(tester, 0, 'cat-food');
    await tester.tap(find.byKey(const Key('capture.save')));
    await tester.pumpAndSettle();

    // The sheet closed; home has both rows; one toast, with the total.
    expect(find.byKey(const Key('capture.sheet')), findsNothing);
    expect(env.capture.calls, hasLength(1));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(r'¡Listo! 2 movimientos por $18.000'), findsOneWidget);
    expect(find.text('Deshacer'), findsOneWidget);
    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('Uber'), findsWidgets);
    // Task 13's hook heard about it once, with both rows.
    expect(env.celebrated.single.map((t) => t.name), ['Almuerzo', 'Uber']);

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(env.capture.calls.last, 'undo batch-1,batch-2');
    expect(env.server.items.map((t) => t.id), ['coffee']);
    expect(find.text('Almuerzo'), findsNothing);
    expect(find.text('Quitados: 2 movimientos'), findsOneWidget);
    await _letTimersEnd(tester);
  });

  testWidgets('the batch save retried after a lost response leaves exactly 2 rows', (tester) async {
    final env = await _pump(tester);
    await _open(tester);
    await _pickCategory(tester, 0, 'cat-food');
    env.capture.loseNextAnswer = true;
    await tester.tap(find.byKey(const Key('capture.save')));
    await tester.pumpAndSettle();
    // The answer was lost: the sheet stays, with Reintentar.
    expect(find.byKey(const Key('capture.sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('capture.retry')));
    await tester.pumpAndSettle();

    expect(env.capture.keys, hasLength(2));
    expect(env.capture.keys[0], env.capture.keys[1], reason: 'Reintentar reuses the key');
    expect(env.server.items.where((t) => t.id.startsWith('batch-')), hasLength(2));
    expect(find.byKey(const Key('capture.sheet')), findsNothing);
    await _letTimersEnd(tester);
  });

  testWidgets('a change after a failed save makes a new key', (tester) async {
    final env = await _pump(tester);
    await _open(tester);
    await _pickCategory(tester, 0, 'cat-food');
    env.capture.failures['save'] = const HomeFailure(500);
    await tester.tap(find.byKey(const Key('capture.save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture.card.1.remove')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture.save')));
    await tester.pumpAndSettle();
    expect(env.capture.keys[0], isNot(env.capture.keys[1]));
    await _letTimersEnd(tester);
  });

  testWidgets('microphone permission denied shows the typing field with one sentence on why', (
    tester,
  ) async {
    final env = await _pump(
      tester,
      failure: const SpeechFailure(SpeechFailureKind.permissionDenied),
    );
    await _open(tester);
    expect(find.byKey(const Key('capture.field')), findsOneWidget);
    expect(
      find.text('Sin permiso para el micrófono no puedo escucharte, así que escríbelo aquí.'),
      findsOneWidget,
    );
    // Typing works as well as speaking.
    await tester.enterText(find.byKey(const Key('capture.field')), _sentence);
    await tester.tap(find.byKey(const Key('capture.read')));
    await tester.pumpAndSettle();
    expect(find.text('GUARDAR 2'), findsOneWidget);
    expect(env.engine.listens, 1);
  });

  testWidgets('no engine available behaves the same', (tester) async {
    final env = await _pump(tester, available: false);
    await _open(tester);
    expect(env.engine.listens, 0);
    expect(find.byKey(const Key('capture.field')), findsOneWidget);
    expect(
      find.text('Este teléfono no puede escuchar con Lukitas, así que escríbelo aquí.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('capture.listen')), findsNothing);
  });

  testWidgets('without the model, an opt-in shows its size; declining leaves the typing field', (
    tester,
  ) async {
    final env = await _pump(tester, failure: const SpeechFailure(SpeechFailureKind.noModel));
    await _open(tester);
    final mb = (voiceModels['es']!.bytes / 1e6).round();
    expect(find.text('Descargar $mb MB'), findsOneWidget);
    await tester.tap(find.byKey(const Key('capture.offer.decline')));
    await tester.pumpAndSettle();
    expect(env.models.downloads, 0);
    expect(find.byKey(const Key('capture.field')), findsOneWidget);
  });

  testWidgets('accepting the opt-in downloads the model, then listens', (tester) async {
    final env = await _pump(tester, failure: const SpeechFailure(SpeechFailureKind.noModel));
    await _open(tester);
    await tester.tap(find.byKey(const Key('capture.offer.download')));
    await tester.pumpAndSettle();
    expect(env.models.downloads, 1);
    expect(env.engine.listens, 2);
    expect(find.text('GUARDAR 2'), findsOneWidget);
  });

  testWidgets('a corrupt download says so and offers it again', (tester) async {
    final env = await _pump(tester, failure: const SpeechFailure(SpeechFailureKind.noModel));
    env.models.failure = const ModelDownloadFailure(corrupt: true);
    await _open(tester);
    await tester.tap(find.byKey(const Key('capture.offer.download')));
    await tester.pumpAndSettle();
    expect(find.text('La voz llegó dañada y la borramos. Inténtalo de nuevo.'), findsOneWidget);
    expect(find.byKey(const Key('capture.offer.download')), findsOneWidget);
  });

  testWidgets('opened to type (listen: false), nothing listens', (tester) async {
    final env = await _pump(tester);
    final context = tester.element(find.byKey(const Key('home.add')));
    // ignore: unawaited_futures
    openCapture(context, listen: false);
    await tester.pumpAndSettle();
    expect(env.engine.listens, 0);
    expect(find.byKey(const Key('capture.field')), findsOneWidget);
  });

  testWidgets('in English the copy is English', (tester) async {
    await _pump(
      tester,
      locale: const Locale('en'),
      heard: [
        ['spent 15 on lunch and 3 on uber'],
      ],
    );
    await _open(tester);
    expect(find.text('SAVE 2'), findsOneWidget);
    expect(find.text('Pick a category'), findsOneWidget);
  });
}
