// The Vosk engine's Dart side (lib/capture/engine/vosk_engine.dart) over a fake platform channel:
// what it asks for before listening, how it turns the two passes' results into one transcript,
// and when it stops by itself.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/engine/speech_engine.dart';
import 'package:lukitas/capture/engine/voice_channel.dart';
import 'package:lukitas/capture/engine/vosk_engine.dart';
import 'package:lukitas/capture/models_download.dart';

class _FakeChannel implements VoicePlatform {
  var supportedAnswer = true;
  var permission = true;

  /// When set, the permission answer waits for it.
  Completer<bool>? permissionAnswer;
  final starts = <({String modelPath, String grammar})>[];
  var stops = 0;
  StreamController<VoiceEvent>? events;

  @override
  Future<bool> supported() async => supportedAnswer;

  @override
  Future<bool> requestPermission() async => permissionAnswer?.future ?? permission;

  @override
  Stream<VoiceEvent> start({required String modelPath, required String grammar}) {
    starts.add((modelPath: modelPath, grammar: grammar));
    events = StreamController<VoiceEvent>();
    return events!.stream;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<String> modelsDirectory() async => '/models';

  @override
  Future<void> unzip(String zip, String into) async {}

  @override
  Future<void> releaseModels() async {}

  @override
  Future<int> freeBytes() async => 1 << 40;

  void send(VoiceEvent event) => events!.add(event);

  /// What the platform does on stop: the last results of both passes, then the end.
  Future<void> finish({String free = '{"text":""}', String grammar = '{"text":""}'}) async {
    send(VoiceEvent.result(VoicePass.free, free));
    send(VoiceEvent.result(VoicePass.grammar, grammar));
    send(const VoiceEvent.done());
    await events!.close();
  }
}

class _Store extends ModelStore {
  _Store(this.path) : super(files: _FakeChannel(), http: Dio());

  String? path;

  @override
  Future<String?> installedPath(String locale) async => path;
}

String _result(List<(String, double, double)> words) =>
    '{"result":[${words.map((w) => '{"conf":1.0,"word":"${w.$1}","start":${w.$2},"end":${w.$3}}').join(',')}],'
    '"text":"${words.map((w) => w.$1).join(' ')}"}';

void main() {
  late _FakeChannel channel;
  late _Store store;
  late VoskEngine engine;

  setUp(() {
    channel = _FakeChannel();
    store = _Store('/models/voice/vosk-model-small-es-0.42');
    engine = VoskEngine(channel: channel, models: store);
  });

  test('available asks the platform whether Vosk runs on this phone', () async {
    expect(await engine.available(), isTrue);
    channel.supportedAnswer = false;
    expect(await engine.available(), isFalse);
  });

  test('listen without the model fails with noModel, and asks nothing else', () async {
    store.path = null;
    await expectLater(
      engine.listen(locale: 'es'),
      emitsError(isA<SpeechFailure>().having((f) => f.kind, 'kind', SpeechFailureKind.noModel)),
    );
    expect(channel.starts, isEmpty);
  });

  test('a denied microphone fails with permissionDenied, without recording', () async {
    channel.permission = false;
    await expectLater(
      engine.listen(locale: 'es'),
      emitsError(
        isA<SpeechFailure>().having((f) => f.kind, 'kind', SpeechFailureKind.permissionDenied),
      ),
    );
    expect(channel.starts, isEmpty);
  });

  test('it starts both passes on the model with the locale\'s grammar', () async {
    final heard = engine.listen(locale: 'es').toList();
    await pumpEventQueue();
    expect(channel.starts.single.modelPath, '/models/voice/vosk-model-small-es-0.42');
    expect(channel.starts.single.grammar, contains('"gasté"'));
    await channel.finish();
    await heard;
  });

  test('partials show while speaking; the end gives the merged transcript (rule v2)', () async {
    final heard = <String>[];
    final done = engine.listen(locale: 'es').listen(heard.add).asFuture<void>();
    await pumpEventQueue();
    channel.send(const VoiceEvent.partial('me de'));
    channel.send(const VoiceEvent.partial('me de ópalo'));
    // The grammar pass hits an endpoint mid-sentence: its intermediate result counts too.
    channel.send(
      VoiceEvent.result(VoicePass.grammar, _result([('medio', 0.30, 0.60), ('palo', 0.60, 1.00)])),
    );
    await pumpEventQueue();
    await channel.finish(
      free: _result([
        ('me', 0.30, 0.42),
        ('de', 0.42, 0.55),
        ('ópalo', 0.55, 1.00),
        ('en', 1.10, 1.20),
        ('el', 1.20, 1.30),
        ('éxito', 1.30, 1.80),
      ]),
      grammar: _result([('[unk]', 1.10, 1.80)]),
    );
    await done;
    expect(heard.first, 'me de');
    expect(heard.last, 'medio palo en el éxito');
  });

  test('results from several endpoints add up, in time order', () async {
    final heard = engine.listen(locale: 'es').toList();
    await pumpEventQueue();
    channel.send(
      VoiceEvent.result(VoicePass.free, _result([('almuerzo', 0, 0.5), ('quince', 0.5, 0.9)])),
    );
    channel.send(VoiceEvent.result(VoicePass.free, _result([('mil', 1.5, 1.9)])));
    await channel.finish();
    expect((await heard).last, 'almuerzo quince mil');
  });

  test('a platform error ends the stream with a failure', () async {
    final heard = engine.listen(locale: 'es').toList();
    await pumpEventQueue();
    channel.send(const VoiceEvent.error('mic_unavailable'));
    await expectLater(
      heard,
      throwsA(isA<SpeechFailure>().having((f) => f.kind, 'kind', SpeechFailureKind.failed)),
    );
  });

  test('closing before the permission answer never starts recording', () async {
    final answer = Completer<bool>();
    channel.permissionAnswer = answer;
    final subscription = engine.listen(locale: 'es').listen((_) {});
    await pumpEventQueue();
    await subscription.cancel();
    answer.complete(true);
    await pumpEventQueue();
    expect(channel.starts, isEmpty);
  });

  test('the platform being ready shows as an empty first event', () async {
    final heard = <String>[];
    final done = engine.listen(locale: 'es').listen(heard.add).asFuture<void>();
    await pumpEventQueue();
    expect(heard, isEmpty, reason: 'nothing before the model is loaded and the mic records');
    channel.send(const VoiceEvent.ready());
    await pumpEventQueue();
    expect(heard, ['']);
    await channel.finish();
    await done;
  });

  test('stopping twice asks the platform once', () async {
    final heard = engine.listen(locale: 'es').toList();
    await pumpEventQueue();
    await engine.stop();
    await engine.stop();
    expect(channel.stops, 1);
    await channel.finish();
    await heard;
  });

  test('stop asks the platform to stop (it then sends the last results)', () async {
    final heard = engine.listen(locale: 'es').toList();
    await pumpEventQueue();
    await engine.stop();
    expect(channel.stops, 1);
    await channel.finish();
    await heard;
  });

  // In testWidgets, time is fake: pump moves it on.
  testWidgets('a pause after something was said stops by itself', (tester) async {
    engine.listen(locale: 'es').listen((_) {});
    await tester.pump();
    channel.send(VoiceEvent.result(VoicePass.free, _result([('almuerzo', 0, 0.5)])));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(channel.stops, 0);
    // Speaking again pushes the end back.
    channel.send(const VoiceEvent.partial('dieciocho'));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(channel.stops, 0);
    channel.send(VoiceEvent.result(VoicePass.free, _result([('dieciocho', 0.6, 1.0)])));
    await tester.pump(endOfSpeechPause);
    expect(channel.stops, 1);
    await channel.finish();
    await tester.pump();
  });

  testWidgets('nothing said at all stops too', (tester) async {
    engine.listen(locale: 'es').listen((_) {});
    await tester.pump();
    await tester.pump(nothingHeardLimit);
    expect(channel.stops, 1);
    await channel.finish();
    await tester.pump();
  });

  testWidgets('speaking for too long stops', (tester) async {
    engine.listen(locale: 'es').listen((_) {});
    await tester.pump();
    for (var i = 0; i * 500 < longestListen.inMilliseconds; i++) {
      channel.send(VoiceEvent.partial('palabra $i'));
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(channel.stops, 1);
    await channel.finish();
    await tester.pump();
  });
}
