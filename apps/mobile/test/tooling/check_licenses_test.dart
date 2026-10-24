import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// scripts/check-licenses.sh, fed a recorded NOTICES text and pubspec instead of a built APK (CI
/// runs it for real on the release APK).
Future<ProcessResult> _check({
  required String notices,
  required String pubspec,
  Map<String, String> files = const {},
}) async {
  final dir = await Directory.systemTemp.createTemp('check-licenses');
  addTearDown(() => dir.delete(recursive: true));
  for (final MapEntry(key: path, value: content) in files.entries) {
    File('${dir.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }
  final noticesFile = File('${dir.path}/NOTICES')..writeAsStringSync(notices);
  final pubspecFile = File('${dir.path}/pubspec.yaml')..writeAsStringSync(pubspec);
  return Process.run('bash', [
    'scripts/check-licenses.sh',
    '--skip-android',
    '--notices',
    noticesFile.path,
    '--pubspec',
    pubspecFile.path,
  ]);
}

const _pubspec = '''
name: lukitas
dependencies:
  flutter:
    sdk: flutter
  # A comment, not a package.
  dio: 5.11.1
  go_router: 18.0.2
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: 2.16.2
''';

const _licence =
    '\nMIT License\n\nPermission is hereby granted.\n\n--------------------------------------------------------------------------------\n';

void main() {
  test('every direct dependency has a licence entry: passes', () async {
    final result = await _check(
      notices:
          'dio\ndio_web_adapter\n$_licence'
          'go_router\n$_licence',
      pubspec: _pubspec,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    expect(result.stdout, contains('2 direct dependencies'));
  });

  test('a dependency without a licence fails with its name', () async {
    final result = await _check(notices: 'dio\n$_licence', pubspec: _pubspec);
    expect(result.exitCode, 1);
    expect(result.stdout, contains('go_router'));
    expect(result.stdout, isNot(contains('No licence for dio')));
  });

  test('a package that is only a prefix of another one\'s name does not count', () async {
    final result = await _check(notices: 'dio\ngo_router_builder\n$_licence', pubspec: _pubspec);
    expect(result.exitCode, 1);
    expect(result.stdout, contains('go_router'));
  });

  test('development dependencies are not asked for', () async {
    final result = await _check(notices: 'dio\ngo_router\n$_licence', pubspec: _pubspec);
    expect(result.exitCode, 0);
  });

  test('an empty NOTICES or a missing APK is an error, not a pass', () async {
    expect((await _check(notices: '', pubspec: _pubspec)).exitCode, 2);
    final noApk = await Process.run('bash', [
      'scripts/check-licenses.sh',
      '--apk',
      '/nowhere/app.apk',
    ]);
    expect(noApk.exitCode, 2);
  });

  group('the bundled fonts', () {
    const withFonts = '''
name: lukitas
dependencies:
  dio: 5.11.1
flutter:
  assets:
    - assets/fonts/Nunito-OFL.txt
  fonts:
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito-Variable.ttf
''';
    const ofl = 'Copyright 2014 The Nunito Project Authors\n\nSIL OPEN FONT LICENSE Version 1.1\n';

    test('a font with its OFL text bundled passes, and is counted', () async {
      final result = await _check(
        notices: 'dio\n$_licence',
        pubspec: withFonts,
        files: {'assets/fonts/Nunito-Variable.ttf': 'ttf', 'assets/fonts/Nunito-OFL.txt': ofl},
      );
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      expect(result.stdout, contains('1 bundled font'));
    });

    test('a font without an OFL.txt next to it fails with its name', () async {
      final result = await _check(
        notices: 'dio\n$_licence',
        pubspec: withFonts,
        files: {'assets/fonts/Nunito-Variable.ttf': 'ttf'},
      );
      expect(result.exitCode, 1);
      expect(result.stdout, contains('assets/fonts/Nunito-OFL.txt'));
    });

    test('an OFL.txt that pubspec.yaml does not bundle fails: About could not show it', () async {
      final result = await _check(
        notices: 'dio\n$_licence',
        pubspec: withFonts.replaceAll(
          '    - assets/fonts/Nunito-OFL.txt\n',
          '    - assets/other.txt\n',
        ),
        files: {'assets/fonts/Nunito-Variable.ttf': 'ttf', 'assets/fonts/Nunito-OFL.txt': ofl},
      );
      expect(result.exitCode, 1);
      expect(result.stdout, contains('not listed under assets'));
    });

    test('a licence file that is not the OFL fails', () async {
      final result = await _check(
        notices: 'dio\n$_licence',
        pubspec: withFonts,
        files: {'assets/fonts/Nunito-Variable.ttf': 'ttf', 'assets/fonts/Nunito-OFL.txt': 'MIT'},
      );
      expect(result.exitCode, 1);
      expect(result.stdout, contains('SIL Open Font License'));
    });

    test('a font file that is not on disk is an error, not a pass', () async {
      final result = await _check(
        notices: 'dio\n$_licence',
        pubspec: withFonts,
        files: {'assets/fonts/Nunito-OFL.txt': ofl},
      );
      expect(result.exitCode, 2);
    });
  });
}
