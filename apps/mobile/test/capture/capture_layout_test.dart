// Quick capture on a short phone with the font at 130%, with the keyboard up, and with long names
// and big amounts: nothing overflows, and what the person does next stays in view.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_sheet.dart' show sheetsWithInputProvider;
import 'package:lukitas/capture/capture_repository.dart';
import 'package:lukitas/capture/capture_sheet.dart';
import 'package:lukitas/capture/engine/speech_engine.dart';
import 'package:lukitas/capture/models_download.dart';
import 'package:lukitas/home/home_screen.dart';

import '../add/fakes.dart';
import '../home/fakes.dart';
import '../home/fixtures.dart';
import '../home/home_harness.dart';
import 'fakes.dart';

const _small = Size(360, 640);

Future<FakeSpeechEngine> _open(
  WidgetTester tester, {
  List<List<String>> heard = const [],
  SpeechFailure? failure,
  bool listen = true,
  bool hold = false,
  double textScale = 1.3,
}) async {
  final server = FakeHomeRepository(
    categoryList: [
      category('cat-food', 'Comida', icon: '🍽️'),
      category('cat-long', 'Una categoría con un nombre larguísimo de cuarenta', icon: '🎬'),
      category('cat-uber', 'Uber', icon: '🚕'),
    ],
    items: [tx('coffee', '2026-10-20', -450000, name: 'Café', categoryId: 'cat-food')],
  );
  final engine = FakeSpeechEngine(transcripts: [...heard], failure: failure)..hold = hold;
  await pumpHome(
    tester,
    server,
    size: _small,
    textScale: textScale,
    addRepo: FakeAddRepository(server),
    overrides: [
      captureRepositoryProvider.overrideWithValue(FakeCaptureRepository(server)),
      speechEngineProvider.overrideWithValue(engine),
      modelStoreProvider.overrideWithValue(FakeModelStore()),
    ],
  );
  unawaited(openCapture(tester.element(find.byType(HomeScreen)), listen: listen));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return engine;
}

/// The button is on the screen, whole, and at least 44 high.
void _reachable(WidgetTester tester, String key) {
  final finder = find.byKey(Key(key));
  expect(finder, findsOneWidget, reason: key);
  final rect = tester.getRect(finder);
  expect(rect.height, greaterThanOrEqualTo(44), reason: '$key is 44 high');
  expect(rect.top, greaterThanOrEqualTo(0), reason: key);
  expect(rect.bottom, lessThanOrEqualTo(_small.height), reason: '$key is in view');
}

void main() {
  testWidgets('listening, at 130%: no overflow, and Listo is in view', (tester) async {
    final engine = await _open(tester, hold: true);
    engine.held!
      ..add('')
      ..add('gasté 15 mil en almuerzo y 3 lukas en uber y otra cosa más larga para que ocupe');
    await tester.pump();
    expect(tester.takeException(), isNull);
    _reachable(tester, 'capture.stop');
    _reachable(tester, 'capture.type');
    await engine.held!.close();
    await tester.pumpAndSettle();
  });

  testWidgets('the typing field with the keyboard up, at 130%: Leer stays above the keyboard', (
    tester,
  ) async {
    await _open(tester, listen: false);
    // The phone's keyboard takes the bottom 260 px.
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final read = tester.getRect(find.byKey(const Key('capture.read')));
    expect(read.bottom, lessThanOrEqualTo(_small.height - 260));
    expect(read.top, greaterThanOrEqualTo(0));
    expect(tester.getRect(find.byKey(const Key('capture.field'))).bottom, lessThan(read.top));
  });

  testWidgets('a long name and a big amount truncate: no overflow, Guardar in view', (
    tester,
  ) async {
    await _open(tester, listen: false, heard: const []);
    await tester.enterText(
      find.byKey(const Key('capture.field')),
      'gasté 1500000000 en una cosa con un nombre larguísimo que no cabe en una línea de la tarjeta '
      'y 3 lukas en uber',
    );
    await tester.tap(find.byKey(const Key('capture.read')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('capture.card.0')), findsOneWidget);
    _reachable(tester, 'capture.save');
    // Open: the fields and the categories (one with a 50-character name) scroll inside the sheet.
    await tester.tap(find.byKey(const Key('capture.card.0')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final chip = find.byKey(const Key('capture.card.0.category.cat-long'));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    _reachable(tester, 'capture.save');
  });

  testWidgets('the unread fragment and its button at 130%', (tester) async {
    await _open(
      tester,
      heard: [
        ['gasté 15 mil en almuerzo y 9,50 en café'],
      ],
    );
    expect(tester.takeException(), isNull);
    final complete = find.byKey(const Key('capture.unread.0.complete'));
    expect(complete, findsOneWidget);
    expect(tester.getSize(complete).height, greaterThanOrEqualTo(44));
    _reachable(tester, 'capture.save');
  });

  testWidgets('the offer and the download at 130%', (tester) async {
    await _open(tester, failure: const SpeechFailure(SpeechFailureKind.noModel));
    expect(tester.takeException(), isNull);
    _reachable(tester, 'capture.offer.download');
    _reachable(tester, 'capture.offer.decline');
    await tester.tap(find.byKey(const Key('capture.offer.download')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('what it holds is marked as input for a link, as before', (tester) async {
    await _open(tester, listen: false);
    final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
    expect(container.read(sheetsWithInputProvider).any, isFalse);
    await tester.enterText(find.byKey(const Key('capture.field')), 'gasté 15 mil');
    await tester.pump();
    expect(container.read(sheetsWithInputProvider).any, isTrue);
  });
}
