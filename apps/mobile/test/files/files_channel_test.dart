import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/files/files_channel.dart';

/// `lukitas/files` (android/.../files/FilesChannel.kt) as Dart talks to it: the arguments it sends
/// and what it makes of the answers. The Kotlin side has its own tests and the emulator one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('lukitas/files');
  final calls = <MethodCall>[];

  void answer(Future<Object?> Function(MethodCall call) handler) {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) {
        calls.add(call);
        return handler(call);
      },
    );
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  const files = MethodFilesChannel();

  test('pickFile asks for the types and the limit, and returns the name and the bytes', () async {
    answer(
      (_) async => {
        'name': 'budge.csv',
        'bytes': Uint8List.fromList([1, 2, 3]),
      },
    );
    final picked = await files.pickFile(mimeTypes: const ['text/csv'], maxBytes: 5 * 1024 * 1024);
    expect(picked?.name, 'budge.csv');
    expect(picked?.bytes, Uint8List.fromList([1, 2, 3]));
    expect(calls.single.method, 'pick');
    expect(calls.single.arguments, {
      'mimeTypes': ['text/csv'],
      'maxBytes': 5 * 1024 * 1024,
    });
  });

  test('a closed picker is no file and no error', () async {
    answer((_) async => null);
    expect(await files.pickFile(mimeTypes: const ['text/csv']), isNull);
  });

  test('a file over the limit is a too-large failure', () async {
    answer((_) async => throw PlatformException(code: 'too-large'));
    await expectLater(
      files.pickFile(mimeTypes: const ['text/csv']),
      throwsA(isA<FilesFailure>().having((f) => f.kind, 'kind', FilesFailureKind.tooLarge)),
    );
  });

  test('every other failure keeps its kind', () async {
    for (final (code, kind) in [
      ('unreadable', FilesFailureKind.unreadable),
      ('unavailable', FilesFailureKind.unavailable),
      ('busy', FilesFailureKind.busy),
      ('write-failed', FilesFailureKind.unreadable),
      ('anything-else', FilesFailureKind.unreadable),
    ]) {
      answer((_) async => throw PlatformException(code: code));
      await expectLater(
        files.pickFile(mimeTypes: const ['text/csv']),
        throwsA(isA<FilesFailure>().having((f) => f.kind, 'kind', kind)),
        reason: code,
      );
    }
  });

  test('a phone without the channel says the picker is unavailable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => throw MissingPluginException(),
    );
    await expectLater(
      files.pickFile(mimeTypes: const ['text/csv']),
      throwsA(isA<FilesFailure>().having((f) => f.kind, 'kind', FilesFailureKind.unavailable)),
    );
  });

  test('saveFile sends the name, the bytes and the type; true when it was saved', () async {
    answer((_) async => true);
    final saved = await files.saveFile('lukitas.csv', Uint8List.fromList([9]), 'text/csv');
    expect(saved, isTrue);
    expect(calls.single.method, 'save');
    expect(calls.single.arguments, {
      'name': 'lukitas.csv',
      'bytes': Uint8List.fromList([9]),
      'mime': 'text/csv',
    });
  });

  test('a closed save picker is false', () async {
    answer((_) async => false);
    expect(await files.saveFile('a.csv', Uint8List(0), 'text/csv'), isFalse);
  });

  test('shareFile hands the file to the share sheet', () async {
    answer((_) async => true);
    expect(await files.shareFile('a.json', Uint8List.fromList([1]), 'application/json'), isTrue);
    expect(calls.single.method, 'share');
    expect(calls.single.arguments, {
      'name': 'a.json',
      'bytes': Uint8List.fromList([1]),
      'mime': 'application/json',
    });
  });

  test('a failed save or share throws a FilesFailure', () async {
    answer((_) async => throw PlatformException(code: 'write-failed'));
    await expectLater(
      files.saveFile('a.csv', Uint8List(0), 'text/csv'),
      throwsA(isA<FilesFailure>()),
    );
    await expectLater(
      files.shareFile('a.csv', Uint8List(0), 'text/csv'),
      throwsA(isA<FilesFailure>()),
    );
  });
}
