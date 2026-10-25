import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/settings/android_libraries.dart';
import 'package:lukitas/settings/licenses.dart';

Future<List<LicenseEntry>> _extras([String language = 'es']) async =>
    extraLicenseEntries(rootBundle, lookupAppLocalizations(Locale(language))).toList();

String _text(LicenseEntry entry) => entry.paragraphs.map((p) => p.text).join('\n');

Future<List<AndroidLibrary>> _libraries() async =>
    parseLibraries(await rootBundle.loadString('assets/licenses/android-libraries.json'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the licences About adds to Flutter\'s', () {
    test('the voice models are listed by name, with the Apache-2.0 text', () async {
      final entries = await _extras();
      for (final model in ['vosk-model-small-es-0.42', 'vosk-model-small-en-us-0.15']) {
        final entry = entries.singleWhere((e) => e.packages.contains(model));
        expect(_text(entry), contains('Version 2.0, January 2004'), reason: model);
        expect(_text(entry), contains('alphacephei.com/vosk/models'), reason: model);
      }
    });

    test('the sounds say they are original work under the app\'s own licence, AGPL-3.0', () async {
      final entries = await _extras('en');
      final sounds = entries.singleWhere((e) => e.packages.contains('Lukitas feedback sounds'));
      expect(_text(sounds), contains('original work'));
      expect(_text(sounds), contains('GNU AFFERO GENERAL PUBLIC LICENSE'));
    });

    test('the speech engine and JNA are named with the versions of the build', () async {
      final libraries = await _libraries();
      String version(String id) => libraries.singleWhere((l) => l.id == id).version;
      final packages = [for (final e in await _extras()) ...e.packages];
      expect(packages, contains('vosk-android ${version('com.alphacephei:vosk-android')}'));
      expect(packages, contains('JNA ${version('net.java.dev.jna:jna')}'));
    });

    test('every library of the release classpath is listed once, with its own version', () async {
      final libraries = await _libraries();
      final listed = [for (final e in await _extras()) ...e.packages];
      for (final library in libraries) {
        final matching = listed.where(
          (p) => p == '${library.id} ${library.version}' || _named(p, library),
        );
        expect(matching, hasLength(1), reason: '${library.id} ${library.version}');
      }
    });

    test('each library sits under the licence its POM declares, not under one for all', () async {
      final libraries = await _libraries();
      final entries = await _extras();
      for (final library in libraries) {
        final entry = entries.singleWhere(
          (e) =>
              e.packages.any((p) => p == '${library.id} ${library.version}' || _named(p, library)),
        );
        final text = _text(entry);
        if (library.license.startsWith('BSD-3-Clause')) {
          expect(
            text,
            contains('Redistribution and use in source and binary forms'),
            reason: library.id,
          );
          expect(
            text,
            isNot(contains('Apache License')),
            reason: '${library.id} is BSD, not Apache',
          );
        } else {
          expect(text, contains('Apache License'), reason: library.id);
        }
      }
    });

    test(
      'the BSD-3-Clause library inside Glance has its published text, apart from the Apache ones',
      () async {
        final entry = (await _extras()).singleWhere(
          (e) => e.packages.any(
            (p) => p.startsWith('androidx.glance:glance-appwidget-external-protobuf '),
          ),
        );
        expect(entry.packages, hasLength(1));
        expect(_text(entry), contains('BSD'));
      },
    );

    test('jspecify, which the release classpath has, is listed', () async {
      final packages = [for (final e in await _extras()) ...e.packages];
      expect(packages.any((p) => p.startsWith('org.jspecify:jspecify ')), isTrue);
    });

    test('JSR 305 is listed with the Apache libraries, as its POM and jar declare', () async {
      final entries = await _extras('en');
      final entry = entries.singleWhere(
        (e) => e.packages.any((p) => p.startsWith('com.google.code.findbugs:jsr305 ')),
      );
      expect(_text(entry), contains('Version 2.0, January 2004'));
      expect(_text(entry), isNot(contains('Redistribution and use in source and binary forms')));
      expect(
        entry.packages.any((p) => p.startsWith('androidx.core:core ')),
        isTrue,
        reason: 'in the same group as the other Apache libraries',
      );
    });

    test('no notice claims one licence for everything', () async {
      for (final language in ['es', 'en']) {
        for (final entry in await _extras(language)) {
          final text = _text(entry).toLowerCase();
          expect(text, isNot(contains('all of them are')), reason: language);
          expect(text, isNot(contains('todas están bajo')), reason: language);
        }
      }
    });

    test('the notices come from the catalog: Spanish and English differ', () async {
      final es = _text(
        (await _extras('es')).firstWhere((e) => e.packages.contains('vosk-model-small-es-0.42')),
      );
      final en = _text(
        (await _extras('en')).firstWhere((e) => e.packages.contains('vosk-model-small-es-0.42')),
      );
      expect(es.split('\n\n').first, isNot(en.split('\n\n').first));
      expect(en, contains('speech model'));
    });

    test('every entry has some text and at least one package name', () async {
      for (final entry in await _extras()) {
        expect(entry.packages, isNotEmpty);
        expect(_text(entry).length, greaterThan(200));
      }
    });

    test('the speech engine names Kaldi and OpenFST, which libvosk.so is built from', () async {
      for (final language in ['es', 'en']) {
        final vosk = (await _extras(language))
            .singleWhere((e) => e.packages.any((p) => p.startsWith('vosk-android ')));
        expect(_text(vosk), contains('Kaldi'), reason: language);
        expect(_text(vosk), contains('OpenFST'), reason: language);
      }
    });

    // What libvosk.so links statically (OpenBLAS without its LAPACK, CLAPACK with libf2c; vosk-api's
    // android/lib/build-vosk.sh) and what libjnidispatch.so embeds (libffi), each with the text its
    // project publishes.
    for (final (name, notice, text) in [
      ('OpenBLAS 0.3.20', 'OpenBLAS', 'Copyright (c) 2011-2014, The OpenBLAS Project'),
      ('CLAPACK 3.2.1', 'CLAPACK', 'Copyright (c) 1992-2008 The University of Tennessee'),
      ('libffi 3.4.4', 'libffi', 'Permission is hereby granted, free of charge'),
    ]) {
      test('$name is listed with its own published text', () async {
        for (final language in ['es', 'en']) {
          final entry = (await _extras(language)).singleWhere((e) => e.packages.contains(name));
          expect(entry.packages, [name]);
          expect(_text(entry), contains(notice), reason: language);
          expect(_text(entry), contains(text), reason: language);
          expect(_text(entry), isNot(contains('Apache License')), reason: language);
        }
      });
    }

    test('CLAPACK also carries the libf2c notice it is built with', () async {
      final entry = (await _extras()).singleWhere((e) => e.packages.contains('CLAPACK 3.2.1'));
      expect(_text(entry), contains('AT&T, Lucent Technologies and Bellcore'));
    });

    test('those versions are the ones of the vosk-android and JNA in the build', () async {
      // OpenBLAS 0.3.20 and CLAPACK 3.2.1 are what vosk-android 0.3.75 is built with, and libffi
      // 3.4.4 what JNA 5.18.1 bundles: upgrading either means checking these entries again.
      final libraries = await _libraries();
      String version(String id) => libraries.singleWhere((l) => l.id == id).version;
      expect(version('com.alphacephei:vosk-android'), '0.3.75');
      expect(version('net.java.dev.jna:jna'), '5.18.1');
    });

    test('the list never silently shrinks', () async {
      final packages = {for (final e in await _extras()) ...e.packages};
      for (final name in [
        'vosk-model-small-es-0.42',
        'vosk-model-small-en-us-0.15',
        'OpenBLAS 0.3.20',
        'CLAPACK 3.2.1',
        'libffi 3.4.4',
        'Fredoka',
        'Nunito',
        'Lukitas feedback sounds',
        'Lukitas',
      ]) {
        expect(packages, contains(name));
      }
      expect(packages.any((p) => p.startsWith('vosk-android ')), isTrue);
      expect(packages.any((p) => p.startsWith('JNA ')), isTrue);
      expect(
        packages.any((p) => p.startsWith('androidx.glance:glance-appwidget-external-protobuf ')),
        isTrue,
      );
    });

    test('every licence text in assets/licenses is bundled and shown', () async {
      final texts = Directory('assets/licenses')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((name) => name.endsWith('.txt'))
          .toList();
      expect(
        texts,
        containsAll([
          'apache-2.0.txt',
          'agpl-3.0.txt',
          'glance-protobuf-bsd-3-clause.txt',
          'openblas-bsd-3-clause.txt',
          'clapack-bsd.txt',
          'libf2c-notice.txt',
          'libffi-mit.txt',
        ]),
      );
      final shown = [for (final e in await _extras()) _text(e)].join('\n');
      for (final name in texts) {
        final text = await rootBundle.loadString('assets/licenses/$name');
        final firstLine = text.split('\n').firstWhere((l) => l.trim().isNotEmpty).trim();
        expect(shown, contains(firstLine), reason: '$name is not shown in About');
      }
    });

    // Fredoka and Nunito, the web's two fonts, are bundled in assets/fonts with the OFL.txt each
    // project publishes (Google Fonts, google/fonts ofl/fredoka and ofl/nunito).
    for (final (name, copyright, file) in [
      ('Fredoka', 'Copyright 2016 The Fredoka Project Authors', 'Fredoka-OFL.txt'),
      ('Nunito', 'Copyright 2014 The Nunito Project Authors', 'Nunito-OFL.txt'),
    ]) {
      test('About lists $name under the SIL Open Font License 1.1', () async {
        for (final language in ['es', 'en']) {
          final entry = (await _extras(language)).singleWhere((e) => e.packages.contains(name));
          expect(entry.packages, [name]);
          expect(_text(entry), contains(copyright), reason: language);
          expect(_text(entry), contains('SIL OPEN FONT LICENSE Version 1.1'), reason: language);
          expect(_text(entry), contains(name), reason: language);
          expect(_text(entry), isNot(contains('Apache License')), reason: language);
          // The text is the one the font ships, whole.
          expect(
            _text(entry),
            contains((await rootBundle.loadString('assets/fonts/$file')).trim().split('\n').last),
            reason: language,
          );
        }
      });
    }

    test('the font notices come from the catalog and say the fonts are inside the app', () async {
      final es = _text((await _extras('es')).singleWhere((e) => e.packages.contains('Nunito')));
      final en = _text((await _extras('en')).singleWhere((e) => e.packages.contains('Nunito')));
      expect(es.split('\n\n').first, isNot(en.split('\n\n').first));
      expect(en, contains('bundled'));
    });

    test('every OFL text in assets/fonts is bundled and shown, next to a font file', () async {
      final files = Directory('assets/fonts').listSync().whereType<File>().toList();
      final names = [for (final f in files) f.uri.pathSegments.last];
      expect(names, containsAll(['Fredoka-Variable.ttf', 'Nunito-Variable.ttf']));
      final shown = [for (final e in await _extras()) _text(e)].join('\n');
      for (final name in names.where((n) => n.endsWith('-OFL.txt'))) {
        final text = await rootBundle.loadString('assets/fonts/$name');
        final firstLine = text.split('\n').firstWhere((l) => l.trim().isNotEmpty).trim();
        expect(shown, contains(firstLine), reason: '$name is not shown in About');
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

/// Whether the listed name [p] is one of the hand-named entries for [library].
bool _named(String p, AndroidLibrary library) => switch (library.id) {
  'com.alphacephei:vosk-android' => p == 'vosk-android ${library.version}',
  'net.java.dev.jna:jna' => p == 'JNA ${library.version}',
  _ => false,
};
