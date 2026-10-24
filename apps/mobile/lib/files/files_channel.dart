import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A document the person picked: its name and everything in it.
class PickedFile {
  const PickedFile(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

/// Why a file did not come or go.
enum FilesFailureKind {
  /// The document is larger than the limit asked for. Nothing past the limit was read.
  tooLarge,

  /// It could not be opened, read or written.
  unreadable,

  /// This phone has no document picker (or share sheet) to ask.
  unavailable,

  /// Another pick or save is still open.
  busy,
}

class FilesFailure implements Exception {
  const FilesFailure(this.kind);

  final FilesFailureKind kind;

  @override
  String toString() => 'FilesFailure($kind)';
}

/// Files in and out of the app, through the system's own pickers and nothing else: the document
/// picker to choose a file (`ACTION_OPEN_DOCUMENT`) or a place to save one
/// (`ACTION_CREATE_DOCUMENT`), and the share sheet (`ACTION_SEND` with a link the app grants to that
/// one file). No storage permission, no plugin: android/.../files/FilesChannel.kt. The import uses
/// [pickFile]; the export uses [saveFile] and [shareFile].
abstract interface class FilesChannel {
  /// The limit [pickFile] reads up to when none is given: the API's (apps/api routes/imports.ts
  /// `MAX_BYTES`, 5 MB).
  static const defaultMaxBytes = 5 * 1024 * 1024;

  /// Shows the document picker for [mimeTypes] and reads the one document chosen, never past
  /// [maxBytes] (a larger one throws [FilesFailureKind.tooLarge]). Null when the person closed the
  /// picker.
  Future<PickedFile?> pickFile({required List<String> mimeTypes, int maxBytes = defaultMaxBytes});

  /// Shows the "save as" picker and writes [bytes] where the person chooses. False when they closed
  /// it.
  Future<bool> saveFile(String name, Uint8List bytes, String mime);

  /// Shows the share sheet for a copy of [bytes] named [name]. True once it is up.
  Future<bool> shareFile(String name, Uint8List bytes, String mime);
}

/// [FilesChannel] over `lukitas/files`.
class MethodFilesChannel implements FilesChannel {
  const MethodFilesChannel();

  static const _channel = MethodChannel('lukitas/files');

  static Future<T?> _call<T>(String method, Map<String, Object?> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      throw const FilesFailure(FilesFailureKind.unavailable);
    } on PlatformException catch (error) {
      throw FilesFailure(switch (error.code) {
        'too-large' => FilesFailureKind.tooLarge,
        'unavailable' => FilesFailureKind.unavailable,
        'busy' => FilesFailureKind.busy,
        _ => FilesFailureKind.unreadable,
      });
    }
  }

  @override
  Future<PickedFile?> pickFile({
    required List<String> mimeTypes,
    int maxBytes = FilesChannel.defaultMaxBytes,
  }) async {
    final picked = await _call<Map<Object?, Object?>>('pick', {
      'mimeTypes': mimeTypes,
      'maxBytes': maxBytes,
    });
    if (picked == null) return null;
    final bytes = picked['bytes'];
    final name = picked['name'];
    if (bytes is! Uint8List || name is! String) {
      throw const FilesFailure(FilesFailureKind.unreadable);
    }
    return PickedFile(name, bytes);
  }

  @override
  Future<bool> saveFile(String name, Uint8List bytes, String mime) async =>
      await _call<bool>('save', {'name': name, 'bytes': bytes, 'mime': mime}) ?? false;

  @override
  Future<bool> shareFile(String name, Uint8List bytes, String mime) async =>
      await _call<bool>('share', {'name': name, 'bytes': bytes, 'mime': mime}) ?? false;
}

/// The phone's files (replaced in tests).
final filesChannelProvider = Provider<FilesChannel>((ref) => const MethodFilesChannel());
