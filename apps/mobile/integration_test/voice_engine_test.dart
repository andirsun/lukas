// The real speech engine on an Android emulator: the Spanish model downloads from a stand-in for
// the GitHub release, is checked against its SHA-256, unzipped and loaded by Vosk, and both
// recognizers listen and stop. The release `voice-models-v1` does not exist yet, so the zips are
// served from this machine (the official files, unchanged), e.g. from a folder holding them:
//
//   python3 -m http.server 8765
//   adb -s emulator-5554 shell pm grant com.andersonlaverde.lukitas android.permission.RECORD_AUDIO
//   flutter test integration_test/voice_engine_test.dart -d emulator-5554 \
//     --dart-define=VOICE_MODELS_URL=http://10.0.2.2:8765
//
// Without VOICE_MODELS_URL it is skipped. A headless emulator has no real microphone, so this
// checks the plumbing (download, unzip, model load, grammar, recording, stop), not accuracy:
// accuracy is measured on a phone with real voices (voice spike report).
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lukitas/capture/engine/speech_engine.dart';
import 'package:lukitas/capture/engine/voice_channel.dart';
import 'package:lukitas/capture/engine/vosk_engine.dart';
import 'package:lukitas/capture/models_download.dart';

const _modelsUrl = String.fromEnvironment('VOICE_MODELS_URL');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the Spanish model downloads, verifies, loads, and both passes listen and stop',
    (tester) async {
      const channel = VoiceChannel();
      final store = ModelStore(files: channel, http: Dio(), releaseUrl: Uri.parse(_modelsUrl));
      await store.deleteModels();
      expect(await store.installedPath('es'), isNull);

      await store.download('es');
      final path = await store.installedPath('es');
      expect(path, endsWith('/voice/vosk-model-small-es-0.42'));

      final engine = VoskEngine(channel: channel, models: store);
      expect(await engine.available(), isTrue);
      final heard = <String>[];
      Object? failure;
      final done = engine
          .listen(locale: 'es')
          .listen(heard.add, onError: (Object e) => failure = e)
          .asFuture<void>()
          .catchError((Object _) {});
      await Future<void>.delayed(const Duration(seconds: 3));
      await engine.stop();
      await done.timeout(const Duration(seconds: 10));
      // Silence is heard as nothing; a failure would be a SpeechFailure (no microphone at all).
      expect(failure, isNull, reason: '$failure');
      expect(heard.last.trim(), isEmpty);

      await store.deleteModels();
      expect(await store.installedPath('es'), isNull);
      // ignore: avoid_print
      print('voice engine plumbing ok; ${heard.length} events');
    },
    skip: _modelsUrl.isEmpty,
    timeout: const Timeout(Duration(minutes: 5)),
  );

  testWidgets('without the model, listening fails with noModel', (tester) async {
    const channel = VoiceChannel();
    final store = ModelStore(files: channel, http: Dio());
    await store.deleteModels();
    final engine = VoskEngine(channel: channel, models: store);
    await expectLater(
      engine.listen(locale: 'es'),
      emitsError(isA<SpeechFailure>().having((f) => f.kind, 'kind', SpeechFailureKind.noModel)),
    );
  });
}
