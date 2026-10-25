import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the phone is asked to open: web pages, and an email to write (`mailto:`). Anything else
/// (`javascript:`, `intent:`, `file:`, `content:`, `tel:`...) is refused, here and again on the Android
/// side (android/.../ExternalLinks.kt).
const openableSchemes = {'http', 'https', 'mailto'};

/// Opens an address in the phone's browser, or its email app.
abstract interface class UrlOpener {
  /// True when an app took it; false when there is none (or the address is not an http, https or
  /// mailto one).
  Future<bool> open(Uri url);
}

/// [UrlOpener] over the `lukitas/device` channel (MainActivity.kt): an `ACTION_VIEW` intent for a
/// page, an `ACTION_SENDTO` one for mail; the same a link in any other app sends. No package for it,
/// so nothing new in the dependency tree.
class ChannelUrlOpener implements UrlOpener {
  const ChannelUrlOpener();

  static const _channel = MethodChannel('lukitas/device');

  @override
  Future<bool> open(Uri url) async {
    if (!openableSchemes.contains(url.scheme.toLowerCase())) return false;
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
