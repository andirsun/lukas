import 'dart:async';

import 'package:dio/dio.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/capture/capture_repository.dart';
import 'package:lukitas/capture/engine/speech_engine.dart';
import 'package:lukitas/capture/models_download.dart';
import 'package:lukitas/capture/parser/parse.dart' show Draft, Kind;
import 'package:lukitas/home/home_repository.dart';

import '../home/fakes.dart';

/// A speech engine that "hears" fixed transcripts instead of audio.
class FakeSpeechEngine implements SpeechEngine {
  FakeSpeechEngine({this.transcripts = const [], this.failure, this.availableAnswer = true});

  /// What each listen hears, in order: partials, then the final transcript.
  List<List<String>> transcripts;

  /// What the next listen fails with instead (then cleared).
  SpeechFailure? failure;
  bool availableAnswer;
  var listens = 0;
  var stops = 0;

  @override
  Future<bool> available() async => availableAnswer;

  @override
  Stream<String> listen({required String locale}) async* {
    listens++;
    final failed = failure;
    if (failed != null) {
      failure = null;
      throw failed;
    }
    final heard = transcripts.isEmpty ? <String>[''] : transcripts.removeAt(0);
    for (final text in heard) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      yield text;
    }
  }

  @override
  Future<void> stop() async => stops++;
}

/// The batch routes in memory, on top of the same movements the fake home repository serves.
/// Like the real API, a batch with a key it has already seen answers with the first rows.
class FakeCaptureRepository implements CaptureRepository {
  FakeCaptureRepository(this.server);

  final FakeHomeRepository server;
  final calls = <String>[];
  final keys = <String>[];
  final _byKey = <String, List<Transaction>>{};
  var _next = 0;

  /// The next save reaches the server and is saved, but its answer never comes back.
  var loseNextAnswer = false;

  /// What the next call of that name throws (then cleared), before anything is saved.
  final failures = <String, Object>{};

  @override
  Future<List<Transaction>> saveBatch(List<Draft> drafts, {required String idempotencyKey}) async {
    calls.add('save $idempotencyKey ${drafts.map((d) => '${d.name}:${d.amount}').join(',')}');
    keys.add(idempotencyKey);
    final failure = failures.remove('save');
    if (failure != null) throw failure;
    final saved = _byKey[idempotencyKey] ??= [
      for (final d in drafts)
        Transaction(
          (b) => b
            ..id = 'batch-${++_next}'
            ..name = d.name
            ..amount = d.kind == Kind.expense ? -d.amount : d.amount
            ..currency = server.currency
            ..date = d.date
            ..status = TransactionStatusEnum.paid
            ..categoryId = d.categoryId
            ..source_ = TransactionSource_Enum.app
            ..createdAt = '2026-10-22T10:00:00.000Z'
            ..updatedAt = '2026-10-22T10:00:00.000Z',
        ),
    ];
    for (final tx in saved) {
      if (!server.items.any((t) => t.id == tx.id)) server.items.add(tx);
    }
    server.items.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });
    if (loseNextAnswer) {
      loseNextAnswer = false;
      throw const HomeFailure(0);
    }
    return saved;
  }

  @override
  Future<void> undoBatch(List<String> ids) async {
    calls.add('undo ${ids.join(',')}');
    final failure = failures.remove('undo');
    if (failure != null) throw failure;
    server.items.removeWhere((t) => ids.contains(t.id));
  }
}

/// A model store whose download "succeeds" at once (or fails), with no files.
class FakeModelStore extends ModelStore {
  FakeModelStore() : super(files: _NoFiles(), http: Dio());

  var downloads = 0;
  ModelDownloadFailure? failure;

  @override
  Future<String?> installedPath(String locale) async => null;

  @override
  Future<void> download(
    String locale, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancel,
  }) async {
    downloads++;
    final total = modelFor(locale).bytes;
    onProgress?.call(total ~/ 2, total);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final failed = failure;
    if (failed != null) {
      failure = null;
      throw failed;
    }
    onProgress?.call(total, total);
  }
}

class _NoFiles implements ModelFiles {
  @override
  Future<String> modelsDirectory() async => '/nowhere';

  @override
  Future<void> releaseModels() async {}

  @override
  Future<void> unzip(String zip, String into) async {}
}
