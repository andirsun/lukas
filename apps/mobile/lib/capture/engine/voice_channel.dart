import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models_download.dart';

/// Which of the two Vosk recognizers a result comes from.
enum VoicePass { free, grammar }

/// What the recording sends while it runs (android/.../voice/VoiceChannel.kt).
sealed class VoiceEvent {
  const VoiceEvent();

  /// The model is loaded and the microphone records: the person can start talking.
  const factory VoiceEvent.ready() = VoiceReady;

  /// The free pass's guess at the words being said right now.
  const factory VoiceEvent.partial(String text) = VoicePartial;

  /// A recognizer's result JSON at an endpoint, or at the end (`getResult()`/`getFinalResult()`).
  const factory VoiceEvent.result(VoicePass pass, String json) = VoiceResult;

  /// Recording has ended and both final results were sent.
  const factory VoiceEvent.done() = VoiceDone;

  /// The model or the microphone failed.
  const factory VoiceEvent.error(String code) = VoiceError;

  static VoiceEvent? fromMap(Object? map) {
    if (map is! Map) return null;
    return switch (map['type']) {
      'ready' => const VoiceEvent.ready(),
      'partial' => VoiceEvent.partial(map['text'] as String? ?? ''),
      'result' => VoiceEvent.result(
        map['pass'] == 'grammar' ? VoicePass.grammar : VoicePass.free,
        map['json'] as String? ?? '',
      ),
      'done' => const VoiceEvent.done(),
      'error' => VoiceEvent.error(map['code'] as String? ?? 'failed'),
      _ => null,
    };
  }
}

class VoiceReady extends VoiceEvent {
  const VoiceReady();
}

class VoicePartial extends VoiceEvent {
  const VoicePartial(this.text);
  final String text;
}

class VoiceResult extends VoiceEvent {
  const VoiceResult(this.pass, this.json);
  final VoicePass pass;
  final String json;
}

class VoiceDone extends VoiceEvent {
  const VoiceDone();
}

class VoiceError extends VoiceEvent {
  const VoiceError(this.code);
  final String code;
}

/// The Android side of listening: the microphone, the two recognizers, and the model files.
abstract interface class VoicePlatform implements ModelFiles {
  /// Whether Vosk's native library loads on this phone.
  Future<bool> supported();

  /// Asks for the microphone when it has not been granted yet; true when granted.
  Future<bool> requestPermission();

  /// Records (16 kHz mono PCM16, `VOICE_RECOGNITION`) into a free and a grammar-biased recognizer
  /// on the model at [modelPath], until [stop].
  Stream<VoiceEvent> start({required String modelPath, required String grammar});

  /// Stops recording: the final results follow, then [VoiceDone].
  Future<void> stop();
}

/// [VoicePlatform] over the `lukitas/voice` channels (VoiceChannel.kt).
class VoiceChannel implements VoicePlatform {
  const VoiceChannel();

  static const _methods = MethodChannel('lukitas/voice');
  static const _events = EventChannel('lukitas/voice/events');

  @override
  Future<bool> supported() async {
    try {
      return await _methods.invokeMethod<bool>('supported') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async =>
      await _methods.invokeMethod<bool>('requestPermission') ?? false;

  @override
  Stream<VoiceEvent> start({required String modelPath, required String grammar}) => _events
      .receiveBroadcastStream({'modelPath': modelPath, 'grammar': grammar})
      .map(VoiceEvent.fromMap)
      .where((e) => e != null)
      .cast<VoiceEvent>();

  @override
  Future<void> stop() => _methods.invokeMethod<void>('stop');

  @override
  Future<String> modelsDirectory() async =>
      (await _methods.invokeMethod<String>('modelsDirectory'))!;

  @override
  Future<void> unzip(String zip, String into) =>
      _methods.invokeMethod<void>('unzip', {'zip': zip, 'into': into});

  @override
  Future<void> releaseModels() => _methods.invokeMethod<void>('releaseModels');

  @override
  Future<int> freeBytes() async => (await _methods.invokeMethod<int>('freeBytes'))!;
}

final voiceChannelProvider = Provider<VoicePlatform>((ref) => const VoiceChannel());
