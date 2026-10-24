import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens an address in the phone's browser.
abstract interface class UrlOpener {
  /// True when a browser took it; false when there is none (or the address is not http or https).
  Future<bool> open(Uri url);
}

/// [UrlOpener] over the `lukitas/device` channel (MainActivity.kt): an `ACTION_VIEW` intent, the
/// same a link in any other app sends. No package for it, so nothing new in the dependency tree.
class ChannelUrlOpener implements UrlOpener {
  const ChannelUrlOpener();

  static const _channel = MethodChannel('lukitas/device');

  @override
  Future<bool> open(Uri url) async {
    try {
      return await _channel.invokeMethod<bool>('openUrl', url.toString()) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

final urlOpenerProvider = Provider<UrlOpener>((ref) => const ChannelUrlOpener());
