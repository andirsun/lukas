import 'dart:async';

import 'package:flutter/services.dart';

import '../models_download.dart';
import 'grammar.dart';
import 'merge.dart';
import 'speech_engine.dart';
import 'voice_channel.dart';

/// How long a pause after some words ends listening.
const endOfSpeechPause = Duration(milliseconds: 1500);

/// Listening ends when nothing at all is heard for this long.
const nothingHeardLimit = Duration(seconds: 8);

/// The longest a sentence is listened to.
const longestListen = Duration(seconds: 30);

/// The voice spike's engine (docs/superpowers/reports/2026-10-22-stage-3-voice-spike.md): Vosk
/// small, on the phone, with no network. Two recognizers share one model while the person speaks,
/// a free one and one biased by a grammar of amount, kind, date and separator words (grammar.dart);
/// their words are merged by timestamps with rule v2 (merge.dart), and the merged text goes to the
/// rules parser unchanged. Every result at an endpoint is kept, not only the final one: the grammar
/// pass hits endpoints mid-sentence.
class VoskEngine implements SpeechEngine {
  VoskEngine({required this._channel, required this._models});

  final VoicePlatform _channel;
  final ModelStore _models;
  _Session? _session;

  @override
  Future<bool> available() => _channel.supported();

  @override
  Stream<String> listen({required String locale}) {
    final session = _Session(_channel, locale);
    _session = session;
    session.out = StreamController<String>(
      onListen: () => unawaited(session.begin(_models)),
      onCancel: session.cancel,
    );
    return session.out.stream;
  }

  @override
  Future<void> stop() async => _session?.stop();
}

class _Session {
  _Session(this._channel, this._locale);

  final VoicePlatform _channel;
  final String _locale;
  late final StreamController<String> out;
  StreamSubscription<VoiceEvent>? _events;
  final _free = <HeardWord>[];
  final _grammar = <HeardWord>[];
  var _partial = '';
  var _stopping = false;

  /// Nobody listens any more (the sheet closed), maybe before recording even started.
  var _cancelled = false;
  Timer? _pause;
  Timer? _nothing;
  Timer? _longest;

  Future<void> begin(ModelStore models) async {
    try {
      final path = await models.installedPath(_locale);
      if (path == null) throw const SpeechFailure(SpeechFailureKind.noModel);
      final granted = await _channel.requestPermission();
      if (!granted) throw const SpeechFailure(SpeechFailureKind.permissionDenied);
      if (out.isClosed || _cancelled) return;
      _nothing = Timer(nothingHeardLimit, () => unawaited(stop()));
      _longest = Timer(longestListen, () => unawaited(stop()));
      _events = _channel
          .start(modelPath: path, grammar: grammarJson(_locale))
          .listen(_onEvent, onError: _fail, onDone: _finish);
    } on SpeechFailure catch (failure) {
      _fail(failure);
    } on PlatformException catch (error) {
      _fail(SpeechFailure(SpeechFailureKind.failed, error.code));
    }
  }

  String get _merged => mergePasses(_free, _grammar, _locale);

  void _onEvent(VoiceEvent event) {
    if (out.isClosed) return;
    switch (event) {
      case VoicePartial(:final text):
        _partial = text;
        if (text.trim().isNotEmpty) {
          _nothing?.cancel();
          _pause?.cancel();
        }
        final heard = [_merged, text].where((t) => t.isNotEmpty).join(' ');
        if (heard.isNotEmpty) out.add(heard);
      case VoiceResult(:final pass, :final json):
        final words = wordsOfResult(json);
        (pass == VoicePass.free ? _free : _grammar).addAll(words);
        if (pass == VoicePass.free) {
          _partial = '';
          if (words.isNotEmpty) {
            _nothing?.cancel();
            _pause?.cancel();
            _pause = Timer(endOfSpeechPause, () => unawaited(stop()));
          }
        }
      case VoiceDone():
        _finish();
      case VoiceError(:final code):
        _fail(SpeechFailure(SpeechFailureKind.failed, code));
    }
  }

  void _fail(Object error) {
    _cancelTimers();
    if (out.isClosed) return;
    out.addError(
      error is SpeechFailure ? error : SpeechFailure(SpeechFailureKind.failed, '$error'),
    );
    unawaited(out.close());
    unawaited(_events?.cancel());
  }

  void _finish() {
    _cancelTimers();
    if (out.isClosed) return;
    _free.sort((a, b) => a.start.compareTo(b.start));
    _grammar.sort((a, b) => a.start.compareTo(b.start));
    final text = _merged;
    out.add(text.isEmpty ? _partial : text);
    unawaited(out.close());
    unawaited(_events?.cancel());
  }

  Future<void> stop() async {
    _cancelTimers();
    if (_stopping || out.isClosed || _events == null) return;
    _stopping = true;
    await _channel.stop();
  }

  Future<void> cancel() async {
    _cancelled = true;
    _cancelTimers();
    // Cancelling the platform stream stops the recording (VoiceChannel.kt, onCancel).
    await _events?.cancel();
  }

  void _cancelTimers() {
    _pause?.cancel();
    _nothing?.cancel();
    _longest?.cancel();
  }
}
