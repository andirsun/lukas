// Loading the speech model in the background (lib/capture/prewarm.dart): only for someone who has
// captured before, only when the model is downloaded, at the start and each time the app comes to
// the front, and never recording.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/engine/speech_engine.dart';
import 'package:lukitas/capture/models_download.dart';
import 'package:lukitas/capture/prewarm.dart';
import 'package:lukitas/feedback/stored_flag.dart';
import 'package:lukitas/settings/preferences.dart';

import '../settings/fakes.dart';
import 'fakes.dart';

class _Installed extends FakeModelStore {
  _Installed({this.installed = true});

  bool installed;
  final asked = <String>[];

  @override
  Future<String?> installedPath(String locale) async {
    asked.add(locale);
    return installed ? '/models/$locale' : null;
  }
}

class _Chosen extends LocaleOverride {
  _Chosen(this.locale);

  final Locale locale;

  @override
  Locale? build() => locale;
}

class _Env {
  _Env(this.container, this.engine, this.models);
  final ProviderContainer container;
  final FakeSpeechEngine engine;
  final _Installed models;
}

Future<_Env> _start(
  WidgetTester tester, {
  bool? noteOn,
  bool installed = true,
  Locale? device,
  String? override,
}) async {
  if (device != null) {
    tester.platformDispatcher.localeTestValue = device;
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  }
  final engine = FakeSpeechEngine();
  final models = _Installed(installed: installed);
  final container = ProviderContainer(
    overrides: [
      speechEngineProvider.overrideWithValue(engine),
      modelStoreProvider.overrideWithValue(models),
      flagStoreProvider.overrideWith(
        (ref, key) => key == 'setting.capture.note' ? FakeFlagStore(noteOn) : FakeFlagStore(),
      ),
      if (override != null) localeOverrideProvider.overrideWith(() => _Chosen(Locale(override))),
    ],
  );
  addTearDown(container.dispose);
  container.read(voicePrewarmProvider);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 10));
  return _Env(container, engine, models);
}

void main() {
  testWidgets('after a first capture, the model is loaded at the start', (tester) async {
    final env = await _start(tester, noteOn: false, device: const Locale('es'));
    expect(env.engine.warmUps, ['es']);
    expect(env.engine.listens, 0, reason: 'loading is not recording');
    expect(env.engine.stops, 0);
  });

  testWidgets('before the first capture nothing is loaded in advance', (tester) async {
    expect((await _start(tester, noteOn: true)).engine.warmUps, isEmpty);
    // Never chosen is the same: the note is on until the first capture.
    expect((await _start(tester)).engine.warmUps, isEmpty);
  });

  testWidgets('without a downloaded model there is nothing to load', (tester) async {
    final env = await _start(tester, noteOn: false, installed: false);
    expect(env.models.asked, isNotEmpty);
    expect(env.engine.warmUps, isEmpty);
  });

  testWidgets('each time the app comes back to the front it asks again', (tester) async {
    final env = await _start(tester, noteOn: false, device: const Locale('es'));
    expect(env.engine.warmUps, hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(env.engine.warmUps, hasLength(1), reason: 'going away loads nothing');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(env.engine.warmUps, hasLength(2));
    expect(env.engine.listens, 0);
  });

  testWidgets('it loads the model of the app\'s language: English for an English phone', (
    tester,
  ) async {
    final env = await _start(tester, noteOn: false, device: const Locale('en', 'US'));
    expect(env.engine.warmUps, ['en']);
  });

  testWidgets('a language the app does not have is Spanish, as everywhere else', (tester) async {
    final env = await _start(tester, noteOn: false, device: const Locale('fr'));
    expect(env.engine.warmUps, ['es']);
  });

  testWidgets('the language chosen in Settings wins over the phone\'s', (tester) async {
    final env = await _start(tester, noteOn: false, device: const Locale('es'), override: 'en');
    expect(env.engine.warmUps, ['en']);
  });

  testWidgets('an engine that cannot load is no error', (tester) async {
    final env = await _start(tester, noteOn: false);
    env.engine.warmFails = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Italian and Portuguese have no model: nothing is loaded, and never the Spanish one',
    (tester) async {
      for (final device in [
        const Locale('it', 'IT'),
        const Locale('pt', 'PT'),
        const Locale('pt', 'BR'),
      ]) {
        final env = await _start(tester, noteOn: false, device: device);
        expect(env.engine.warmUps, isEmpty, reason: '$device');
        expect(env.models.asked, isNot(contains('es')), reason: '$device');
        expect(tester.takeException(), isNull, reason: '$device');
      }
      final chosen = await _start(
        tester,
        noteOn: false,
        device: const Locale('es'),
        override: 'it',
      );
      expect(chosen.engine.warmUps, isEmpty);
    },
  );

  test('voiceLocale names the app\'s own language, even without a model for it', () {
    expect(voiceLocale(const Locale('es', 'CO')), 'es');
    expect(voiceLocale(const Locale('en', 'GB')), 'en');
    expect(voiceLocale(const Locale('it', 'IT')), 'it');
    expect(voiceLocale(const Locale('pt', 'BR')), 'pt');
    expect(voiceLocale(const Locale('fr')), 'es');
  });
}
