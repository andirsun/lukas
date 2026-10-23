import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models_download.dart';
import 'voice_channel.dart';
import 'vosk_engine.dart';

/// Turns speech into text, on the phone (spec section 6.1.4). The engine is the voice spike's
/// choice: Vosk, two passes merged (vosk_engine.dart). Capture only sees this interface, so tests
/// and the integration tests put a fixed transcript in place of audio.
abstract class SpeechEngine {
  /// Whether this phone can run the engine at all (with or without a model downloaded).
  Future<bool> available();

  /// Listens in [locale] (`es` or `en`) until [stop], or until the person stops talking. Each event
  /// is the transcript so far; the last one, just before the stream closes, is the final one. Fails
  /// with a [SpeechFailure].
  Stream<String> listen({required String locale});

  /// Stops listening: the stream sends the final transcript, then closes.
  Future<void> stop();
}

enum SpeechFailureKind {
  /// The person said no to the microphone.
  permissionDenied,

  /// The language's model is not downloaded.
  noModel,

  /// The engine or the microphone failed.
  failed,
}

class SpeechFailure implements Exception {
  const SpeechFailure(this.kind, [this.detail]);

  final SpeechFailureKind kind;
  final String? detail;

  @override
  String toString() => 'SpeechFailure(${kind.name}${detail == null ? '' : ', $detail'})';
}

/// The phone's speech engine.
final speechEngineProvider = Provider<SpeechEngine>(
  (ref) =>
      VoskEngine(channel: ref.watch(voiceChannelProvider), models: ref.watch(modelStoreProvider)),
);
