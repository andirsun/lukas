@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/capture_repository.dart';
import 'package:lukitas/capture/capture_sheet.dart';
import 'package:lukitas/capture/engine/speech_engine.dart';
import 'package:lukitas/capture/models_download.dart';
import 'package:lukitas/home/home_screen.dart';

import '../add/fakes.dart';
import '../home/fakes.dart';
import '../home/fixtures.dart';
import '../home/home_harness.dart';
import '../support/parity.dart';
import '../support/parity_home.dart' show precacheLukitas;
import 'fakes.dart';

/// Quick capture as a phone shows it, 412 × 915 at a device pixel ratio of 2, in night and in day.
/// The web has no capture, so there is no story to compare with: these pictures are for the
/// founder to review by eye (the listening with its waves, the preview with two cards, a fragment
/// the parser could not read, a card open, the offer to download the voice, and the download under
/// way). The goldens are the Mac's pixels (emoji from the parity harness's Noto Color Emoji),
/// tagged `golden`; update them with
/// `flutter test --update-goldens test/capture/capture_golden_test.dart`.

/// A voice download that stays at 40 % until [finish]ed.
class _SlowModelStore extends FakeModelStore {
  final _done = Completer<void>();

  void finish() => _done.complete();

  @override
  Future<void> download(
    String locale, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancel,
  }) async {
    downloads++;
    final total = modelFor(locale).bytes;
    onProgress?.call((total * 0.405).round(), total);
    await _done.future;
  }
}

ThemeData _withFallbacks(ThemeData base) =>
    base.copyWith(textTheme: base.textTheme.apply(fontFamilyFallback: parityFallbackFamilies));

class _Env {
  _Env(this.engine, this.models);
  final FakeSpeechEngine engine;
  final FakeModelStore models;
}

Future<_Env> _open(
  WidgetTester t,
  String theme, {
  List<List<String>> heard = const [],
  SpeechFailure? failure,
  bool hold = false,
  FakeModelStore? models,
}) async {
  await t.runAsync(loadParityFonts);
  final server = FakeHomeRepository(
    categoryList: [
      category('cat-food', 'Comida', icon: '🍽️'),
      category('cat-uber', 'Uber', icon: '🚕'),
      category('cat-home', 'Hogar', icon: '🏠', color: 'orange'),
      category('cat-fun', 'Ocio', icon: '🎬'),
      category('cat-salary', 'Nómina', kind: 'income', icon: '💰'),
    ],
    items: [
      tx('coffee', '2026-10-20', -450000, name: 'Café', categoryId: 'cat-food'),
      tx('taxi', '2026-10-21', -1200000, name: 'Taxi', categoryId: 'cat-uber'),
    ],
  );
  final engine = FakeSpeechEngine(transcripts: [...heard], failure: failure)
    ..warm = true
    ..hold = hold;
  final store = models ?? FakeModelStore();
  await pumpHome(
    t,
    server,
    size: parityViewSize * parityPixelRatio,
    pixelRatio: parityPixelRatio,
    themeMode: theme == 'night' ? ThemeMode.dark : ThemeMode.light,
    restyle: _withFallbacks,
    addRepo: FakeAddRepository(server),
    overrides: [
      captureRepositoryProvider.overrideWithValue(FakeCaptureRepository(server)),
      speechEngineProvider.overrideWithValue(engine),
      modelStoreProvider.overrideWithValue(store),
    ],
  );
  await precacheLukitas(t);
  unawaited(openCapture(t.element(find.byType(HomeScreen))));
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  return _Env(engine, store);
}

Future<void> _picture(WidgetTester t, String name, String theme) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile(Uri.file('${Directory.current.path}/test/capture/goldens/${name}_$theme.png')),
);

/// A test that draws shadows blurred: `flutter test` draws them hard-edged, and the primary
/// button's glow is a blur. The framework checks the flag is back before the tear-downs run.
void _golden(String description, Future<void> Function(WidgetTester t) body) {
  testWidgets(description, (t) async {
    debugDisableShadows = false;
    try {
      await body(t);
    } finally {
      debugDisableShadows = true;
    }
  });
}

void main() {
  for (final theme in ['night', 'day']) {
    _golden('listening, with the waves ($theme)', (t) async {
      final env = await _open(t, theme, hold: true);
      env.engine.held!
        ..add('')
        ..add('gasté 15 mil en almuerzo');
      await t.pump();
      // Silence, then a sentence: the newest level is on the right.
      for (final level in [
        0.0, 0.02, 0.05, 0.3, 0.55, 0.8, 0.6, 0.35, 0.5, 0.9, 0.7, 0.4, //
        0.2, 0.1, 0.45, 0.75, 0.95, 0.65, 0.3, 0.55, 0.8, 0.5, 0.25, 0.4,
      ]) {
        env.engine.levelsController.add(level);
        await t.pump(const Duration(milliseconds: 40));
      }
      await t.pump(const Duration(milliseconds: 400));
      await _picture(t, 'listening', theme);
      await env.engine.held!.close();
      await t.pumpAndSettle();
    });

    _golden('the preview with two cards ($theme)', (t) async {
      await _open(
        t,
        theme,
        heard: [
          ['gasté 15 mil en almuerzo y 3 lukas en uber'],
        ],
      );
      await t.pumpAndSettle();
      await _picture(t, 'preview', theme);
    });

    _golden('a card open to change it ($theme)', (t) async {
      await _open(
        t,
        theme,
        heard: [
          ['gasté 15 mil en almuerzo y 3 lukas en uber'],
        ],
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('capture.card.0')));
      await t.pumpAndSettle();
      await _picture(t, 'card_open', theme);
    });

    _golden('a fragment that could not be read ($theme)', (t) async {
      await _open(
        t,
        theme,
        heard: [
          ['gasté 15 mil en almuerzo y 9,50 en café'],
        ],
      );
      await t.pumpAndSettle();
      await _picture(t, 'unread', theme);
    });

    _golden('the offer to download the voice ($theme)', (t) async {
      await _open(t, theme, failure: const SpeechFailure(SpeechFailureKind.noModel));
      await t.pumpAndSettle();
      await _picture(t, 'offer', theme);
    });

    _golden('the download under way ($theme)', (t) async {
      final models = _SlowModelStore();
      await _open(
        t,
        theme,
        failure: const SpeechFailure(SpeechFailureKind.noModel),
        models: models,
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('capture.offer.download')));
      await t.pumpAndSettle();
      await _picture(t, 'downloading', theme);
      models.finish();
      await t.pumpAndSettle();
    });
  }
}
