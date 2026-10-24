// On an Android emulator, no dev stack needed (docs/mobile/setup.md):
//
//   flutter test integration_test/settings_test.dart -d emulator-5554
//
// The licences About adds to Flutter's are registered when the app starts, and "Más en la web"
// hands only http, https and mailto addresses to Android. (The Dart packages' own licences are collected
// by `flutter build`, which tests never run: scripts/check-licenses.sh checks them in the release
// APK.)
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lukitas/main.dart' as app;
import 'package:lukitas/settings/url_opener.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('About lists the voice models\' and the sounds\' licences, read from the APK', (
    tester,
  ) async {
    // The app's start registers them; nothing needs to be drawn.
    await app.bootstrap();
    final entries = await LicenseRegistry.licenses.toList();
    final packages = {for (final entry in entries) ...entry.packages};

    for (final extra in [
      'vosk-model-small-es-0.42',
      'vosk-model-small-en-us-0.15',
      'vosk-android 0.3.75',
      'JNA 5.18.1',
      'Lukitas feedback sounds',
    ]) {
      expect(packages, contains(extra));
    }
    // The Android libraries come from the release classpath's POMs, each at its own version.
    for (final library in [
      'androidx.core:core ',
      'androidx.glance:glance-appwidget-external-protobuf ',
      'org.jspecify:jspecify ',
    ]) {
      expect(packages.any((p) => p.startsWith(library)), isTrue, reason: library);
    }
    final model = entries.firstWhere((e) => e.packages.contains('vosk-model-small-es-0.42'));
    expect(model.paragraphs.map((p) => p.text).join('\n'), contains('Apache License'));
  });

  testWidgets('"Más en la web" only ever hands http and https addresses to Android', (
    tester,
  ) async {
    await app.bootstrap();
    // Anything else is refused by MainActivity before an intent exists. (A real address is not
    // opened here: it would take a browser to the front in the middle of the run.)
    expect(await const ChannelUrlOpener().open(Uri.parse('intent://x#Intent;end')), isFalse);
    expect(await const ChannelUrlOpener().open(Uri.parse('file:///etc/hosts')), isFalse);
    expect(await const ChannelUrlOpener().open(Uri.parse('market://details?id=x')), isFalse);
  });

  testWidgets(
    'MainActivity itself refuses javascript:, intent: and the like, and knows its version',
    (tester) async {
      await app.bootstrap();
      // The channel asked directly, as a compromised Dart side would: the Android side checks too.
      const channel = MethodChannel('lukitas/device');
      for (final address in [
        'javascript:alert(1)',
        'intent:#Intent;action=android.intent.action.CALL;end',
        'file:///etc/hosts',
        'content://com.android.contacts/contacts',
        'tel:+34600000000',
        'sms:+34600000000',
        ' mailto:a@b.co',
      ]) {
        expect(await channel.invokeMethod<bool>('openUrl', address), isFalse, reason: address);
      }
      // The version the email to the founder carries.
      expect(await channel.invokeMethod<String>('appVersion'), isNotEmpty);
    },
  );
}
