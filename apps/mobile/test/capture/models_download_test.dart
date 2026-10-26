// The voice model download (lib/capture/models_download.dart) against a fake HTTP server on this
// machine, standing in for the repo's GitHub release (tag voice-models-v1), which does not exist
// yet. The server honours Range, can cut a download short, redirect, or ignore Range.
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/capture/models_download.dart';

/// A zip's bytes for the tests: what is in it does not matter, the unzip is faked.
final _payload = Uint8List.fromList(List<int>.generate(300 * 1024, (i) => (i * 31 + 7) % 251));

class _FakeServer {
  late final HttpServer _server;

  /// Every request: its path and Range header.
  final requests = <({String path, String? range})>[];

  /// The next response stops after this many body bytes, then the connection drops.
  int? cutAfter;

  /// Answers 200 with the whole file even when a Range is asked for.
  var ignoreRange = false;

  /// Sends `/release/...` to `/objects/...` with a 302 first, as GitHub does.
  var redirect = false;

  /// Sends the body in small pieces, slowly.
  var slow = false;

  /// A 206 answer says it starts here instead of where it was asked to.
  int? wrongRangeStart;

  Uint8List body = _payload;

  Uri get base => Uri.parse('http://127.0.0.1:${_server.port}/release');

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final range = request.headers.value(HttpHeaders.rangeHeader);
    requests.add((path: request.uri.path, range: range));
    final response = request.response;
    if (redirect && request.uri.path.startsWith('/release/')) {
      await response.redirect(
        request.uri.replace(path: request.uri.path.replaceFirst('/release/', '/objects/')),
        status: HttpStatus.found,
      );
      return;
    }
    var from = 0;
    var status = HttpStatus.ok;
    String? contentRange;
    final match = range == null ? null : RegExp(r'^bytes=(\d+)-$').firstMatch(range);
    if (match != null && !ignoreRange) {
      from = wrongRangeStart ?? int.parse(match.group(1)!);
      wrongRangeStart = null;
      if (from >= body.length) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        await response.close();
        return;
      }
      status = HttpStatus.partialContent;
      contentRange = 'bytes $from-${body.length - 1}/${body.length}';
    }
    final slice = body.sublist(from);
    final cut = cutAfter;
    if (cut != null) {
      cutAfter = null;
      // Raw HTTP, so the connection can drop mid-body.
      final socket = await response.detachSocket(writeHeaders: false);
      socket.write(
        'HTTP/1.1 $status X\r\n'
        'content-length: ${slice.length}\r\n'
        '${contentRange == null ? '' : 'content-range: $contentRange\r\n'}'
        'connection: close\r\n\r\n',
      );
      socket.add(slice.sublist(0, cut));
      await socket.flush();
      socket.destroy();
      return;
    }
    response.statusCode = status;
    if (contentRange != null) response.headers.set(HttpHeaders.contentRangeHeader, contentRange);
    response.contentLength = slice.length;
    if (slow) {
      for (var i = 0; i < slice.length; i += 16 * 1024) {
        response.add(slice.sublist(i, i + 16 * 1024 > slice.length ? slice.length : i + 16 * 1024));
        await response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await response.close();
      return;
    }
    response.add(slice);
    await response.close();
  }
}

class _FakeFiles implements ModelFiles {
  _FakeFiles(this.root);

  final Directory root;
  final unzipped = <String>[];
  var released = 0;

  /// Free space where the models go; null: unknown.
  int? free = 1 << 40;

  /// The free-space question fails outright.
  var freeFails = false;

  @override
  Future<int?> freeBytes() async {
    if (freeFails) throw StateError('statfs failed');
    return free;
  }

  @override
  Future<String> modelsDirectory() async => root.path;

  @override
  Future<void> unzip(String zip, String into) async {
    unzipped.add(zip);
    // The official zips hold one folder named after the model.
    final name = zip.split('/').last.replaceAll(RegExp(r'\.zip(\.part)?$'), '');
    await Directory('$into/$name/am').create(recursive: true);
  }

  @override
  Future<void> releaseModels() async => released++;
}

VoiceModel _model(Uint8List bytes) => VoiceModel(
  locale: 'es',
  name: 'vosk-model-small-es-0.42',
  bytes: bytes.length,
  unzippedBytes: bytes.length * 2,
  sha256: sha256.convert(bytes).toString(),
);

void main() {
  late _FakeServer server;
  late Directory root;
  late _FakeFiles files;

  setUp(() async {
    server = _FakeServer();
    await server.start();
    root = await Directory.systemTemp.createTemp('voice-models');
    files = _FakeFiles(root);
  });

  tearDown(() async {
    await server.close();
    await root.delete(recursive: true);
  });

  ModelStore store({VoiceModel? model}) => ModelStore(
    files: files,
    http: Dio(),
    releaseUrl: server.base,
    models: {'es': model ?? _model(_payload)},
  );

  test('the constants name this repo\'s release, one official zip per language', () {
    expect(
      voiceModelsReleaseUrl.toString(),
      'https://github.com/andirsun/lukas/releases/download/voice-models-v1',
    );
    expect(voiceModels['es']!.fileName, 'vosk-model-small-es-0.42.zip');
    expect(voiceModels['en']!.fileName, 'vosk-model-small-en-us-0.15.zip');
    for (final model in voiceModels.values) {
      expect(model.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(model.bytes, greaterThan(30 * 1000 * 1000));
      expect(model.unzippedBytes, greaterThan(model.bytes));
    }
  });

  test('nothing is installed at first; a download verifies, unzips and installs', () async {
    final s = store();
    expect(await s.installedPath('es'), isNull);
    final progress = <int>[];
    await s.download(
      'es',
      onProgress: (received, total) {
        expect(total, _payload.length);
        progress.add(received);
      },
    );
    expect(progress.last, _payload.length);
    expect(files.unzipped, hasLength(1));
    expect(await s.installedPath('es'), '${root.path}/voice/vosk-model-small-es-0.42');
    expect(server.requests.single.path, '/release/vosk-model-small-es-0.42.zip');
    // The zip is gone once unzipped: only the model takes room.
    expect(File('${root.path}/voice/vosk-model-small-es-0.42.zip.part').existsSync(), isFalse);
  });

  test('a download cut short resumes where it stopped (Range), and only the rest comes', () async {
    final s = store();
    server.cutAfter = 100 * 1024;
    await expectLater(s.download('es'), throwsA(isA<ModelDownloadFailure>()));
    expect(await s.installedPath('es'), isNull);
    final part = File('${root.path}/voice/vosk-model-small-es-0.42.zip.part');
    expect(part.lengthSync(), 100 * 1024);

    await s.download('es');
    expect(server.requests.last.range, 'bytes=${100 * 1024}-');
    expect(await s.installedPath('es'), isNotNull);
  });

  test('a server that ignores Range starts the file over instead of appending', () async {
    final s = store();
    server.cutAfter = 50 * 1024;
    await expectLater(s.download('es'), throwsA(isA<ModelDownloadFailure>()));
    server.ignoreRange = true;
    await s.download('es');
    expect(await s.installedPath('es'), isNotNull);
  });

  test('a redirect (GitHub sends release assets elsewhere) is followed', () async {
    server.redirect = true;
    await store().download('es');
    expect(server.requests.map((r) => r.path), [
      '/release/vosk-model-small-es-0.42.zip',
      '/objects/vosk-model-small-es-0.42.zip',
    ]);
  });

  test('a resume through the redirect still asks for the rest only', () async {
    server.redirect = true;
    final s = store();
    server.cutAfter = 120 * 1024;
    await expectLater(s.download('es'), throwsA(isA<ModelDownloadFailure>()));
    await s.download('es');
    expect(server.requests.last.path, '/objects/vosk-model-small-es-0.42.zip');
    expect(server.requests.last.range, 'bytes=${120 * 1024}-');
    expect(await s.installedPath('es'), isNotNull);
  });

  test('a file whose SHA-256 is not the constant is thrown away and never used', () async {
    server.body = Uint8List.fromList([..._payload]..[10] ^= 0xff);
    final s = store();
    await expectLater(
      s.download('es'),
      throwsA(isA<ModelDownloadFailure>().having((f) => f.corrupt, 'corrupt', isTrue)),
    );
    expect(files.unzipped, isEmpty);
    expect(await s.installedPath('es'), isNull);
    expect(File('${root.path}/voice/vosk-model-small-es-0.42.zip.part').existsSync(), isFalse);
  });

  test('a cancelled download keeps what came, to resume later', () async {
    final s = store();
    final cancel = CancelToken();
    server.slow = true;
    final done = s.download(
      'es',
      cancel: cancel,
      onProgress: (received, _) {
        if (received > 0) cancel.cancel();
      },
    );
    await expectLater(
      done,
      throwsA(isA<ModelDownloadFailure>().having((f) => f.cancelled, 'cancelled', isTrue)),
    );
    expect(await s.installedPath('es'), isNull);
    final kept = File('${root.path}/voice/vosk-model-small-es-0.42.zip.part').lengthSync();
    expect(kept, inExclusiveRange(0, _payload.length));
  });

  test('a file error while writing (a full disk, say) is a ModelDownloadFailure', () async {
    // The partial file's path is taken by a folder: writing fails, and the error surfaces when
    // the file is closed.
    await Directory('${root.path}/voice/vosk-model-small-es-0.42.zip.part').create(recursive: true);
    await expectLater(
      store().download('es'),
      throwsA(isA<ModelDownloadFailure>().having((f) => f.cancelled, 'cancelled', isFalse)),
    );
    expect(await store().installedPath('es'), isNull);
  });

  test('a models folder that cannot be made is a ModelDownloadFailure too', () async {
    await File('${root.path}/voice').writeAsString('not a folder');
    await expectLater(store().download('es'), throwsA(isA<ModelDownloadFailure>()));
  });

  test('not enough free space for the zip and the model refuses before downloading', () async {
    files.free = _payload.length * 2;
    await expectLater(
      store().download('es'),
      throwsA(isA<ModelDownloadFailure>().having((f) => f.noSpace, 'noSpace', isTrue)),
    );
    expect(server.requests, isEmpty);
    files.free = _payload.length * 3;
    await store().download('es');
    expect(await store().installedPath('es'), isNotNull);
  });

  test('free space unknown, or its question failing, goes ahead: the hash still guards', () async {
    files.free = null;
    await store().download('es');
    expect(await store().installedPath('es'), isNotNull);
    await store().deleteModels();
    files.freeFails = true;
    await store().download('es');
    expect(await store().installedPath('es'), isNotNull);
  });

  test(
    'a 206 that starts somewhere else than asked is refused, and the next try starts over',
    () async {
      final s = store();
      server.cutAfter = 100 * 1024;
      await expectLater(s.download('es'), throwsA(isA<ModelDownloadFailure>()));
      server.wrongRangeStart = 50 * 1024;
      await expectLater(s.download('es'), throwsA(isA<ModelDownloadFailure>()));
      await s.download('es');
      expect(server.requests.last.range, isNull, reason: 'started over');
      expect(await s.installedPath('es'), isNotNull);
    },
  );

  test('a server sending more than the model\'s size is cut at the size', () async {
    server.body = Uint8List.fromList([..._payload, ...List<int>.filled(64 * 1024, 7)]);
    // The model is the payload: what comes after it is never written.
    final s = store(model: _model(_payload));
    await s.download('es');
    expect(await s.installedPath('es'), isNotNull);
  });

  test('deleteModels removes every model and frees the loaded one', () async {
    final s = store();
    await s.download('es');
    await s.deleteModels();
    expect(await s.installedPath('es'), isNull);
    expect(Directory('${root.path}/voice').existsSync(), isFalse);
    expect(files.released, 1);
  });

  test('English phones get the English model', () async {
    final en = VoiceModel(
      locale: 'en',
      name: 'vosk-model-small-en-us-0.15',
      bytes: _payload.length,
      unzippedBytes: _payload.length * 2,
      sha256: sha256.convert(_payload).toString(),
    );
    final s = ModelStore(
      files: files,
      http: Dio(),
      releaseUrl: server.base,
      models: {'es': _model(_payload), 'en': en},
    );
    expect(s.modelFor('en')!.name, 'vosk-model-small-en-us-0.15');
    await s.download('en');
    expect(await s.installedPath('en'), isNotNull);
    expect(await s.installedPath('es'), isNull);
  });

  test('Italian and Portuguese have no model yet, and are never given the Spanish one', () async {
    final s = ModelStore(
      files: files,
      http: Dio(),
      releaseUrl: server.base,
      models: {'es': _model(_payload)},
    );
    // The Spanish model is on the phone: it is not the answer for anyone else.
    await s.download('es');
    expect(await s.installedPath('es'), isNotNull);
    for (final language in ['it', 'pt', 'fr']) {
      expect(s.hasModel(language), isFalse, reason: language);
      expect(s.modelFor(language), isNull, reason: language);
      expect(await s.installedPath(language), isNull, reason: language);
      await expectLater(
        s.download(language),
        throwsA(isA<ModelDownloadFailure>()),
        reason: language,
      );
    }
    expect(s.hasModel('es'), isTrue);
  });
}
