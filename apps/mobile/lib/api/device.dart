import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the API learns about the phone with every request: its IANA time zone
/// (`x-lukas-timezone`) and its language tag (`x-lukas-locale`). A new guest's profile, currency
/// included, starts from them (apps/api/src/auth.ts, `guestDefaults`).
class DeviceHints {
  const DeviceHints({required this.timezone, required this.locale});

  /// Until the phone has answered, and in tests: the API then falls back to UTC and Spanish.
  static const fallback = DeviceHints(timezone: 'UTC', locale: 'es');

  static const _channel = MethodChannel('lukitas/device');

  /// The phone's settings: the zone from Android (Dart only knows its abbreviation), the
  /// language as a BCP 47 tag such as `es-CO`, which also carries the region.
  static Future<DeviceHints> read() async {
    String? zone;
    try {
      zone = await _channel.invokeMethod<String>('timeZone');
    } on PlatformException {
      zone = null;
    } on MissingPluginException {
      zone = null;
    }
    return DeviceHints(
      timezone: (zone == null || zone.isEmpty) ? fallback.timezone : zone,
      locale: PlatformDispatcher.instance.locale.toLanguageTag(),
    );
  }

  final String timezone;
  final String locale;

  /// The request headers, as the API names them.
  Map<String, String> get headers => {'x-lukas-timezone': timezone, 'x-lukas-locale': locale};
}

/// The phone's [DeviceHints], read once at start (main.dart overrides this).
final deviceHintsProvider = Provider<DeviceHints>((ref) => DeviceHints.fallback);

/// The server the app talks to (spec section 6.1: changeable in settings later). A build can point
/// at another one with `--dart-define=LUKITAS_SERVER=http://10.0.2.2:3000` (the dev stack, seen
/// from the emulator).
final serverUrlProvider = Provider<Uri>(
  (ref) => Uri.parse(
    const String.fromEnvironment(
      'LUKITAS_SERVER',
      defaultValue: 'https://app-lukas.andersonlaverde.com',
    ),
  ),
);
