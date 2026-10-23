// The voice models: not in the APK, downloaded on first 🎤 use after an opt-in that shows the size
// (founder ruling, Task 12). Each is the official Vosk zip, re-published as an asset of this
// repo's GitHub release `voice-models-v1`, checked against the SHA-256 below before it is ever
// unzipped or loaded. A download cut short resumes where it stopped.
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'engine/voice_channel.dart';

/// Where the models are downloaded from: this repo's release, one zip per model.
final voiceModelsReleaseUrl = Uri.parse(
  'https://github.com/andirsun/lukas/releases/download/voice-models-v1',
);

/// One language's Vosk model (Apache-2.0, https://alphacephei.com/vosk/models).
class VoiceModel {
  const VoiceModel({
    required this.locale,
    required this.name,
    required this.bytes,
    required this.unzippedBytes,
    required this.sha256,
  });

  /// `es` or `en`.
  final String locale;

  /// The model's name, which is also its zip's name and the one folder inside it.
  final String name;

  /// The zip's size, shown before anything is downloaded.
  final int bytes;

  /// The model's size once unzipped (the sum of the zip's entries): checked as free space first.
  final int unzippedBytes;

  /// The zip's SHA-256, lowercase hex: of the official file, published unchanged.
  final String sha256;

  String get fileName => '$name.zip';
}

/// The models, by language: the voice spike's choice (Vosk small).
const voiceModels = {
  'es': VoiceModel(
    locale: 'es',
    name: 'vosk-model-small-es-0.42',
    bytes: 39817833,
    unzippedBytes: 60286598,
    sha256: '09b239888f633ef2f0b4e09736e3d9936acfd810bc65d53fad45261762c6511f',
  ),
  'en': VoiceModel(
    locale: 'en',
    name: 'vosk-model-small-en-us-0.15',
    bytes: 41205931,
    unzippedBytes: 70898967,
    sha256: '30f26242c4eb449f948e42cb302dd7a686cb29a3423a8367f99ff41780942498',
  ),
};

/// A download that did not end with a model ready to use.
class ModelDownloadFailure implements Exception {
  const ModelDownloadFailure({this.corrupt = false, this.cancelled = false, this.noSpace = false});

  /// The file was complete but not the published one (its SHA-256 differs); it was deleted.
  final bool corrupt;

  /// The person stopped it. What came is kept, to resume.
  final bool cancelled;

  /// The phone has too little free space for the zip and the unzipped model; nothing was fetched.
  final bool noSpace;

  @override
  String toString() =>
      'ModelDownloadFailure(corrupt: $corrupt, cancelled: $cancelled, noSpace: $noSpace)';
}

/// Where models live on the phone, and what Dart cannot do on its own there.
abstract interface class ModelFiles {
  /// An app-private directory (no backup) for the models.
  Future<String> modelsDirectory();

  /// Unzips [zip] into the directory [into].
  Future<void> unzip(String zip, String into);

  /// Frees a model the recognizer has loaded (before its files are deleted).
  Future<void> releaseModels();

  /// The bytes free where the models go.
  Future<int> freeBytes();
}

/// The downloaded models: which are ready, getting one, deleting them all.
class ModelStore {
  ModelStore({
    required this._files,
    required this._http,
    Uri? releaseUrl,
    this._models = voiceModels,
  }) : _releaseUrl = releaseUrl ?? voiceModelsReleaseUrl;

  final ModelFiles _files;

  /// A plain client: never the API's, which carries the session token.
  final Dio _http;
  final Uri _releaseUrl;
  final Map<String, VoiceModel> _models;
  final _running = <String, Future<void>>{};

  /// The model for [locale]: English for `en`, Spanish otherwise (as the app's language).
  VoiceModel modelFor(String locale) => _models[locale] ?? _models['es']!;

  Future<String> _voiceDir() async => '${await _files.modelsDirectory()}/voice';

  /// The model's folder, when it is downloaded, verified and unzipped; otherwise null.
  Future<String?> installedPath(String locale) async {
    final model = modelFor(locale);
    final dir = await _voiceDir();
    final ready = File('$dir/${model.name}.ready');
    if (!ready.existsSync() || (await ready.readAsString()).trim() != model.sha256) return null;
    final path = '$dir/${model.name}';
    return Directory(path).existsSync() ? path : null;
  }

  /// Downloads [locale]'s model, resuming a partial file, verifies its SHA-256, unzips it and marks
  /// it ready. [onProgress] gets the bytes so far (resumed ones included) and the total. Throws a
  /// [ModelDownloadFailure]. A second call while one runs joins it.
  Future<void> download(
    String locale, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancel,
  }) {
    final model = modelFor(locale);
    return _running[model.name] ??= _download(model, onProgress, cancel).whenComplete(() {
      // A block, not `=>`: remove returns this very future, which whenComplete would wait for.
      _running.remove(model.name);
    });
  }

  Future<void> _download(
    VoiceModel model,
    void Function(int received, int total)? onProgress,
    CancelToken? cancel,
  ) async {
    try {
      await _fetchAndInstall(model, onProgress, cancel);
    } on ModelDownloadFailure {
      rethrow;
    } on DioException catch (error) {
      throw ModelDownloadFailure(cancelled: CancelToken.isCancel(error));
    } on Object {
      // Anything else (a full disk, a file that cannot be written or read) ends the same way: the
      // offer comes back with Reintentar. What came is kept; it is never used unverified.
      throw ModelDownloadFailure(cancelled: cancel?.isCancelled ?? false);
    }
  }

  Future<void> _fetchAndInstall(
    VoiceModel model,
    void Function(int received, int total)? onProgress,
    CancelToken? cancel,
  ) async {
    final dir = await _voiceDir();
    await Directory(dir).create(recursive: true);
    final part = File('$dir/${model.fileName}.part');
    var from = part.existsSync() ? part.lengthSync() : 0;
    if (from > model.bytes) {
      await part.delete();
      from = 0;
    }
    // Room for the rest of the zip and the unzipped model, which exist together for a moment.
    if (await _files.freeBytes() < model.bytes - from + model.unzippedBytes) {
      throw const ModelDownloadFailure(noSpace: true);
    }

    if (from < model.bytes) {
      final response = await _http.getUri<ResponseBody>(
        _releaseUrl.replace(path: '${_releaseUrl.path}/${model.fileName}'),
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.stream,
          headers: {if (from > 0) HttpHeaders.rangeHeader: 'bytes=$from-'},
          validateStatus: (status) => status == 200 || status == 206 || status == 416,
        ),
      );
      // 416: nothing left to send, the file is whole; check it below.
      if (response.statusCode != 416) {
        // 200: the whole file again (the server ignored Range), so it starts over.
        if (response.statusCode == 200) from = 0;
        if (response.statusCode == 206 && _rangeStart(response.headers) != from) {
          // Not the bytes that come next: appending them would spoil the file. Start over.
          await part.delete();
          throw const ModelDownloadFailure();
        }
        final sink = part.openWrite(mode: from == 0 ? FileMode.write : FileMode.append);
        var received = from;
        try {
          onProgress?.call(received, model.bytes);
          await for (final chunk in response.data!.stream) {
            // Never more than the model's size, whatever the server sends.
            final room = model.bytes - received;
            sink.add(chunk.length <= room ? chunk : chunk.sublist(0, room));
            received += chunk.length <= room ? chunk.length : room;
            onProgress?.call(received, model.bytes);
            if (received >= model.bytes) break;
          }
        } finally {
          // Write errors (a full disk) surface here; the catch in _download maps them.
          await sink.close();
        }
      }
    }

    final digest = await sha256.bind(part.openRead()).first;
    if (digest.toString() != model.sha256) {
      await part.delete();
      throw const ModelDownloadFailure(corrupt: true);
    }
    final target = Directory('$dir/${model.name}');
    if (target.existsSync()) await target.delete(recursive: true);
    // Unzipped under a temporary name first, so a half-unzipped model is never taken for one.
    final staging = Directory('$dir/.unzip-${model.name}');
    if (staging.existsSync()) await staging.delete(recursive: true);
    await staging.create(recursive: true);
    try {
      await _files.unzip(part.path, staging.path);
      await Directory('${staging.path}/${model.name}').rename(target.path);
    } finally {
      if (staging.existsSync()) await staging.delete(recursive: true);
    }
    await File('$dir/${model.name}.ready').writeAsString(model.sha256, flush: true);
    await part.delete();
  }

  /// The first byte of a 206 answer (`Content-Range: bytes <start>-<end>/<size>`), or null.
  static int? _rangeStart(Headers headers) {
    final value = headers.value(HttpHeaders.contentRangeHeader);
    final match = value == null ? null : RegExp(r'^bytes (\d+)-').firstMatch(value.trim());
    return match == null ? null : int.parse(match.group(1)!);
  }

  /// Deletes every downloaded model (and partial download), freeing a loaded one first. Settings
  /// calls it (Task 14); the next 🎤 asks to download again.
  Future<void> deleteModels() async {
    await _files.releaseModels();
    final dir = Directory(await _voiceDir());
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}

/// The phone's model store.
final modelStoreProvider = Provider<ModelStore>(
  (ref) => ModelStore(
    files: ref.watch(voiceChannelProvider),
    http: Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        // Between two chunks of the body, not for the whole file.
        receiveTimeout: const Duration(seconds: 30),
      ),
    ),
  ),
);

/// Deletes the downloaded voice models (Settings, Task 14, adds the button).
Future<void> deleteModels(WidgetRef ref) => ref.read(modelStoreProvider).deleteModels();
