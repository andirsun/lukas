import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/settings/licenses.dart';

Future<List<LicenseEntry>> _extras() => extraLicenseEntries(rootBundle).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the licences About adds to Flutter\'s', () {
    test('the voice models are listed by name, with the Apache-2.0 text', () async {
      final entries = await _extras();
      for (final model in ['vosk-model-small-es-0.42', 'vosk-model-small-en-us-0.15']) {
        final entry = entries.singleWhere((e) => e.packages.contains(model));
        final text = entry.paragraphs.map((p) => p.text).join('\n');
        expect(text, contains('Apache License'), reason: model);
        expect(text, contains('Version 2.0, January 2004'), reason: model);
        expect(text, contains('alphacephei.com/vosk/models'), reason: model);
      }
    });

    test('the sounds say they are original work under the app\'s own licence, AGPL-3.0', () async {
      final entries = await _extras();
      final sounds = entries.singleWhere((e) => e.packages.contains('Lukitas feedback sounds'));
      final text = sounds.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('original work'));
      expect(text, contains('GNU AFFERO GENERAL PUBLIC LICENSE'));
    });

    test('the speech engine, its JNA bridge and the Android libraries are there too', () async {
      final packages = [for (final e in await _extras()) ...e.packages];
      for (final name in [
        'vosk-android 0.3.75',
        'JNA 5.18.1',
        'AndroidX',
        'Kotlin standard library',
        'Tink',
        'Gson',
        'ReLinker',
      ]) {
        expect(packages, contains(name));
      }
    });

    test('every entry has some text and at least one package name', () async {
      for (final entry in await _extras()) {
        expect(entry.packages, isNotEmpty);
        expect(entry.paragraphs.map((p) => p.text).join().length, greaterThan(200));
      }
    });

    test('registering twice does not list anything twice', () async {
      registerExtraLicenses();
      registerExtraLicenses();
      final models = <LicenseEntry>[];
      await for (final entry in LicenseRegistry.licenses) {
        if (entry.packages.contains('vosk-model-small-es-0.42')) models.add(entry);
      }
      expect(models, hasLength(1));
    });
  });
}
