import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/preferences.dart';
import 'capture_note.dart';
import 'engine/speech_engine.dart';
import 'models_download.dart';

/// The language the voice model is for: English for an English app, Spanish otherwise (as the app's
/// own language, and as `_CaptureSheetState._locale` decides it).
String voiceLocale(Locale? chosen) =>
    (chosen ?? WidgetsBinding.instance.platformDispatcher.locale).languageCode == 'en' ? 'en' : 'es';

/// Loads the speech model in the background so a tap on 🎤 starts listening at once (the app's own,
/// the widget's, the tile's): when the app starts and each time it comes back to the front. Only
/// for someone who has captured before (the first-use note is off), and only when the model is
/// downloaded. It only loads: recording starts on the person's tap, and the microphone is let go
/// when the app goes to the background as ever. Kotlin keeps the model while the process lives and
/// frees it on memory pressure or when the models are deleted.
class VoicePrewarm with WidgetsBindingObserver {
  VoicePrewarm(this._ref);

  final Ref _ref;

  void _start() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(warm());
  }

  void _stop() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(warm());
  }

  /// Loads the model now, if it is wanted and there is one. Never throws.
  Future<void> warm() async {
    try {
      final note = _ref.read(captureNoteProvider.notifier);
      await note.ready;
      // The note is on until the first capture: nothing is loaded before the person first uses it.
      if (_ref.read(captureNoteProvider)) return;
      final locale = voiceLocale(_ref.read(localeOverrideProvider));
      if (await _ref.read(modelStoreProvider).installedPath(locale) == null) return;
      await _ref.read(speechEngineProvider).warmUp(locale: locale);
    } on Object {
      // Not loaded in advance: the first tap loads it.
    }
  }
}

/// Started by the app at once (app.dart).
final voicePrewarmProvider = Provider<VoicePrewarm>((ref) {
  final prewarm = VoicePrewarm(ref).._start();
  ref.onDispose(prewarm._stop);
  return prewarm;
});
